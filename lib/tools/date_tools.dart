import './constants.dart';

extension DateNavigation on DateTime {
  /// Shifts the date by a given number of [days] while preserving UTC/Local mode.
  /// This approach is safe from Daylight Saving Time (DST) hour shifts.
  DateTime shift(int days) {
    if (isUtc) {
      return DateTime.utc(year, month, day + days);
    }
    return DateTime(year, month, day + days);
  }

  /// Returns true if this date falls on a Sunday.
  bool get isSunday => weekday == DateTime.sunday;

  /// Checks if this date is the same calendar day as [other], ignoring time.
  bool isSameDayAs(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

final _specialChristmasPattern =
    RegExp(r'^christmas_2[6-9]$|^christmas_3[0-1]$');

/// Detects if a celebration is a ferial day
/// Returns true if the celebration name starts with one of the ferial prefixes
/// Special cases: christmas_26 to christmas_31 are NOT ferial days (they are proper celebrations)
bool ferialDayCheck(String celebrationCode) {
  if (_specialChristmasPattern.hasMatch(celebrationCode)) return false;
  return timePrefixes.any((prefix) => celebrationCode.startsWith(prefix));
}

/// Filters an evangelicAntiphon map to keep only the generic key and the
/// current liturgical year key (A, B or C).
Map<String, List<String>>? filterEvangelicAntiphon(
    Map<String, List<String>>? antiphonMap, int year) {
  if (antiphonMap == null) return null;
  final yearKey = liturgicalYear(year);
  return {
    if (antiphonMap.containsKey('antiphon'))
      'antiphon': antiphonMap['antiphon']!,
    if (antiphonMap.containsKey(yearKey)) yearKey: antiphonMap[yearKey]!,
  };
}

String liturgicalYear(int year) {
  // returns the type of liturgcial year:
  // C for multiples of 3, then A and B
  switch (year % 3) {
    case 0:
      return 'C';
    case 1:
      return 'A';
  }
  return 'B';
}

String breviaryWeekToRoman(int weekNumber) {
  // converts breviary week number (1-4) to Roman numerals
  switch (weekNumber) {
    case 1:
      return 'I';
    case 2:
      return 'II';
    case 3:
      return 'III';
    case 4:
      return 'IV';
    default:
      return weekNumber.toString(); // fallback to number if out of range
  }
}

