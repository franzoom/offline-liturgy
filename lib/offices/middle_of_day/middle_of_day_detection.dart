import '../../classes/calendar_class.dart';
import '../../classes/middle_of_day_class.dart';
import '../../tools/data_loader.dart';
import '../office_detection.dart';

/// Returns a map of possible Middle of Day Offices, sorted by precedence (lowest first)
/// Key: celebration title from YAML (or resolved ferial name)
/// Value: MiddleOfDayDefinition with all celebration data
///
/// This is a wrapper around detectCelebrations that converts
/// DetectedCelebration to MiddleOfDayDefinition
Future<Map<String, MiddleOfDayDefinition>> middleOfDayDetection(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
) async {
  // Use the common detection function
  final celebrations = await detectCelebrations(calendar, date, dataLoader);

  // Convert to MiddleOfDayDefinition map
  final Map<String, MiddleOfDayDefinition> possibleMiddleOfDays = {};

  for (final c in celebrations) {
    possibleMiddleOfDays[c.celebrationTitle ?? c.celebrationCode] = MiddleOfDayDefinition(
      middleOfDayDescription: c.celebrationGlobalName ?? c.celebrationCode,
      celebrationCode: c.celebrationCode,
      ferialCode: c.ferialCode ?? '',
      commonList: c.commonList,
      liturgicalTime: c.liturgicalTime,
      breviaryWeek: c.breviaryWeek,
      precedence: c.precedence ?? 13,
      liturgicalColor: c.liturgicalColor ?? 'green',
      isCelebrable: c.isCelebrable,
    );
  }

  print(
      '+-+-+-+-+-+-+-+-+-+ MIDDLE OF DAY DETECTION V2 - Possible Offices: $possibleMiddleOfDays');
  return possibleMiddleOfDays;
}
