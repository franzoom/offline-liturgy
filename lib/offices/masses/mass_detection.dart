import '../../assets/libraries/french_liturgy_labels.dart';
import '../../classes/calendar_class.dart';
import '../../classes/mass_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/celebration_index.dart';
import '../../tools/data_loader.dart';
import '../../tools/date_tools.dart';
import '../../tools/hierarchical_common_loader.dart';
import '../office_detection.dart';
import './mass_extract.dart';
import './ferial_mass_resolution.dart';

/// Returns a map of possible Masses, sorted by precedence (lowest first).
/// Unlike other offices, each entry corresponds to one [Mass] object —
/// a single celebration may produce multiple entries (e.g. vigil + day mass).
///
/// Key: `"celebrationTitle - mass.name"` (unique per Mass)
/// Value: CelebrationContext with celebrationType='mass' and massName set
Future<Map<String, CelebrationContext>> massDetection(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
) async {
  final celebrations = await detectCelebrations(calendar, date, dataLoader);
  // The Masses of one celebration, keyed as above
  Future<Map<String, CelebrationContext>> massesOf(CelebrationContext c) async {
    final Map<String, CelebrationContext> possibleMasses = {};
    // Load masses: full ferial resolution for ferial days, direct extract
    // otherwise. isProperCelebration tracks which branch ran.
    Masses masses;
    bool isProperCelebration;
    if (c.ferialCode != null && ferialDayCheck(c.celebrationCode)) {
      masses = await ferialMassResolution(c);
      isProperCelebration = false;
    } else {
      masses = await massExtract(
          await celebrationFilePath(c.celebrationCode, c.dataLoader),
          c.dataLoader);
      isProperCelebration = true;
    }

    // The proper's own Masses, before the Common may stand in for them below
    final Masses properMasses = isProperCelebration ? masses : Masses();

    // If celebrating a saint with commons declared, also resolve the
    // selected Common — both as a structural fallback (when the proper has
    // no mass: block of its own at all, e.g. a local commemoration with
    // only oration/readings for the Office) and to know whether "the
    // feast's own readings" would have anything to offer via the Common
    // for a massType the proper doesn't cover — see the reading sources
    // below. A Common can supply readingParts too, inherited from a more
    // general level of its hierarchy (e.g. pastors_bishop inherits
    // pastors' readings).
    Masses? commonMasses;
    if (isProperCelebration && (c.commonList?.isNotEmpty ?? false)) {
      commonMasses = await loadMassHierarchicalCommon(c);
      if (masses.masses?.isEmpty ?? true) {
        masses = commonMasses;
        isProperCelebration = false;
      }
    }

    // The day's Masses, whose readings a celebration is measured against
    // (see referenceReadingPartTypes) — only needed when celebrating a saint
    final Masses dayMasses = c.hasProper && c.hasFerialBase
        ? await ferialMassResolution(c)
        : Masses();
    List<String> typesOf(Mass? mass) =>
        mass?.readingParts?.map((p) => p.partType).toList() ?? const [];

    final massList = masses.masses ?? [];
    for (final mass in massList) {
      final celebrationTitle = c.celebrationTitle ?? c.celebrationCode;
      final key = '$celebrationTitle - ${mass.name ?? mass.massType}';

      // Disambiguate the label only when this celebration has several
      // Masses (e.g. Christmas' 4 Masses, Palm Sunday's procession +
      // Passion Mass) — a single-Mass day keeps the plain celebration name.
      // The celebration name itself is shown separately above the chips
      // (see CelebrationContext.celebrationTitle), so the chip only needs
      // to name the Mass — via massType's canonical translation, falling
      // back to the YAML's freeform name for a massType not yet migrated.
      final String? description = massList.length > 1
          ? massTypeLabels[mass.massType] ?? mass.name ?? mass.massType
          : c.celebrationGlobalName;

      final entry = c.copyWith(
        celebrationType: 'mass',
        officeDescription: description,
        massName: mass.massType,
      );
      // The ferial day celebrated is its own Mass: nothing to choose
      if (!c.hasProper) {
        possibleMasses[key] = entry;
        continue;
      }

      // What the proper and the Common provide, against a complete Mass
      // (see massExport): the reading sources a memorial offers, and
      // whether choosing the Common makes any difference
      final properMass = properMasses.ofType(mass.massType);
      final commonMass = commonMasses?.ofType(mass.massType);
      final properTypes = typesOf(properMass);
      final commonTypes = typesOf(commonMass);
      final reference = referenceReadingPartTypes(
          c.precedence, typesOf(dayMasses.ofType(mass.massType)), properTypes);
      final commonFillsReadings = reference
          .any((t) => !properTypes.contains(t) && commonTypes.contains(t));
      final commonUsedForPrayers = commonMass != null &&
          commonMass.providedPrayerFields
              .difference(properMass?.providedPrayerFields ?? const {})
              .isNotEmpty;

      possibleMasses[key] = entry.copyWith(
        massReadingSources: c.isMemorial
            ? memorialReadingSources(
                properTypes: properTypes,
                commonFillsReadings: commonFillsReadings)
            : const [],
        properReadingPartTypes: properTypes,
        commonUsedForPrayers: commonUsedForPrayers,
        commonUsedForReadings: commonFillsReadings,
      );
    }
    return possibleMasses;
  }

  // Celebrations are resolved in parallel, then kept in their order
  final perCelebration = await Future.wait(celebrations.map(massesOf));
  return {for (final masses in perCelebration) ...masses};
}
