import '../../classes/calendar_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/data_loader.dart';
import '../office_detection.dart';

/// Returns a map of possible Readings Offices, sorted by precedence (lowest first)
/// Key: celebration title from YAML (or resolved ferial name)
/// Value: CelebrationContext with all celebration data and celebrationType='readings'
Future<Map<String, CelebrationContext>> readingsDetection(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
) async {
  final celebrations = await detectCelebrations(calendar, date, dataLoader);

  final Map<String, CelebrationContext> possibleReadings = {};

  for (final c in celebrations) {
    possibleReadings[c.celebrationTitle ?? c.celebrationCode] = c.copyWith(
      celebrationType: 'readings',
      officeDescription: c.celebrationGlobalName,
    );
  }

  return possibleReadings;
}
