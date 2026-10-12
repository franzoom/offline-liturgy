# Import des propres de Paris, Lille et Fréjus-Toulon depuis liturgie-plus

Rapport de l'import décrit dans [PROMPT_import_dioceses.md](PROMPT_import_dioceses.md) (octobre 2026).

## Résultat

- **Calendrier** : `assets/locations/{paris,lille,frejus}.yaml` sont alignés sur `Sanctoral_diocese()` de
  liturgie-plus (`www/include/lh-calendrier.js`). Correspondance des préséances : `4` → 4, `8` et `8.1` → 8,
  `9.99` et `11` → 10. Les mémoires facultatives (12) absentes de liturgie-plus sont conservées.
- **Textes** : les 27 jours propres de liturgie-plus ont été convertis (10 à Paris, 5 à Lille, 12 à Fréjus-Toulon).
  Sur les 208 fichiers HTML diocésains (`*_paris.html`, `*_lille.html`, `*_frejus-toulon.html`), 91 sont des
  scripts d'assemblage (`laudes`, `vepres`, `vepres0`, `lectures`, `milieu`). Tous les autres ont servi de source,
  ainsi que les fichiers non suffixés vers lesquels ces scripts pointent.
- **Fichiers créés** : 65 fichiers de fête et 3 hymnes. Toutes les clés des trois fichiers de lieu se résolvent
  vers un fichier, soit `sanctoral/<lieu>/<clé>.yaml`, soit un fichier `roman/` ou `france/` de même nom
  (surcharge de préséance seule).
- **Vérifications** :
  - `python3 scripts/validate_yaml.py` → 1957/1957 fichiers OK ;
  - `scripts/make_index.py` relancé : `index.json` et `pubspec.yaml` ont reçu `sanctoral/lille/` et `sanctoral/frejus/`.
    Python 3.9 ne connaît pas la syntaxe `dict | None` du script : il a été lancé avec
    `from __future__ import annotations` injecté, sans modifier le script ;
  - `dart run test/calendar_output.dart` s'exécute sans erreur. Un contrôle ponctuel des calendriers des trois
    diocèses en 2026 et 2027 donne les bonnes clés aux bonnes dates.

## Méthode

1. Les scripts JS de liturgie-plus sont interprétés pour obtenir, office par office, la liste
   bloc → fichier HTML (propre ou commun) et les numéros de psaumes.
2. Seuls les fichiers propres (`sanctoral/MM/…`) sont convertis. Les blocs pris dans un commun
   (`sanctoral/vierges/`, `martyr/`, `dedicace/`…) sont fournis par `celebration.commons`.
3. Numéros de psaumes : `62` → `PSALM_62`, `44-I` → `PSALM_44_1`. Cantique de laudes `41` → `OT_41`,
   cantique de vêpres `4` → `NT_4` : la numérotation est identique dans les deux projets.
4. Quand une fête existe déjà sous `roman/` ou `france/`, le fichier local part de ce fichier (messe comprise),
   et on y superpose le propre diocésain. Un champ diocésain quasi identique au texte de base
   (similarité ≥ 0,9) est ignoré, pour garder la version déjà relue. Si rien ne diffère, aucun fichier local
   n'est créé : la préséance seule est surchargée.
5. La typographie (espaces insécables, apostrophes) est normalisée avec `scripts/fix_nbsp.py`.

## Détail par diocèse

### Paris

