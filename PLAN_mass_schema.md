# Refonte de la clé `mass:` des fichiers YAML (Phase 1)

## Context

Le package `offline_liturgy` doit désormais gérer les textes des messes, pas seulement l'Office. La clé `mass:` existe déjà dans 388 fichiers (`ferial_days/`, quelques `sanctoral/roman/*.yaml` pour les grandes solennités) et une classe `Mass`/`Masses` existe dans `lib/classes/mass_class.dart`, mais rien n'est branché sur le pipeline `offices/` ni sur l'app Flutter.

Avant de construire la classe, le pipeline et le widget (étapes 2 à 4, à planifier séparément), il faut stabiliser le schéma YAML lui-même : l'exploration a mis au jour un champ à la sémantique ambiguë et plusieurs bugs de données. Cette phase 1 corrige ces deux points sans toucher à la classe Dart au-delà d'un renommage mécanique, afin de garder une base saine pour la suite.

Décisions validées avec l'utilisateur :
- `sundayAndWeekCycles` reste un **champ unique**, renommé en `cycle` (nom neutre) — le code Dart interprétera le sens (I/II en semaine, A/B/C le dimanche/fêtes, options libres à la Pentecôte) selon le contexte, pas le YAML.
- L'ordre des lectures dans `readingParts`/`partContents` reste la seule source de vérité (pas de champ `role`/`order` ajouté).
- Les bugs de données identifiés sont corrigés, **sauf** `EPISTLE` qui reste distinct de `READING` (pas de fusion).
- Les trous de contenu (pas de `mass:` pour Noël/Épiphanie/Ascension, Gospel de procession des Rameaux vide, absence de "Commun" de Messe) sont **hors scope** pour l'instant.

## Changements à appliquer

### 1. Renommage `sundayAndWeekCycles` → `cycle`
- Dans les ~388 fichiers YAML sous `mass:` (`assets/calendar_data/ferial_days/*.yaml` et les 8 fichiers `sanctoral/` concernés : `roman/pentecost.yaml`, `roman/christ_king.yaml`, `roman/mary_mother_of_god.yaml`, `roman/mary_mother_of_the_church.yaml`, `roman/immaculate_heart_of_mary.yaml`, `lyon/gregory_x_pope.yaml`, `lyon/polycarp_of_smyrna_bishop.yaml`, `lyon/marie_of_saint_ignatius_claudine_thevenet_religious.yaml`).
- Dans `lib/classes/mass_class.dart` : renommer le champ `sundayAndWeekCycles` en `cycle` sur `MassReading`, `MassPsalm`, `MassGospel` (constructeur + `fromJson`). Renommage mécanique uniquement — pas de logique de résolution par année ajoutée ici (ce sera fait en phase 3, pipeline).

### 2. Correction des bugs de données
- **Valeurs non quotées** : `ot_8_1.yaml`, `ot_8_2.yaml`, `ot_8_3.yaml`, `ot_9_1.yaml`, `ot_9_2.yaml` (4 occurrences chacun, confirmé par grep) écrivent `- 1` / `- 2` au lieu de `- '1'` → à requoter pour rester cohérent avec les 388/384 occurrences correctement quotées ailleurs (évite un typage `int` inattendu une fois `cycle` réellement consommé par le Dart).
- **Duplication `easter_1_0.yaml`** : confirmé — le bloc `mass:` entier (`easter_vigil` puis `day_mass`) est répété deux fois (lignes 119/898 puis 1157/1936, contenu identique). Supprimer la seconde occurrence complète.
- **`note:`/`entranceAntiphon:`/`collect:`/etc. vides vs `null` explicite** : uniformiser vers `null` explicite partout où la clé existe mais n'a pas de valeur, pour homogénéiser les ~25 fichiers `ot_1_*`/`ot_2_*`/`ot_3_*`/`ot_4_*` qui laissent la valeur vide.
- `EPISTLE` : **ne pas toucher**, reste tel quel dans `easter_1_0.yaml`.

### 3. Méthode d'application
Écrire un script Python ponctuel dans `scripts/` (cohérent avec les utilitaires de migration déjà présents dans ce dossier), utilisant un parseur YAML round-trip (`ruamel.yaml`) pour préserver la mise en forme existante (style de citation, blocs `|-`, commentaires) et n'appliquer que les transformations ciblées :
- renommage de clé `sundayAndWeekCycles` → `cycle` (uniquement à l'intérieur de `mass:`, pas ailleurs)
- forcer les valeurs de `cycle` en chaînes quotées
- normaliser les valeurs vides en `null` explicite pour les champs listés ci-dessus
- traiter `easter_1_0.yaml` séparément (suppression manuelle du bloc dupliqué, trop spécifique pour le script générique)

Le script sera à usage unique (lancé puis supprimé ou déplacé en historique), pas un outil pérenne.

## Vérification
- `dart analyze` doit passer sans erreur après le renommage dans `mass_class.dart`.
- `dart run test/calendar_output.dart` doit toujours générer le calendrier Lyon 2026 sans erreur (non-régression sur l'Office, qui ne dépend pas de `mass:`).
- Écrire un petit script Dart ad hoc (ou test ponctuel) qui parcourt tous les fichiers contenant `mass:`, appelle `Masses.fromJson` dessus, et vérifie : (a) aucune exception de parsing, (b) plus aucune occurrence d'un `cycle` de type `int` (confirmant le requotage), (c) le fichier `easter_1_0.yaml` ne contient plus qu'une seule occurrence de `easter_vigil` et une de `day_mass`.
- `grep -rn "sundayAndWeekCycles" assets/ lib/` doit retourner vide après migration.

## Suite (hors scope de cette phase, à planifier séparément après validation)
- **Phase 2** : reconstruire `lib/classes/mass_class.dart` en s'alignant sur les conventions des autres offices (`isEmpty`, `overlayWithCommon` sur `Mass`, `overlayWith` public sur `Masses`, résolution du cycle d'année selon le contexte dimanche/semaine).
- **Phase 3** : pipeline `lib/offices/masses/` sur le modèle de `offices/readings/` (créer `mass_export.dart` manquant, simplifier `mass_detection.dart`, ajouter `loadMassHierarchicalCommon`, ajouter la logique de cycle I/II absente de `date_tools.dart`).
- **Phase 4** : nouveau widget d'affichage des messes dans `aelf-flutter`, sur le modèle de `morning_view`.

Chaque phase suivante fera l'objet d'une planification et d'une confirmation dédiées avant toute modification.
