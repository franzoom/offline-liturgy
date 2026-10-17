# Audit de la branche `2-years` (offline-liturgy + aelf-flutter)

Date : 2026-10-14. Audit en lecture seule, aucun code n'a été modifié.

Vérifications faites : `dart analyze` (15 infos `curly_braces_in_flow_control_structures` dans
`readings_class.dart`, apparemment dans du code qui existait déjà), tests de la branche
(`two_year_readings_test.dart` + `bible_text_provider_test.dart` : 763 tests réussis), analyse des 382 YAML porteurs
de variantes.

## 1. Points à corriger avant le merge

### 1.1 `pubspec.yaml` d'aelf-flutter — ⏸ décidé
**Décision (15/10/2026) :** l'app pointe sur le dépôt local du package (override actif, non commité). Les deux branches
`2-years` restent des branches le temps de tout tester à l'usage ; la ref git sera mise à jour au merge.

L'override `dependency_overrides: offline_liturgy: path: ../offline-liturgy/` est actif dans la copie de travail
(non commité). Le pubspec commité pointe sur `ref: 12adf10f`, qui ne connaît ni `twoYearReadingCycle` ni
`bibleTextProvider` : la branche ne compile pas sans l'override.
→ Faire pointer la ref sur le commit offline-liturgy mergé, puis recommenter l'override.

### 1.2 Répons qui ne correspondent pas à la lecture — ⏸ décidé
**Décision :** on laisse ainsi, sans le noter dans les données : il y a peu de chances d'avoir un jour des répons
propres aux lectures du cycle de deux ans. Le code utilise toutefois le répons propre d'une variante s'il existe.

Une variante sans répons prend celui de la lecture annuelle de même rang. Sur `ot_10_2` en année paire, la lecture de
Ph 1, 27 – 2, 11 est suivie du répons de Jos 2. C'est documenté, mais c'est une approximation liturgique visible.
→ À noter comme dette de données dans le compte-rendu, idéalement avec un test qui liste les variantes concernées
(ref ≠ ref annuelle).

### 1.3 Repli `context.date.year`, faux en Avent — ✅ fait
`biblicalCycleFor()` ([readings_extract.dart](../lib/offices/readings/readings_extract.dart)) fait
`liturgicalYear ?? date.year`. En Avent, `date.year` (2026) n'est pas l'année liturgique (2027) : la parité
s'inverse. Ce repli ne sert pas aujourd'hui (voir section 4), mais il est trompeur.
→ Le calculer correctement (même règle que `_liturgicalYearOf`) ou lever une assertion. Voir 4.3.

**Fait** (`6d2d1430`, `85d578bd`) : le repli utilise `liturgicalYearOf(date)`, puis le getter
`CelebrationContext.effectiveLiturgicalYear` (`liturgicalYear ?? liturgicalYearOf(date)`) remplace le repli dans les
quatre offices. Pas d'assertion : les contextes de Complies n'ont pas de `liturgicalYear` et n'en ont pas besoin.

## 2. Simplifications côté package

### A. Arrêter de passer `biblicalCycle` à chaque appel — ✅ fait
**Fait** (`5180e4bc`) : option simple, `readingsExtractFor(context, path, {year})` ; `biblicalCycleFor` devient privé.
L'option « plus structurante » a été écartée : superposer les trois variantes ferait survivre la variante d'une férie
sous une fête qui a sa propre lecture annuelle.

Dans [ferial_readings_resolution.dart](../lib/offices/readings/ferial_readings_resolution.dart), `biblicalCycle:` est
ajouté à une douzaine d'appels `readingsExtract`, et `biblicalCycleFor(context)` est recalculé dans chaque
`_resolveXxx`. Deux options :
- **Simple :** un helper local `_extract(context, path, {year})` qui passe `dataLoader` et le cycle. Le diff se réduit
  beaucoup, et `commons/christmas.yaml`, chargé aujourd'hui sans cycle, devient cohérent avec le reste.
- **Plus structurant :** `Readings` garde les trois variantes brutes, `overlayWith` les superpose, et le choix se fait
  une seule fois dans `readingsExport`, juste avant `hydrateBiblicalReadings`. Plus aucun paramètre n'est passé de
  fonction en fonction.

