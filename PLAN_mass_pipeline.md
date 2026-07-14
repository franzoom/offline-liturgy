# Pipeline `lib/offices/masses/` (Phase 3)

## Statut : ✅ Terminée (2026-07-14)

Tous les changements ont été appliqués et vérifiés :
- `dart analyze` : propre (mêmes 3 infos préexistantes non liées)
- `dart run test/calendar_output.dart` : sortie identique
- Script ad hoc exerçant `massDetection`/`massExport` sur 5 dates réelles (calendrier Lyon 2026) : dimanche ordinaire (2 lectures + évangile filtrés sur 3 → cycle A confirmé), lundi ordinaire (cycle II confirmé, 2026 étant paire), Saint Joseph transféré (repli correct sur le férial, aucune donnée propre), dimanche des Rameaux (2 messes détectées, procession + passion), Pâques (2 messes détectées, vigile + jour ; options sans `cycle` bien conservées, ex: le double choix de 2e lecture Col 3/1 Co 5)
- Ajout supplémentaire (non prévu au plan initial mais nécessaire) : `lib/offline_liturgy.dart` n'exportait pas encore `mass_class.dart`/`mass_export.dart`/`mass_detection.dart`, contrairement aux autres offices — corrigé pour que le pipeline soit réellement utilisable.

## Context

Phases 1 (schéma YAML) et 2 (classe `Mass`/`Masses`) sont terminées. Il reste à construire le pipeline qui résout le contenu complet d'une messe pour une date donnée, sur le modèle de `lib/offices/readings/`. Le code existant dans `lib/offices/masses/` (`mass_extract.dart`, `mass_detection.dart`, `ferial_mass_resolution.dart`) est partiel : il n'y a pas de `mass_export.dart` (l'étape qui assemble ferial + propre + commun et retourne le contenu final), et rien ne sait encore choisir la bonne lecture selon le cycle liturgique (Année I/II en semaine, A/B/C le dimanche).

En lisant `ferial_mass_resolution.dart` en détail, j'ai trouvé une découverte importante : `DayContent.liturgicalYear` (`lib/classes/calendar_class.dart:11`) est un entier **déjà calculé par le calendrier** pour chaque jour, qui gère déjà correctement le décalage de l'Avent (confirmé par toi : l'année liturgique 2027 commence à l'Avent 2026). Ce champ n'est actuellement **pas transmis** à `CelebrationContext` (utilisé seulement en interne par `main_calendar_fill.dart`) — il suffit de le faire transiter pour obtenir gratuitement la bonne "année de référence" du cycle, sans réinventer de logique de décalage.

Décision confirmée : Année I = années impaires, Année II = années paires (ex: 2027 impaire → Année I), avec l'année de référence égale à `DayContent.liturgicalYear`.

J'ai aussi trouvé deux petits problèmes préexistants dans `ferial_mass_resolution.dart` en le relisant :
- `if (code.startsWith('paschal')) return _resolveEaster(context);` — faute de frappe, aucun code ferial ne commence par `paschal` (le préfixe réel est `easter`, cf. `easter_1_0.yaml` etc.). Cette branche n'est donc jamais prise ; le code retombe sur le fallback générique en bas de fonction, qui produit **par coïncidence** le bon résultat. Sans risque aujourd'hui, mais fragile et trompeur à la lecture.
- `_resolveOrdinaryTime` charge un fichier "base" sur un cycle de 4 semaines puis le remplace par le fichier de la semaine réelle si `week > 4` — copié du pipeline des lectures (où le Psautier suit un vrai cycle de 4 semaines). Pour la Messe, chaque fichier `ot_N_D.yaml` (semaines 1 à 34) contient déjà un contenu complet et autonome (confirmé en phase 1) : le fetch "base" est donc toujours entièrement écrasé, un aller-retour réseau/fichier inutile.

## Changements

### 1. `lib/classes/office_elements_class.dart` — `CelebrationContext`
Ajouter un champ `final int? liturgicalYear;` (constructeur + `copyWith`), pour transporter `DayContent.liturgicalYear`.

### 2. `lib/offices/office_detection.dart` — `detectCelebrations()`
Peupler ce nouveau champ depuis `dayContent.liturgicalYear` lors de la construction de chaque `CelebrationContext` (ligne ~300-317). Comme `copyWith` préserve les champs existants par défaut, ce champ se propage automatiquement à `massDetection`/`massExport` sans autre câblage.

### 3. `lib/tools/date_tools.dart`
Ajouter :
```dart
/// Returns '1' or '2' for the two-year weekday Lectionary cycle
/// (Year I in odd-numbered years, Year II in even-numbered years).
String weekdayLectionaryYear(int year) => year.isOdd ? '1' : '2';
```
(`liturgicalYear(int year)` existant, pour A/B/C, est réutilisé tel quel)

### 4. `lib/offices/masses/ferial_mass_resolution.dart` — corrections
- Corriger `'paschal'` → `'easter'`, et adapter `_resolveEaster` pour gérer explicitement les codes composés type `easter_6_3_before_ascension` (que `extractWeekAndDay` ne peut pas parser) en repassant par un fetch littéral du code — comportement final identique à aujourd'hui, mais explicite plutôt qu'accidentel.
- Simplifier `_resolveOrdinaryTime` en un seul fetch direct du fichier de la semaine demandée (suppression du fetch "base" 4-semaines devenu inutile).

### 5. `lib/tools/hierarchical_common_loader.dart`
Ajouter `loadMassHierarchicalCommon(CelebrationContext context)`, sur le modèle exact des 4 fonctions existantes (`loadReadingsHierarchicalCommon` etc.), utilisant `massExtract` et le nouveau `Masses.overlayWith` (phase 2).

### 6. `lib/offices/masses/mass_export.dart` (nouveau fichier)
`Future<Mass> massExport(CelebrationContext context)`, sur le modèle de `readingsExport` (`lib/offices/readings/readings_export.dart`) :
1. Base férial via `ferialMassResolution` si `ferialCode` non vide
2. Overlay du propre via `massExtract` + `dirPathForCode` (comme `_loadProperReadings`)
3. Commun : `loadMassHierarchicalCommon`, appliqué avec `overlayWithCommon` si `precedence > 7` (mémoire), sinon `overlayWith`
4. Ré-application du propre par-dessus
5. Sélection du `Mass` correspondant à `context.massName` dans la liste `Masses.masses` (repli sur le premier disponible, ou `Mass()` vide si aucun)
6. Filtrage des `readingParts` selon le cycle applicable : dimanche/solennité → `liturgicalYear(context.liturgicalYear!)` (A/B/C) ; jour de semaine → `weekdayLectionaryYear(context.liturgicalYear!)` ('1'/'2'). Les options sans `cycle` (ex: évangile de semaine) sont toujours conservées.

Pas d'hydratation façon `resolveOfficeContent` (le contenu de la Messe est du texte littéral, pas des références de code comme la psalmodie de l'Office), pas de Te Deum, pas d'antienne pascale dynamique — aucun de ces mécanismes ne s'applique à la Messe.

