import 'dart:developer';

import '../classes/office_elements_class.dart' show BiblicalReading;

/// One verse of a Bible chapter.
class BibleVerse {
  /// Verse label as numbered in the Bible: '12', or '17k' for the Greek
  /// additions of Esther. Empty for an unnumbered line (speaker label,
  /// heading), which is read only when it falls inside a range.
  final String verse;
  final String text;

  const BibleVerse(this.verse, this.text);
}

/// Supplies Bible text to the package, so that a reading can be stored in
/// the YAML by its reference only (`ref`, no `content`).
///
/// Injected by the consumer, like [DataLoader]: the Flutter app backs it with
/// its Bible database, tests and CLI tools with any other source.
abstract class BibleTextProvider {
  /// Verses of [chapter] of [book], in canonical order (sub-verses such as
  /// '1a', '1b' right after '1'), or null if the chapter is unknown.
  /// [book] is the abbreviation used in references ('Jos', '1Jn', 'Ph'...).
  Future<List<BibleVerse>?> chapter(String book, String chapter);
}

/// A contiguous stretch of a reference: from [startVerse] of [startChapter]
/// to [endVerse] of [endChapter].
class BiblePassage {
  final String book;
  final String? startChapter; // null for a single-chapter book ("Jude 1-25")
  final String startVerse;
  final String? endChapter;
  final String endVerse;

  const BiblePassage(this.book, this.startChapter, this.startVerse,
      this.endChapter, this.endVerse);
}

/// Splits a liturgical reference into passages.
///
/// Handles "Jos 2, 1-24", "Ph 1, 27 – 2, 11" (across chapters),
/// "Is 25, 6-12 ; 26, 1-6" (several chapters), "Gn 45, 1-15.21-28"
/// (several segments), "Est 4, 17k-17z" (lettered verses) and
/// "Jude 1-25" (single-chapter book). Throws a [FormatException] otherwise.
List<BiblePassage> parseBibleReference(String reference) {
  final ref = reference
      .replaceAll(RegExp(r'[\u00a0\u202f]'), ' ')
      .replaceAll(RegExp(r'\s*[–—]\s*'), '-')
      .trim();
  final match = RegExp(r'^(\S+)\s+(.+)$').firstMatch(ref);
  if (match == null) throw FormatException('No book in "$reference"');
  final book = match.group(1)!;
  final passages = <BiblePassage>[];

  for (var group in match.group(2)!.split(';')) {
    group = group.trim();
    String? chapter;
    final chapterMatch = RegExp(r'^(\d+)\s*,\s*(.+)$').firstMatch(group);
    if (chapterMatch != null) {
      chapter = chapterMatch.group(1);
      group = chapterMatch.group(2)!;
    }
    for (final segment in group.split('.')) {
      final seg = segment.trim();
      if (seg.isEmpty) continue;
      final dash = seg.indexOf('-');
      if (dash < 0) {
        passages.add(BiblePassage(book, chapter, seg, chapter, seg));
        continue;
      }
      final start = seg.substring(0, dash).trim();
      final end = seg.substring(dash + 1).trim();
      final crossChapter = RegExp(r'^(\d+)\s*,\s*(\S+)$').firstMatch(end);
      if (crossChapter != null) {
        // "27-2, 11": the end is in a later chapter, which then becomes the
        // current one for the following segments.
        passages.add(BiblePassage(book, chapter, start, crossChapter.group(1),
            crossChapter.group(2)!));
        chapter = crossChapter.group(1);
      } else {
        passages.add(BiblePassage(book, chapter, start, chapter, end));
      }
    }
  }
  if (passages.isEmpty) throw FormatException('No verse in "$reference"');
  return passages;
}

/// Returns the text of [reference], or null if [provider] does not know one
/// of its chapters. Throws a [FormatException] if the reference cannot be
/// parsed or names a verse missing from its chapter.
///
/// Each segment of the reference (stretch of consecutive verses, possibly
/// across chapters) is one paragraph: the line breaks of the source (poetry)
/// and the joins between its verses become a single space, so that no two
/// words end up glued together. Between two segments ("1-15.21-28",
/// "6-12 ; 26, 1-6") the text skips verses: the segment ends with a
/// no-break space and "~" (the omission mark of the data), and the next one
/// starts a new paragraph (blank line).
Future<String?> bibleText(String reference, BibleTextProvider provider) async {
  final parts = <String>[];
  for (final p in parseBibleReference(reference)) {
    final verses = <BibleVerse>[];
    if (p.startChapter == null) {
      // Single-chapter book: stored as chapter 1, or 0 in some sources.
      final rows = await provider.chapter(p.book, '1') ??
          await provider.chapter(p.book, '0');
      if (rows == null) return null;
      verses.addAll(_slice(rows, p.startVerse, p.endVerse, reference));
    } else {
      final first = int.parse(p.startChapter!);
      final last = int.parse(p.endChapter!);
      for (var c = first; c <= last; c++) {
        final rows = await provider.chapter(p.book, '$c');
        if (rows == null) return null;
        final from = c == first ? p.startVerse : null;
        final to = c == last ? p.endVerse : null;
        verses.addAll(_slice(rows, from, to, reference));
      }
    }
    parts.add(_flatten(verses.map((v) => v.text)));
  }
  return parts.join('\u00a0~\n\n');
}