### B. `_selectBiblicalReading` contient du code mort — ✅ fait
**Fait** (`55dd48df`) : une variante est toujours une lecture unique ; elle garde son répons propre ou prend celui de
la lecture annuelle, sur des objets typés. `_selectBiblicalReading` et `asMaps` sont supprimés.

([readings_class.dart](../lib/classes/readings_class.dart)) Sur les 382 fichiers : 0 variante dont le nombre
d'entrées diffère de l'annuel, et 0 variante avec son propre répons.
- Le repli `annualEntries.first` ne sert jamais. Le simple appariement par index suffit.
- `asMaps` refait ce que fait déjà `parseReadings`. Alternative : parser les deux listes en `BiblicalReading`,
  puis compléter le répons avec `copyWith`.

### C. Ajouter `BiblicalReading.copyWith` — ✅ fait
**Fait** (`4451bedd`), utilisé par `hydrateBiblicalReadings` et `Readings.fromJson`.

`hydrateBiblicalReadings` reconstruit le `BiblicalReading` champ par champ : un champ ajouté plus tard serait perdu en
silence. `copyWith(content: …)` règle le problème et sert aussi au point B.

### D. Variantes identiques à la lecture annuelle (115 cas) — ✖ écarté
**Décision :** on ne touche pas au texte des fichiers YAML : le package peut servir à d'autres applications, qui
peuvent avoir besoin de variantes complètes.

Dans 115 cas, `biblicalReadingEven` ou `biblicalReadingOdd` a exactement la même ref que `biblicalReading`
(`biblicalReadingOdd` de `ot_10_2`, les deux variantes de `mary_mother_of_god`, `easter_5_1`, `christmas_29`…).
Sans ces variantes, le repli prendrait la lecture annuelle :
- avec son texte YAML relu, et non le texte de la base biblique ;
- avec son vrai répons ;
- sans dépendre de la base biblique ;
- avec environ 115 blocs YAML en moins.

→ Un script pourrait les retirer. Un test pourrait ensuite interdire `variante == annuelle`.

