# Office des lectures : cycle biblique sur deux ans

## Objectif

Permettre à offline-liturgy et à aelf-flutter de proposer, au choix de l'utilisateur, le cycle de lectures
bibliques sur deux ans de l'office des lectures. Les textes viennent de liturgie-plus.

Travailler sur la branche `2-years` des deux dépôts :
- offline-liturgy : la branche existe déjà ;
- aelf-flutter : la créer depuis `master`.

C'est terminé quand :
- toutes les lectures du cycle de deux ans de liturgie-plus sont intégrées dans les YAML, sous les clés
  `biblicalReadingEven` (années paires) et `biblicalReadingOdd` (années impaires), ou bien listées dans le
  compte-rendu avec la raison ;
- le package choisit la bonne variante quand l'option est activée, et le cycle annuel sinon ;
- aelf-flutter propose un réglage « Office des lectures sur deux ans », désactivé par défaut ;
- les vérifications passent sans erreur :
  - `python3 scripts/validate_yaml.py` ;
  - `dart analyze` (package) ;
  - `dart run test/calendar_output.dart` ;
  - `flutter analyze` (aelf-flutter) ;
- le compte-rendu `docs/TWO_YEAR_READINGS_REPORT.md` est écrit.

## Décisions déjà prises (ne pas les rediscuter)

1. **Clés YAML** : `biblicalReadingEven` (pair) et `biblicalReadingOdd` (impair). Même structure que
   `biblicalReading` (liste de `title` / `ref` / `content` / `responsory`). `biblicalReading` reste la lecture
   du cycle annuel et sert de repli.
2. **Parité** : c'est celle de l'année liturgique telle que la porte `CelebrationContext.liturgicalYear`
   (l'Avent 2026 compte pour 2027), ce qui correspond exactement à la parité de liturgie-plus
   (`lh-calendrier.js:432`). On a donc :
   - `lecture_0_*` (parité 0) → `biblicalReadingEven` ;
   - `lecture_1_*` (parité 1) → `biblicalReadingOdd`.
3. **Titre** : `title` reçoit la valeur de `readingAnnouncement(ref)`, définie dans
   `lib/assets/libraries/biblical_book_labels.dart`. C'est la fonction qu'aelf-flutter utilise pour afficher
   le titre (`offline_liturgy_readings_view.dart:505`). Par exemple, `Jos 2, 1-24` donne
   « Lecture du livre de Josué », et `1 S 3, 1-21` donne « Lecture du 1^er livre de Samuel » (garder la
   notation `^er`). La table couvre les 68 livres présents dans les 778 fichiers ; si une référence n'est pas
   reconnue, la signaler et ne pas mettre de `title`.
4. **Répons** : les fichiers de deux ans de liturgie-plus n'en ont pas. Le répons est **hydraté par le code** :
   quand une entrée de la variante choisie n'a pas de `responsory`, on prend celui de l'entrée de même rang de
   `biblicalReading`, ou à défaut celui de la première entrée. On ne recopie pas le répons dans le YAML.
5. **Option** : réglage dans aelf-flutter, désactivé par défaut, transmis au package par
   `CelebrationContext.twoYearReadingCycle`.
6. **Mots collés** (par ex. `Dieuqui`, `Nomqui`, `Jésustout`, `jalousementle`, `fléchisseau`) : on corrige
   automatiquement les seuls cas sûrs, et on liste les autres dans le compte-rendu.
7. **Fêtes du temps de Noël incluses** : les 26, 27, 28 décembre et le 1er janvier reçoivent aussi leurs
   variantes, dans leurs fichiers `sanctoral/roman/`. Le cycle s'applique donc aussi aux lectures propres.
8. **Rien n'est poussé.** aelf-flutter est testé contre le package local avec `dependency_overrides`
   (`path: ../offline-liturgy/`), et cette modification n'est **jamais committée**. Je ferai le lien entre les
   deux dépôts moi-même.

## Étape 1 : sources liturgie-plus (`/Users/franzoom/development/liturgie-plus/www`)

- Fichiers de deux ans : `lectures/lectures/lecture_{p}_{temps}_{semaine}_{jour}.html`, avec `p` ∈ {0,1},
  soit 358 fichiers par parité. Codes de `temps` : 1 Avent, 2 Noël, 3 TO, 4 Carême, 5 Pâques.
- Fichiers datés :
  - `sanctoral/12/F{17-24}-{p}_l_lecture.html` ;
  - `sanctoral/12/N{29-31}-{p}_l_lecture.html` ;
  - `sanctoral/01/J{2-7}-{p}_l_lecture.html` ;
  - `sanctoral/12/{26,27,28}-{p}_l_lecture.html` et `sanctoral/01/01-{p}_l_lecture.html`.
- Logique à relire : `include/lh.js` (`Formulaire_lectures`, l. 753 ; `Lectures_temps_noel`, l. 233) et
  `include/lh-calendrier.js` (calcul de `parite`, l. 432).
- Format d'un fichier : un `<h2>` (toujours « Lecture »), `<p class="ref">(Ph 1,27 – 2,11)</p>`, puis des
  paragraphes de texte, sans répons.
- Reprendre la conversion HTML → texte du script d'import des diocèses (fonction `inline()` : `&nbsp;`,
  `<br>`, italique → `%…%`). Normaliser la référence au format des données existantes : sans parenthèses, et
  avec une espace après la virgule (`Ph 1, 27 – 2, 11`).

