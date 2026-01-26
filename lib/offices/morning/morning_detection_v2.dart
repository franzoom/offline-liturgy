import '../../classes/calendar_class.dart';
import '../../classes/morning_class.dart';
import '../../tools/data_loader.dart';
import '../office_detection.dart';

/// Returns a map of possible Morning Offices, sorted by precedence (lowest first)
/// Key: celebration title from YAML (or resolved ferial name)
/// Value: MorningDefinition with all celebration data
///
/// This is a wrapper around detectCelebrations that converts
/// DetectedCelebration to MorningDefinition
Future<Map<String, MorningDefinition>> morningDetection(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
) async {
  // Use the common detection function
  final celebrations = await detectCelebrations(calendar, date, dataLoader);

  // Convert to MorningDefinition map
  final Map<String, MorningDefinition> possibleMornings = {};

  for (final c in celebrations) {
    possibleMornings[c.mapKey] = MorningDefinition(
      morningDescription: c.celebrationName,
      celebrationCode: c.celebrationCode,
      ferialCode: c.ferialCode,
      commonList: c.commonList,
      liturgicalTime: c.liturgicalTime,
      breviaryWeek: c.breviaryWeek?.toString(),
      precedence: c.precedence,
      liturgicalColor: c.liturgicalColor,
      isCelebrable: c.isCelebrable,
      celebrationDescription: c.celebrationDescription,
    );
  }

  print(
      '+-+-+-+-+-+-+-+-+-+ MORNING DETECTION V2 - Possible Morning Offices: $possibleMornings');
  return possibleMornings;
}
