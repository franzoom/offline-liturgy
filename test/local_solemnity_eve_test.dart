// A memorial or a feast celebrated as a local solemnity (a precedence
// override to 4) begins with its First Vespers: vespersEveCandidates lists
// tomorrow's memorials and feasts that may be raised, and once raised
// vespersDetection and complineDetection give them their First Vespers and
// the Compline of their eve — then, on the day, a solemnity's Compline.

import 'package:test/test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';

void main() {
  late LiturgyData data;
  final dataLoader = FileSystemDataLoader();

  setUpAll(() async => data = await LiturgyData.load());

  Calendar calendarFor(DateTime date) =>
      getCalendar(Calendar(), date, 'lyon', data);

  /// [code] raised to a local solemnity on [day]
  PrecedenceOverride raise(DateTime day, String code) =>
      (date, celebrationCode) =>
          date.isSameDayAs(day) && celebrationCode == code ? 4 : null;

  const agatha = 'roman/agatha_of_sicily_virgin';
  final agathaEve = DateTime(2027, 2, 4); // Thursday, Ordinary Time
  final agathaDay = DateTime(2027, 2, 5);

  group('vespersEveCandidates', () {
    test("lists tomorrow's memorial, not celebrable", () async {
      final candidates = await vespersEveCandidates(
          calendarFor(agathaEve), agathaEve, dataLoader);
      final c = candidates['I Vespers: Sainte Agathe']!;
      expect(c.celebrationCode, agatha);
      expect(c.celebrationType, 'vespers1');
      expect(c.date, agathaDay);
      expect(c.isCelebrable, isFalse);
    });

    test('no longer lists it once raised', () async {
      final candidates = await vespersEveCandidates(
          calendarFor(agathaEve), agathaEve, dataLoader,
          precedenceOverride: raise(agathaDay, agatha));
      expect(candidates, isEmpty);
    });

    test('nothing when today is a solemnity of the general calendar', () async {
      // Mary, Mother of God (prec. 3), before Saints Basil and Gregory
      final date = DateTime(2027, 1, 1);
      expect(await vespersEveCandidates(calendarFor(date), date, dataLoader),
          isEmpty);
    });
  });

  group('vespersDetection', () {
    test("a raised memorial's First Vespers outrank a weekday's Vespers",
        () async {
      final vespers = await vespersDetection(
          calendarFor(agathaEve), agathaEve, dataLoader,
          precedenceOverride: raise(agathaDay, agatha));
      final first = vespers.entries.first;
      expect(first.key, 'I Vespers: Sainte Agathe');
      expect(first.value.isFirstVespers, isTrue);
      expect(first.value.precedence, 4);
      expect(first.value.isCelebrable, isTrue);
      expect(
          vespers.values
              .where((c) => c.celebrationCode == 'ot_4_4')
              .single
              .isCelebrable,
          isFalse);
    });

    test(
        'a feast of the Lord with First Vespers only on a Sunday has them '
        'once a local solemnity', () async {
      // The Presentation of the Lord on Tuesday, Feb 2
      final monday = DateTime(2027, 2, 1);
      final presentation = DateTime(2027, 2, 2);
      final candidates =
          await vespersEveCandidates(calendarFor(monday), monday, dataLoader);
      final code = candidates.values.single.celebrationCode;

      final vespers = await vespersDetection(
          calendarFor(monday), monday, dataLoader,
          precedenceOverride: raise(presentation, code));
      expect(vespers.values.first.celebrationCode, code);
      expect(vespers.values.first.isFirstVespers, isTrue);
      expect(vespers.values.first.isCelebrable, isTrue);

      // Its Sunday file's First Vespers, as when Feb 2 is a Sunday (2025)
      final saturday = DateTime(2025, 2, 1);
      final sundayFirstVespers =
          (await vespersDetection(calendarFor(saturday), saturday, dataLoader))
              .values
              .firstWhere((c) =>
                  c.celebrationCode == 'roman/presentation_of_the_lord_sunday');
      final raised = await vespersExport(vespers.values.first);
      final sunday = await vespersExport(sundayFirstVespers);
      expect(raised.evangelicAntiphon, isNotNull);
      expect(raised.evangelicAntiphon.toString(),
          sunday.evangelicAntiphon.toString());
      // The proper's hymn: the season's, after it, depend on the day
      expect(raised.hymn?.first.code, sunday.hymn?.first.code);
    });

    test(
        "a proper solemnity's First Vespers outrank an Ordinary Time Sunday's "
        'Second Vespers', () async {
      // Saint Luke (Monday, Oct 18) made a local solemnity
      final sunday = DateTime(2027, 10, 17);
      final vespers = await vespersDetection(
          calendarFor(sunday), sunday, dataLoader,
          precedenceOverride:
              raise(DateTime(2027, 10, 18), 'roman/luke_evangelist'));
      expect(vespers.keys.first, 'I Vespers: Saint Luc');
      expect(vespers.values.first.isCelebrable, isTrue);
      expect(
          vespers.values
              .where((c) => c.celebrationCode == 'ot_29_0')
              .single
              .isCelebrable,
          isFalse);
    });
  });

  group('complineDetection', () {
    test("the eve of a raised memorial has only its eve's Compline", () async {
      final complines = await complineDetection(
          calendarFor(agathaEve), agathaEve, dataLoader,
          precedenceOverride: raise(agathaDay, agatha));
      expect(complines.length, 1);
      expect(complines.values.single.isEveCompline, isTrue);
      expect(complines.values.single.dayOfCompline, 'saturday');
    });

    test("a raised memorial's day has a solemnity's Compline", () async {
      final complines = await complineDetection(
          calendarFor(agathaDay), agathaDay, dataLoader,
          precedenceOverride: raise(agathaDay, agatha));
      expect(complines.keys.first, startsWith('Complies de Sainte Agathe'));
      expect(complines.values.first.dayOfCompline, 'sunday');
    });
  });
}
