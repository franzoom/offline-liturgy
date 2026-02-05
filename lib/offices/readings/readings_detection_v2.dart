import '../../classes/calendar_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/data_loader.dart';
import '../office_detection.dart';

/// Determines if Te Deum should be displayed for a celebration
/// Te Deum is displayed when:
/// - It's a Feast or Solemnity (precedence < 6)
/// - OR it's a Sunday AND not during Lent
bool _computeTeDeum(int precedence, DateTime date, String liturgicalTime) {
  // Feast or Solemnity
  if (precedence < 6) {
    return true;
  }

  // Sunday, but not during Lent
  if (date.weekday == DateTime.sunday) {
    final lowerLiturgicalTime = liturgicalTime.toLowerCase();
    if (!lowerLiturgicalTime.contains('lent') &&
        !lowerLiturgicalTime.contains('carême')) {
      return true;
    }
  }

  return false;
}

/// Returns a map of possible Readings Offices, sorted by precedence (lowest first)
/// Key: celebration title from YAML (or resolved ferial name)
/// Value: CelebrationContext with all celebration data and celebrationType='readings'
///
/// This is a wrapper around detectCelebrations that converts
/// DetectedCelebration to CelebrationContext and computes Te Deum
Future<Map<String, CelebrationContext>> readingsDetection(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
) async {
  // Use the common detection function
  final celebrations = await detectCelebrations(calendar, date, dataLoader);

  // Convert to CelebrationContext map with Te Deum computation
  final Map<String, CelebrationContext> possibleReadings = {};

  for (final c in celebrations) {
    final bool shouldDisplayTeDeum =
        _computeTeDeum(c.precedence, date, c.liturgicalTime);

    possibleReadings[c.mapKey] = CelebrationContext(
      celebrationType: 'readings',
      celebrationCode: c.celebrationCode,
      ferialCode: c.ferialCode,
      commonList: c.commonList,
      date: date,
      liturgicalTime: c.liturgicalTime,
      breviaryWeek: c.breviaryWeek,
      precedence: c.precedence,
      teDeum: shouldDisplayTeDeum,
      isCelebrable: c.isCelebrable,
      dataLoader: dataLoader,
      officeDescription: c.celebrationName,
      liturgicalColor: c.liturgicalColor,
    );
  }

  print(
      '+-+-+-+-+-+-+-+-+-+ READINGS DETECTION V2 - Possible Readings Offices: $possibleReadings');
  return possibleReadings;
}
