# Comparaison des antiennes avec AELF — état des lieux

`dart test test/aelf_antiphons_reference_test.dart -r expanded`

Compare, pour chaque dimanche/solennité/fête de l'année 2026 (calendrier France), les antiennes de psaumes, du Benedictus, du Magnificat et des Petites Heures (Tierce/Sexte/None) calculées par le package contre les textes publiés par AELF (zone `france`). La fixture (`test/fixtures/aelf_antiphons_reference_2026_france.json`) est pré-téléchargée par `test/tools/fetch_aelf_antiphons_reference.dart` — le test lui-même ne fait aucun appel réseau. Le texte est normalisé (HTML retiré, guillemets/espaces uniformisés) avant comparaison, pour ignorer les différences purement cosmétiques.

Mis à jour le 2026-09-10 : 1292 antiennes comparées sur 79 dates, 137 divergences, regroupées en 2 causes distinctes encore ouvertes (4 déjà corrigées, 2 étaient des faux positifs du test).

## Non-problèmes identifiés — le test comparait mal, pas le package

- **Un psaume avec deux antiennes n'est pas un bug : c'est le site AELF qui a la limite de n'en montrer qu'une, alors que le bréviaire papier en propose parfois deux.** Ce qui semblait être une « 2ème ligne parasite » sur quasiment tout le Temps Ordinaire (Laudes/Vêpres) était en réalité notre projet plus complet que le site AELF, pas plus fautif. Exemple (`ot_2_0.yaml`, PSALM_117) : nous avons *« Rendez grâce au Seigneur : éternel est son amour ! »* + *« Approchons-nous de Jésus Christ, pierre vivante, choisie par Dieu. »* — AELF n'affiche que la première. Le test a été corrigé (`_isLegitimateSecondAntiphon`) : quand notre antienne commence par le texte d'AELF et continue au-delà, ce n'est plus compté comme une divergence. Ça a fait passer le total de 333 à 176.
- **Les deux « antiennes fixes erronées » récurrentes aux Petites Heures étaient un repli de test trop simpliste, pas une erreur dans les données.** `ot_2_0.yaml` et `ot_4_0.yaml` ont chacun un psaume coupé en deux (`PSALM_75_1`/`PSALM_75_2`) qui partage légitimement son antienne — ce n'est pas une troisième antienne distincte. Côté AELF, `antienne_3` est simplement absente pour cette même raison, mais mon test repliait toujours vers `antienne_1` au lieu de la dernière antienne non vide qui précède (ici `antienne_2`, pas `antienne_1`). Corrigé (repli en cascade). Ça a fait passer le total de 174 à 137.

## Corrigé depuis le dernier bilan

- **Une Fête (précédence 5) prenait le pas sur les 2èmes Vêpres d'un dimanche.** La Présentation du Seigneur (2 février, un lundi en 2026), précédence 5, gagnait à tort les 1ères Vêpres du dimanche précédent. `vespersDetection` accordait les 1ères Vêpres à toute célébration non-férial de précédence ≤5 sans vérifier si le jour précédent était déjà un dimanche. Corrigé : cette clause est maintenant restreinte aux jours non-dimanche ; seules les vraies solennités (précédence ≤3) peuvent encore l'emporter sur un dimanche.
- **Antienne de saison collée sur une antienne déjà propre (Tierce/Sexte/None).** `middle_of_day_export.dart`, étape « APPEND SEASON ANTIPHON » : le garde-fou qui protégeait les solennités/fêtes n'existait que pour Carême/Semaine Sainte, pas pour l'Avent/Noël/Temps pascal — le texte générique de saison se retrouvait collé à la suite de l'antienne propre du jour (Sainte Marie Mère de Dieu, Épiphanie, Baptême, les 4 dimanches de l'Avent, Immaculée Conception). Corrigé en changeant la règle elle-même : l'antienne de saison ne sert plus qu'en repli, quand le psaume n'en a encore aucune — plus besoin d'énumérer les saisons protégées.
- **Dédicace des Églises consacrées (25 octobre) à précédence trop basse.** `france.yaml` la déclarait à précédence 12 (mémoire facultatif), ce qui l'empêchait de jamais l'emporter sur un dimanche ordinaire (précédence 6) — alors qu'AELF la célèbre entièrement le 25 octobre 2026 (30e dimanche). Remontée à précédence 8 par l'utilisateur.
- **Saints Pierre et Paul (28 juin) — antiennes 2 et 3 des Vêpres interverties.** Corrigé par l'utilisateur dans la source (`saint_pieter_and_saint_paul.yaml`).

