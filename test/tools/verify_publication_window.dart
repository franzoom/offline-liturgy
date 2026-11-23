// One-off verification script (NOT a test, not part of the committed suite):
// compares this package's data against the live AELF API
// (https://api.aelf.org, the same data behind aelf.org) for a specific
// publication window, requested ahead of a release. Deliberately not
// integrated into the regression tests — delete after use.
//
// Scope:
// - Mass (every day, not just Sundays): biblical reading REFERENCES only
//   (AELF's Mass API gives no prayer text at all).
// - Every Office (Lectures, Laudes, Tierce, Sexte, None, Vêpres, Complies):
//   the office's own biblical reading REFERENCE (AELF: pericope/lecture).
//   Psalm/canticle antiphon references are NOT redone here: they're already
//   covered, for 2024-2026, by the committed test/aelf_antiphons_reference_test.dart
//   — see this script's own stdout banner for how 2027 was checked instead.
// - The responsory's full TEXT, word-normalized (AELF gives it no reference
//   at all, so text is the only thing to compare).
// - The oration's full TEXT, word-normalized, for Lauds and Vêpres only (by
//   explicit choice — not Readings/Tierce/Sexte/None/Complies).
//
// Usage: dart run test/tools/verify_publication_window.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:offline_liturgy/offline_liturgy.dart';

const String _location = 'france';
const String _aelfZone = 'france';
final DateTime _startDate = DateTime(2026, 11, 23);
final DateTime _endDate = DateTime(2027, 1, 31);
const int _maxConcurrentRequests = 8;
const int _maxAttempts = 3;
const List<String> _officeCodes = [
  'lectures',
  'laudes',
  'tierce',
  'sexte',
  'none',
  'vepres',
  'complies',
];

String _iso(DateTime d) => d.toIso8601String().substring(0, 10);

