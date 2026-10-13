# Office des lectures : cycle biblique sur deux ans — compte-rendu

Compte-rendu de l'exécution de [PROMPT_two_year_readings.md](PROMPT_two_year_readings.md), révisée ensuite.
Le texte des lectures n'est plus stocké dans le package : il vient de la base biblique d'aelf-flutter, injectée par
un `BibleTextProvider`. Branches `2-years` des deux dépôts.

## Résultat

- **Données** : 382 fichiers YAML reçoivent `biblicalReadingEven` et `biblicalReadingOdd`, avec seulement `title` et
  `ref`. Cela couvre 378 jours tirés de liturgie-plus, plus 4 jours « avant une Ascension au dimanche ».
- **Package** :
  - `CelebrationContext.twoYearReadingCycle` choisit la variante selon la parité de l'année liturgique, avec repli
    sur `biblicalReading` et reprise du répons annuel ;
  - `CelebrationContext.bibleTextProvider` fournit le texte des lectures qui n'ont qu'une `ref`.
- **aelf-flutter** :
  - interrupteur « Office des lectures sur deux ans » dans les paramètres, désactivé par défaut ;
  - `AppBibleTextProvider` lit `assets/bible.db` et est injecté dans les offices hors ligne.
- **Vérifications** :
  - `python3 scripts/validate_yaml.py` → 1957/1957 fichiers OK ;
  - `dart analyze` (package) → aucune erreur ni avertissement, 15 remarques `info` déjà présentes avant ;
  - `test/bible_text_provider_test.dart` → toutes les références sans `content` (745 références distinctes) se
    résolvent dans `bible.db` ;
  - `test/two_year_readings_test.dart` → 7/7, dont le texte réellement fourni par la base ;
  - suite complète : seul `office_content_coverage_test` échoue, sur des manques de **messe** (défunts, Vendredi
    saint, Vigile pascale) qui existaient déjà avant ce travail ;
  - `flutter analyze` (aelf-flutter, contre le package local) → aucune erreur ni avertissement.

## Commits

offline-liturgy (`2-years`, historique reconstruit depuis `4d0be5fb`) :
- `21feb0c1` feat: support the two-year cycle of biblical readings in the Office of Readings
- `c7780453` feat: resolve biblical readings stored by reference from an injected Bible provider
- `68f370cf` data: add two-year cycle biblical readings for Ordinary Time
- `bd29e756` data: add two-year cycle biblical readings for Advent and Christmas time
- `b77c0241` data: add two-year cycle biblical readings for Lent and Holy Week
- `5db82634` data: add two-year cycle biblical readings for Easter time
- `5350c761` data: add two-year cycle readings to the days before a Sunday Ascension
- `26ba22cd` data: add two-year cycle biblical readings for Dec 26-28 and Jan 1
- `38cf40fa` test: cover the two-year cycle and Bible references
- `049063ab` docs: document references-only readings and the two-year cycle keys
- (ce compte-rendu)

aelf-flutter (`2-years`) :
- `7378909` feat: add a setting for the two-year Office of Readings cycle
- `92c1afb` feat: pass the two-year reading cycle setting to the offline offices
- `7dd1318` feat: provide the Bible database text to offline offices
- `ee99ace` feat: inject the Bible text provider into the offline offices

L'ancienne version de la branche, qui stockait le texte dans les YAML, est conservée sous le tag local `2-years-v1`
(`df7f551d`), à supprimer une fois la nouvelle branche validée et poussée. `origin/2-years` pointe encore sur
cette ancienne version : il faudra un `git push --force-with-lease origin 2-years`.

## Pourquoi la référence seule

Lors de la première intégration, le texte de liturgie-plus avait été copié dans les YAML. Une comparaison mot à mot
avec `bible.db` a montré que 712 lectures sur 764 étaient identiques. Pour les autres, la base était plus fiable que
liturgie-plus :

| Défaut de liturgie-plus | Lectures |
|---|---|
| Lecture tronquée par rapport à sa propre référence | 19 |
| Mots collés formant un vrai mot (« toile » pour « toi le »…) | 9 |
| Étiquettes du Cantique (LUI, ELLE, CHŒUR) absentes | 5 |
| Coquilles (« Noum », « fût », « étais », mot manquant) | 4 |
| Référence fausse | 3 |
| Versets grecs d'Esther numérotés dans le texte (« 1A », « 1B »…) | 1 |

La base ne fait moins bien que sur un point : les capitales n'y sont pas accentuées (« ETAIT », « ANNEE », 10 lectures).
Il faudra la corriger dans un second temps.

## Couverture