## Non-bug confirmé

**Une solennité du samedi qui garde ses propres 2èmes Vêpres célébrables à côté des 1ères Vêpres du dimanche suivant est le comportement voulu**, pas un bug : le 15 août 2026 (Assomption, un samedi), les 2èmes Vêpres de l'Assomption et les 1ères Vêpres du 20e dimanche sont toutes les deux marquées célébrables — la priorité d'affichage va au dimanche, mais l'Assomption doit rester disponible. Rien à changer ici.

## Encore ouvert

### 1. Coquilles isolées (échantillon — famille de ~68 occurrences, majoritairement de la ponctuation)

| Date | Office/Célébration | Nous | AELF |
|---|---|---|---|
| 2026-02-08 | Laudes, 5e dim. TO (Benedictus) | alléluia | allléluia (AELF, coquille côté AELF) |
| 2026-02-08 | Tierce, 5e dim. TO | Alléluia. | Allélluia ! (idem) |
| 2026-01-01 | Vêpres, Ste Marie Mère de Dieu | en prennant | en prenant |
| 2026-02-01 | Vêpres, Présentation | ccœur | cœur |
| 2026-03-01 | Laudes, 2e dim. Carême (Benedictus) | Christ a détruit | Le Christ a détruit |
| 2026-03-29 | Laudes, Rameaux | au plus des cieux | au plus haut des cieux |
| 2026-11-02 | Laudes, Commémoraison des défunts | je vie | je vis |
| 2026-12-25 | Laudes, Nativité (Benedictus) | nous recevons | nous recevrons |
| 2026-02-18 | Laudes, Mercredi des Cendres (Benedictus) | parfumez | parfu­mez (espace insécable AELF, probable artefact) |

### 2. Bénin, à part — Annonciation (25 mars)

AELF ajoute « (alléluia) » à toutes les antiennes de l'Annonciation, nous non. Probablement une mention conditionnelle stockée telle quelle côté AELF plutôt qu'un vrai trou chez nous — priorité basse.

## Méthodologie

- Fixture générée par `test/tools/fetch_aelf_antiphons_reference.dart` (79 dates : tout dimanche/solennité/fête de 2026, France — inclusion : `isSunday || précédence ≤ 5`).
- Comparaison : `test/aelf_antiphons_reference_test.dart`, texte normalisé (HTML retiré, apostrophes/espaces uniformisés).
- Pour Tierce/Sexte/None, une `antienne_2`/`antienne_3` vide côté AELF est traitée comme « identique à la dernière antienne non vide qui précède » (repli en cascade, pas systématiquement `antienne_1` — un psaume coupé en deux partage son antienne avec l'entrée juste avant lui, pas forcément la première).
- Pour Laudes/Vêpres, les psaumes/cantiques connus pour n'avoir légitimement aucune antienne (`OT_40`, `OT_41`, `NT_x`, `PSALM_135_*`, `PSALM_45`, `PSALM_8` — même liste que `office_content_coverage_test.dart`) sont exclus de la comparaison sur ce point précis.
- Quand notre antienne commence par le texte d'AELF puis continue au-delà, ce n'est pas compté comme une divergence (`_isLegitimateSecondAntiphon`) : le site AELF n'affiche jamais qu'une seule antienne par psaume, même quand le bréviaire papier en propose deux.
