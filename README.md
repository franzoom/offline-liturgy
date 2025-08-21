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

## Structure des données fournies par complineDefinitionResolution

On appelle complineDefinitionResolution(calendar, DateTime(x,x,x)) pour obtenir les complies du jour. Si le calendrier n'existe pas ou ne contient pas cette date, il est calculé et stocké dans assets/calendar.json.

Structure de la sortie de la fonction:

- <compline.complineCommentary> donne des commentaires sur l'utilisation des complies (si elles sont facultatives un jour particulier)
- <compline.celebrationType> chaîne qui indique si c'est des complies normales, une solennité ou une veille de solennité ('normal', 'solemnity' ou 'solemnityEve')
- <compline.complineHymns> qui est la liste des hymnes possibles.
  Pour récupérer le texte des hymnes on applique :
  Map<String, Hymns> selectedHymns = filterHymnsByCodes(compline.complineHymns!, complineHymnsContent) et on récupère une Map<String, Hymns> en important '../assets/compline/compline\*hymns.dart'
  - <title> et le titre de l'hymne (en code raccourci)
    \_ Hymns est une Map qui contient trois champs: + <title> est le titre officiel de l'hymne + <author> est l'éventuel auteur + <content> est le texte de l'hymne
- <compline.complinePsalm1Antiphon>: première antienne du premier psaume
- <compline.complinePsalm1Antiphon2>: deuxième antienne du premier psaume
- <compline.complinePsalm1> qui contient la référence du 1er psaume ou cantique. On appelle les détails du psaume ainsi, en important '../assets/psalms.dart':
  - <psalms[compline.complinePsalm1]!.getTitle> récupère le titre du psaume (peut être vide)
  - <psalms[compline.complinePsalm1]!.getSubtitle> récupère le soustitre du psaume (peut être vide)
  - <psalms[compline.complinePsalm1]!.getCommentary> récupère la phrase biblique proposée en commentaire du psaume
  - <psalms[compline.complinePsalm1]!.getBiblicalReference> récupère la référence biblique (utilisé pour les cantiques, autrement vide)
  - <psalms[compline.complinePsalm1]!.getContent> récupère le contenu du psaume en formatage HTML donné par AELF
- si <compline.complinePsalm2> est non nul (s'il y a un deuxième psaume), on applique la même recette pour ce deuxième psaume
- <compline.complineReadingRef>: référence biblique de la lecture biblique
- <compline.complineReading>: texte de la lecture biblique
- <compline.complineResponsory>: texte du répons
- <compline.complineEvangelicAntiphon>: texte de l'antienne du cantique évangélique
- <compline.complineOration>: texte de l'oraison finale
- <compline.marialHymnRef>: liste des hymnes mariales pour clôturer les complies. On récupère les données de la même manière que pour les hymnes de début d'office.

Pour un affichage complet du texte des complies, il faut évidemment rajouter le cantique évangélique (cantique de Syméon) qui peut être appelé comme pour les psaumes: psalms[NT_3].