void main() async {
  final data = await LiturgyData.load();
  final loader = FileSystemDataLoader();
  final client = HttpClient();
  final semaphore = _Semaphore(_maxConcurrentRequests);

  final calendars = <int, Calendar>{};
  Calendar calendarFor(DateTime date) => calendars[date.year] ??=
      getCalendar(Calendar(), DateTime(date.year, 1, 1), _location, data);

  final dates = [
    for (var d = _startDate; !d.isAfter(_endDate); d = d.add(const Duration(days: 1))) d,
  ];

  print('Vérification AELF du ${_iso(_startDate)} au ${_iso(_endDate)} '
      '(${dates.length} jours, zone $_aelfZone)...\n');

  final massMismatches = <String>[];
  final refMismatches = <String>[];
  final textMismatches = <String>[];
  final failures = <String>[];
  int comparedMass = 0;
  int comparedRefs = 0;
  int comparedTexts = 0;
  int done = 0;

  Future<void> processDate(DateTime date) async {
    await semaphore.acquire();
    try {
      final iso = _iso(date);
      final calendar = calendarFor(date);

      final aelfOffices = <String, Map<String, dynamic>?>{};
      for (final office in _officeCodes) {
        aelfOffices[office] = await _getJson(client, office, iso);
      }
      final aelfMesses = await _getJson(client, 'messes', iso);

      if (aelfOffices.values.any((v) => v == null) || aelfMesses == null) {
        failures.add(iso);
        return;
      }

      // ---------------- Mass: reading references, every day ----------------
      final massDetected = await massDetection(calendar, date, loader);
      final aelfMassList = aelfMesses['messes'] as List? ?? [];
      if (massDetected.isNotEmpty && aelfMassList.isNotEmpty) {
        final principal = massDetected.values.first.celebrationCode;
        final ours = <String, List<_Ref>>{
          for (final e in massDetected.entries)
            if (e.value.celebrationCode == principal)
              e.key: _ourMassRefs(await massExport(e.value)),
        };
        for (final aelfMass in aelfMassList) {
          final aelfRefs = _aelfMassRefs(aelfMass as Map<String, dynamic>);
          if (aelfRefs.isEmpty || ours.isEmpty) continue;
          comparedMass++;
          final aelfChapters = aelfRefs.map((r) => r.chapter).toSet();
          final best = ours.entries.reduce((a, b) {
            int score(List<_Ref> refs) =>
                refs.map((r) => r.chapter).toSet().intersection(aelfChapters).length;
            return score(b.value) > score(a.value) ? b : a;
          });
          final ourChapters = best.value.map((r) => r.chapter).toSet();
          final missing = aelfRefs.where((r) => !ourChapters.contains(r.chapter)).toList();
          if (missing.isNotEmpty) {
            massMismatches.add('$iso [${aelfMass['nom']}] ($principal) '
                'AELF seulement : ${missing.map((r) => r.raw).join(' | ')} '
                '— appli : ${best.value.map((r) => r.raw).join(' | ')}');
          }
        }
      }

      // ---------------- Offices: reading ref, responsory, oration ----------------
      Future<CelebrationContext?> winner(
          Future<Map<String, CelebrationContext>> Function() detect) async {
        final map = await detect();
        return map.values.isEmpty ? null : map.values.first;
      }

      void compareRef(String label, String? aelfRef, String? ourRef) {
        if (aelfRef == null || aelfRef.isEmpty) return;
        comparedRefs++;
        if (ourRef == null || _bookChapterKey(ourRef) != _bookChapterKey(aelfRef)) {
          refMismatches.add('$label — AELF: "$aelfRef" / appli: "${ourRef ?? '(absent)'}"');
        }
      }

      void compareText(String label, String? aelfRaw, String? ourRaw) {
        final aelfWords = _wordsKey(_normalize(aelfRaw));
        if (aelfWords.isEmpty) return;
        comparedTexts++;
        final ourWords = _wordsKey(_normalize(ourRaw));
        if (ourWords != aelfWords) {
          textMismatches.add('$label\n'
              '      AELF  : ${_normalize(aelfRaw)}\n'
              '      appli : ${_normalize(ourRaw) == '' ? '(absent)' : _normalize(ourRaw)}');
        }
      }

      final morning = await winner(() => morningDetection(calendar, date, loader));
      if (morning != null) {
        final m = await morningExport(morning);
        final laudes = aelfOffices['laudes']!['laudes'] as Map<String, dynamic>;
        compareRef('$iso Laudes lecture',
            (laudes['pericope'] as Map?)?['reference'] as String?, m.reading?.biblicalReference);
        compareText('$iso Laudes répons', laudes['repons'] as String?, m.responsory);
        compareText('$iso Laudes oraison', laudes['oraison'] as String?, m.oration?.join(' '));
      }

      final vespers = await winner(() => vespersDetection(calendar, date, loader));
      if (vespers != null) {
        final v = await vespersExport(vespers);
        final vepres = aelfOffices['vepres']!['vepres'] as Map<String, dynamic>;
        compareRef('$iso Vêpres lecture',
            (vepres['pericope'] as Map?)?['reference'] as String?, v.reading?.biblicalReference);
        compareText('$iso Vêpres répons', vepres['repons'] as String?, v.responsory);
        compareText('$iso Vêpres oraison', vepres['oraison'] as String?, v.oration?.join(' '));
      }

      final readings = await winner(() => readingsDetection(calendar, date, loader));
      if (readings != null) {
        final r = await readingsExport(readings);
        final lectures = aelfOffices['lectures']!['lectures'] as Map<String, dynamic>;
        final biblical = r.biblicalReading?.isNotEmpty == true ? r.biblicalReading!.first : null;
        compareRef('$iso Lectures (biblique)',
            (lectures['lecture'] as Map?)?['reference'] as String?, biblical?.ref);
        compareText('$iso Lectures répons (biblique)',
            lectures['repons_lecture'] as String?, biblical?.responsory);
        final patristic = r.patristicReading?.isNotEmpty == true ? r.patristicReading!.first : null;
        compareText('$iso Lectures répons (patristique)',
            lectures['repons_patristique'] as String?, patristic?.responsory);
      }

      final middleOfDay = await winner(() => middleOfDayDetection(calendar, date, loader));
      if (middleOfDay != null) {
        final md = await middleOfDayExport(middleOfDay);
        for (final (hour, office, aelfKey) in [
          (md.tierce, 'tierce', 'tierce'),
          (md.sexte, 'sexte', 'sexte'),
          (md.none, 'none', 'none'),
        ]) {
          if (hour == null) continue;
          final aelfHour = aelfOffices[aelfKey]![office] as Map<String, dynamic>;
          compareRef('$iso ${office[0].toUpperCase()}${office.substring(1)} lecture',
              (aelfHour['pericope'] as Map?)?['reference'] as String?,
              hour.reading?.biblicalReference);
          compareText('$iso ${office[0].toUpperCase()}${office.substring(1)} répons',
              aelfHour['repons'] as String?, hour.responsory);
        }
      }

      final complineMap = await complineDetection(calendar, date, loader);
      if (complineMap.isNotEmpty) {
        final c = await complineExport(complineMap.values.first);
        final complies = aelfOffices['complies']!['complies'] as Map<String, dynamic>;
        compareRef('$iso Complies lecture',
            (complies['pericope'] as Map?)?['reference'] as String?, c.reading?.biblicalReference);
        compareText('$iso Complies répons', complies['repons'] as String?, c.responsory);
      }
    } catch (e, st) {
      failures.add('${_iso(date)} (exception: $e)');
      stderr.writeln('Erreur pour ${_iso(date)}: $e\n$st');
    } finally {
      semaphore.release();
      done++;
      if (done % 10 == 0) print('  $done/${dates.length}...');
    }
  }

  try {
    await Future.wait(dates.map(processDate));
  } finally {
    client.close();
  }

  print('\n===== RÉSUMÉ ($comparedMass messe(s), $comparedRefs référence(s) '
      'd\'office, $comparedTexts texte(s) comparés) =====\n');

  if (failures.isNotEmpty) {
    print('${failures.length} jour(s) en échec de récupération AELF :');
    for (final f in failures) {
      print('  $f');
    }
    print('');
  }

  if (massMismatches.isEmpty) {
    print('Messe : aucun écart de référence de lecture.');
  } else {
    print('Messe : ${massMismatches.length} écart(s) de référence :');
    for (final m in massMismatches) {
      print('  $m');
    }
  }
  print('');

  if (refMismatches.isEmpty) {
    print('Offices : aucun écart de référence de lecture.');
  } else {
    print('Offices : ${refMismatches.length} écart(s) de référence :');
    for (final m in refMismatches) {
      print('  $m');
    }
  }
  print('');

  if (textMismatches.isEmpty) {
    print('Répons/oraisons : aucun écart de texte.');
  } else {
    print('Répons/oraisons : ${textMismatches.length} écart(s) de texte :');
    for (final m in textMismatches) {
      print('  $m');
    }
  }
}

