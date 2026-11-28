# Supprimer la double source des textes usuels (usual_texts.dart vs YAML)

## Contexte

`lib/assets/usual_texts.dart` (package `offline_liturgy`) contient 6 textes liturgiques codés en dur en Dart : les 3 cantiques évangéliques (`magnificat`, `benedictus`, `nuncDimittis`), le `teDeum`, le `notrePere` et le `confiteor`. Un commit de février 2026 (`1735a164`, message : *"hardcoding OurFather and NT1-3 canticles as usual texts to improve loading logic"*) explique que c'était un choix de perf délibéré. Aujourd'hui, les variantes **latine et grecque de ces 6 mêmes textes** passent déjà par le circuit YAML (`hymnsLibrary`/`psalmsLibrary`/`latinCanticlesLibrary`/`greekCanticlesLibrary`, avec cache borné via `yaml_map_loader.dart`) sans problème visible — seul le français reste en dur, de façon asymétrique. Le but est de n'avoir plus qu'une seule source (YAML) pour le français aussi, sans rien perdre fonctionnellement.

Deux groupes de textes, avec deux traitements différents car leur architecture actuelle diffère déjà :

- **Groupe A — Magnificat, Benedictus, Nunc Dimittis, Te Deum** : déjà résolus de façon asynchrone, par office, dans le package (`vespers_export.dart`, `morning_export.dart`, `compline_export.dart`, `readings_export.dart`), en parallèle du chargement de leurs variantes latine/grecque. Un fichier YAML équivalent existe déjà pour chacun (`assets/psalms/NT_1.yaml`, `NT_2.yaml`, `NT_3.yaml`, `assets/hymns/te-deum.yaml`) mais n'est jamais lu pour ce rôle aujourd'hui (le code ne passe que le code `'NT_1'` etc. pour retrouver le fichier SVG du ton psalmodique, jamais pour charger le texte français).
- **Groupe B — Notre Père, Confiteor** : à l'inverse, ces deux textes n'ont **aucune** étape de résolution par office dans le package ; ils sont lus directement et de façon synchrone côté aelf-flutter, via un import du fichier interne (non exporté) `package:offline_liturgy/assets/usual_texts.dart` :
  - `liturgyState.dart` (`displayedOurFather`, utilisé par les vues Vêpres et Laudes) retombe sur `notrePere` en dehors du latin/grec ; le latin/grec (`ourFatherLatin`/`ourFatherGreek`) est déjà chargé via `hymnsLibrary.get('pater-noster'/'pater-noster-greek', ...)` dans `initOurFatherTexts()`, appelé sans attente depuis le constructeur de `LiturgyState` (le même schéma "null au départ, `notifyListeners()` une fois chargé" que `initCanticleLanguage()`/`initTeDeumLatin()`). Un YAML `assets/hymns/notre-pere.yaml` existe déjà et se charge très bien par ce même mécanisme.
  - `offline_liturgy_compline_view.dart` lit `confiteor.title`/`confiteor.content` directement. Aucun YAML autonome n'existe pour ce texte précis (celui de `mass_missal/elements/ouverture.yaml` est le Confiteor de la Messe, plus riche, avec rubriques et absolution — un texte différent, à ne pas réutiliser). La classe `Compline` (`lib/classes/compline_class.dart`) n'a aujourd'hui aucun champ pour le porter.

Deux écarts de contenu confirmés en comparant le Dart et le YAML existant — à corriger avant la bascule, pas après :
1. `assets/hymns/te-deum.yaml` est **incomplet** : il manque les 4 derniers versets "ad libitum" présents dans la constante Dart. Le YAML latin (`te-deum-latin.yaml`) les a bien, lui (sans balise de rubrique) — seul le YAML français les a perdus.
2. Chaque apostrophe diffère typographiquement : le Dart échappe `\'` (apostrophe droite) alors que tous les YAML utilisent `’` (apostrophe typographique) — sans impact visuel actuel, mais c'est une preuve supplémentaire de double source ; la bascule corrige ce point au passage puisque le YAML a la bonne typographie.

## Approche

### 1. Combler les deux YAML avant de les utiliser comme seule source (package offline-liturgy)

- **`assets/hymns/te-deum.yaml`** : ajouter à la fin le bloc manquant, copié tel quel depuis `usual_texts.dart`, avec la même convention de balise que `mass_missal/elements/ouverture.yaml` :
  ```
  [rubric]Versets ad libitum[/rubric]
  Sauve ton peuple, bénis ton héritage ;
  veille sur lui, porte-le à jamais
  ...
  ```
- **`assets/hymns/confiteor.yaml`** (nouveau fichier) : `title`/`content` copiés tel quel depuis la constante `confiteor` de `usual_texts.dart` (le texte court des Complies — pas celui, plus long, de la Messe).

