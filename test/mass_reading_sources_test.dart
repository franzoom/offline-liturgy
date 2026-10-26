// Where a celebrated saint's Mass readings come from. A memorial offers the
// day's readings (the default), its proper ones completed from the day, or
// all of them completed from the Common — only the sources that make a
// difference. A feast or a solemnity takes its proper readings, completed
// from the Common up to a complete Liturgy of the Word: the day's readings,
// two for a solemnity. massDetection also tells whether choosing the Common
// makes any difference (CelebrationContext.massUsesCommon).

import 'package:test/test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/offices/masses/mass_extract.dart';
import 'package:offline_liturgy/tools/celebration_index.dart';

List<String> partTypes(Mass mass) =>
    mass.readingParts?.map((p) => p.partType).toList() ?? [];

/// The biblical reference of the first choice of [partType] in [parts].
String? firstRef(List<MassReadingPart>? parts, String partType) {
  final part = parts?.where((p) => p.partType == partType).firstOrNull;
  return switch (part?.partContents.firstOrNull) {
    MassReading r => r.biblicalRef,
    MassPsalm p => p.biblicalRef,
    MassGospel g => g.biblicalRef,
    null => null,
  };
}

MassReadingPart part(String type, String ref) => MassReadingPart(
    partType: type, partContents: [MassReading(biblicalRef: ref)]);

