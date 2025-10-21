import 'offline_liturgy.dart';

//import 'classes/complineHymn_class.dart';

void main() {
  Calendar calendar = Calendar(); // calendar creation
  DateTime date = DateTime(2025, 10, 22);
  String location = 'lyon';
  calendar =
      calendarFill(calendar, date.year, location); // calendar initialisation

  // lancement de la génération des Laudes pour le jour demandé:
  Map<String, Morning> ferialMorning = ferialMorningResolution(calendar, date);
  final zegfqzgrf = ferialMorning;

  // lancement de la génération des Complies pour le jour demandé:
  List<Map<String, ComplineDefinition>> possibleComplinesList =
      complineDefinitionResolution(calendar, date);

  //affichage de ces complies:
  Map<String, Compline> complineTextCompiled =
      complineTextCompilation(possibleComplinesList[0]);

  complineTextCompiled.forEach((key, compline) {
    print('Compline for $key:');
    print('=========================');
    complineDisplay(compline);
    print('=========================');
  });

/*
  String json = exportComplineToAelfJson(calendar, DateTime(2025, 10, 23));
  print("json: $json");
  */
}