| Date | Fête | Clé | Avant (date, préséance) | Préséance | Fichier |
|---|---|---|---|---|---|
| 03/01 | Sainte Geneviève, patronne du diocèse de Paris | `genevieve_of_paris_virgin` | — | 4 | complété |
| 16/01 | Notre-Dame du Refuge | `our_lady_of_refuge` | 16/01, 12 | 12 | minimal (à relire) |
| 07/02 | Bienheureuse Marie de la Providence | `mary_of_providence_virgin` | 07/02, 12 | 12 | minimal (à relire) |
| 09/02 | Bienheureuse Rosalie Rendu | `rosalie_rendu_virgin` | 09/02, 12 | 12 | minimal (à relire) |
| 24/02 | Bienheureuse Isabelle de France | `isabelle_de_france_virgin` | 24/02, 12 | 12 | minimal (à relire) |
| 28/02 | Bienheureux Daniel Brottier | `daniel_brottier_priest` | 28/02, 12 | 12 | minimal (à relire) |
| 10/03 | Sainte Marie-Eugénie de Jésus | `marie_eugenie_de_jesus_virgin` | 10/03, 12 | 12 | minimal (à relire) |
| 18/04 | Bienheureuse Marie de l’Incarnation (Barbe Acarie) | `marie_of_the_incarnation_acarie_religious` | 18/04, 12 | 12 | minimal (à relire) |
| 28/05 | Saint Germain | `germanus_of_paris_bishop` | 28/05, 10 | 10 | créé |
| 01/06 | Dédicace de la cathédrale Notre-Dame de Paris | `anniversary_of_the_dedication_of_the_cathedral` | 16/06, 8 | 8 | créé |
| 04/06 | Sainte Clotilde | `clotilde_of_burgundy` | — | 10 | surcharge de `france/clotilde_of_burgundy` |
| 10/06 | Saint Landry | `landry_of_paris_bishop` | 10/06, 12 | 12 | minimal (à relire) |
| 23/06 | Bienheureux Innocent V | `innocent_v_pope` | 23/06, 12 | 12 | copié de `lyon/innocent_v_pope` |
| 17/07 | Saintes carmélites de Compiègne | `carmelites_of_compiegne_virgins_and_martyrs` | 17/07, 12 | 12 | minimal (à relire) |
| 25/08 | Saint Louis, roi de France | `louis_ix_of_france` | — | 10 | surcharge de `roman/louis_ix_of_france` |
| 02/09 | Bienheureux martyrs de Paris | `martyrs_of_paris` | 02/09, 10 | 10 | créé |
| 09/09 | Bienheureux Frédéric Ozanam | `frederic_ozanam` | — | 12 | copié de `lyon/frederic_ozanam` |
| 26/09 | Saint Céraune | `ceraunus_of_paris_bishop` | 26/09, 12 | 12 | minimal (à relire) |
| 27/09 | Saint Vincent de Paul | `vincent_de_paul_priest` | — | 8 | aucun : préséance seule (`roman/`) |
| 09/10 | Saint Denis, évêque, et ses compagnons | `denis_of_paris_bishop_and_companions_martyrs` | — | 4 | surcharge de `roman/denis_of_paris_bishop_and_companions_martyrs` |
| 21/10 | Bienheureux Nicolas Barré | `nicolas_barre_priest` | 21/10, 12 | 12 | minimal (à relire) |
| 03/11 | Saint Marcel | `marcellus_of_paris_bishop` | 03/11, 10 | 10 | créé |
| 08/11 | Tous les saints du diocèse de Paris | `all_saints_of_the_diocese` | — | 10 | créé |
| 27/11 | Notre-Dame de la Médaille miraculeuse | `our_lady_of_the_miraculous_medal` | 27/11, 12 | 12 | minimal (à relire) |
| 28/11 | Sainte Catherine Labouré | `catherine_laboure_virgin` | 28/11, 12 | 12 | minimal (à relire) |
| 01/12 | Saint Charles de Foucauld | `charles_de_foucauld_priest` | 01/12, 12 | 12 | minimal (à relire) |
| 26/08 | Saint Joseph de Calasanz | `joseph_of_calasanz_priest` | 26/08, 12 | 12 | aucun : préséance seule (`roman/`), via `move:` |

Clés retirées ou renommées : `genevieve_virgin`, `coltilda`, `louis`, `frederick_ozanam`, `denis_of_paris_bishop_and_martyr`.

### Lille

