// A Common's more specific levels only give the Mass readingParts that differ
// from the general one: pastors_pope.yaml only its GOSPEL, pastors_paschal.yaml
// only its READING_1. Overlaying them wholesale (Mass.overlayWith) dropped
// the general level's other parts, so Saint John Paul II's Mass with "the
// feast's own readings" only had a Gospel. Common levels are merged by
// partType instead (Mass.overlayCommonLevel).

import 'package:test/test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/offices/masses/mass_extract.dart';
import 'package:offline_liturgy/tools/constants.dart';

List<String> partTypes(Mass? mass) =>
    mass?.readingParts?.map((p) => p.partType).toList() ?? [];

/// The biblical reference of the first choice of [partType] in [mass].
String? firstRef(Mass? mass, String partType) {
  final part =
      mass?.readingParts?.where((p) => p.partType == partType).firstOrNull;
  return switch (part?.partContents.firstOrNull) {
    MassReading r => r.biblicalRef,
    MassPsalm p => p.biblicalRef,
    MassGospel g => g.biblicalRef,
    null => null,
  };
}

Future<Mass?> commonLevel(String level, DataLoader dataLoader) async =>
    (await massExtract('$commonsFilePath/$level.yaml', dataLoader))
        .ofType('DAY_MASS');

void main() {
  late DataLoader dataLoader;
  late CelebrationContext johnPaul;

  setUpAll(() async {
    final data = await LiturgyData.load();
    dataLoader = FileSystemDataLoader();
    final date = DateTime(2026, 10, 22);
    final calendar = getCalendar(Calendar(), date, 'lyon', data);
    final masses = await massDetection(calendar, date, dataLoader);
    johnPaul = masses.values
        .firstWhere((c) => c.celebrationCode == 'roman/john_paul_ii_pope');
  });

  test('pastors_pope keeps the readings of pastors, with its own Gospel',
      () async {
    final common =
        (await loadMassHierarchicalCommon(johnPaul)).ofType('DAY_MASS');
    expect(partTypes(common),
        ['READING_1', 'PSALM', 'READING_2', 'ALLELUIA', 'GOSPEL']);
    expect(firstRef(common, 'GOSPEL'),
        firstRef(await commonLevel('pastors_pope', dataLoader), 'GOSPEL'));
    expect(firstRef(common, 'READING_1'),
        firstRef(await commonLevel('pastors', dataLoader), 'READING_1'));
  });

  test('pastors_paschal only replaces the first reading in Easter time',
      () async {
    final common = (await loadMassHierarchicalCommon(
            johnPaul.copyWith(liturgicalTime: 'paschaltime')))
        .ofType('DAY_MASS');
    expect(partTypes(common),
        ['READING_1', 'PSALM', 'READING_2', 'ALLELUIA', 'GOSPEL']);
    expect(
        firstRef(common, 'READING_1'),
        firstRef(
            await commonLevel('pastors_paschal', dataLoader), 'READING_1'));
    expect(firstRef(common, 'GOSPEL'),
        firstRef(await commonLevel('pastors_pope', dataLoader), 'GOSPEL'));
  });

  test("Saint John Paul II with the feast's own readings has the whole Mass",
      () async {
    final mass = await massExport(
        johnPaul.copyWith(massReadingSource: MassReadingSource.all));
    expect(partTypes(mass), ['READING_1', 'PSALM', 'GOSPEL']);
  });
}
