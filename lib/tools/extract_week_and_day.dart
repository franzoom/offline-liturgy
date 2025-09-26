List extractWeekAndDay(String celebrationName, String prefix) {
  // this function recieves a ferial day name with its prefix (OT_x_y for exemple)
  // and returns x: week number and y: day number.
  // If the format is incorrect, it returns [0, 0].
  final regex = RegExp('^${RegExp.escape(prefix)}_(\\d+)_(\\d+)\$');
  final match = regex.firstMatch(celebrationName);
  int week;
  int day;
  if (match != null) {
    week = int.parse(match.group(1)!);
    day = int.parse(match.group(2)!);
  } else {
    week = 0;
    day = 0;
  }
  return [week, day];
}