## Étape 2 : correspondance avec offline-liturgy (à vérifier fichier par fichier)

| liturgie-plus | offline-liturgy |
|---|---|
| `lecture_{p}_3_S_J` | `ferial_days/ot_S_J.yaml` |
| `lecture_{p}_4_S_J` (dont `4_0_3`, mercredi des Cendres, et `4_6_J`, Semaine sainte) | `ferial_days/lent_S_J.yaml` |
| `lecture_{p}_5_S_J` | `ferial_days/easter_S_J.yaml` (variantes `easter_6_J_before_ascension` ; Ascension `5_6_4` et Pentecôte `5_8_0` → fichiers `sanctoral/roman/` correspondants) |
| `lecture_{p}_1_S_J` | `ferial_days/advent_S_J.yaml` |
| `lecture_{p}_2_S_J` | `ferial_days/christmas_S_J.yaml` |
| `F{d}` | `ferial_days/advent_{d}.yaml` |
| `N{d}` | `ferial_days/christmas_{d}.yaml` |
| `J{d}` | `ferial_days/christmas-ferial_before_epiphany_{d}.yaml` |
| `26`, `27`, `28` (déc.), `01` (janv.) | fichiers `sanctoral/roman/` de saint Étienne, saint Jean, des saints Innocents, de Sainte Marie Mère de Dieu |

- Avant d'écrire, vérifier sur un échantillon que la lecture annuelle d'offline-liturgy (`biblicalReading`)
  correspond bien à `lecture_{temps}_{S}_{J}.html` (cycle annuel de liturgie-plus) : cela valide la
  correspondance des semaines.
- Tout fichier source sans cible, ou toute cible absente, va dans le compte-rendu.
- Insérer `biblicalReadingEven` / `biblicalReadingOdd` juste après `biblicalReading`, sans toucher au reste du
  fichier. Passer ensuite `scripts/fix_nbsp.py` sur les fichiers modifiés.

## Étape 3 : mots collés

- Construire un vocabulaire (mot → fréquence) à partir de tous les textes YAML du package et des fichiers
  annuels de liturgie-plus.
- Pour chaque mot des nouveaux textes absent du vocabulaire, chercher une coupure en deux mots présents.
- Corriger automatiquement seulement si la coupure est unique et si les deux parties sont fréquentes.
  Exemples : `Dieuqui` → `Dieu qui`, `Nomqui` → `Nom qui`.
- Tout le reste (aucune coupure, ou plusieurs possibles) est listé dans le compte-rendu avec le fichier et le
  contexte, sans modification.