void main() {
  late LiturgyData data;
  final dataLoader = FileSystemDataLoader();

  setUpAll(() async => data = await LiturgyData.load());

  /// The Masses of [date] in [location]: the celebration [code]'s, and the
  /// day's own (the ferial one).
  Future<({CelebrationContext saint, CelebrationContext day})> massesOn(
      DateTime date, String location, String code) async {
    final calendar = getCalendar(Calendar(), date, location, data);
    final masses = await massDetection(calendar, date, dataLoader);
    return (
      saint: masses.values.firstWhere((c) => c.celebrationCode == code),
      day: masses.values.firstWhere((c) => !c.hasProper),
    );
  }

  group('a memorial with no readings of its own (Saint John Paul II)', () {
    late CelebrationContext saint, day;
    setUpAll(() async => (saint: saint, day: day) = await massesOn(
        DateTime(2026, 10, 22), 'lyon', 'roman/john_paul_ii_pope'));

    test("offers the day's readings or all of them from the Common", () {
      expect(saint.massReadingSources,
          [MassReadingSource.day, MassReadingSource.all]);
      expect(saint.properReadingPartTypes, isEmpty);
    });

    test('uses its Common for its prayers, whatever the readings', () {
      expect(saint.commonUsedForPrayers, isTrue);
      expect(saint.massUsesCommon, isTrue);
    });

    test("takes the day's readings by default, the Common's on request",
        () async {
      final dayMass = await massExport(day);
      final byDefault = await massExport(saint);
      final all = await massExport(
          saint.copyWith(massReadingSource: MassReadingSource.all));

      expect(partTypes(byDefault), partTypes(dayMass));
      expect(firstRef(byDefault.readingParts, 'READING_1'),
          firstRef(dayMass.readingParts, 'READING_1'));
      expect(partTypes(all), ['READING_1', 'PSALM', 'GOSPEL']);
      expect(firstRef(all.readingParts, 'READING_1'),
          isNot(firstRef(dayMass.readingParts, 'READING_1')));
    });
  });

  group('a memorial with all its readings (Saint Hilary)', () {
    late CelebrationContext saint;
    setUpAll(() async => saint = (await massesOn(
            DateTime(2027, 1, 13), 'lyon', 'roman/hilary_of_poitiers_bishop'))
        .saint);

    test("offers the day's readings or its own, not the Common's", () {
      expect(saint.massReadingSources,
          [MassReadingSource.day, MassReadingSource.proper]);
      expect(saint.commonUsedForReadings, isFalse);
    });

    test('takes its own readings on request', () async {
      final proper = (await massExtract(
              await celebrationFilePath(saint.celebrationCode, dataLoader),
              dataLoader))
          .ofType(saint.massName);
      final mass = await massExport(
          saint.copyWith(massReadingSource: MassReadingSource.proper));
      expect(firstRef(mass.readingParts, 'READING_1'),
          firstRef(proper?.readingParts, 'READING_1'));
      expect(firstRef(mass.readingParts, 'GOSPEL'),
          firstRef(proper?.readingParts, 'GOSPEL'));
    });
  });

  group('a feast with no Mass of its own (dedication of Lyon cathedral)', () {
    late CelebrationContext saint;
    setUpAll(() async => saint = (await massesOn(DateTime(2026, 10, 24), 'lyon',
            'lyon/dedication_of_the_cathedral_of_saint_john_the_baptist'))
        .saint);

    test('offers no reading choice, but uses its Common', () {
      expect(saint.massReadingSources, isEmpty);
      expect(saint.commonUsedForReadings, isTrue);
      expect(saint.massUsesCommon, isTrue);
    });

    test("takes the Common's readings, as many as the day's", () async {
      final mass = await massExport(saint);
      expect(partTypes(mass), ['READING_1', 'PSALM', 'GOSPEL']);
    });
  });

  test(
      'a solemnity with no Mass of its own has two readings (Saint '
      'Genevieve in Paris, on a weekday)', () async {
    final saint = (await massesOn(
            DateTime(2028, 1, 3), 'paris', 'paris/genevieve_of_paris_virgin'))
        .saint;
    final mass = await massExport(saint);
    expect(partTypes(mass), ['READING_1', 'PSALM', 'READING_2', 'GOSPEL']);
  });

  group('completeReadingParts', () {
    final source = [
      part('READING_1', 'source R1'),
      part('PSALM', 'source Ps'),
      part('READING_2', 'source R2'),
      part('GOSPEL', 'source Gospel'),
    ];
    const reference = ['READING_1', 'PSALM', 'GOSPEL'];

    test("fills a partial proper in the reference's order", () {
      final parts = completeReadingParts(
          [part('GOSPEL', 'own Gospel')], source, reference);
      expect(parts.map((p) => p.partType), reference);
      expect(firstRef(parts, 'READING_1'), 'source R1');
      expect(firstRef(parts, 'GOSPEL'), 'own Gospel');
    });

    test('keeps a complete proper as is, repeated entries included', () {
      final own = [
        part('READING_1', 'own R1'),
        part('READING_1', 'own R1 bis'),
        part('PSALM', 'own Ps'),
        part('GOSPEL', 'own Gospel'),
      ];
      expect(completeReadingParts(own, source, reference), same(own));
    });

    test('takes everything from the source when there is no proper', () {
      final parts = completeReadingParts(null, source, reference);
      expect(parts.map((p) => p.partType), reference);
      expect(firstRef(parts, 'PSALM'), 'source Ps');
    });
  });

  group('memorialReadingSources', () {
    test('complete or partial proper, completed or not by the Common', () {
      expect(
          memorialReadingSources(
              properTypes: ['READING_1', 'PSALM', 'GOSPEL'],
              commonFillsReadings: false),
          [MassReadingSource.day, MassReadingSource.proper]);
      expect(
          memorialReadingSources(
              properTypes: ['GOSPEL'], commonFillsReadings: true),
          MassReadingSource.values);
      expect(
          memorialReadingSources(
              properTypes: ['GOSPEL'], commonFillsReadings: false),
          [MassReadingSource.day, MassReadingSource.proper]);
    });

    test('no proper readings: the Common only, or no choice at all', () {
      expect(memorialReadingSources(properTypes: [], commonFillsReadings: true),
          [MassReadingSource.day, MassReadingSource.all]);
      expect(
          memorialReadingSources(properTypes: [], commonFillsReadings: false),
          isEmpty);
    });
  });

  test('referenceReadingPartTypes: two readings for a solemnity', () {
    const day = ['READING_1', 'PSALM', 'GOSPEL'];
    expect(referenceReadingPartTypes(4, day, []), solemnityReadingPartTypes);
    expect(referenceReadingPartTypes(8, day, []), day);
    expect(referenceReadingPartTypes(7, [], ['GOSPEL']), ['GOSPEL']);
  });
}
