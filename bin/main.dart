import 'classes/calendar_class.dart'; //classe de calendar
import './classes/compline_class.dart';
import './offices/compline.dart';

//import 'classes/complineHymn_class.dart';

void main() {
  Calendar calendar = Calendar(); //initialisation du calendrier

  // lancement de la génération des Complies pour le jour demandé:
  Map<String, ComplineDefinition> complineDefinitionResolved =
      complineDefinitionResolution(calendar, DateTime(2025, 3, 4), 'lyon');

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
