List extractWeekAndDay(String celebrationName, String prefix) {
  // fonction qui récupère un nom de jour de férie avec son préfixe (OT_x_y par exemple)
  // et retourne x: numéro de semaine et y: numéro de jour
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
