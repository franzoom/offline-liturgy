# Import des propres de Paris, Lille et Fréjus-Toulon depuis liturgie-plus

## Objectif

Intégrer dans offline-liturgy (branche `dioceses`) toutes les données diocésaines de
Paris, Lille et Fréjus-Toulon présentes dans liturgie-plus : calendrier et textes des offices.

C'est terminé quand :
- tous les fichiers HTML `*_paris.html`, `*_lille.html` et `*_frejus-toulon.html` de
  liturgie-plus ont été convertis, ou bien listés dans le rapport avec la raison ;
- les fichiers `assets/locations/{paris,lille,frejus}.yaml` reflètent le calendrier de liturgie-plus ;
- `python3 scripts/validate_yaml.py` passe sans erreur ;
- `python3 scripts/make_index.py` a été relancé et `index.json` contient les nouveaux codes ;
- `dart run test/calendar_output.dart` s'exécute sans exception.

## Décisions déjà prises (ne pas les rediscuter)

1. **liturgie-plus fait foi pour le calendrier.** Quand une fête figure dans `Sanctoral_diocese()`
   (`liturgie-plus/www/include/lh-calendrier.js`, l. 940-1080), on aligne la date, la préséance
   et la présence de la fête dans le fichier de lieu. Les fêtes présentes seulement dans
   offline-liturgy, surtout des mémoires facultatives que liturgie-plus ne gère pas, sont conservées.
2. **Les clés suivent les noms de fichiers.** Une clé de `feasts:` est identique au nom (sans `.yaml`)
   du fichier de la fête. Si le saint existe déjà dans `sanctoral/roman/` ou `sanctoral/france/`,
   on reprend ce nom de base. Exemples : `genevieve_virgin` → `genevieve_of_paris_virgin`,
   `coltilda` → `clotilde_of_burgundy`, `caesarius_of_arles_bishop` → `cesaire_of_arles_bishop`,
   `louis` → `louis_ix_of_france`, `denis_of_paris_bishop_and_martyr` → `denis_of_paris_bishop_and_companions_martyrs`.
3. **Les fêtes sans texte dans liturgie-plus reçoivent un fichier minimal**, si aucun fichier n'existe
   déjà sous `roman/` ou `france/`. Ce fichier contient seulement le bloc `celebration`
   (title, subtitle, description si connue, commons, color). Le titre français et les communs sont
   déduits du saint. Chaque fichier minimal est listé dans le rapport, pour relecture.
4. **Les hymnes manquantes sont créées** dans `assets/hymns/<code>.yaml`, au format des hymnes existantes,
   et ajoutées à `assets/hymns/000_list.yaml` si cette liste les recense.

## Étape 1 : comprendre liturgie-plus (`/Users/franzoom/development/liturgie-plus`)

- Lire `www/include/Architecture.md`, `Preseance.md`, la fonction `Sanctoral_diocese()` et les fonctions
  de fêtes mobiles (`NDTreille()` : Pâques + 69 jours) dans `lh-calendrier.js`. Lire aussi `Fichier_sanctoral()`
  et la logique de chargement (propre/commun, `vepres0` = premières vêpres) dans `lh.js`.
- Inventaire des fichiers : `www/sanctoral/MM/<JJ|code>-<partie>_<diocèse>.html`. On compte 10 jours pour Paris,
  5 pour Lille dont `05/NDT-*` (ND de la Treille, fête mobile) et 12 pour Fréjus-Toulon.
- Signification des préfixes de partie :
  - `titre` : titre et rang ;
  - `oraison` : oraison ;
  - `laudes` / `vepres` / `vepres0` / `lectures` / `milieu` : scripts qui listent le propre, le commun
    (`path_commun`) et les psaumes (`sessionStorage.setItem('la_psaume_1', '62')`) ;
  - `la_*` laudes, `v_*` vêpres, `v0_*` premières vêpres, `l_*` office des lectures (`l_lecture` = lecture
    biblique, `l_patristique` = seconde lecture), `m_*` milieu du jour ;
  - `*_antienne_ev2` : antienne évangélique alternative, à vérifier au cas par cas.
- Pour chaque fichier propre, vérifier si le même fichier existe **sans** suffixe diocésain : c'est alors
  le texte général, que le propre remplace.

## Étape 2 : comprendre le format offline-liturgy

- Lire `CLAUDE.md`, `docs/add_data_manual.md` (format complet des fichiers de lieu et de fête),
  `docs/celebration_file_lookup.md` (résolution clé → fichier, override de préséance sans fichier via `knownCodes`)
  et `docs/preseances.md`.
- Modèles : `assets/calendar_data/sanctoral/paris/genevieve_of_paris_virgin.yaml` (fichier complet) et
  `assets/calendar_data/sanctoral/lyon/` (diocèse déjà traité, y compris les surcharges de fêtes `roman/`).
- L'identifiant de lieu est le nom du fichier de lieu : le répertoire des fêtes est `sanctoral/paris/`,
  `sanctoral/lille/` et `sanctoral/frejus/` (et non `frejus-toulon`).
