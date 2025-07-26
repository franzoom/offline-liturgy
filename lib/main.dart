import 'offline_liturgy.dart';

//import 'classes/complineHymn_class.dart';

void main() {
  Calendar calendar = Calendar(); //initialisation du calendrier

  calendar = checkAndFillCalendar(calendar, DateTime(2025, 6, 23), 'lyon');
  List<MapEntry<int, String>> dayFeasts =
      calendar.getSortedItemsForDay(DateTime(2025, 2, 9));
  print(dayFeasts);

  // lancement de la génération des Complies pour le jour demandé:
  Map<String, ComplineDefinition> complineDefinitionResolved =
      complineDefinitionResolution(calendar, DateTime(2025, 10, 23), 'lyon');

  //affichage de ces complies:
  Map<String, Compline> complineTextCompiled =
      complineTextCompilation(complineDefinitionResolved);

  complineTextCompiled.forEach((key, compline) {
    print('Compline for $key:');
    print('=========================');
    complineDisplay(compline);
    print('=========================');
  });
}