### 2. Groupe A — brancher le français sur le YAML déjà en place, dans le chargement parallèle existant

- **`lib/offices/compose_office.dart`** (`completeHourPrayer`) : au lieu de recevoir un `Psalm canticle` imposé par l'appelant, résoudre le français lui-même via `psalmsLibrary.get(canticleSvgCode, dataLoader)`, ajouté au tuple `(...).wait` qui charge déjà `latinCanticlesLibrary`/`greekCanticlesLibrary` pour ce même code — puis supprimer le paramètre `canticle`.
- **`vespers_export.dart`** / **`morning_export.dart`** : retirer l'argument `canticle: magnificat`/`canticle: benedictus` (devenu inutile) et l'import de `usual_texts.dart`.
- **`compline_export.dart`** : ajouter `psalmsLibrary.get('NT_3', dataLoader)` au tuple existant (étape 3, à côté du latin/grec), l'utiliser comme base de `.withLatin().withGreek()` à la place de `nuncDimittis` ; retirer l'import.
- **`readings_export.dart`** : charger français et latin en parallèle — `(french, latin) = await (hymnsLibrary.get('te-deum', dataLoader), hymnsLibrary.get('te-deum-latin', dataLoader)).wait`, puis `readingsOffice.teDeum = hasTeDeum ? french?.withLatin(latin) : null` ; retirer l'import.
- **`lib/classes/compline_class.dart`** : ajouter un champ `Hymns? confiteor` (constructeur, `mergeWith`, `copyWith` — même schéma mécanique que les champs assignés tardivement comme `evangelicCanticle`).
- **`compline_export.dart`** : assigner `compline.confiteor = await hymnsLibrary.get('confiteor', dataLoader);`.

### 3. Groupe B — aelf-flutter, côté Notre Père

**`lib/states/liturgyState.dart`** :
- Remplacer l'import de `usual_texts.dart` (déjà remplacé par `hymns_library.dart`, déjà importé).
- Ajouter un champ `Hymns? ourFatherFrench` ; étendre le tuple déjà chargé dans `initOurFatherTexts()` avec `hymnsLibrary.get('notre-pere', dataLoader)`.
- `displayedOurFather` : utiliser `ourFatherFrench` au lieu de `notrePere`, avec un `Hymns` vide comme seul repli pour l'instant transitoire avant la fin du chargement (même logique que le `null` actuel sur `ourFatherLatin`/`ourFatherGreek`, corrigé par le `notifyListeners()` qui suit).

### 4. Groupe B — aelf-flutter, côté Confiteor

**`lib/widgets/offline_liturgy_compline_view.dart`** :
- Retirer l'import de `usual_texts.dart`.
- Remplacer `confiteor.title`/`confiteor.content` par `compline.confiteor?.title`/`compline.confiteor?.content` (l'objet `Compline` déjà disponible dans ce widget), avec le même type de garde que les autres champs optionnels de Complies affichés dans ce fichier.

### 5. Nettoyage final

Une fois les 4 points ci-dessus faits et vérifiés, supprimer `lib/assets/usual_texts.dart` du package (plus aucune référence ni dans le package ni dans aelf-flutter).

## Vérification

- `dart analyze` + `dart test` dans offline-liturgy après chaque étape du groupe A (878 tests doivent rester verts).
- `flutter analyze` + `flutter test` dans aelf-flutter après les étapes du groupe B.
- Comparaison fine (lecture côte à côte, pas un diff brut à cause de l'écart d'apostrophes) de chacun des 6 textes YAML contre la constante Dart qu'il remplace, avant de supprimer `usual_texts.dart`.
- Lancer l'app et ouvrir : Vêpres (Magnificat + Notre Père), Laudes (Benedictus + Notre Père), Complies (Nunc Dimittis + Confiteor), Office des lectures un dimanche hors Carême (Te Deum) — y compris basculer en latin (bouton cantiques, bouton Te Deum latin) pour confirmer que ces chemins n'ont pas changé.
- Vérifier que `test/fixtures/office_vepres.json` (aelf-flutter, qui mentionne "magnificat") et la sortie de `test/calendar_output.dart` n'attendent pas la chaîne Dart littérale d'une façon qui casserait avec le nouveau texte.

## Granularité des commits

Un commit par étape logique (conforme à la préférence habituelle) : 1) fix `te-deum.yaml` + nouveau `confiteor.yaml`, 2) chaque fichier du groupe A dans offline-liturgy, 3) suppression de `usual_texts.dart`, puis côté aelf-flutter : 4) Notre Père, 5) Confiteor — avec mise à jour du `pubspec.yaml`/`pubspec.lock` d'aelf-flutter vers le nouveau commit du package entre les deux.
