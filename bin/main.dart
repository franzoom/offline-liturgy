import 'classes/calendar_class.dart'; //classe de calendar
import './classes/compline_class.dart';
import './offices/compline.dart';
import './classes/morning_class.dart';
import './offices/morning.dart';
import './tools/check_and_fill_calendar.dart';

//import 'classes/complineHymn_class.dart';

void main() {
  Calendar calendar = Calendar(); //initialisation du calendrier

  calendar = checkAndFillCalendar(calendar, DateTime(2025, 6, 23), 'lyon');

  // lancement de la génération des Laudes pour le jour demandé:
  Map<String, Morning> ferialMorning =
      ferialMorningResolution(calendar, DateTime(2025, 10, 23), 'lyon');

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