/// The office's JSON, retried [_maxAttempts] times; null if it still fails.
/// A 404 (an office AELF doesn't have that day, e.g. Readings on Easter
/// Sunday) is an empty map, not a failure.
Future<Map<String, dynamic>?> _getJson(
    HttpClient client, String office, String isoDate) async {
  final uri = Uri.parse('https://api.aelf.org/v1/$office/$isoDate/$_aelfZone');
  for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        decoded.putIfAbsent(office, () => <String, dynamic>{});
        return decoded;
      }
      if (response.statusCode == HttpStatus.notFound) {
        await response.drain();
        return {office: <String, dynamic>{}, 'messes': <dynamic>[]};
      }
      await response.drain();
    } catch (_) {
      // retried below
    }
    await Future.delayed(Duration(seconds: attempt));
  }
  return null;
}

class _Semaphore {
  _Semaphore(this._max);
  final int _max;
  int _current = 0;
  final _waiting = <Completer<void>>[];

  Future<void> acquire() {
    if (_current < _max) {
      _current++;
      return Future.value();
    }
    final completer = Completer<void>();
    _waiting.add(completer);
    return completer.future;
  }

  void release() {
    _current--;
    if (_waiting.isNotEmpty) {
      _current++;
      _waiting.removeAt(0).complete();
    }
  }
}

// ---------------- Mass reading references (adapted from
// test/aelf_sunday_masses_reference_test.dart, generalized to every day) ----------------

class _Ref {
  final String chapter;
  final String full;
  final String raw;
  _Ref(this.chapter, this.full, this.raw);
}

final _psalmStart = RegExp(r'^(?:ps\.?\s*)?(\d+)', caseSensitive: false);
final _bookChapterPattern =
    RegExp(r'^(\d?\s*[a-zà-ÿ]+)\.?\s*(\d+)', caseSensitive: false);
const _bookAliases = {'jean': 'jn', 'matthieu': 'mt', 'marc': 'mc', 'luc': 'lc'};

