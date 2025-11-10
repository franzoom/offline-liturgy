import 'offline_liturgy.dart';

void main() {
  Calendar calendar = Calendar(); // calendar creation
  DateTime date = DateTime(2024, 12, 8);
  String location = 'lyon';
  calendar = getCalendar(calendar, date, location); // calendar initialisation
/*
  // lancement de la génération des Laudes pour le jour demandé:
  Map<String, Morning> ferialMorning = ferialMorningResolution(calendar, date);
  final zegfqzgrf = ferialMorning;
*/
  // lancement de la génération des Complies pour le jour demandé:
  Map<String, ComplineDefinition> possibleComplines =
      complineDefinitionResolution(calendar, date);

  //affichage de ces complies:
  Map<String, Compline> complineTextCompiled =
      complineTextCompilation(possibleComplines);

  complineTextCompiled.forEach((key, compline) {
    print('$key');
    print('=========================');
    complineDisplay(compline);
    print('=========================');
  });

/*
  String json = exportComplineToAelfJson(calendar, DateTime(2025, 10, 23));
  print("json: $json");
  */
}
