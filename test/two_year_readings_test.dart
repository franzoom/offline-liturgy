// The Office of Readings can follow the two-year cycle of biblical readings:
// ferial files carry biblicalReadingEven / biblicalReadingOdd next to the
// annual biblicalReading, and CelebrationContext.twoYearReadingCycle selects
// the variant by the parity of the liturgical year. A variant is a single
// reading, with no responsory (the annual one is used) and no content (the
// text comes from the Bible provider).

import 'dart:io';

import 'package:test/test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';

import 'tools/sqlite_bible_text_provider.dart';

String _flat(String? s) => (s ?? '').replaceAll(RegExp(r'[\s  ]+'), ' ');

void main() {
  group('Readings.fromJson biblicalCycle', () {
    final annual = {'ref': 'A 1', 'responsory': 'R/ annual'};
    final data = {
      'biblicalReading': [annual],
      'biblicalReadingEven': [
        {'ref': 'E 1'},
      ],
      'biblicalReadingOdd': [
        {'ref': 'O 1', 'responsory': 'R/ own'},
      ],
    };

    test('no cycle keeps the annual reading', () {
      final r = Readings.fromJson(data);
      expect(r.biblicalReading!.map((b) => b.ref), ['A 1']);
    });

    test('a variant without responsory takes the annual one', () {
      final r = Readings.fromJson(data, biblicalCycle: 'Even');
      expect(r.biblicalReading!.map((b) => b.ref), ['E 1']);
      expect(r.biblicalReading!.map((b) => b.responsory), ['R/ annual']);
    });

    test('a variant keeps its own responsory', () {
      final r = Readings.fromJson(data, biblicalCycle: 'Odd');
      expect(r.biblicalReading!.map((b) => b.ref), ['O 1']);
      expect(r.biblicalReading!.map((b) => b.responsory), ['R/ own']);
    });

    test('a missing variant falls back to the annual reading', () {
      final r = Readings.fromJson({
        'biblicalReading': [annual]
      }, biblicalCycle: 'Even');
      expect(r.biblicalReading!.map((b) => b.ref), ['A 1']);
    });
  });

  test('twoYearReadingCycle follows the liturgical year parity', () {
    expect(twoYearReadingCycle(2026), 'Even');
    expect(twoYearReadingCycle(2027), 'Odd');
  });

  // Tuesday of the 10th week in Ordinary Time (ot_10_2): annual Jos 2,
  // even years Ph 1,27 – 2,11, odd years Jos 2 again.
  final cases = <String, (int, bool, String, String)>{
    'annual cycle': (2026, false, 'Jos 2, 1-24', 'Depuis Shittim'),
    'two-year cycle, even year': (
      2026,
      true,
      'Ph 1, 27 – 2, 11',
      'Quant à vous'
    ),
    'two-year cycle, odd year': (2027, true, 'Jos 2, 1-24', 'Depuis Shittim'),
  };
  final dbFile = File(bibleDbPath);
  final provider =
      dbFile.existsSync() ? SqliteBibleTextProvider(dbFile.path) : null;
  tearDownAll(() => provider?.close());

  Future<Readings> office(
      int year, bool twoYears, BibleTextProvider? bibleTextProvider) async {
    final data = await LiturgyData.load();
    final dataLoader = FileSystemDataLoader();
    final calendar =
        getCalendar(Calendar(), DateTime(year, 2, 18), 'romain', data);
    final date = calendar.calendarData.entries
        .firstWhere((e) =>
            e.value.defaultCelebrationTitle == 'ot_10_2' &&
            e.value.liturgicalYear == year)
        .key;
    final contexts = await readingsDetection(calendar, date, dataLoader);
    final context = contexts.values
        .firstWhere((c) => c.celebrationCode == 'ot_10_2')
        .copyWith(
            twoYearReadingCycle: twoYears,
            bibleTextProvider: bibleTextProvider);
    return readingsExport(context);
  }

  group('Office of Readings on ot_10_2', () {
    for (final entry in cases.entries) {
      test(entry.key, () async {
        final (year, twoYears, expectedRef, expectedStart) = entry.value;
        final reading =
            (await office(year, twoYears, provider)).biblicalReading!.single;
        expect(_flat(reading.ref), _flat(expectedRef));
        expect(reading.responsory, startsWith('R/'));
        expect(reading.content, startsWith(expectedStart));
      }, skip: provider == null ? 'Bible database not found' : false);
    }

    // Without the text of the even-year reading, the annual one is used.
    for (final (label, bible) in [
      ('no Bible provider', null),
      ('a Bible that lacks the chapter', _EmptyBible()),
    ]) {
      test('two-year cycle with $label falls back to the annual reading',
          () async {
        final reading =
            (await office(2026, true, bible)).biblicalReading!.single;
        expect(_flat(reading.ref), _flat('Jos 2, 1-24'));
        expect(reading.content, startsWith('Depuis Shittim'));
      });
    }
  });
}

class _EmptyBible implements BibleTextProvider {
  @override
  Future<List<BibleVerse>?> chapter(String book, String chapter) async => null;
}
