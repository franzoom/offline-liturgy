// Biblical readings can be stored by reference only: the text comes from an
// injected BibleTextProvider. These tests cover the reference parser on an
// in-memory Bible, then check that every reference stored without content
// resolves in the aelf-flutter Bible database (skipped if it is missing).

import 'dart:io';

import 'package:test/test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:yaml/yaml.dart';

import 'tools/sqlite_bible_text_provider.dart';

class _FakeBible implements BibleTextProvider {
  final Map<String, List<BibleVerse>> chapters;
  _FakeBible(this.chapters);

  @override
  Future<List<BibleVerse>?> chapter(String book, String chapter) async =>
      chapters['$book $chapter'];
}

List<BibleVerse> _verses(String prefix, int count) =>
    [for (var i = 1; i <= count; i++) BibleVerse('$i', '$prefix$i')];

void main() {
  final bible = _FakeBible({
    'Ph 1': _verses('a', 30),
    'Ph 2': _verses('b', 30),
    'Ph 3': _verses('c', 21),
    'Jude 1': _verses('j', 25),
    'Ab 0': _verses('o', 21),
    'Est 5': [
      const BibleVerse('1', 'e1'),
      const BibleVerse('1a', 'e1a'),
      const BibleVerse('1b', 'e1b'),
      const BibleVerse('2', 'e2'),
      const BibleVerse('3', 'e3'),
    ],
    'Ps 2': [
      const BibleVerse('1', 'line 1\nline 2'),
      const BibleVerse('2', 'line 3'),
    ],
    'Ps 3': [
      const BibleVerse('1', 'end\u00a0!  \n'),
      const BibleVerse('2', '\n next \n\n word'),
    ],
  });

  group('bibleText', () {
    test('simple range', () async {
      expect(await bibleText('Ph 1, 2-4', bible), 'a2 a3 a4');
    });

    test('range across chapters, then a segment of the last one', () async {
      expect(await bibleText('Ph 1, 29 – 2, 2.5-6', bible),
          'a29 a30 b1 b2\u00a0~\n\nb5 b6');
    });

    test('several chapters separated by a semicolon', () async {
      expect(
          await bibleText('Ph 1, 1 ; 3, 20-21', bible), 'a1\u00a0~\n\nc20 c21');
    });

    test('a plain verse includes its lettered sub-verses', () async {
      expect(await bibleText('Est 5, 1.2', bible), 'e1 e1a e1b\u00a0~\n\ne2');
      expect(await bibleText('Est 5, 1b-3', bible), 'e1b e2 e3');
    });

    test('a half verse missing from the source takes the whole verse',
        () async {
      expect(await bibleText('Ph 1, 3a-4', bible), 'a3 a4');
    });

    test('single-chapter books, stored as chapter 1 or 0', () async {
      expect(await bibleText('Jude 24-25', bible), 'j24 j25');
      expect(await bibleText('Ab 20-21', bible), 'o20 o21');
    });

    test('line breaks become single spaces', () async {
      expect(await bibleText('Ps 2, 1-2', bible), 'line 1 line 2 line 3');
      expect(await bibleText('Ps 3, 1-2', bible), 'end\u00a0! next word');
    });

    test('unknown chapter gives null, unknown verse throws', () async {
      expect(await bibleText('Ph 9, 1', bible), isNull);
      expect(bibleText('Ph 1, 99', bible), throwsFormatException);
    });
  });

  test('hydrateBiblicalReadings fills only readings without content', () async {
    final readings = await hydrateBiblicalReadings([
      const BiblicalReading(ref: 'Ph 1, 1', responsory: 'R/'),
      const BiblicalReading(ref: 'Ph 1, 2', content: 'kept'),
    ], bible);
    expect(readings!.map((r) => r.content), ['a1', 'kept']);
    expect(readings.first.responsory, 'R/');
    expect(await hydrateBiblicalReadings(readings, null), same(readings));
  });

  group('references stored without content resolve in the Bible database', () {
    final dbFile = File(bibleDbPath);
    if (!dbFile.existsSync()) {
      test('Bible database not found at $bibleDbPath', () {},
          skip: 'set BIBLE_DB to the aelf-flutter bible.db');
      return;
    }
    final provider = SqliteBibleTextProvider(dbFile.path);
    tearDownAll(provider.close);

    final refs = <String, String>{}; // ref -> file
    for (final file in Directory('assets/calendar_data')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.yaml'))) {
      final yaml = loadYaml(file.readAsStringSync());
      final readings = yaml is Map ? yaml['readings'] : null;
      if (readings is! Map) continue;
      for (final entry in readings.entries) {
        if (!'${entry.key}'.startsWith('biblicalReading')) continue;
        final list = entry.value is List ? entry.value : [entry.value];
        for (final r in list) {
          if (r is Map && r['content'] == null && r['ref'] != null) {
            refs['${r['ref']}'] = file.path;
          }
        }
      }
    }

    test('there are readings stored by reference', () {
      expect(refs, isNotEmpty);
    });

    for (final e in refs.entries) {
      test('${e.key} (${e.value.split('/').last})', () async {
        final text = await bibleText(e.key, provider);
        expect(text, isNotNull);
        expect(text!.trim(), isNotEmpty);
        // one paragraph per segment of the reference, each but the last
        // ending with the omission mark; no line break inside a segment
        final paragraphs = text.split('\n\n');
        expect(paragraphs, hasLength(parseBibleReference(e.key).length));
        for (var i = 0; i < paragraphs.length; i++) {
          expect(paragraphs[i], isNot(contains('\n')));
          expect(paragraphs[i], isNot(contains('  ')));
          expect(paragraphs[i].endsWith('\u00a0~'), i < paragraphs.length - 1);
        }
      });
    }
  });
}
