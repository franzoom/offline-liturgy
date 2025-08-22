# Projet offline-liturgy

Cette routine en dart permet de créer l'agenda liturgique pour au moins une année et d'extraire les offices du bréviaire et du missel romain.

## fonctionnalités

pour le moment le fichier main.dart initialise une variable calendrier, puis appelle la fonction complineDefinitionResolution(calendrier, date) pour donner en sortie toutes les références nécessaires à l'obtention des textes pour les complies du jour demandé.
main.dart appelle ensuite la fonction (temporaire) complineTextCompilation qui permet d'afficher dans la console toutes les données de ces vigiles. À terme ces données seront récupérées directement par l'application Flutter pour afficher l'office.
On passera ensuite aux autres offices.

## Construction du calendrier

Le calendrier se construit par la fonction calendarFill en plusieurs étapes.

1. création du squelette par la fonction createLiturgicalDays (dans common_calendar.dart) qui donne toutes les fêtes mobiles
2. la fonction calendarFill parcours tout le calendrier, ajoute les fêtes mobiles calculées et complète avec tous les jours de féries, de fête ou d'octave. À ce point, chaque jour du calendrier liturgqiue est forcé d'exister
3. la fonction calendarFill appelle la fonction addFeastsToCalendar qui ajoute toutes les fêtes (ou mémoires) du calendrier commun (calendrier romain général).
4. on termine la fonction en invoquant si besoin les calendrier locaux. Ces calendriers s'appellent l'un l'autre dans l'ordre croissant. Si j'appelle Lyon, il appelera la France, qui appelera à son tour l'Europe. Ainsi tous les dates des calendriers locaux sont insérées dans le calendrier général.

Le calendrier est enregistré dans calendar.json, dans le répertoire ./assets. S'il n'existe pas il est créé.

# The function complineDefinitionResolution

complineDefinitionResolution(calendar, DateTime(x,x,x)) is called to return the day Complines.
(for the moment:) if the calendar doesn't exist or doesn't possess that date, the calendar is calculater and stored in assets/calendar.json.

## Structure returned by the Compline function:

- <compline.complineCommentary> some commentaries about the Compline use (if they are facultative)
- <compline.celebrationType> indication about the type of Complines: ('normal', 'solemnity' ou 'solemnityEve')
- introduction of the Office: use the file '.lib/assets/libraries/fixed-texts_library.dart': fixedTexts['officeIntroduction'] to display the html content.
- <compline.complineHymns> list possible possible hymns for the day.
  every elemnt of the list is a key refercenint to the Map<String, Hymns> in '.lib/assets/libraries/hymns_library.dart'. For each key we receive 3 elements:
  - <<title> : official title of the Hymn
  - <author> author of the Hymn (not always provided)
  - <content> is the text of the Hymn in html code.
- <compline.complinePsalm1Antiphon>: first antiphon of first Psalm
- <compline.complinePsalm1Antiphon2>: second antiphon of first Psalm. If it's not empty, it should be great to display the first antiphon, then "or" and the second antiphon.
- <compline.complinePsalm1> key of the psalm of canticle to be found in '../assets/libraries/psalms_library.dart'
  - <psalms[compline.complinePsalm1]!.getTitle> returns the title of the psalm or canticle (can be empty)
  - <psalms[compline.complinePsalm1]!.getSubtitle> returns the subtitle only for the canticles (can be empty)
  - <psalms[compline.complinePsalm1]!.getCommentary> returns the biblical description of the psalm or canticle. It should be great to have the opportunity to display it (in shorter size ?)
  - <psalms[compline.complinePsalm1]!.getBiblicalReference> returns the biblical reference (only for the canticles)
  - <psalms[compline.complinePsalm1]!.getContent> returns the text of the psalm or canticle, formatted in html
- if <compline.complinePsalm2> is not empty (there is a second psalm), we use the same receipe for this second psalm
- <compline.complineReadingRef>: reference of the biblical reading
- <compline.complineReading>: content of the biblical reading
- <compline.complineResponsory>: responsory text
- <compline.complineEvangelicAntiphon>: antiphon for the Evangelic Canticle
- the Evangelic Canticle (Symeon Canticle) will be found in the psalms_library, using the key "NT_3": psalms['NT_3']
- <compline.complineOration>: list of the final orations. If there is more than one oration, display both, separated by "or".
- <compline.marialHymnRef>: marial hymns list. Same use as the hymns list for the beginning of the Compline Office
- conclusion of the Office: use the file '.lib/assets/libraries/fixed-texts_library.dart': fixedTexts['complineConclusion'] to display the html content.

# THE DAY OFFICE CLASS

This class contains all the possible datas for the 4 offices of the day (Complines excluded)

## Particular keys

- celebrationTitle
- celebrationSubtitle
- celebrationDescription: texte describing some elements of the saints' life.
- commons: list of commons possibles for this celebration
- liturgicalGrade (usefull ?)
- liturgicalColor

## Methods

- fromJSON: creates an instance of the Class by extracting all the datas of a given JSON file

# THE MORNING CLASS

This class is used to define a the final form of the office.

1. Firstable the datas are picked with the day_office Class
2. then a Common is chosen (if needed)
3. then the MorningData can be set up, using the datas of day_office (Proper) and the chosen Common.

## Description of the Class

- describes all the elements used for the Morning Office
- adds the elements describing the celebration:

  - celebrationTitle and Subtitle
  - description of the celebration
  - liturgicalGrade
  - liturgialColor
  - common used

## Methods of the Class:

- fromDayOffices: extracts the usefull datas from an instance of DayOffices containing all the datas of a whole day (coming from the json files)
- overlay: merges with another set of MorningDatas. Used to add a layer on another layer (proper on common, for example).
- setInvitatoryPsalms: used after all the merging part, in order to exclude the Invitatory Psalms already used in the Morning Office.

## example of use:

var morning = Morning();
morning
..overlay(overlayCommon)
..overlay(overlaySpecific)
..setInvitatoryPsalms();