/// Verses of [rows] from [from] to [to] (whole chapter side when null).
/// A plain number also covers its lettered sub-verses ('1' -> '1', '1a'...).
List<BibleVerse> _slice(
    List<BibleVerse> rows, String? from, String? to, String reference) {
  int find(String label, {required bool last}) {
    final exact = rows.indexWhere((v) => v.verse == label);
    final subs = [
      for (var i = 0; i < rows.length; i++)
        if (rows[i].verse == label ||
            RegExp('^${RegExp.escape(label)}[a-z]+\$').hasMatch(rows[i].verse))
          i
    ];
    if (subs.isEmpty) {
      // Half verse ("3a", "8b") that the source does not split: whole verse.
      final half = RegExp(r'^(\d+)[a-z]$').firstMatch(label);
      if (half != null) return find(half.group(1)!, last: last);
      throw FormatException('Verse $label not found in "$reference"');
    }
    if (last) return subs.last;
    return exact >= 0 ? exact : subs.first;
  }

  final i = from == null ? 0 : find(from, last: false);
  final j = to == null ? rows.length - 1 : find(to, last: true);
  if (j < i) throw FormatException('Empty range in "$reference"');
  return rows.sublist(i, j + 1);
}

/// Joins verse texts into one line: every line break, with the spaces and
/// indentation (no-break spaces) around it, becomes one space, runs of
/// ordinary spaces are collapsed, then French spacing is applied around
/// ; ! ? : « » (see [_frenchSpacing]).
String _flatten(Iterable<String> texts) => _frenchSpacing(texts
    .map((t) => t.trim())
    .where((t) => t.isNotEmpty)
    .join(' ')
    .replaceAll(RegExp(r'[ \t\r\u00a0\u202f]*\n[ \t\r\n\u00a0\u202f]*'), ' ')
    .replaceAll(RegExp(r' {2,}'), ' '));

/// French typography: a narrow no-break space (U+202F) before ; ! ?, a
/// no-break space (U+00A0) before : and » and after «. The space that was
/// there (ordinary, no-break or narrow) is replaced, never doubled, and one
/// is inserted where there was none. In "?!" only the first mark gets a
/// space; in "?»" the » keeps its own.
String _frenchSpacing(String text) => text
    .replaceAllMapped(
        RegExp(r'(?<=[^ \u00a0\u202f;!?«])[ \u00a0\u202f]*([;!?])'),
        (m) => '\u202f${m[1]}')
    .replaceAllMapped(RegExp(r'(?<=[^ \u00a0\u202f«])[ \u00a0\u202f]*([:»])'),
        (m) => '\u00a0${m[1]}')
    .replaceAll(RegExp(r'«[ \u00a0\u202f]*'), '«\u00a0');

/// Fills the `content` of readings stored by reference only, from
/// [provider]. Readings that already have a content are kept as they are;
/// without a provider, or if the reference cannot be resolved, the content
/// stays null.
Future<List<BiblicalReading>?> hydrateBiblicalReadings(
    List<BiblicalReading>? readings, BibleTextProvider? provider) async {
  if (readings == null || provider == null) return readings;
  return [
    for (final r in readings)
      if (r.content != null || r.ref == null)
        r
      else
        BiblicalReading(
          title: r.title,
          subtitle: r.subtitle,
          ref: r.ref,
          content: await _safeBibleText(r.ref!, provider),
          responsory: r.responsory,
        ),
  ];
}

Future<String?> _safeBibleText(String ref, BibleTextProvider provider) async {
  try {
    return await bibleText(ref, provider);
  } catch (e) {
    log('Cannot resolve Bible reference "$ref"',
        name: 'BibleTextProvider', level: 900, error: e);
    return null;
  }
}
