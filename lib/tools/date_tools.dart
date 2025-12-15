DateTime dayShift(DateTime date, int shift) {
  /// adds some days to a date.
  /// (used to avoid probleme with timeshift issues)
  return DateTime(date.year, date.month, date.day + shift);
}

/// Detects if a celebration is a ferial day
/// Returns true if the celebration name starts with one of the ferial prefixes
bool isFerialDays(String celebrationName) {
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
