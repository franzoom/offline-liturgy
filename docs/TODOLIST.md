
Intercession
permettre d'en avoir plusieurs. Changer la structure pour mettre en liste. (exemple Laudes du Commun de la Vierge Marie)
→ toujours ouvert : `Intercession` (lib/classes/office_elements_class.dart) reste un objet unique
  (`description`/`content`), pas une liste, sur `HourPrayer.intercession`.

- Vérifier les textes bibliques pour le commun des Saints (multiples choix, pas tous trouvés...) et les répons qui suivent

- Avent: vérifier combien d'antienne d'Invitatoire il y a. 2 dans PTP, 3 dans liturgie-plus...

~~Milieu du jour - psaumes qui sont différents pour l'office des défunts~~ (fait : `commons/trespassed.yaml` a son propre `middleOfDay.psalmody`)
~~Mémoire de la Sainte Vierge le samedi: Le proposer dans l'office~~ (fait : `roman/virgin_mary_memory`, lib/offices/office_detection.dart)
~~terminer la migration des données en YAML~~ (fait : plus aucune donnée calendaire en JSON, seuls index.json/validated_locations.json, générés)