## Étape 4 : code du package (`offline-liturgy`, branche `2-years`)

- `CelebrationContext` (`lib/classes/office_elements_class.dart`) : ajouter `final bool twoYearReadingCycle`
  (défaut `false`), au constructeur et à `copyWith`.
- `Readings.fromJson(data, {year, biblicalCycle})` (`lib/classes/readings_class.dart`) :
  - `biblicalCycle` vaut `'Even'`, `'Odd'` ou `null` ;
  - lire `data['biblicalReading$biblicalCycle'] ?? data['biblicalReading']`, sur le modèle de
    `patristicReading$year` ;
  - si c'est une variante qui a été lue, hydrater les répons manquants depuis `data['biblicalReading']`
    (décision 4).
- `readingsExtract()` (`lib/offices/readings/readings_extract.dart`) : transmettre `biblicalCycle`.
- Calculer une seule fois `biblicalCycle = context.twoYearReadingCycle ? ((context.liturgicalYear ?? context.date.year).isEven ? 'Even' : 'Odd') : null`,
  dans un petit helper, par exemple dans `date_tools.dart`. Le passer :
  - à tous les appels de `readingsExtract` de `ferial_readings_resolution.dart` (toutes les saisons, y compris
    les jours datés) ;
  - au chargement des lectures propres dans `readings_export.dart` (`_loadProperReadings`), pour les fêtes de
    la décision 7.
- Vérifier que les mémoires gardent la lecture biblique fériale (variante comprise) : l'overlay du propre et
  des communs ne doit pas l'écraser quand la mémoire n'a pas de lecture biblique propre.
- Ajouter un test (`test/`) qui charge un jour de TO avec `twoYearReadingCycle` à `false`, puis à `true` pour
  une année paire et une année impaire. Il vérifie la `ref` attendue et la présence du répons hydraté.
- Documenter les nouvelles clés dans `docs/add_data_manual.md` (section `readings`), et ajouter une ligne dans
  `CLAUDE.md`.

## Étape 5 : aelf-flutter (branche `2-years`)

- `lib/utils/settings.dart` : `getTwoYearReadings()` / `setTwoYearReadings(bool)`, sur le modèle de
  `getImprecatoryVerses`.
- `lib/states/liturgyState.dart` : `bool useTwoYearReadings = false`, `initTwoYearReadings()` et
  `updateTwoYearReadings(bool)`, sur le modèle des versets imprécatoires.
- `lib/app_screens/settings_screen.dart` : interrupteur « Office des lectures sur deux ans », près de celui des
  versets imprécatoires.
- `lib/widgets/offline_liturgy_readings_view.dart` : `exportOffice` appelle
  `readingsExport(ctx.copyWith(twoYearReadingCycle: …))`, et la vue se reconstruit quand le réglage change.
- Tester avec `dependency_overrides` vers `../offline-liturgy/` (sans le committer), puis lancer
  `flutter analyze`.

## Contraintes

- Ne pas toucher à l'algorithme de Pâques ni à la logique de préséance.
- Ne rien pousser, ne rien merger. Ne pas committer `dependency_overrides` ni `pubspec.lock` d'aelf-flutter si
  seul l'override l'a modifié.
- Commits par étape dans chaque dépôt, **sans** ligne `Co-Authored-By`. Par exemple :
  - données TO, puis Avent / Noël, puis Carême, puis Pâques, puis fêtes ;
  - code du package, puis test, puis documentation ;
  - réglage aelf-flutter, puis vue.

## Compte-rendu (`docs/TWO_YEAR_READINGS_REPORT.md`, dans offline-liturgy)

- Opérations effectuées, avec les commits de chaque dépôt.
- Couverture : nombre de jours avec `Even` / `Odd` par saison, et fichiers source sans cible.
- Mots collés corrigés (avant → après), et mots suspects laissés à relire (fichier, contexte).
- Références non reconnues par `readingAnnouncement`, s'il y en a.
- Écarts relevés lors de la vérification de correspondance des semaines.
- Comment tester dans l'appli.
