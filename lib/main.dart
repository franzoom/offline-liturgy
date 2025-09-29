import 'offline_liturgy.dart';
import './classes/morning_class.dart';
import './offices/morning.dart';
import '../tools/check_and_fill_calendar.dart';

//import 'classes/complineHymn_class.dart';

void main() {
  Calendar calendar = Calendar(); //initialisation du calendrier

  DateTime date = DateTime(2025, 09, 26);
  String location = 'lyon';
  calendar = checkAndFillCalendar(calendar, date, location);

  // lancement de la génération des Laudes pour le jour demandé:
  Map<String, Morning> ferialMorning =
      ferialMorningResolution(calendar, date, location);
  final zegfqzgrf = ferialMorning;

  /*
  // lancement de la génération des Complies pour le jour demandé:
  Map<String, ComplineDefinition> complineDefinitionResolved =
      complineDefinitionResolution(calendar, date, location);

  //affichage de ces complies:
  Map<String, Compline> complineTextCompiled =
      complineTextCompilation(complineDefinitionResolved);

  complineTextCompiled.forEach((key, compline) {
    print('Compline for $key:');
    print('=========================');
    complineDisplay(compline);
    print('=========================');
  });

  String json =
      exportComplineToAelfJson(calendar, DateTime(2025, 10, 23), 'lyon');
  print("json: $json");
  */
}
