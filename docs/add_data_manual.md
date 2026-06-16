# Manuel d'ajout de données liturgiques

Ce document explique comment ajouter des données liturgiques au package `offline_liturgy` : déclarer un diocèse (ou tout autre lieu) et son calendrier propre, créer les fichiers de fêtes correspondants, et y rattacher d'éventuelles hymnes. Il remplace `data_user_manual.pdf`, qui n'est plus à jour.

Merci de votre participation à ce projet !

---

## Prérequis

- Un éditeur de texte **sans formatage** (pas Word) :
  - Windows : Notepad++
  - Mac : Visual Studio Code (le plus simple d'utilisation), ou en plus minimaliste Sublime Text ou Zed.
- De la rigueur dans la gestion des indentations : les fichiers sont au format **YAML**, qui utilise l'indentation (espaces à gauche) pour représenter la hiérarchie des données. Utilisez systématiquement **2 espaces par niveau**, jamais de tabulation.

---

## Vue d'ensemble : les trois étages de données

1. **Le lieu et son calendrier** : un fichier par diocèse, pays, continent..., qui déclare la liste des fêtes qui s'ajoutent au calendrier romain général, avec leur date et leur préséance.
2. **Les fêtes** : un fichier par fête, contenant le titre, la description, et le texte de chaque office (vêpres, laudes, lectures...).
3. **Les hymnes** : un fichier par hymne, référencé depuis les fichiers de fête par son code.

L'application lit ces données dans cet ordre : calendrier romain général → calendrier du continent → calendrier du pays → calendrier du diocèse → (éventuellement calendrier d'un lieu plus précis, ville ou église). Chaque étage peut ajouter une fête, ou déplacer une fête héritée de l'étage précédent.

Vous n'avez pas à vous soucier de l'endroit où ranger vos fichiers : envoyez-les simplement nommés correctement (voir ci-dessous), ils seront classés au bon endroit à la réception.

---

## 1. Le fichier de lieu (diocèse, pays, continent...)

### Nom de fichier

Chaque lieu est un fichier nommé d'après son identifiant, en anglais, minuscules, mots séparés par `_`, suivi de l'extension `.yaml` :

```
lyon.yaml
france.yaml
canada.yaml
```

Cet identifiant (`lyon`, `france`...) sert aussi de préfixe aux codes des fêtes de ce lieu (`lyon/pauline_marie_jaricot`).

### Le préambule

```yaml
language: french
geography: diocese       # continent | country | diocese | city | church | community
parent: france            # identifiant du fichier de lieu parent
frenchName: diocèse de Lyon
frenchLocative: dans le diocèse de Lyon

epiphanyDate: sunday       # optionnel : sunday | day
ascensionDate: thursday    # optionnel : sunday | thursday
corpusDominiDate: sunday   # optionnel : sunday | thursday
```

| Clef | Description |
|---|---|
| `language` | toujours `french` actuellement |
| `geography` | niveau géographique : `continent`, `country`, `diocese`, `city`, `church` ou `community` |
| `parent` | identifiant du lieu parent dans la hiérarchie. Absent uniquement pour un lieu racine (ex. `europe.yaml`) |
| `frenchName` | nom à afficher. Pour un pays, le nom seul suffit (`France`). Pour un diocèse, une ville ou une église, précisez le type pour éviter toute ambiguïté (`diocèse de Lyon`, et non juste `Lyon`) |
| `frenchLocative` | tournure « dans/à... » utilisée dans les textes (`dans le diocèse de Lyon`, `en France`) |

`epiphanyDate`, `ascensionDate` et `corpusDominiDate` sont optionnels et s'appliquent à tout le lieu et ses descendants. Ils sont résolus en remontant la chaîne du lieu le plus précis vers la racine, en prenant la première valeur trouvée (donc un diocèse peut les omettre pour hériter de la valeur du pays).

| Clef | Valeurs | Sens |
|---|---|---|
| `epiphanyDate` | `day` | fixée au 6 janvier |
| | `sunday` | reportée au dimanche qui suit le 1ᵉʳ janvier |
| `ascensionDate` | `thursday` (défaut) | jeudi, 39 jours après Pâques |
| | `sunday` | reportée au dimanche suivant |
| `corpusDominiDate` | `sunday` (défaut) | dimanche, 63 jours après Pâques |
| | `thursday` | jeudi |

