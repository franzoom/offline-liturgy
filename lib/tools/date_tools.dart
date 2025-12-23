import '../assets/libraries/french_liturgy_labels.dart';

DateTime dayShift(DateTime date, int shift) {
  /// adds some days to a date.
  /// (used to avoid probleme with timeshift issues)
  return DateTime(date.year, date.month, date.day + shift);
}

/// Detects if a celebration is a ferial day
/// Returns true if the celebration name starts with one of the ferial prefixes
bool isFerialDay(String celebrationCode) {
  final prefixes = ['ot', 'advent', 'lent', 'christmas', 'easter'];
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