| Date | Fête | Clé | Avant (date, préséance) | Préséance | Fichier |
|---|---|---|---|---|---|
| 04/01 | Saint Thomas Becket | `thomas_becket_bishop` | — | 10 | surcharge de `roman/thomas_becket_bishop` |
| 15/01 | Saint Rémi | `remigius_of_reims_bishop` | 15/01, 10 | 10 | surcharge de `france/remigius_of_reims_bishop` |
| 27/01 | Saint Jean de Warneton | `john_of_warneton_bishop` | 27/01, 12 | 12 | minimal (à relire) |
| 06/02 | Saint Vaast | `vaast_of_arras_bishop` | 06/02, 12 | 12 | minimal (à relire) |
| 06/02 | Saint Paul Miki et ses compagnons | `paul_miki_and_companions_martyrs` | 06/02, 12 | 12 | aucun : préséance seule (`roman/`) |
| 07/02 | Bienheureuse Marie de la Providence | `mary_of_providence_virgin` | 07/02, 12 | 12 | minimal (à relire) |
| 07/02 | Saint Amand | `amand_bishop` | — | 12 | copié de `belgium/amand_bishop` |
| 07/02 | Saint Chrysole | `chrysolius_the_armenian_bishop_and_martyr` | 07/02, 12 | 12 | minimal (à relire) |
| 20/02 | Saint Éleuthère | `eleutherius_of_tournai_bishop` | 20/02, 12 | 12 | minimal (à relire) |
| 05/05 | Saint Mauront | `mauront_of_marchiennes_abbot` | 05/05, 12 | 12 | minimal (à relire) |
| Pâques + 69 j | Notre-Dame de la Treille | `our_lady_of_the_trellis` | 13/06, 8 | 8 | créé |
| 20/07 | Saint Vulmar | `vulmar_hermit` | 20/07, 12 | 12 | minimal (à relire) |
| 20/07 | Saints Paul Denn et Rémi Isoré | `paul_denn_and_saint_remi_isore_priests_and_martyrs` | 20/07, 12 | 12 | minimal (à relire) |
| 05/08 | Bienheureux Frédéric Janssoone | `frederic_janssoone_priest` | 05/08, 12 | 12 | minimal (à relire) |
| 12/08 | Saint Géry | `gaugericus_of_cambrai_bishop` | 12/08, 12 | 12 | minimal (à relire) |
| 02/09 | Bienheureux martyrs de septembre 1792 | `martyrs_of_september` | 02/09, 12 | 12 | minimal (à relire) |
| 09/09 | Saint Omer | `audomar_of_terouenne_bishop` | 09/09, 12 | 12 | minimal (à relire) |
| 03/10 | Saint Piat | `piatus_of_tournai_priest_and_martyr` | 03/10, 10 | 10 | créé |
| 16/10 | Saint Mommolin | `mommolin_of_noyon_bishop` | 16/10, 12 | 12 | minimal (à relire) |
| 06/11 | Saint Winoc | `winnoc_of_bergues_abbot` | 06/11, 12 | 12 | minimal (à relire) |
| 08/11 | Tous les saints du diocèse de Lille | `all_saints_of_the_diocese` | — | 10 | créé |
| 01/12 | Saint Éloi | `eligius_of_noyon_bishop` | 01/12, 12 | 12 | minimal (à relire) |
| 15/12 | Saint Folquin | `folcwin_of_therouanne_bishop` | 15/12, 12 | 12 | minimal (à relire) |
| 16/12 | Bienheureux Évrard de Frioul | `everard_of_frioul` | 16/12, 12 | 12 | minimal (à relire) |

Clés retirées ou renommées : `amandus_of_maastricht_bishop`.

### Fréjus-Toulon

