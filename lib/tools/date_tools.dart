import '../assets/libraries/french_liturgy_labels.dart';

/*
DateTime dayShift(DateTime date, int shift) {
  /// adds some days to a date.
  /// (used to avoid probleme with timeshift issues)
  return DateTime(date.year, date.month, date.day + shift);
}
*/
extension DateNavigation on DateTime {
  /// Adds or removes days to a given date
  /// by preserving the date mode (UTC or Local)
  DateTime shift(int days) {
    if (isUtc) {
      return DateTime.utc(year, month, day + days);
    }
    return DateTime(year, month, day + days);
  }
}

/// Detects if a celebration is a ferial day
/// Returns true if the celebration name starts with one of the ferial prefixes
/// Special cases: christmas_26 to christmas_31 are NOT ferial days (they are proper celebrations)
bool ferialDayCheck(String celebrationCode) {
  // Special christmas days (26-31 Dec) are NOT ferial days
  final specialChristmasPattern =
      RegExp(r'^christmas_2[6-9]$|^christmas_3[0-1]$');
  if (specialChristmasPattern.hasMatch(celebrationCode)) {
    return false;
  }

  const prefixes = ['ot', 'advent', 'lent', 'christmas', 'easter'];
  return prefixes.any((prefix) => celebrationCode.startsWith(prefix));
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

List dayName = [
  '',
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

/// Name resolution for ferial days
/// Takes a ferial code (e.g., 'advent_3_5') and returns the French celebration name
/// Example: 'advent_3_5' -> 'vendredi de la 3ème semaine du Temps de l'Avent'
String ferialNameResolution(String ferialCode) {
  // Split the ferial code by underscore
  final parts = ferialCode.split('_');
  if (parts.length != 3) {
    return ferialCode; // Return original code if format is unexpected
  }

  String liturgicalTime = parts[0];
  final weekNumber = int.tryParse(parts[1]);
  final dayNumber = int.tryParse(parts[2]);
  String result = '';
  if (weekNumber == null ||
      dayNumber == null ||
      dayNumber < 0 ||
      dayNumber > 6) {
    return ferialCode; // Return original code if parsing failed
  }
  final liturgicalTimeParts = liturgicalTime.split('-');
  final liturgicalTimeEssential = liturgicalTimeParts[0];
  final int? dayNumberEssential = liturgicalTimeParts.length > 1
      ? int.tryParse(liturgicalTimeParts[1])
      : null;
  final dayOfWeekLabel = daysOfWeek[dayNumber];
  final weekOrdinal = getFrenchOrdinalFemale(weekNumber);
  if (dayNumberEssential == null) {
    // Simple case: 'advent' without day number
    final liturgicalTimeLabel =
        liturgicalTimeLabels[liturgicalTime] ?? liturgicalTime;

    result =
        '$dayOfWeekLabel de la $weekOrdinal semaine du $liturgicalTimeLabel';
  } else {
    // Special case: 'advent-17 to 24' or 'christmas-2' with day number
    switch (liturgicalTimeEssential) {
      case 'advent':
        result =
            '$dayOfWeekLabel de la $weekOrdinal semaine de l’Avent ($dayNumberEssential décembre)';
        break;
      case 'christmas':
        result =
            '$dayNumberEssential janvier, $weekOrdinal semaine du temps de Noël';
      default:
        result = '';
    }
  }
  return result[0].toUpperCase() + result.substring(1);
}

/// Returns the celebration type label based on precedence
String getCelebrationTypeLabel(int precedence) {
  switch (precedence) {
    case 3:
    case 4:
      return '(Solennité)';
    case 5:
    case 7:
    case 8:
      return '(Fête)';
    case 10:
    case 11:
      return '(Mémoire obligatoire)';
    case 12:
      return '(Mémoire facultative)';
  }
  return '';
}
