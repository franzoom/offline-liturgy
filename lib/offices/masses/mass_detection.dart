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
  final Map<String, CelebrationContext> possibleMasses = {};

  for (final c in celebrations) {
    // Load masses: full ferial resolution for ferial days, direct extract
    // otherwise. isProperCelebration tracks which branch ran.
    Masses masses;
    bool isProperCelebration;
    if (c.ferialCode != null && ferialDayCheck(c.celebrationCode)) {
      masses = await ferialMassResolution(c);
      isProperCelebration = false;
    } else {
      final filePath = await dirPathForCode(c.celebrationCode, c.dataLoader);
      masses = await massExtract(
          '$filePath/${c.celebrationCode}.yaml', c.dataLoader);
      isProperCelebration = true;
    }

    // If celebrating a saint with commons declared, also resolve the
    // selected Common — both as a structural fallback (when the proper has
    // no mass: block of its own at all, e.g. a local commemoration with
    // only oration/readings for the Office) and to know whether "the
    // feast's own readings" would have anything to offer via the Common
    // for a massType the proper doesn't cover — see hasFeastReadingParts
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

      // Only meaningful when actually celebrating the saint — the ferial's
      // own entry always has readingParts (it's the day's own Mass), which
      // isn't a "the feast's readings vs the day's" alternative to offer.
      final commonMassList = commonMasses?.masses;
      final int commonIndex = commonMassList == null
          ? -1
          : commonMassList.indexWhere((m) => m.massType == mass.massType);
      final bool hasFeastReadingParts = c.celebrationCode != c.ferialCode &&
          ((mass.readingParts?.isNotEmpty ?? false) ||
              (commonIndex >= 0 &&
                  (commonMassList![commonIndex].readingParts?.isNotEmpty ??
                      false)));

      possibleMasses[key] = c.copyWith(
        celebrationType: 'mass',
        officeDescription: description,
        massName: mass.name,
        hasFeastReadingParts: hasFeastReadingParts,
      );
    }
  }

  return possibleMasses;
}
