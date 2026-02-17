import '../../classes/calendar_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/date_tools.dart';
import '../office_detection.dart';

/// Returns a map of possible Middle of Day Offices for a given date.
///
/// For the Middle of Day office, the ferial office is always used,
/// UNLESS the celebration is a feast or solemnity (precedence <= 6),
/// in which case that celebration's office is used instead.
Future<Map<String, CelebrationContext>> middleOfDayDetection(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
) async {
  final celebrations = await detectCelebrations(calendar, date, dataLoader);

  if (celebrations.isEmpty) return {};

  // Check if there is a feast or solemnity (precedence <= 6)
  final hasFeastOrSolemnity =
      celebrations.any((c) => (c.precedence ?? 13) <= 6);

  final Map<String, CelebrationContext> possibleMiddleOfDays = {};

  if (hasFeastOrSolemnity) {
    // Use the feast/solemnity celebration (highest priority, i.e. lowest precedence)
    final c = celebrations.where((c) => (c.precedence ?? 13) <= 6).first;
    possibleMiddleOfDays[c.celebrationTitle ?? c.celebrationCode] = c.copyWith(
      celebrationType: 'middleOfDay',
      officeDescription: c.celebrationGlobalName,
    );
  } else {
    // Use the ferial office
    final c = celebrations.firstWhere(
      (c) => ferialDayCheck(c.celebrationCode),
      orElse: () => celebrations.first,
    );
    possibleMiddleOfDays[c.celebrationTitle ?? c.celebrationCode] = c.copyWith(
      celebrationType: 'middleOfDay',
      officeDescription: c.celebrationGlobalName,
    );
  }

  print(
      '+-+-+-+-+-+-+-+-+-+ MIDDLE OF DAY DETECTION - Possible Offices: $possibleMiddleOfDays');
  return possibleMiddleOfDays;
}
