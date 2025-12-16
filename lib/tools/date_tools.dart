import '../assets/libraries/french_liturgy_labels.dart';

DateTime dayShift(DateTime date, int shift) {
  /// adds some days to a date.
  /// (used to avoid probleme with timeshift issues)
  return DateTime(date.year, date.month, date.day + shift);
}

/// Detects if a celebration is a ferial day
/// Returns true if the celebration name starts with one of the ferial prefixes
bool isFerialDay(String celebrationName) {
  final prefixes = ['ot', 'advent', 'lent', 'christmas', 'easter'];
  return prefixes.any((prefix) => celebrationName.startsWith(prefix));
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

  final liturgicalTime = parts[0];
  final weekNumber = int.tryParse(parts[1]);
  final dayNumber = int.tryParse(parts[2]);

  if (weekNumber == null ||
      dayNumber == null ||
      dayNumber < 0 ||
      dayNumber > 6) {
    return ferialCode; // Return original code if parsing failed
  }
  final liturgicalTimeLabel =
      liturgicalTimeLabels[liturgicalTime] ?? liturgicalTime;
  final dayOfWeekLabel = daysOfWeek[dayNumber];
  final weekOrdinal = getFrenchOrdinalFemale(weekNumber);
  final result =
      '$dayOfWeekLabel de la $weekOrdinal semaine du $liturgicalTimeLabel';
  return result[0].toUpperCase() + result.substring(1);
}
