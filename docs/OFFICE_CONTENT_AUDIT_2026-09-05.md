# Office content audit — état des lieux

`dart test test/office_content_coverage_test.dart -r expanded`

Mis à jour le 2026-09-07. Parti de 814 anomalies (premier passage, Lyon 2026) ; l'historique des correctifs réels est dans `git log` (chacun est son propre commit avec une explication). Ce fichier est refait à neuf à chaque bilan plutôt que complété au fil de l'eau.

## 1. Référence officielle (Lyon, 2026) : 24 anomalies signalées, 0 trou de contenu réel

C'est la config par défaut du fichier de test (3295 offices vérifiés). L'audit ne connaît ni les `note` du Missel, ni la distinction Mass/rite-sans-consécration, ni les coïncidences calendaires fixes — il vérifie juste « le champ est-il rempli ? ». Les 24 lignes qu'il signale relèvent toutes d'un des 7 cas ci-dessous, vérifiés un par un contre le contenu source. Si un futur passage de l'audit signale autre chose que ces 7 cas sur Lyon 2026, c'est probablement un vrai trou.

| Cas | Occurrences | Pourquoi c'est normal |
|---|---|---|
| `PROCESSION_WITH_PALMS` (Rameaux) | 3 | Rite d'ouverture, pas une messe — `offeringPrayer`/`communionAntiphon`/`prayerAfterCommunion` sont `null` dans la source. La vraie messe du jour (`MASS_OF_THE_PASSION`) a bien tous ces champs. |
| `CELEBRATION_OF_THE_PASSION` (Vendredi Saint) | 4 | Pas une messe non plus (pas de consécration) — mêmes champs `null` par construction dans `lent_6_5.yaml`. |
| `EASTER_VIGIL` (Vigile pascale) | 2 | Commence par le Lucernaire, pas une ouverture de messe classique — `entranceAntiphon`/`collect` sont `null` dans `easter_1_0.yaml`. |
| Lectures, Dimanche de Pâques | 3 | `readings.note` dans `easter_1_0.yaml` : « La Vigile Pascale tient lieu d'office des lectures… » — la note *est* le contenu, il n'y a rien d'autre à afficher. |
| Messes de la Commémoraison des défunts (2 nov., ×3) | 6 | `mass.note` dans `commemoration_of_all_the_faithful_departed.yaml` : « On choisira les lectures parmi celles proposées pour les funérailles… aucune péricope fixe n'est imprimée dans le Missel ». Même principe que la Vigile pascale. |
| Vêpres II, Mercredi de la 6^e semaine du Temps pascal `[non célébrable]` | 2 | Toujours la veille de l'Ascension (Pâques + 39 jours tombe toujours un jeudi) — cette Vêpres II ferial n'est jamais utilisée, aucune année. |
| Vêpres II, 24 décembre `[non célébrable]` | 4 | Toujours la veille de Noël (date fixe) — même raison. |

**Remarque sur les deux cas « note »** : `mass.note` et `readings.note` sont déjà parsées par le package mais jamais affichées côté app — indépendamment de cet audit, ça reste une amélioration UI possible si on veut un jour montrer ces instructions au lecteur plutôt que de les laisser implicites.

## 2. Balayage 2010-2030 (France) : 66 934 offices vérifiés

