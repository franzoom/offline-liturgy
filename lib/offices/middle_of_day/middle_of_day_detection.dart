import '../../classes/calendar_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/date_tools.dart';
import '../office_detection.dart';

/// Returns a map of possible Middle of Day Offices for a given date.
///
/// For the Middle of Day office, the ferial office is always used,
/// UNLESS the celebration is a feast or solemnity (precedence <= 9),
/// in which case that celebration's office is used instead.
Future<Map<String, CelebrationContext>> middleOfDayDetection(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
) async {
  final celebrations =
      await detectOfficeCelebrations(calendar, date, dataLoader);

  if (celebrations.isEmpty) return {};

  // A feast or solemnity (precedence <= 9, feasts included), otherwise
  // the ferial day
  final c = celebrations.where((c) => (c.precedence ?? 13) <= 9).firstOrNull ??
      celebrations.firstWhere(
        (c) => ferialDayCheck(c.celebrationCode),
        orElse: () => celebrations.first,
      );

  final result = {
    c.celebrationTitle ?? c.celebrationCode: c.copyWith(
      celebrationType: 'middleOfDay',
      officeDescription: c.celebrationGlobalName,
    ),
  };

  return result;
}