| Date | Fête | Clé | Avant (date, préséance) | Préséance | Fichier |
|---|---|---|---|---|---|
| 16/01 | Saint Honorat | `honoratus_bishop` | 16/01, 10 | 10 | créé |
| 17/01 | Sainte Roseline | `roseline_de_villeneuve_virgin` | 17/01, 10 | 10 | créé |
| 27/04 | Dédicace de la cathédrale de Toulon | `anniversary_of_the_dedication_of_the_cathedral` | 27/04, 8 | 8 | créé |
| 15/05 | Bienheureux André Abellon | `andre_abellon_priest` | 15/05, 12 | 12 | minimal (à relire) |
| 21/05 | Saint Eugène de Mazenod | `eugene_de_mazenod_bishop` | 21/05, 12 | 12 | minimal (à relire) |
| 24/05 | Saint Vincent de Lérins | `vincent_of_lerins_priest` | 24/05, 12 | 12 | minimal (à relire) |
| 27/05 | Saint Lambert | `lambert_of_vence_bishop` | 27/05, 12 | 12 | minimal (à relire) |
| 02/06 | Saint Caprais et les saints moines de Lérins | `caprasius_and_the_holy_monks_of_lerins` | 02/06, 12 | 12 | minimal (à relire) |
| 25/06 | Bienheureux Jean d’Espagne | `jean_d_espagne_priest` | 25/06, 12 | 12 | minimal (à relire) |
| 22/07 | Sainte Marie Madeleine | `mary_magdalene` | 22/07, 4 | 4 | surcharge de `roman/mary_magdalene` |
| 19/08 | Saint Louis de Brignoles | `louis_of_toulouse_bishop` | 19/08, 10 | 10 | créé |
| 26/08 | Saint Césaire d’Arles | `cesaire_of_arles_bishop` | — | 10 | surcharge de `france/cesaire_of_arles_bishop` |
| 02/09 | Bienheureux Jules Pazery de Thorame et François-Joseph Pey | `jules_pazery_de_thorame_and_blessed_francois_joseph_pey_priests_and_martyrs` | 02/09, 10 | 10 | créé |
| 22/09 | Dédicace de la co-cathédrale de Fréjus | `anniversary_of_the_dedication_of_the_co_cathedral` | 22/09, 10 | 10 | créé |
| 03/10 | Saint Cyprien | `cyprian_of_toulon_bishop` | 03/10, 10 | 10 | créé |
| 08/11 | Tous les saints du diocèse de Fréjus-Toulon | `all_saints_of_the_diocese` | 08/11, 10 | 10 | créé |
| 01/12 | Saint Léonce | `leontius_of_frejus_bishop` | 01/12, 10 | 10 | créé |
| 18/01 | Saint Antoine | `anthony_of_egypt_abbot` | — | 10 | aucun : préséance seule (`roman/`), via `move:` |

Clés retirées ou renommées : `anthony_abbot`, `caesarius_of_arles_bishop`.

## Surcharges et textes identiques à la base

Ces champs de liturgie-plus reprenaient le texte romain ou national ; la version déjà présente a été gardée :

