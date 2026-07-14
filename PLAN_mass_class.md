# Reconstruction de `lib/classes/mass_class.dart` (Phase 2)

## Statut : ✅ Terminée (2026-07-14)

Tous les changements ci-dessous ont été appliqués et vérifiés :
- `dart analyze` : propre (3 infos préexistantes non liées, dans `readings_class.dart`)
- `dart run test/calendar_output.dart` : sortie identique, aucune régression
- Test ciblé manuel sur `ot_7_0.yaml` : confirmé que les 2 lectures du dimanche restent bien distinctes après `overlayWith` (le bug de fusion est corrigé), que `cycle` est bien un `List<String>`, et que `isEmpty`/`overlayWithCommon` se comportent comme prévu
- Écart mineur par rapport au plan initial : `ferial_mass_resolution.dart` avait **4** sites d'appel à `_overlayMasses` (pas 3 comme estimé initialement) — tous mis à jour.

## Context

Phase 1 (terminée, voir `PLAN_mass_schema.md`) a stabilisé le schéma YAML `mass:` (renommage `sundayAndWeekCycles` → `cycle`, correction de bugs de données). La classe `Mass`/`Masses` existante dans `lib/classes/mass_class.dart` a été écrite avant cette stabilisation et avant que les conventions des autres offices (`Morning`, `Vespers`, `Readings`, `MiddleOfDay`) ne soient bien établies : il lui manque `isEmpty`, `overlayWithCommon`, et une méthode `overlayWith` publique sur le conteneur `Masses`. Elle contient aussi deux défauts trouvés en lisant le code en détail :

1. **Bug de fusion `readingParts`** : `Mass.overlayWith` fusionne les `readingParts` par une clé `partType` (`{'READING': ..., 'PSALM': ...}`). Or les dimanches (`ot_7_0.yaml`) et la Vigile pascale ont **plusieurs entrées avec le même `partType`** (1ère et 2ème lecture, toutes deux `READING`). Une `Map` ne peut garder qu'une entrée par clé : la fusion actuelle **écraserait silencieusement une des deux lectures** dès qu'un dimanche passe par le chemin de fusion (`_resolveOrdinaryTime` le fait dès que `week > 4`, donc pour la majorité des dimanches de l'année). Comme chaque fichier `ot_N_D.yaml` contient déjà un jeu de `readingParts` complet et autonome (confirmé en phase 1 : aucune superposition partielle n'existe réellement dans les données), la fusion doit être un **remplacement complet**, pas une fusion élément par élément.
2. **Type incohérent pour `cycle`** : le champ est typé `String?` mais la donnée YAML est toujours une liste (`cycle: ['1']`). `json['cycle']?.toString()` produit donc `"[1]"` au lieu de `"1"` (confirmé en vérifiant après le renommage de phase 1). Le type doit devenir `List<String>?`.

Décisions validées avec l'utilisateur pour cette phase :
- Le filtrage par cycle (choisir la bonne lecture selon l'année liturgique) reste **entièrement dans le pipeline** (phase 3) — la classe reste un miroir brut du YAML, aucun paramètre `cycle`/`year` n'est ajouté à `fromJson`.
- `overlayWithCommon` est ajouté dès maintenant sur `Mass` et `Masses`, par symétrie avec les autres offices, même si aucune donnée de "Commun des saints" pour la Messe n'existe encore.

## Changements à `lib/classes/mass_class.dart`

1. **`cycle` : `String?` → `List<String>?`** sur `MassReading`, `MassPsalm`, `MassGospel` (constructeur + `fromJson`), avec le même style de parsing que les autres champs liste-de-strings du fichier (ex: `Celebration.commons`) :
   ```dart
   cycle: (json['cycle'] as List?)?.map((e) => e.toString()).toList(),
   ```

2. **`Mass.overlayWith` — remplacement complet de `readingParts`** au lieu de la fusion par `partType` :
   ```dart
   if (overlay.readingParts != null && overlay.readingParts!.isNotEmpty) {
     readingParts = overlay.readingParts;
   }
   ```
   (supprime la logique `Map<String, MassReadingPart> merged = {...}` actuelle, qui est le bug décrit ci-dessus)

3. **`Mass.isEmpty`** (getter), sur le modèle de `Readings.isEmpty` (`lib/classes/readings_class.dart:116`) : vérifie que tous les champs sont `null` ou vides.

4. **`Mass.overlayWithCommon(Mass common)`** — overlay sélectif, sur le modèle de `Readings.overlayWithCommon` (`lib/classes/readings_class.dart:108`, qui exclut `biblicalReading` du commun). Pour `Mass`, on copie `entranceAntiphon`, `collect`, `offeringPrayer`, `prefaceList`, `communionAntiphon`, `prayerAfterCommunion`, `solemnBlessingList` ; on exclut `massType`, `name`, `note` (métadonnées d'identité) et **`readingParts`** (la Liturgie de la Parole reste toujours férial/propre, jamais issue du commun — même raisonnement que Readings pour `biblicalReading`).

5. **`Masses.overlayWith(Masses overlay)`** — promotion en méthode publique de la logique actuellement privée `_overlayMasses()` dans `lib/offices/masses/ferial_mass_resolution.dart:9` (correspondance par `massType` ; `Mass.overlayWith` pour les types déjà présents, ajout des nouveaux types).

6. **`Masses.overlayWithCommon(Masses common)`** — même correspondance par `massType`, mais n'enrichit que les `massType` déjà présents (n'introduit jamais un nouveau type de messe depuis le commun) et appelle `Mass.overlayWithCommon` sur les entrées correspondantes.

7. **`Masses.isEmpty`** (getter) : `masses == null || masses!.isEmpty`.

## Changement d'accompagnement (pour rester compilable)

Dans `lib/offices/masses/ferial_mass_resolution.dart` : remplacer les 3 appels à la fonction privée `_overlayMasses(base, overlay)` par `base.overlayWith(overlay)`, et supprimer la fonction `_overlayMasses` désormais redondante (lignes 7-21). Aucun autre changement dans ce fichier — la reconstruction complète du pipeline (`mass_export.dart`, nettoyage de `mass_detection.dart`, résolution réelle du cycle I/II) reste la phase 3, à planifier séparément.

## Vérification
- `dart analyze` doit passer sans erreur.
- `dart run test/calendar_output.dart` doit rester identique (n'affecte pas l'Office).
- Réexécuter le script de vérification ad hoc utilisé en phase 1 (parcourir tous les fichiers `mass:`, appeler `Masses.fromJson`, vérifier l'absence d'exception) pour confirmer que le remplacement du parsing de `cycle` ne casse rien.
- Test ciblé manuel : construire deux `Mass` avec des `readingParts` contenant chacun 2 entrées `READING` (comme `ot_7_0.yaml`), appeler `overlayWith`, et vérifier que le résultat contient bien 2 entrées distinctes (celles de l'overlay), pas une lecture dupliquée — pour confirmer la correction du bug de fusion.

## Suite (hors scope de cette phase)
- **Phase 3** : pipeline `lib/offices/masses/` (créer `mass_export.dart`, simplifier `mass_detection.dart`, `loadMassHierarchicalCommon` dans `hierarchical_common_loader.dart`, logique de cycle I/II dans `date_tools.dart`, câblage réel du filtrage par cycle).
- **Phase 4** : widget Flutter dans `aelf-flutter`, sur le modèle de `morning_view`.
