import '../../classes/calendar_class.dart';
import '../../classes/mass_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/date_tools.dart';
import '../../tools/constants.dart';
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
      // Try special_days first, then sanctoral
      Masses loaded =
          await massExtract('$specialFilePath/${c.celebrationCode}.yaml', c.dataLoader);
      if (loaded.masses == null || loaded.masses!.isEmpty) {
        loaded = await massExtract(
            '$sanctoralFilePath/${c.celebrationCode}.yaml', c.dataLoader);
      }
      masses = loaded;
    }

    for (final mass in masses.masses ?? []) {
      final celebrationTitle = c.celebrationTitle ?? c.celebrationCode;
      final key = '$celebrationTitle - ${mass.name ?? mass.massType}';

      possibleMasses[key] = c.copyWith(
        celebrationType: 'mass',
        officeDescription: c.celebrationGlobalName,
        massName: mass.name,
      );
    }
  }

  print('+-+-+-+-+-+-+-+-+-+ MASS DETECTION - Possible Masses: $possibleMasses');
  return possibleMasses;
}
