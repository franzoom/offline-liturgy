import '../../classes/calendar_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/data_loader.dart';
import '../office_detection.dart';

/// Returns a map of possible Morning Offices, sorted by precedence (lowest first)
/// Key: celebration title from YAML (or resolved ferial name)
/// Value: CelebrationContext with all celebration data and celebrationType='morning'
///
/// This is a wrapper around detectCelebrations that converts
/// DetectedCelebration to CelebrationContext
Future<Map<String, CelebrationContext>> morningDetection(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
) async {
  // Use the common detection function
  final celebrations = await detectCelebrations(calendar, date, dataLoader);

  // Convert to CelebrationContext map
  final Map<String, CelebrationContext> possibleMornings = {};

  for (final c in celebrations) {
    possibleMornings[c.mapKey] = CelebrationContext(
      celebrationType: 'morning',
      celebrationCode: c.celebrationCode,
      ferialCode: c.ferialCode,
      commonList: c.commonList,
      date: date,
      liturgicalTime: c.liturgicalTime,
      breviaryWeek: c.breviaryWeek,
      precedence: c.precedence,
      isCelebrable: c.isCelebrable,
      dataLoader: dataLoader,
      officeDescription: c.celebrationName,
      liturgicalColor: c.liturgicalColor,
    );
  }

  print(
      '+-+-+-+-+-+-+-+-+-+ MORNING DETECTION V2 - Possible Morning Offices: $possibleMornings');
  return possibleMornings;
}