_Ref? _parseMassRef(String? raw, {required bool psalm}) {
  if (raw == null) return null;
  var s = raw
      .replaceAll(RegExp(r'[  \s]+'), ' ')
      .replaceAll(RegExp(r'[–—]'), '-')
      .trim();
  if (s.isEmpty) return null;
  s = s.replaceFirst(RegExp(r'^cf\.?\s*', caseSensitive: false), '');
  final full = s.toLowerCase().replaceAll(' ', '').replaceFirst('ps', '');
  if (psalm) {
    final m = _psalmStart.firstMatch(s);
    if (m != null) return _Ref('ps${m.group(1)}', full, raw);
  }
  final m = _bookChapterPattern.firstMatch(s);
  if (m == null) return _Ref(full, full, raw);
  final book = _bookAliases[m.group(1)!.toLowerCase().replaceAll(' ', '')] ??
      m.group(1)!.toLowerCase().replaceAll(' ', '');
  return _Ref('$book${m.group(2)}', full, raw);
}

List<String?> _refsOf(MassReadingContent c) => switch (c) {
      MassReading r => [r.biblicalRef, r.shortReadingRef],
      MassPsalm p => [p.biblicalRef],
      MassGospel g => [g.biblicalRef, g.shortBiblicalRef],
    };

List<_Ref> _ourMassRefs(Mass mass) => [
      for (final part in mass.readingParts ?? <MassReadingPart>[])
        for (final c in part.partContents)
          for (final raw in _refsOf(c))
            if (_parseMassRef(raw, psalm: part.partType == 'PSALM') case final ref?) ref,
    ];

List<_Ref> _aelfMassRefs(Map<String, dynamic> mass) => [
      for (final l in (mass['lectures'] as List? ?? []))
        if (_parseMassRef(l['ref'] as String?,
                psalm: l['type'] == 'psaume' || l['type'] == 'cantique')
            case final ref?)
          ref,
    ];

// ---------------- Biblical-reading reference comparison (offices) ----------------

/// "1 S 2", "1S 2,1-10", "Ap 4-5" → "1s 2", "1s 2", "ap 4" — book/chapter
/// only, same normalization idea as test/aelf_antiphons_reference_test.dart's
/// own _bookChapterKey, so spacing/abbreviation differences aren't reported.
String _bookChapterKey(String reference) {
  final match =
      RegExp(r'^\s*(\d?\s*\p{L}+)\s*(\d+)', unicode: true).firstMatch(reference);
  if (match == null) return reference.toLowerCase();
  final book = match.group(1)!.replaceAll(' ', '').toLowerCase();
  return '$book ${match.group(2)}';
}

// ---------------- Text comparison (adapted from
// test/aelf_antiphons_reference_test.dart's _normalize/_wordsKey) ----------------

const _htmlNamedEntities = {
  'nbsp': ' ',
  'eacute': 'é',
  'egrave': 'è',
  'ecirc': 'ê',
  'euml': 'ë',
  'agrave': 'à',
  'acirc': 'â',
  'ccedil': 'ç',
  'ocirc': 'ô',
  'ograve': 'ò',
  'ucirc': 'û',
  'ugrave': 'ù',
  'uuml': 'ü',
  'icirc': 'î',
  'iuml': 'ï',
  'oelig': 'œ',
  'OElig': 'Œ',
  'rsquo': '’',
  'lsquo': '‘',
  'laquo': '«',
  'raquo': '»',
  'hellip': '…',
  'mdash': '—',
  'ndash': '–',
  'amp': '&',
};

String _decodeHtmlEntities(String t) {
  t = t.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'),
      (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)));
  t = t.replaceAllMapped(
      RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m.group(1)!)));
  return t.replaceAllMapped(RegExp(r'&(\w+);'), (m) {
    final name = m.group(1)!;
    return _htmlNamedEntities[name] ?? m.group(0)!;
  });
}

String _normalize(String? text) {
  if (text == null) return '';
  var t = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
  t = _decodeHtmlEntities(t);
  t = t.replaceAll('’', "'").replaceAll('‘', "'");
  t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
  return t;
}

String _wordsKey(String text) {
  final t = text
      .replaceAll('­', '')
      .replaceAll('œ', 'oe')
      .replaceAll('Œ', 'Oe')
      .replaceAll(RegExp(r'\b[RV]/'), ' ');
  return t
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .split(' ')
      .where((w) => w.isNotEmpty)
      .join(' ');
}