### 7. `lib/offices/masses/mass_detection.dart` — nettoyage
- Remplacer le `sanctoralFilePath` codé en dur par `dirPathForCode` (comme `readingsExport._loadProperReadings`).
- Supprimer le `print` de débogage.
- La forme générale (une entrée de contexte par objet `Mass`, car une célébration peut produire plusieurs messes) reste inchangée : elle ne peut pas réutiliser `buildDetectionMap` directement, et ce n'est pas un problème à corriger — `CelebrationContext` ne transporte jamais de contenu pré-résolu pour aucun office, la résolution complète est toujours refaite dans l'étape `export`, appelée à la demande pour la célébration sélectionnée.

## Vérification
- `dart analyze` doit passer sans erreur
- `dart run test/calendar_output.dart` doit rester identique
- Script ad hoc temporaire exerçant `massDetection` + `massExport` sur plusieurs dates représentatives : un dimanche du Temps ordinaire (vérifie la sélection A/B/C et les 2 lectures distinctes), un jour de semaine ordinaire (vérifie la sélection I/II), un jour avec mémoire/fête (vérifie l'overlay propre + commun), le dimanche des Rameaux et la Vigile pascale (vérifie la détection de plusieurs messes par jour et la bonne distinction vigile/messe du jour) — supprimé après vérification, comme en phases 1 et 2

## Suite
- **Phase 4** : widget Flutter dans `aelf-flutter`, sur le modèle de `morning_view`.
