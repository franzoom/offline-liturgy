// The offices of the Dedication and of the Dead, celebrated in place of the
// day's celebrations: the ferial day under a Common alone. Every part of
// every hour must be there, in Ordinary Time, Easter time, Lent and Advent.

import 'package:test/test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/tools/constants.dart' show dayName;

void main() {
  late LiturgyData data;
  final dataLoader = FileSystemDataLoader();

  setUpAll(() async => data = await LiturgyData.load());

  final dates = {
    'Ordinary Time': DateTime(2027, 7, 13),
    'Easter time': DateTime(2027, 5, 4),
    'Lent': DateTime(2027, 3, 3),
    'Advent': DateTime(2026, 12, 9),
  };

  List<String> missingParts(HourPrayer office) => [
        if (office.hymn?.isEmpty ?? true) 'hymn',
        if ((office.psalmody?.where((p) => p.psalmData != null).length ?? 0) <
            3)
          'psalmody',
        if (office.reading == null) 'reading',
        if (office.responsory == null) 'responsory',
        if (office.evangelicAntiphon?.isEmpty ?? true) 'evangelic antiphon',
        if (office.intercession == null) 'intercession',
        if (office.oration?.isEmpty ?? true) 'oration',
      ];

  for (final MapEntry(key: season, value: date) in dates.entries) {
    for (final office in VotiveOffice.values) {
      for (final common in votiveCommons[office]!) {
        test('$season: ${office.name} with $common, every part', () async {
          final calendar = getCalendar(Calendar(), date, 'lyon', data);
          CelebrationContext withCommon(CelebrationContext c) =>
              c.copyWith(commonList: [common]);
          Future<CelebrationContext> hour(String type) async =>
              withCommon((await votiveOfficeDetection(
                      calendar, date, dataLoader, office, type))
                  .values
                  .single);

          final lauds = await morningExport(await hour('morning'));
          expect(missingParts(lauds), isEmpty, reason: 'Lauds');
          expect(lauds.invitatory, isNotNull);

          final vespers =
              await votiveVespersDetection(calendar, date, dataLoader, office);
          expect(
              vespers.values.map((v) => v.celebrationType),
              office == VotiveOffice.dedication
                  ? ['vespers2', 'vespers1']
                  : ['vespers2']);
          for (final v in vespers.values) {
            expect(missingParts(await vespersExport(withCommon(v))), isEmpty,
                reason: v.celebrationType);
          }

          final readings = await readingsExport(await hour('readings'));
          expect(readings.psalmody, isNotEmpty);
          expect(readings.biblicalReading, isNotEmpty);
          expect(readings.patristicReading, isNotEmpty);
          expect(readings.oration, lauds.oration, reason: "the Common's");
          expect(readings.teDeum != null, office == VotiveOffice.dedication);

          final middleOfDay =
              await middleOfDayExport(await hour('middleOfDay'));
          for (final psalmody in [
            middleOfDay.psalmodyTierce,
            middleOfDay.psalmodySexte,
            middleOfDay.psalmodyNone,
          ]) {
            expect(psalmody, isNotEmpty);
          }
          for (final hour in [
            middleOfDay.tierce,
            middleOfDay.sexte,
            middleOfDay.none,
          ]) {
            expect(hour?.reading, isNotNull);
          }

          final complines =
              await votiveComplineDetection(calendar, date, dataLoader, office);
          expect(
              complines.values.map((c) => c.dayOfCompline),
              office == VotiveOffice.dedication
                  ? ['sunday', 'saturday']
                  : [dayName[date.weekday]]);
          for (final c in complines.values) {
            expect((await complineExport(c)).psalmody, isNotEmpty);
          }
        });
      }
    }
  }

  group('the Mass', () {
    Future<(Mass votive, Mass day)> masses(
        DateTime date, VotiveOffice office) async {
      final calendar = getCalendar(Calendar(), date, 'lyon', data);
      final votive =
          (await votiveMassDetection(calendar, date, dataLoader, office))
              .values
              .single;
      final day = (await massDetection(calendar, date, dataLoader))
          .values
          .firstWhere((m) => m.celebrationCode == m.ferialCode);
      return (
        await massExport(
            votive.copyWith(commonList: [votive.commonList!.first])),
        await massExport(day),
      );
    }

    List<String> typesOf(Mass mass) =>
        mass.readingParts?.map((p) => p.partType).toList() ?? const [];

    for (final MapEntry(key: season, value: date) in dates.entries) {
      test("$season: the Dedication's, complete", () async {
        final (mass, _) = await masses(date, VotiveOffice.dedication);
        expect(mass.entranceAntiphon, isNotEmpty);
        expect(mass.collect, isNotEmpty);
        expect(mass.prefaceList, isNotEmpty);
        expect(mass.communionAntiphon, isNotEmpty);
        expect(mass.prayerAfterCommunion, isNotEmpty);
        expect(typesOf(mass),
            ['READING_1', 'PSALM', 'READING_2', 'ALLELUIA', 'GOSPEL']);
      });

      test("$season: the Office of the Dead's, its Common's alone", () async {
        final (mass, day) = await masses(date, VotiveOffice.departed);
        expect(typesOf(mass), containsAll(['READING_1', 'PSALM', 'GOSPEL']));
        // None of the day's prayers
        expect(mass.collect, isNot(day.collect));
      });
    }
  });

  test('the Office of the Dead is black and has no rank label', () async {
    final date = dates['Ordinary Time']!;
    final departed = await votiveOfficeContext(
        getCalendar(Calendar(), date, 'lyon', data),
        date,
        dataLoader,
        VotiveOffice.departed);
    expect(departed!.liturgicalColor, 'black');
    expect(departed.celebrationDisplayLabel, '');
    expect(departed.commonList, ['trespassed']);
  });

  test("the Office of the Dead takes trespassed_paschal in Easter time",
      () async {
    Future<(String?, String?)> orationAndCollect(DateTime date) async {
      final calendar = getCalendar(Calendar(), date, 'lyon', data);
      final lauds = (await votiveOfficeDetection(
              calendar, date, dataLoader, VotiveOffice.departed, 'morning'))
          .values
          .single;
      final mass = (await votiveMassDetection(
              calendar, date, dataLoader, VotiveOffice.departed))
          .values
          .single;
      CelebrationContext withCommon(CelebrationContext c) =>
          c.copyWith(commonList: ['trespassed']);
      return (
        (await morningExport(withCommon(lauds))).oration?.first,
        (await massExport(withCommon(mass))).collect?.first,
      );
    }

    final (orationOT, collectOT) =
        await orationAndCollect(dates['Ordinary Time']!);
    final (oration, collect) = await orationAndCollect(dates['Easter time']!);
    expect(oration, startsWith('Tu nous as montré, Seigneur'));
    expect(collect, startsWith('Écoute nos prières avec bonté'));
    expect(oration, isNot(orationOT));
    expect(collect, isNot(collectOT));
  });

  test(
      "a saint's oration with no readings section of its own is the Office "
      "of Readings' too (Saint Genevieve)", () async {
    final date = DateTime(2026, 1, 3);
    final calendar = getCalendar(Calendar(), date, 'lyon', data);
    CelebrationContext genevieve(Map<String, CelebrationContext> offices) =>
        offices['Sainte Geneviève']!.copyWith(commonList: []);
    final readings = await readingsExport(
        genevieve(await readingsDetection(calendar, date, dataLoader)));
    final lauds = await morningExport(
        genevieve(await morningDetection(calendar, date, dataLoader)));
    expect(readings.oration, lauds.oration);
  });
}
