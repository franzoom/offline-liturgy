Map<int, Map<String, List<String>>> mergePsalms(
  // fonction de fusion de listes de psaumes.
  // est utilisée lorsque les psaumes d'un temps particulier ne sont pas ceux par défaut du temps ordinaire
  Map<int, Map<String, List<String>>> base,
  Map<int, Map<String, List<String>>> additions,
) {
  additions.forEach((week, days) {
    if (!base.containsKey(week)) {
      base[week] = {};
    }
    days.forEach((day, psalms) {
      base[week]![day] = psalms;
    });
  });
  return base;
}
