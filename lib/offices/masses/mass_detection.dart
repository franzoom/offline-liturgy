import '../../assets/libraries/french_liturgy_labels.dart';
import '../../classes/calendar_class.dart';
import '../../classes/mass_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/celebration_index.dart';
import '../../tools/data_loader.dart';
import '../../tools/date_tools.dart';
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
    // Load masses: full ferial resolution for ferial days, direct extract otherwise
    final Masses masses;
    if (c.ferialCode != null && ferialDayCheck(c.celebrationCode)) {
      masses = await ferialMassResolution(c);
    } else {
      final filePath = await dirPathForCode(c.celebrationCode, c.dataLoader);
      masses = await massExtract(
          '$filePath/${c.celebrationCode}.yaml', c.dataLoader);
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

      possibleMasses[key] = c.copyWith(
        celebrationType: 'mass',
        officeDescription: description,
        massName: mass.name,
      );
    }
  }

  return possibleMasses;
}
