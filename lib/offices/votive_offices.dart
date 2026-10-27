import '../assets/libraries/french_liturgy_labels.dart';
import '../classes/calendar_class.dart';
import '../classes/compline_class.dart';
import '../classes/office_elements_class.dart';
import '../tools/constants.dart';
import '../tools/data_loader.dart';
import '../tools/hierarchical_common_loader.dart';
import '../tools/date_tools.dart';
import '../tools/yaml_map_loader.dart';

/// The Common a votive office is celebrated with: the Dedication's, inside
/// the consecrated church; the Office of the Dead's. The hierarchical
/// loader adds the season's variants (e.g. trespassed_paschal).
const votiveCommons = {
  VotiveOffice.dedication: ['dedicace_inside'],
  VotiveOffice.departed: ['trespassed'],
};

const _votiveTitles = {
  VotiveOffice.dedication: 'Dédicace de l’église',
  VotiveOffice.departed: 'Office des défunts',
};

/// [office] celebrated on [date] in place of the day's celebrations: the
/// ferial day (its season, psalter week and year) under its Common
/// (votiveCommons, its commonList), with no file of its own —
/// ranked a solemnity for the Dedication, as All Souls for the Office of
/// the Dead. Null when the calendar has no such day.
Future<CelebrationContext?> votiveOfficeContext(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
  VotiveOffice office,
) async {
  final day = calendar.getDayContent(date);
  if (day == null) return null;

  final root = day.defaultCelebrationTitle;
  final commons = votiveCommons[office]!;
  final commonFiles = await Future.wait(commons
      .map((code) => loadYamlMap('$commonsFilePath/$code.yaml', dataLoader)));
  final title = _votiveTitles[office]!;
  final isDedication = office == VotiveOffice.dedication;

  return CelebrationContext(
    celebrationCode: root,
    celebrationTitle: title,
    celebrationGlobalName: title,
    officeDescription: title,
    ferialCode: ferialDayCheck(root) ? root : null,
    commonList: commons,
    commonTitles: {
      for (int i = 0; i < commons.length; i++)
        commons[i]: commonFiles[i]?['commonTitle']?.toString() ?? commons[i],
    },
    date: date,
    liturgicalTime: day.liturgicalTime,
    breviaryWeek: day.breviaryWeek,
    liturgicalYear: day.liturgicalYear,
    precedence: isDedication ? 4 : 3,
    liturgicalColor: isDedication ? 'white' : 'black',
    isCelebrable: true,
    dataLoader: dataLoader,
    votiveOffice: office,
  );
}

/// The votive [office] of [date] for Lauds ('morning'), the Office of
/// Readings ('readings') or the Middle of Day ('middleOfDay') — keyed like
/// the offices' detection, its only entry.
Future<Map<String, CelebrationContext>> votiveOfficeDetection(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
  VotiveOffice office,
  String celebrationType,
) async {
  final c = await votiveOfficeContext(calendar, date, dataLoader, office);
  if (c == null) return {};
  return {c.celebrationTitle!: c.copyWith(celebrationType: celebrationType)};
}

/// The votive [office]'s Vespers on [date]: the Dedication's Second Vespers
/// (by default) and First Vespers, the Office of the Dead's Vespers.
Future<Map<String, CelebrationContext>> votiveVespersDetection(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
  VotiveOffice office,
) async {
  final c = await votiveOfficeContext(calendar, date, dataLoader, office);
  if (c == null) return {};
  final title = c.celebrationTitle!;
  if (office == VotiveOffice.departed) {
    return {title: c.copyWith(celebrationType: 'vespers2')};
  }
  return {
    title: c.copyWith(
      celebrationType: 'vespers2',
      officeDescription: '$title (${celebrationTypeLabels['secondVespers']})',
    ),
    'I Vespers: $title': c.copyWith(
      celebrationType: 'vespers1',
      officeDescription: '$title (${celebrationTypeLabels['firstVespers']})',
    ),
  };
}

/// The votive [office]'s Compline on [date]: the Dedication's, a
/// solemnity's (Sunday II, by default), and its eve's (Sunday I, after its
/// First Vespers); for the Office of the Dead, the day's.
Future<Map<String, ComplineDefinition>> votiveComplineDetection(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
  VotiveOffice office,
) async {
  final c = await votiveOfficeContext(calendar, date, dataLoader, office);
  if (c == null) return {};
  final title = c.celebrationTitle!;

  ComplineDefinition compline(
          String description, String celebrationType, String dayOfCompline,
          {bool isEveCompline = false}) =>
      ComplineDefinition(
        context: c.copyWith(
          celebrationType: celebrationType,
          officeDescription: description,
        ),
        dayOfCompline: dayOfCompline,
        isEveCompline: isEveCompline,
      );

  if (office == VotiveOffice.departed) {
    final weekday = dayName[date.weekday];
    final description = 'Complies du ${dayOfWeekLabels[weekday]}';
    return {description: compline(description, 'normal', weekday)};
  }
  final day = 'Complies – $title';
  final eve = 'Complies de la veille – $title';
  return {
    day: compline(day, 'solemnity', 'sunday'),
    eve: compline(eve, 'solemnityeve', 'saturday', isEveCompline: true),
  };
}

/// The votive [office]'s Mass on [date], keyed like massDetection's: its
/// Common's alone, the day's left aside (see massExport).
Future<Map<String, CelebrationContext>> votiveMassDetection(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
  VotiveOffice office,
) async {
  final c = await votiveOfficeContext(calendar, date, dataLoader, office);
  if (c == null) return {};
  final mass = c.copyWith(celebrationType: 'mass', massName: 'DAY_MASS');
  final commonMass = (await loadMassHierarchicalCommon(
          mass.copyWith(commonList: [c.commonList!.first])))
      .ofType('DAY_MASS');
  return {
    '${c.celebrationTitle} - DAY_MASS': mass.copyWith(
      commonUsedForPrayers:
          commonMass?.providedPrayerFields.isNotEmpty ?? false,
      commonUsedForReadings: commonMass?.readingParts?.isNotEmpty ?? false,
    ),
  };
}