Une seule année ne suffit pas : plusieurs bugs ne se déclenchent que certaines années selon le jour de semaine de Noël, de l'Épiphanie ou d'autres coïncidences calendaires. Ce passage couvre 21 années consécutives pour rattraper les cas rares (jusqu'à une occurrence tous les 6-11 ans). Méthode : script temporaire réutilisant les mêmes fonctions de vérification que `office_content_coverage_test.dart`, en bouclant les années sans recharger les données à chaque fois ; supprimé après usage, comme d'habitude pour ce type de vérification jetable.

Sur les 21 années : 15 années n'ont que les 24 anomalies de référence (§1) ; les 6 autres cumulent en plus une ou plusieurs des situations ci-dessous, selon la coïncidence calendaire de l'année.

### Corrigé depuis le dernier bilan

- **Numérotation du temps ordinaire décalée d'une semaine quand le Baptême du Seigneur tombe un lundi** (`main_calendar_fill.dart`, `_fillOrdinaryTimeBeforeLent`). Le compteur de jours partait toujours de 1, en supposant implicitement 6 jours fériaux avant le dimanche suivant — vrai seulement quand le Baptême est un dimanche. Quand l'Épiphanie tombe le 7 ou le 8 janvier, le Baptême est reporté au lundi et il n'y a que 5 jours fériaux avant le dimanche suivant, qui héritait alors à tort de l'étiquette `ot_1_0` (donc du contenu de `ot_1_0.yaml`, centré sur le Baptême) au lieu de `ot_2_0` — et toutes les semaines suivantes jusqu'au Carême étaient décalées d'une unité. Confirmé résolu sur ce balayage : la « Baptême du Seigneur — lecture biblique et patristique absente » précédemment observée en 2029/2030 a disparu, sans qu'aucune nouvelle anomalie n'apparaisse sur les 21 années.
- **`sundayOnlyFirstVespersCodes` cassé depuis toujours pour ses entrées** (`vespers_detection.dart`) : la liste comparait des codes sans le préfixe `roman/`, alors que `celebrationCode` l'a toujours à l'exécution — la Transfiguration et l'Exaltation de la Sainte Croix proposaient donc à tort des Vêpres I chaque année. Corrigé, et la Sainte Famille ajoutée à la liste (elle n'a de Vêpres I que si elle tombe un dimanche).
- **Sainte Famille sur le 29/30/31 décembre → messe entièrement vide.** Résolu en passant sa précédence de 6 à 5 (elle est une Fête, pas un simple jour d'octave), ce qui lui fait emprunter la branche générique `precedence <= 5` de `massExport`.

### Encore ouvert — même famille de bug (mémoire sans base férial à enrichir)

Un saint à précédence > 5 dont le jour est entièrement supplanté par une fête plus prioritaire (Sainte Famille, ou simplement la fin de l'octave de Noël) n'a aucun jour férial de base sur lequel `overlayPrayerFields` puisse s'appuyer — il ressort entièrement vide (Laudes, Vêpres, Lectures, Messe) plutôt que de replier sur un commun. Déjà repéré avec Isidore/Matthias/Cécile ; ce balayage en trouve deux autres occurrences dans la même zone du calendrier :

| Saint | Jour | Années touchées (2010-2030) |
|---|---|---|
| Saint Thomas Becket | 29 décembre | 2013, 2019, 2024, 2030 |
| Saint Sylvestre I^er, pape | 31 décembre | 2017, 2023, 2028 |
| Saint Raymond de Penyafort | 7 janvier | 2013, 2019, 2030 |

*(Correction par rapport au bilan précédent : Saint Hilaire de Poitiers, 13 janvier, avait été cité comme possiblement affecté en 2030 — vérifié sur les 21 années, il n'apparaît dans aucune anomalie, donc pas concerné par ce bug.)*

### Encore ouvert — trous de contenu statiques (pas un bug de code)

| Cas | Occurrences (2010-2030) | Constat |
|---|---|---|
| Saint Étienne (26 déc.), Vêpres II — antienne de psalmodie absente | 15/21 années (masqué les années où la Sainte Famille tombe ce jour-là) | `christmas_26.yaml` : `PSALM_109` et `PSALM_129` sans antienne. |
| « Deuxième dimanche après la Nativité » (6 janvier) — Laudes, Vêpres II, Lectures, Sexte/Tierce/None entièrement vides | 2012, 2017, 2023 | Jour rare (seulement quand il y a deux dimanches pleins entre le 1^er janvier et l'Épiphanie) : `christmas_2_0.yaml` ne contient qu'une section `mass`, aucune section Heures. Probablement jamais rempli parce que rarement exercé lors des relectures précédentes. |
| 1^ères Vêpres du 4^e dimanche de l'Avent quand il tombe le 24 décembre — antienne du Magnificat absente | 2017, 2023, 2028 (célébrées la veille, le 23) | `advent_4_0.yaml` n'a pas de section `evangelicAntiphon` du tout, et aucun fichier `advent-24_4_0.yaml` ne vient la fournir. Uniquement la 1^ère Vêpres proprement dite est touchée — la 2^e Vêpres (non célébrable ce jour-là, supplantée par Noël) n'a pas besoin d'être complète. |

Prochaine étape suggérée : remplir les sections Heures manquantes de `christmas_2_0.yaml` et l'antienne du Magnificat de `advent_4_0.yaml`, puis regarder si la même logique « overlay sans base férial » qui touche Thomas Becket/Sylvestre/Raymond de Penyafort peut être corrigée à la racine plutôt qu'au cas par cas.