### La section `feasts:`

Liste toutes les fêtes ajoutées au calendrier pour ce lieu et ses descendants. Chaque fête utilise une **clef courte**, sans préfixe de lieu :

```yaml
feasts:
  pauline_marie_jaricot:
    month: 1
    day: 9
    precedence: 12
  francis_of_sales_bishop:
    month: 1
    day: 24
    precedence: 11
```

`month` et `day` sont obligatoires pour une fête à date fixe. `precedence` suit l'échelle standard 1 à 13 (voir plus bas).

Internement, l'application préfixe la clef avec l'identifiant du lieu avant de l'enregistrer dans le calendrier : `pauline_marie_jaricot` devient `lyon/pauline_marie_jaricot`. C'est ce nom court, `pauline_marie_jaricot`, qui doit aussi être le nom du fichier de fête correspondant (voir partie 2).

#### Fête à date mobile (relative à une autre fête)

Certaines fêtes locales sont calées sur une date mobile (Pâques, l'Avent...) plutôt que sur une date fixe. On utilise alors `relativeTo` et `shift` (nombre de jours après l'ancre) à la place de `month`/`day` :

```yaml
feasts:
  our_lady_of_fourviere:
    relativeTo: EASTER
    shift: 13
    precedence: 7
```

Ici, Notre-Dame de Fourvière (Lyon) est calée 13 jours après Pâques, c'est-à-dire le samedi après le 2ᵉ dimanche de Pâques.

Liste des codes `relativeTo` disponibles :

| Code | Fête de référence |
|---|---|
| `ADVENT` | 1er dimanche de l'Avent |
| `NATIVITY` | Noël |
| `IMMACULATE_CONCEPTION` | Immaculée Conception |
| `HOLY_FAMILY` | Sainte Famille |
| `EPIPHANY` | Épiphanie |
| `BAPTISM` | Baptême du Seigneur |
| `SECOND_SUNDAY_OT` | 2ᵉ dimanche du Temps Ordinaire |
| `ASHES` | Mercredi des Cendres |
| `PALMS` | Dimanche des Rameaux |
| `HOLY_THURSDAY` | Jeudi saint |
| `HOLY_FRIDAY` | Vendredi saint |
| `HOLY_SATURDAY` | Samedi saint |
| `EASTER` | Pâques |
| `ASCENSION` | Ascension |
| `PENTECOST` | Pentecôte |
| `HOLY_TRINITY` | Sainte Trinité |
| `CORPUS_DOMINI` | Saint Sacrement (Fête-Dieu) |
| `SACRED_HEART` | Sacré-Cœur |
| `CHRIST_KING` | Christ Roi |

### La section `move:`

Déplace une fête qui existe déjà dans le calendrier (typiquement une fête du calendrier romain général) à une autre date, pour laisser la place à une fête locale au même endroit. La recherche se fait par le nom court de la fête, quel que soit le préfixe sous lequel elle a été enregistrée (`roman/...`, ou celui d'un lieu parent) :

```yaml
move:
  #déplacé du 7 au 8 janvier pour laisser la place à André Bessette
  raymond_of_penyafort_priest:
    month: 1
    day: 8
    precedence: 10
```

Exemple complet (ébauche du Canada, sans diocèse créé) :

```yaml
language: french
geography: country
parent: north_america
frenchName: Canada
frenchLocative: au Canada
epiphanyDate: sunday
ascensionDate: sunday

feasts:
  canada_andre_bessette_religious:
    month: 1
    day: 7
    precedence: 10
  canada_marguerite_bourgeoys:
    month: 1
    day: 12
    precedence: 10

move:
  raymond_of_penyafort_priest:
    month: 1
    day: 8
    precedence: 10
```

### Remplacement automatique par nom de base

Quand un lieu ajoute une fête qui porte le même nom court qu'une fête déjà présente ce jour-là (ajoutée par un lieu parent ou par le calendrier romain), la nouvelle entrée **remplace automatiquement** l'ancienne — y compris sa préséance — sans avoir besoin d'un `move` explicite. C'est ce mécanisme qui permet à un diocèse de surclasser une fête nationale ou romaine simplement en la redéclarant avec une préséance différente.

### Préséances (1 à 13)

La numérotation suit la *Présentation Générale de la Liturgie des Heures* (PGLH) :

| Niveau | Type |
|---|---|
| 1–3 | Solennités |
| 4–5 | Fêtes |
| 6–9 | Mémoires obligatoires |
| 10–11 | Mémoires facultatives |
| 12 | Commémoraisons |
| 13 | Féries |

Le détail complet des règles de préséance (table de la Conférence des évêques de France) est reproduit en annexe à la fin de ce document. Pendant l'Avent, le Carême et les octaves, les mémoires obligatoires (6–9) sont automatiquement rétrogradées en facultatives.

---

## 2. Les fichiers de fête

### Nom de fichier

Le fichier de contenu d'une fête porte le **même nom court** que la clef déclarée sous `feasts:` dans le fichier de lieu — sans préfixe de lieu, et sans le répéter dans le nom (`lyon_pauline_marie_jaricot.yaml` est incorrect, c'est simplement `pauline_marie_jaricot.yaml`) — en anglais, pour la cohérence du projet et une éventuelle utilisation internationale future. Les mots sont séparés par `_` :

