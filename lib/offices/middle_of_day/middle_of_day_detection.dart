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

  // Check if there is a feast or solemnity (precedence <= 9, feasts included)
  final hasFeastOrSolemnity =
      celebrations.any((c) => (c.precedence ?? 13) <= 9);

  final c = hasFeastOrSolemnity
      ? celebrations.where((c) => (c.precedence ?? 13) <= 9).first
      : celebrations.firstWhere(
          (c) => ferialDayCheck(c.celebrationCode),
          orElse: () => celebrations.first,
        );

  // A Sunday that stays celebrable under the chosen celebration (e.g. under
  // France's Dedication of the churches whose date of consecration is
  // unknown, which a church knowing its own date doesn't keep) is offered
  // after it, as in the other offices.
  final sunday = date.weekday == DateTime.sunday
      ? celebrations
          .where((s) =>
              s != c && s.isCelebrable && ferialDayCheck(s.celebrationCode))
          .firstOrNull
      : null;

  final result = {
    for (final option in [c, if (sunday != null) sunday])
      option.celebrationTitle ?? option.celebrationCode: option.copyWith(
        celebrationType: 'middleOfDay',
        officeDescription: option.celebrationGlobalName,
      ),
  };

  return result;
}