| Fichier | Champs gardés de la base |
|---|---|
| `paris/clotilde_of_burgundy` | oraison (la lecture patristique, différente, vient de liturgie-plus) |
| `paris/louis_ix_of_france` | oraison |
| `lille/thomas_becket_bishop` | lecture patristique, oraison. Fichier gardé malgré tout, parce que la fête est au 4/1 à Lille et reste au 29/12 dans le calendrier romain |
| `lille/remigius_of_reims_bishop` | lecture patristique (l'oraison lilloise est propre) |
| `frejus/mary_magdalene` | hymnes des lectures et des laudes, psalmodie, répons, lecture brève et antienne des vêpres, oraison |
| `frejus/cesaire_of_arles_bishop` | oraison |

Aucun fichier local n'a été créé dans deux cas, car tous les textes de liturgie-plus sont identiques au romain :
- **saint Vincent de Paul** à Paris : surcharge de préséance (8) ;
- **saint Antoine** à Fréjus-Toulon : `move:` du 17/1 au 18/1, préséance 10.

## Hymnes

- Créées : `roi-des-rois-jesus-seigneur` et `tu-es-le-seul-saint-seigneur-dieu` (saint Louis, Paris),
  `madeleine-ou-vas-tu` (Marie-Madeleine, Fréjus-Toulon). Leur auteur n'est pas indiqué dans liturgie-plus.
- Réutilisées : `quand-le-jour-est-obscur`, `genevieve-attentive-a-la-voix`, `puissance-et-gloire-de-l-esprit`,
  `mes-larmes-nuit-et-jour`, `pleine-de-grace-rejouis-toi`, `comment-es-tu-foyer-de-feu`, `un-nouveau-matin-se-leve`.
  liturgie-plus ne donne que certaines strophes selon l'office ; les fichiers existants contiennent l'hymne complète.

## Fichiers minimaux à relire

Les fêtes marquées « minimal (à relire) » ci-dessus n'ont aucun texte dans liturgie-plus. Leur fichier ne contient
que le bloc `celebration` : titre, qualité, communs, couleur. Ces éléments ont été déduits de la clé et du saint ;
la notice (`description`) est à compléter. Points à vérifier en priorité :
- `paris/carmelites_of_compiegne_virgins_and_martyrs` : canonisées en 2024, d'où le titre « Saintes » ; commun `martyrs_female_virgin` ;
- `paris/our_lady_of_refuge` : intitulé exact de la fête ;
- `lille/vulmar_hermit` : « ermite » d'après la clé (saint Vulmar fut aussi abbé de Samer) ;
- `lille/everard_of_frioul` : commun `saints-male`.

Trois fichiers ont été copiés d'un autre lieu plutôt que créés vides : `paris/innocent_v_pope` et
`paris/frederic_ozanam` (depuis `lyon/`), `lille/amand_bishop` (depuis `belgium/`).

## Corrections apportées aux sources

- Coquilles de liturgie-plus : « J’ai maché » → « J’ai marché » et « 2M I5,14 » → « 2M 15,14 » (Geneviève) ;
  « Ile-de-France » → « Île-de-France », comme dans le fichier existant.
- `sanctoral/06/01-milieu_paris.html` pointe vers `06/06-titre_paris.html` et `06/06-oraison_paris.html`, qui
  n'existent pas. Ce sont les fichiers du 1/6 qui ont été utilisés.
- `sanctoral/05/NDT-milieu_lille.html` pointe vers `marie/m_capitule*_lille.html` et `m_repons*_lille.html`, qui
  n'existent pas. Le milieu du jour de ND de la Treille vient donc du commun marial (`virgin-mary`).
- `09/02-l_patristique_frejus-toulon.html` : la même lecture figure deux fois (la première sans répons) ; une seule
  a été gardée. Son sous-titre « Le séjour de saint Césaire à Lérins », copié par erreur, a été supprimé.
- Le marqueur « Stance » des répons en forme de stance (Lille 8/11, Fréjus 18/1) a été retiré du texte.

## Changements par rapport au fichier existant `paris/genevieve_of_paris_virgin.yaml`

Le bloc `celebration` existant (titre, notice) est conservé. Ont été ajoutés depuis liturgie-plus :
- l'invitatoire ;
- la psalmodie des laudes, des vêpres et des premières vêpres ;
- l'hymne et les intercessions des premières vêpres ;
- la lecture patristique ;
- les psaumes et l'antienne du milieu du jour.

Le répons de la lecture biblique, tronqué, a été complété. Divergences relevées :
- l'hymne `genevieve-attentive-a-la-voix` est inchangée ;
- la référence de None devient « cf. 2M 15,14 » (au lieu de « 2M 15,14 »).

## Cas particuliers et points ouverts

- **ND de la Treille** (Pâques + 69 jours) tombe toujours le samedi après le Sacré-Cœur, donc le même jour que la
  mémoire du Cœur immaculé de Marie (préséance 10), qui passe au second plan.
- **Antienne évangélique `*_antienne_ev2`** (Marie-Madeleine) : dans liturgie-plus elle s'affiche avant le cantique,
  comme seconde antienne. Elle est enregistrée comme deuxième élément de la liste `common`, c'est-à-dire au choix.
- **Lectures patristiques au choix** (Marie-Madeleine) : les trois lectures séparées par « ou bien » sont devenues
  trois entrées de `patristicReading`.
- **Références de source des lectures patristiques** : liturgie-plus les affiche en italique sous le titre. Elles sont
  placées en tête du contenu, sous la forme `%(...)%`.
- **Abréviations bibliques** reprises telles quelles (`1 Esd`, `Prov`). Elles pourront être harmonisées avec le
  reste des données.