### E. [bible_text_provider.dart](../lib/tools/bible_text_provider.dart) — ✅ fait
**Fait** (`3d1acc21`) : regex compilées une fois, recherche du verset en un seul parcours, chapitres en `int`. Les
954 références des données donnent exactement le même texte qu'avant. **`_flatten` est gardé tel quel** : la version en
une regex effaçait des insécables voulues (avant un tiret d'incise, dans des guillemets) sur 168 chapitres.

- **Regex recompilées à chaque passage.** Dans `_slice.find`, `RegExp('^${label}[a-z]+$')` est créée pour chaque
  verset, à chaque recherche. Un test `v.verse.startsWith(label)` suivi d'un contrôle du suffixe `[a-z]+` suffit.
  Les autres regex fixes de `parseBibleReference` peuvent devenir des `final` de niveau fichier.
- **Calcul en double dans `find`.** `exact` et `subs` parcourent tous deux les lignes ; comme `exact ∈ subs`, un seul
  parcours suffit.
- **Chapitres en `String`.** `BiblePassage` les stocke en `String`, puis `int.parse` les relit dans `bibleText`.
  Les stocker en `int?` dès le parsing est plus simple.
- **`_flatten` en une regex ?** En Dart, `\s` couvre déjà U+00A0 et U+202F, et `_frenchSpacing` remet ensuite les
  insécables : `texts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim()`. Risque : une insécable légitime au milieu
  d'une ligne (par exemple `10 000`) deviendrait une espace normale. À vérifier sur la base avant de changer.

### F. Cache de chapitres dupliqué — ✅ fait
**Fait** : `CachedBibleTextProvider` dans le package (`54f758e7`), utilisé par l'app (`2686ff7`). Il partage une
lecture en cours entre requêtes simultanées et ne garde ni un chapitre absent ni une erreur.

`AppBibleTextProvider` (app) et `SqliteBibleTextProvider` (tests) ont chacun le leur. Un wrapper
`CachedBibleTextProvider` (ou un mixin) dans le package, qui stocke des `Future`
(`Map<String, Future<List<BibleVerse>?>>`), supprime la duplication et évite deux requêtes SQL pour un même chapitre
si deux offices le demandent en même temps.

### G. Un échec d'hydratation laisse un texte vide — ✅ fait
**Fait** (`4c9e1a1e`) : si une lecture du cycle de deux ans reste sans texte (pas de fournisseur, référence non
résolue), `readingsExport` reprend l'office avec le cycle annuel, dont les lectures ont toujours leur texte.

Si une ref ne se résout pas, l'erreur est seulement journalisée et la lecture s'affiche sans texte. On pourrait se
replier sur la lecture annuelle. Le test qui parcourt toutes les refs réduit le risque, mais pas pour une autre base
biblique.

## 3. Côté aelf-flutter — ✅ fait
**Fait** sur la branche `2-years` de l'app : renommage (`a22b60d`), rechargement limité à l'office des lectures
(`0f595bd`), versets imprécatoires lus depuis `LiturgyState` dans les offices (`49a0f2b` ; les Complies, sans listener,
lisent toujours SharedPreferences), réglage déplacé dans une section « Lectures » avec la mention « hors ligne »
(`9cd386f`).


- **Nom trompeur :** `_onPsalmSettingsChanged` réagit aussi au cycle de deux ans → `_onOfficeSettingsChanged`.
- **Rechargements inutiles :** basculer l'option recharge tous les offices (Laudes, Vêpres, Milieu du jour), alors que
  seul l'office des lectures est concerné.
- **Sources incohérentes pour les réglages :** `_imprecatoryVerses` est lu depuis SharedPreferences
  (`await getImprecatoryVerses()`), `_twoYearReadings` vient de `LiturgyState`. La seconde approche est la meilleure ;
  aligner les versets imprécatoires dessus serait un petit refactor séparé.
- **Rangement du réglage :** le switch est dans `_buildPsalmodieSection`, alors qu'il ne concerne pas la psalmodie.
  Le sous-titre pourrait préciser qu'il ne s'applique qu'aux offices hors ligne.
- **Point vérifié :** la base biblique est ouverte dans `main.dart:140`, avant l'affichage. `db == null` dans
  `AppBibleTextProvider` ne devrait donc pas arriver en pratique.

## 4. Enquête : utilisation de `liturgicalYear` (décembre)

### 4.1 Conclusion
**Aucune erreur de calcul en décembre**, ni dans le package ni dans l'app : tous les consommateurs reçoivent l'année
liturgique décalée à l'Avent. Il reste en revanche trois fragilités (4.3).

### 4.2 Ce qui a été vérifié

**Source unique : `_liturgicalYearOf(date)`** ([main_calendar_fill.dart](../lib/calendar_management/main_calendar_fill.dart)) :
civil, ou +1 à partir du 1er dimanche de l'Avent. Chaque `DayContent` reçoit ce `liturgicalYear` dans
`calendarFill`. Les fêtes fixes de décembre sont placées par `resolveFixedFeastDate` dans l'intervalle
[ADVENT, CHRIST_KING + 6] et non par `DateTime(year, 12, …)`. `_fillFixedSolemnities` n'utilise `DateTime(year, …)`
que pour février à novembre (avant l'Avent).

**Vérification sur un calendrier réel** (Lyon, construit depuis juin, novembre et décembre 2026) :

| Date | Code | liturgicalYear | A/B/C | Deux ans |
|---|---|---|---|---|
| 28/11/2026 | ot_34_6 | 2026 | A | Even |
| 29/11/2026 | advent_1_0 | 2027 | B | Odd |
| 08/12/2026 | advent_2_2 | 2027 | B | Odd |
| 17/12/2026 | advent-17_3_4 | 2027 | B | Odd |
| 25/12/2026 | roman/nativity | 2027 | B | Odd |
| 31/12/2026 | christmas_31 | 2027 | B | Odd |
| 01/01/2027 | roman/mary_mother_of_god | 2027 | B | Odd |

Les valeurs sont les mêmes quel que soit le mois de construction : 2025-2026 est l'année A, 2026-2027 l'année B,
année I en semaine (impaire) et `Odd` pour le cycle de deux ans, conformément à la décision du prompt (parité de
liturgie-plus).

**Contextes d'office :** `detectCelebrations` passe `dayContent.liturgicalYear`. Les I Vêpres font `copyWith` sur le
contexte du lendemain : le samedi 28/11/2026 au soir, les I Vêpres du 1er dimanche de l'Avent ont bien `ly=2027`.
L'app construit ses contextes par `definition.copyWith(...)` et conserve donc `liturgicalYear`.

**Consommateurs :**

| Endroit | Usage | Repli si null |
|---|---|---|
| `morning_export.dart:106` | antiennes évangéliques A/B/C | `date.year` ⚠ |
| `vespers_export.dart:93` | antiennes évangéliques A/B/C | `date.year` ⚠ |
| `ferial_readings_resolution.dart:142` | lectures patristiques A/B/C (Carême 4 et 5) | `date.year` (sans risque : jamais en décembre) |
| `readings_extract.dart:14` | cycle de deux ans | `date.year` ⚠ |
| `mass_export.dart:164` | filtres A/B/C et I/II de la messe | aucun filtrage |
| aelf-flutter `liturgyState.dart:517`, `liturgy_info_widget.dart:36`, `liturgy_part_info_widget.dart:31`, `office_common_widgets.dart:542` | affichage année / parité | lisent `DayContent.liturgicalYear` directement ✔ |

Aucun autre calcul de cycle à partir de `date.year` dans `lib/` (package et app).

### 4.3 Fragilités (pas de bug aujourd'hui) — ✅ toutes traitées
1. ✅ **Le repli `?? date.year` est faux dans trois endroits.** Pour morning, vespers et le cycle de deux ans, il donne
   la mauvaise année de l'Avent au 31 décembre. Il ne s'applique que si un `CelebrationContext` est construit hors de
   `detectCelebrations` : les contextes de Complies (`compline_detection.dart`) n'ont pas de `liturgicalYear`, sans
   conséquence aujourd'hui car les Complies ne l'utilisent pas. Un même helper public `liturgicalYearOf(date)`
   (aujourd'hui `_liturgicalYearOf`, privé) utilisé dans ces replis supprimerait le risque, de même qu'un
   `liturgicalYear` requis dans `CelebrationContext`.
   **Fait** : `liturgicalYearOf()` est public, à côté de `advent()` dans `common_calendar_definitions.dart`
   (`9c1bb06f`), et tous les replis passent par `CelebrationContext.effectiveLiturgicalYear` (`85d578bd`).
   `mass_export.dart` garde volontairement son comportement (pas de filtrage si l'année manque).
2. ✅ **Homonymie.** `liturgicalYear` désigne à la fois un `int` (champ de `DayContent` et `CelebrationContext`) et une
   fonction `liturgicalYear(int) → 'A'|'B'|'C'`. D'où des lignes comme `liturgicalYear(context.liturgicalYear)`.
   Renommer la fonction (`sundayCycle()`, `liturgicalYearLetter()`) clarifierait.
   **Fait** : renommée `sundayCycle()` (`b67a0711`), aelf-flutter suit (`62f0142`), l'alias déprécié est supprimé
   (`cf2b992a`) et l'app pointe sur cette version (`3eda94d`).
3. ✅ **Paramètre inutilisé.** Dans `resolveFixedFeastDate` (`location_class.dart:76`), le paramètre `liturgicalYear`
   n'est jamais utilisé : seuls `beginYear` et `endYear` comptent.
   **Fait** (`5c20f9bb`) : retiré, ainsi que sur toute la chaîne qui ne faisait que le transmettre
   (`applyCommonFeastsToCalendar`, `localCalendarFill`, `Location.applyToCalendar`).

Remarque annexe : un calendrier construit depuis une date de décembre ne contient pas les jours avant l'Avent
(28/11/2026 → null). C'est cohérent avec la construction de N et N+1 à partir de l'année liturgique, mais l'app doit
reconstruire le calendrier quand on navigue en arrière.

## 5. Divers
- Vérifier si `docs/PROMPT_two_year_readings.md` (un prompt de travail) doit vraiment être mergé dans le package.
  `docs/TWO_YEAR_READINGS_REPORT.md` a davantage sa place.

## 6. État au 15/10/2026
- Fait : 1.3, 2.A, 2.B, 2.C, 2.E, 2.F, 2.G, section 3, 4.3.
- Décidé de ne pas faire : 1.2, 2.D.
- En attente : 1.1 (au merge des branches `2-years`, après les tests à l'usage) et 5.