- Seul le propre est saisi. Le reste vient des communs déclarés dans `celebration.commons`. Vérifier que la
  correspondance commun liturgie-plus → offline-liturgy est cohérente :
  `pasteurs` → `pastors`/`pastors_bishop`, `vierges`/`saintes` → `virgins`/`holy_women`,
  `martyr`/`martyrs`, `saints` → `holy_men`, `dedicace`, `marie`. Contrôler les codes exacts dans `assets/calendar_data/commons/`.
- Psaumes : convertir les numéros de liturgie-plus vers les codes `PSALM_N` / `OT_N` / `NT_N`. Pour un cantique,
  comparer le texte avant de choisir le code : la numérotation des cantiques diffère.

## Étape 3 : calendrier (fichiers de lieu)

Correspondance des préséances de liturgie-plus : `4` → 4, `8` et `8.1` → 8, `9.99` → 10, `11` → 10
(les mémoires obligatoires ont la préséance 10). Une fête mobile utilise `relativeTo` + `shift` :
ND de la Treille = `relativeTo: EASTER`, `shift: 69`.

Divergences déjà repérées (à confirmer en relisant le JS) :
- **Paris** :
  - dédicace de la cathédrale le **1er juin**, préséance 8 (et non le 16 juin) ;
  - saint Denis le 9/10, préséance **4** ;
  - **saint Vincent de Paul** le 27/9, préséance 8, manquant ;
  - **saints du diocèse** le 8/11, préséance 10, manquant ;
  - Germain, Clotilde, Louis, martyrs de Paris et Marcel passent en préséance 10.
- **Lille** :
  - **saint Thomas Becket** le 4/1, préséance 10, manquant ;
  - **ND de la Treille**, fête mobile (Pâques + 69 jours), et non le 13 juin ;
  - **saints du diocèse** le 8/11, préséance 10, manquant ;
  - Remi et Piat passent en préséance 10.
- **Fréjus-Toulon** :
  - Honorat, Antoine, Louis, Césaire, bienheureux Pazery et Pey, co-cathédrale, Cyprien, saints du diocèse
    et Léonce passent en préséance 10 ;
  - Roseline : `9.99` → 10 ;
  - saint Antoine (`roman/` le 17/1) est déplacé au 18/1 : utiliser la clé du fichier `roman/` (via `move:`
    si nécessaire) plutôt qu'une nouvelle clé `anthony_abbot`.

## Étape 4 : textes (fichiers de fête)

Pour chaque jour diocésain de liturgie-plus :
1. Déterminer la clé finale (décision 2) et le fichier cible `sanctoral/<lieu>/<clé>.yaml`.
   - Si le fichier existe déjà (ex. Geneviève), le compléter sans écraser les textes existants
     et signaler toute divergence de texte.
   - Si la fête existe sous `roman/` ou `france/` et que liturgie-plus fournit un propre diocésain,
     créer le fichier local avec le **même nom de base**, qui sert alors de surcharge.
2. Convertir le HTML en YAML : retirer les balises et garder les retours à la ligne utiles
   (répons `R/` `V/`, strophes d'hymnes). Respecter les conventions typographiques de `add_data_manual.md`
   (apostrophes typographiques, espaces insécables, `|-` pour les blocs multilignes, citation des valeurs
   contenant `:`).
3. Placer chaque élément sous la bonne clé : `celebration`, `oration`, `invitatory`, `firstVespers`,
   `morning`, `readings`, `middleOfDay`, `vespers`, `hymn`, `psalmody`, `evangelicAntiphon`, `intercession`, etc.
4. Pour les fêtes sans texte, créer le fichier minimal (décision 3).

## Étape 5 : vérification

```bash
python3 scripts/validate_yaml.py
python3 scripts/make_index.py
dart run test/calendar_output.dart
```

Contrôler aussi que chaque clé des trois fichiers de lieu a un fichier `sanctoral/<lieu>/<clé>.yaml`.
À défaut, la clé doit correspondre à un fichier `roman/` ou `france/` au même nom de base
(override de préséance seulement).

## Contraintes

- Ne pas toucher à `docs/celebration_file_lookup.md` (modification en cours non commitée)
  ni à `scripts/__pycache__/`.
- Ne pas modifier le code Dart, sauf bug bloquant ; dans ce cas, s'arrêter et le signaler.
- Commits par étape, par exemple un pour les fichiers de lieu, puis un par diocèse pour les fichiers de fête,
  et un pour les hymnes et l'index. **Sans** ligne `Co-Authored-By`.

## Rapport final (`docs/IMPORT_DIOCESES_REPORT.md`)

- Tableau par diocèse : date, fête, clé finale, préséance avant/après, fichier créé, complété ou réutilisé.
- Fichiers HTML de liturgie-plus non convertis, avec la raison.
- Fichiers minimaux à relire (titres et communs déduits).
- Hymnes créées.
- Divergences de texte avec les fichiers existants, et cas ambigus (`antienne_ev2`, cantiques).