| Saison | Jours avec Even / Odd |
|---|---|
| Temps ordinaire | 237 |
| Temps pascal | 48 (+ 4 jours avant une Ascension au dimanche) |
| Carême et Semaine sainte | 46 |
| Avent (dont 17-24 décembre) | 28 |
| Temps de Noël (29-31 déc., 2-7 janv., après l'Épiphanie) | 15 |
| Fêtes : 26, 27, 28 décembre et 1er janvier | 4 |
| **Total** | **378** (+ 4) |

- **Correspondance des semaines vérifiée** : pour 376 jours sur 378, la lecture annuelle d'offline-liturgy a la même
  référence que le fichier annuel de liturgie-plus. Les 2 écarts sont des variantes de découpage (`ot_29_3`, `ot_32_3`).
- **Non intégré** : le dimanche de Pentecôte (`5_8_0`). Ses deux parités donnent Rm 8, 5-27, comme le cycle annuel
  déjà présent dans `roman/pentecost`.
- **Jours avant une Ascension au dimanche** : liturgie-plus ne gère pas ce cas. J'ai appliqué le même décalage que le
  cycle annuel (6_4 → 6_5, 6_5 → 6_6, 6_6 → 7_0). En année impaire, le résultat est identique au cycle annuel ; en
  année paire (Actes des Apôtres), c'est une déduction à confirmer.

## Références corrigées

| Fichier | liturgie-plus | Corrigée |
|---|---|---|
| `ot_20_2` (pair) | Qo 3, 1-23 | Qo 3, 1-22 (le chapitre n'a que 22 versets) |
| `ot_24_3` (pair) | Est 17k-17z | Est 4, 17k-17z |
| `ot_31_1` (impair) | Jr 37, 21 ; 28, 14-28 | Jr 37, 21 ; 38, 14-28 |
| `ot_18_0` (pair) | Ab 0, 1-21 | Ab 1-21 (livre d'un seul chapitre) |

## Code

**offline-liturgy** — `lib/tools/bible_text_provider.dart` :
- `BibleTextProvider` : interface abstraite, sur le modèle de `DataLoader` ; elle renvoie les versets d'un chapitre.
- `parseBibleReference()` / `bibleText()` : transforment une référence liturgique en texte. Formes prises en charge :
  - plages (`Jos 2, 1-24`) ;
  - changement de chapitre (`Ph 1, 27 – 2, 11`) ;
  - groupes séparés par `;` et segments séparés par `.` ;
  - versets lettrés (`Est 4, 17k-17z`) ;
  - livres d'un seul chapitre (`Jude 1-25`, stockés au chapitre 1 ou 0 selon la source).

  Un numéro seul inclut ses sous-versets (`Est 5, 1` couvre 1a…1f), et un demi-verset absent de la base est pris en
  entier. Chaque segment de la référence (suite de versets consécutifs, éventuellement sur deux chapitres) est rendu
  en un paragraphe : les retours à la ligne de la base (poésie) et les jonctions entre versets deviennent une seule
  espace. Entre deux segments (`1-15.21-28`, `6-12 ; 26, 1-6`), des versets sont sautés : le segment se termine
  par une espace insécable et `~` (la marque de coupure des données), et le suivant commence un nouveau paragraphe
  (`\n\n`, ligne vide). Vérifié sur les 745 références : un paragraphe par segment, `~` à la fin de chacun sauf
  le dernier, aucun mot collé, aucune double espace.
- Typographie française appliquée au texte de la base : demi-espace insécable (U+202F) avant ; ! ?, espace
  insécable (U+00A0) avant : et » et après «. L'espace existante est remplacée, quel que soit son type, et une
  espace est ajoutée là où il n'y en avait pas. Vérifié sur les 745 références. Les lignes sans numéro de verset (étiquettes LUI / ELLE / CHŒUR du Cantique,
  « Alléluia » des Ps 106 et 117…) sont lues quand elles tombent à l'intérieur de la plage.
- `hydrateBiblicalReadings()` : appelée à la fin de `readingsExport`, elle remplit `content` pour les lectures qui
  n'ont qu'une `ref`. Sans fournisseur, ou si la référence ne se résout pas, `content` reste vide.
- Cycle de deux ans : `twoYearReadingCycle()`, `biblicalCycleFor()`, `Readings.fromJson(…, biblicalCycle:)`
  (répons hydraté), transmis à toute la résolution fériale et aux lectures propres.
- Tests : `test/tools/sqlite_bible_text_provider.dart`, avec `sqlite3` en dépendance de développement.
  Variable `BIBLE_DB`, par défaut `../aelf-flutter/assets/bible.db`.

**aelf-flutter** :
- `lib/utils/bible_text_provider.dart` : `AppBibleTextProvider` lit `verses` dans l'ordre des lignes (`rowid`), car
  `getChapterVerses()` trie par `CAST(verse AS INTEGER)`, ce qui mélange les sous-versets comme « 1a » ou « 17k ».
  Les chapitres sont mis en cache.
- `base_office_view_state.dart` : injecte le fournisseur et le réglage `twoYearReadingCycle`.
- Réglage : `settings.dart`, `LiturgyState`, `settings_screen.dart`.

## Points d'attention

- **Mise à jour de la base** : `BibleDbSqfProvider` ne copie `bible.db` dans les documents de l'appli qu'au
  **premier lancement**. Une base corrigée (accents sur les capitales…) n'atteindra donc pas les appareils déjà
  installés sans un mécanisme de version (copie à nouveau quand l'asset change).
- **Origine de la base** : si `bible.db` est régénérée depuis une source AELF, des corrections faites à la main seraient
  perdues. Mieux vaut un script de correctifs, versionné et rejoué après chaque régénération.
- **Cycle annuel non concerné** : les lectures annuelles du package viennent du livre de la Liturgie des Heures, une
  traduction différente de la Bible AELF (161 lectures identiques sur 514). Elles gardent donc leur texte.
- **Dépendance aelf-flutter → package** : `pubspec.yaml` pointe encore vers `12adf10f`. Pour compiler la branche,
  activer `dependency_overrides` (actuellement activé en local, non commité) ou pointer `ref:` vers le commit poussé
  de `2-years`.

## Comment tester dans l'appli

1. Avec `dependency_overrides` actif (`path: ../offline-liturgy/`), lancer `flutter pub get` puis l'appli.
2. Ouvrir l'office des lectures du mardi de la 10e semaine du temps ordinaire : Jos 2, 1-24 en cycle annuel.
3. Activer **Paramètres → Office des lectures sur deux ans** : en 2026 (année paire), la lecture devient
   Ph 1, 27 – 2, 11, avec son texte tiré de la Bible de l'appli, suivie du répons de la lecture annuelle.