```
pauline_marie_jaricot.yaml
```

### Attentions de saisie YAML

Les fichiers YAML utilisent le caractère deux-points (`:`) pour signaler une clef. Sa présence dans un texte peut donc créer une ambiguïté. Pour l'éviter, utilisez la notation `|-` et passez à la ligne avec une indentation :

```yaml
exemple: |-
  maintenant : les deux-points ne sont plus un problème
```

Cette même notation `|-` est utilisée pour tout texte sur plusieurs paragraphes (typiquement les lectures patristiques de l'Office des lectures). Chaque paragraphe est une ligne, avec la même indentation :

```yaml
content: |-
  Premier paragraphe sur une seule ligne logique.
  Second paragraphe.
```

### Points typographiques français

- Utilisez les **apostrophes typographiques** (`’`, en haut) et non les apostrophes dactylographiques (`'`, droites). Vérifiez ce point après tout copier-coller — les éditeurs de texte permettent généralement un remplacement de masse.
- Les signes de ponctuation double (`:` `;` `?` `!`) sont précédés d'une **espace insécable**.
- Les guillemets de citation sont les guillemets français : `« bla bla »` — avec une espace insécable après le guillemet ouvrant et avant le guillemet fermant, et non les guillemets droits `"..."`.

### Le préambule : la clef `celebration`

Donne les informations générales de la fête :

```yaml
celebration:
  title: Bienheureux Antoine Chevrier
  subtitle: prêtre
  description: Né le 16 avril 1826 à Lyon, Antoine Chevrier fut ordonné prêtre en 1850. [...]
#attention: si la description comporte le symbole ':', ne pas oublier d'utiliser |- (voir plus haut) 
  commons:
    - pastors
  locative: à Lyon
  color: white
```

| Clef | Description |
|---|---|
| `title` | nom affiché de la fête |
| `subtitle` | qualité du saint (« prêtre », « évêque et docteur de l'Église »...) — optionnel |
| `description` | notice biographique, affichée comme complément — optionnel |
| `commons` | **toujours une liste** (précédée de `-`), même s'il n'y a qu'un seul commun ; voir ci-dessous |
| `locative` | lieu où le saint est honoré (« à Lyon ») — optionnel |
| `color` | couleur liturgique : `white`, `red`, `green`, `violet`, `rose` |

#### La liste des communs

Quand une fête n'a pas son propre texte d'office complet, l'application va chercher un **commun** : un jeu de textes adapté au type de saint (apôtre, martyr, pasteur...). Les communs sont toujours donnés en liste, même un seul :

```yaml
commons:
  - pastors
```

Attention aux deux séparateurs différents :
- `-` (tiret) définit une clef de commun à part entière : `saints-male`, `saints-female`.
- `_` (souligné) définit une **sous-catégorie** qui hérite du commun de base : `apostles_evangelist` prend ses données propres puis va chercher le reste dans `apostles`. Les variantes saisonnières `_advent`, `_lent`, `_easter` sont gérées automatiquement par l'application — il n'y a jamais besoin de les spécifier soi-même.

Liste des communs disponibles :

| Commun | Description |
|---|---|
| `apostles` | apôtres |
| `apostles_evangelist` | apôtres évangélistes |
| `dedicace` | dédicace d'une église |
| `martyr` | un seul martyr |
| `martyr_female` | une martyre |
| `martyr_female_virgin` | une martyre vierge |
| `martyrs` | plusieurs martyrs |
| `martyrs_female` | plusieurs martyres |
| `martyrs_female_virgin` | plusieurs martyres vierges |
| `martyrs_male` | plusieurs martyrs hommes |
| `martyrs_male_priest` | plusieurs martyrs prêtres |
| `pastors` | pasteurs |
| `pastors_pope` | un pasteur pape |
| `pastors_bishop` | un pasteur évêque |
| `pastors_doctors` | un pasteur docteur de l'Église (hérite de `pastors`) |
| `pastors_founders` | un pasteur fondateur |
| `pastors_multiple` | plusieurs pasteurs |
| `pastors_missionary` | un pasteur missionnaire |
| `saints` | saints en général |
| `saints_doctors` | un docteur de l'Église (hérite de `saints`) |
| `saints-female` | saintes femmes |
| `saints-female_caritative` | une sainte au service caritatif |
| `saints-female_educator` | une sainte éducatrice |
| `saints-female_married` | une sainte femme mariée |
| `saints-female_multiple` | plusieurs saintes femmes |
| `saints-female_religious` | une religieuse |
| `saints-male` | saints hommes |
| `saints-male_caritative` | un saint au service caritatif |
| `saints-male_educator` | un saint éducateur |
| `saints-male_married` | un saint homme marié |
| `saints-male-multiple` | plusieurs saints hommes |
| `saints-male_religious` | un religieux |
| `virgin-mary` | la Vierge Marie |
| `virgins` | vierges |
| `virgins_multiple` | plusieurs vierges |
| `virgins_martyrs` | une vierge martyre |

### Les clefs principales (offices)

Après le préambule, le reste du fichier décrit le contenu de chaque office. (La Compline n'est pas concernée : elle est gérée séparément, par jour de la semaine, et n'a pas besoin d'être déclarée dans un fichier de fête.)

| Clef | Description |
|---|---|
| `oration` | oraison par défaut, utilisée par tous les offices sauf si un office en précise une à lui (qui devient alors prioritaire). **Toujours une liste**, même avec une seule oraison (il peut y en avoir plusieurs au choix) |
| `invitatory` | antienne invitatoire, sous une sous-clef `antiphon` |
| `firstVespers` | premières vêpres (veille de la fête, pour les solennités et fêtes) |
| `readings` | office des lectures |
| `morning` | laudes |
| `middleOfDay` | milieu du jour (tierce, sexte, none) |
| `vespers` | second vêpres (le jour même) |
| `mass` | données pour la messe, quand disponibles (fonctionnalité pas encore activée côté application) |

`oration` et `evangelicAntiphon` peuvent aussi être placés directement à la racine du fichier, en dehors de toute clef d'office : ils servent alors de valeur par défaut pour `morning`, `vespers`/`firstVespers` et `readings` (pour `oration` seulement) quand l'office concerné ne les précise pas lui-même.

Le plus simple pour démarrer est de copier un fichier existant proche de votre cas (par exemple un autre fichier du même commun) et d'en adapter le contenu.

#### `invitatory`

```yaml
invitatory:
  antiphon:
    - Venez, crions de joie pour le Seigneur, acclamons notre Rocher, notre salut !
```

#### `firstVespers` et `vespers`

Les deux utilisent exactement la même structure : `firstVespers` se célèbre la veille (uniquement pour les solennités et fêtes), `vespers` le jour même.

```yaml
vespers:
  hymn:
    - puissance-et-gloire-de-l-esprit
  psalmody:
    - psalm: PSALM_114
      antiphon:
        - Les corps des saints ont été ensevelis dans la paix et leur nom reste vivant pour toutes les générations.
    - psalm: PSALM_115
      antiphon:
        - Leur descendance subsistera toujours ; jamais leur gloire ne sera effacée.
    - psalm: NT_9
      antiphon:
        - Voilà ceux qui ont donné leurs vies pour la cause de Dieu, et qui ont lavé leurs robes dans le sang de l'Agneau.
  reading:
    biblicalReference: 2Th 2,14-15
    content: Dieu vous a appelés par notre proclamation de l'Évangile, pour que vous entriez en possession de la gloire de notre Seigneur Jésus Christ.
  responsory: |-
    R/ Ayez la joie dans le Seigneur. Exultez les justes.
    V/ Jubilez tous les cœurs droits.
    Gloire au Père.
    R/ Ayez la joie.
  evangelicAntiphon:
    common: Que leur souvenir soit en bénédiction. Que leurs os refleurissent de leur tombe et que leur nom se renouvelle dans la descendance de ces hommes illustres.
  intercession:
    content: |-
      Avec les témoins du Christ ressuscité sur qui nous appuyons notre foi, rendons grâce à Dieu le Père :

      R/ Loué sois-tu, Seigneur de gloire !

      Loué sois-tu pour Jésus de Nazareth, le prophète puissant par la parole et par les actes :
      il a été crucifié, il est à jamais vivant.
```

| Clef | Description |
|---|---|
| `hymn` | liste de codes d'hymnes (voir partie 3) |
| `psalmody` | liste d'entrées `psalm` (code du psaume, ex. `PSALM_114`, `NT_9`, `OT_41`) + `antiphon` (toujours une liste de textes, même avec une seule antienne) |
| `reading` | lecture brève : `biblicalReference` + `content` |
| `responsory` | texte du répons |
| `evangelicAntiphon` | antienne du Magnificat (vêpres) ou du Benedictus (laudes) — voir la sous-section dédiée ci-dessous |
| `intercession` | `content` : texte des intercessions |
| `oration` | sinon hérité de la racine du fichier |

#### `morning` (Laudes)

Structure identique à `vespers` ci-dessus — seul l'`evangelicAntiphon` correspond alors au Benedictus plutôt qu'au Magnificat. La psalmodie comprend généralement trois psaumes : un psaume du matin, un cantique de l'Ancien Testament (codes `OT_...`), et un psaume de louange.

#### `readings` (Office des lectures)

```yaml
readings:
  hymn:
    - sauveur-du-monde-o-maitre
  psalmody:
    - psalm: PSALM_2
      antiphon:
        - L'Agneau qui se tient au milieu du Trône sera leur Pasteur pour les conduire vers les eaux de la source de vie.
  verse: |-
    V/ Nous sommes entrés dans l'eau et le feu
    et tu nous as fait sortir vers l'abondance.
  biblicalReading:
    - title: LECTURE DU LIVRE DE BEN SIRA LE SAGE
      ref: Si 44, 1-15 ; 46, 9-12
      content: |-
        Faisons l'éloge de ces hommes glorieux qui sont nos ancêtres. [...]
      responsory: |-
        R/ Enveloppés d'une si grande nuée de témoins
        fixons nos regards sur le Christ.
  patristicReading:
    - title: EXTRAIT DE L'ADVERSUS HAERESES DE SAINT IRÉNÉE
      subtitle: La gloire de Dieu, c'est l'homme vivant
      content: |-
        La splendeur de Dieu est vivifiante : ceux qui voient Dieu, reçoivent la vie. [...]
      responsory: |-
        R/ Prenons en mains le bouclier de la foi
        et le glaive de la Parole de Dieu.
```

| Clef | Description |
|---|---|
| `hymn`, `psalmody` | comme pour les autres offices (généralement trois psaumes) |
| `verse` | verset chanté en introduction des lectures |
| `biblicalReading` | une **liste** d'entrées `title` / `subtitle` (optionnel) / `ref` / `content` / `responsory` (le plus souvent une seule entrée) |
| `patristicReading` | même structure, sans `ref`, pour le texte patristique ou hagiographique |
| `oration` | sinon hérité de la racine |

Quand le texte patristique varie selon l'année liturgique (A/B/C), on dédouble la clef elle-même plutôt que son contenu : `patristicReadingA`, `patristicReadingB`, `patristicReadingC` au lieu de `patristicReading`. Si la clef de l'année en cours est absente, l'application se reporte automatiquement sur `patristicReading`.

#### `middleOfDay` (Tierce, Sexte, None)

```yaml
middleOfDay:
  psalmody:
    - antiphon: Le Seigneur leur a donné la victoire dans un combat redoutable ; il leur a fait comprendre ainsi que la fidélité à Dieu est la plus grande force.
    - antiphon: Le Seigneur leur a donné la victoire dans un combat redoutable ; il leur a fait comprendre ainsi que la fidélité à Dieu est la plus grande force.
    - antiphon: Le Seigneur leur a donné la victoire dans un combat redoutable ; il leur a fait comprendre ainsi que la fidélité à Dieu est la plus grande force.
  tierce:
    reading:
      biblicalReference: Sg 3, 1-3
      content: Les âmes des justes sont dans la main de Dieu ; aucun tourment n'a de prise sur eux.
    responsory: |-
      V/ Criez de joie pour le Seigneur, hommes justes !
      Hommes droits, à vous la louange !
  sexte:
    reading:
      biblicalReference: Sg 3, 1-3
      content: Les âmes des justes sont dans la main de Dieu ; aucun tourment n'a de prise sur eux.
    responsory: |-
      V/ Criez de joie pour le Seigneur, hommes justes !
      Hommes droits, à vous la louange !
  none:
    reading:
      biblicalReference: Sg 3, 1-3
      content: Les âmes des justes sont dans la main de Dieu ; aucun tourment n'a de prise sur eux.
    responsory: |-
      V/ Criez de joie pour le Seigneur, hommes justes !
      Hommes droits, à vous la louange !
```

La clef `psalmody` placée directement sous `middleOfDay` donne les antiennes communes aux trois petites heures (les psaumes eux-mêmes, toujours les mêmes trois psaumes gradués, sont gérés automatiquement par l'application — inutile de préciser `psalm`). Si une fête a besoin d'une antienne ou d'une lecture différente à une heure précise, on détaille cette heure dans sa propre sous-clef `tierce`/`sexte`/`none`, chacune avec sa structure `antiphon` + `reading` (`biblicalReference` + `content`) + `responsory`. `oration`, si présent, suit la même règle d'héritage que pour les autres offices.

#### Antienne évangélique variable selon l'année (A/B/C)

Pour les féries du Temps Ordinaire, l'antienne du Benedictus/Magnificat peut varier selon l'année liturgique. On utilise alors une structure à trois sous-clefs au lieu d'un simple texte :

```yaml
evangelicAntiphon:
  yearA: |-
    Jean-Baptiste a rendu témoignage : Voici l'Agneau de Dieu qui enlève le péché du monde.
  yearB: Nous avons trouvé le Messie, alléluia, Jésus de Nazareth, l'Agneau de Dieu.
  yearC: Jésus fut invité aux noces, à Cana de Galilée ; et sa mère était là.
```

Pour une fête sans variation annuelle, une simple chaîne ou une clef `common` suffit :

```yaml
evangelicAntiphon:
  common: Que leur souvenir soit en bénédiction.
```

Ou, plus simplement encore, sans clef `common` du tout :

```yaml
evangelicAntiphon: Que leur souvenir soit en bénédiction.
```

Contrairement à `oration` ou `commons`, l'antienne évangélique **n'a jamais besoin de la notation en liste** (`-`) : une simple chaîne suffit toujours, y compris sous `common`. Pour `yearA`/`yearB`/`yearC` en particulier, seule une chaîne unique est acceptée — ne jamais y mettre une liste.

---

## 3. Les hymnes

Le texte d'une hymne n'est jamais stocké dans le fichier de la fête : seul son **code** y est référencé. Le contenu réel vit dans un fichier séparé.

### Référencer une hymne dans un office

```yaml
readings:
  hymn:
    - entre-dans-la-gloire
    - autre-hymne
```

`hymn` est toujours une liste (même avec une seule hymne), car certains offices proposent un choix.

### Créer le fichier d'une nouvelle hymne

Le code (`entre-dans-la-gloire`) est le nom du fichier (suivi de `.yaml`), en anglais/translitéré, minuscules, mots séparés par `-` :

```
entre-dans-la-gloire.yaml
```

Contenu :

```yaml
title: Entré dans la gloire
author: D. Rimaud / Seuil    # optionnel
context: Ascension            # optionnel — indication du contexte d'usage
content: |-
  Entré dans la gloire,
  Jésus nous trace le chemin
  Et nous conduit vers le matin
  De sa victoire.

  R/ Mais l'amour seul est puissance,
  Mystère découvert
  Aux yeux de l'espérance. [...]
```

Seul `title` et `content` sont véritablement nécessaires ; `author` et `context` sont des informations complémentaires optionnelles.

---

## Pour aller plus loin

- [`location_geography.md`](location_geography.md) — détail technique de la résolution hiérarchique des lieux.
- [`celebration_file_lookup.md`](celebration_file_lookup.md) — comment un code de célébration est résolu en chemin de fichier.
- [`hymns.md`](hymns.md) — pipeline complet de résolution des hymnes (férial/commun/propre).

---

## Annexe : table des préséances liturgiques

Source : [Table des préséances des jours liturgiques](https://liturgie.catholique.fr/wp-content/uploads/sites/11/2019/02/Table-des-préséances-des-jours-liturgiques.pdf) (Conférence des évêques de France).

1. Triduum pascal de la Passion et de la Résurrection du Seigneur.

2. Nativité du Seigneur, Épiphanie, Ascension et Pentecôte. Dimanches de l'Avent, du Carême et de Pâques. Mercredi des Cendres. Jours de la semaine sainte, du lundi au jeudi inclus. Jours de l'octave de Pâques.

3. Solennités du Seigneur, de la bienheureuse Vierge Marie, des saints inscrits au calendrier général. Commémoration de tous les fidèles défunts.

4. Les solennités propres, à savoir :
   a) solennité du patron principal du lieu, de la ville ou de la cité ;
   b) solennité de la dédicace et de l'anniversaire de la dédicace de l'église propre ;
   c) solennité du titulaire de l'église propre ;
   d) solennité du titulaire, du fondateur, ou du patron principal de l'ordre ou de la congrégation.

5. Les fêtes du Seigneur inscrites au calendrier général.

6. Les dimanches du temps de Noël et les dimanches du Temps ordinaire.

7. Les fêtes de la bienheureuse Vierge Marie et des saints du calendrier général.

8. Les fêtes propres, à savoir :
   a) la fête du patron principal du diocèse ;
   b) la fête de l'anniversaire de la dédicace de la cathédrale ;
   c) la fête du patron principal de la région ou de la province, de la nation, d'un territoire plus vaste ;
   d) la fête du titulaire, du fondateur, du patron principal de l'ordre ou de la congrégation et de la province religieuse, restant sauf ce qui est prescrit au n° 4 ;
   e) les autres fêtes propres à une église ; les autres fêtes inscrites au calendrier d'un diocèse, d'un ordre ou d'une congrégation.

9. Les féries de l'Avent, du 17 au 24 décembre inclus. Les jours dans l'octave de Noël. Les féries de Carême.

10. Les mémoires obligatoires du calendrier général.

11. Les mémoires obligatoires propres, à savoir :
    a) les mémoires du patron secondaire du lieu, du diocèse, de la région ou de la province religieuse ;
    b) les autres mémoires obligatoires inscrites au calendrier d'un diocèse, d'un ordre ou d'une congrégation.

12. Les mémoires facultatives, lesquelles cependant peuvent, de la manière particulière indiquée dans les Présentations générales du Missel romain et de la Liturgie des Heures, se faire également les jours dont il est question au n° 9. De la même façon, les mémoires obligatoires qui tombent occasionnellement dans les féries du Carême peuvent être célébrées comme mémoires facultatives.

13. Les féries de l'Avent jusqu'au 16 décembre inclus. Les féries du temps de Noël, du 2 janvier au samedi après l'Épiphanie. Les féries du Temps pascal, du lundi après l'octave de Pâques au samedi avant la Pentecôte inclus. Les féries du Temps ordinaire.

Bon travail, et merci pour votre participation à ce beau projet !
