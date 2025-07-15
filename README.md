# Projet offline-liturgy

Cette routine en dart permet de créer l'agenda liturgique pour au moins une année et d'extraire les offices du bréviaire et du missel romain.

## fonctionnalités

pour le moment le fichier main.dart initialise une variable calendrier, puis appelle la fonction complineDefinitionResolution(date) pour donner en sortie toutes les références nécessaires à l'obtention des textes pour les complies du jour demandé.
On passera ensuite aux autres offices.
main.dart appelle ensuite la fonction (temporaire) complineTextCompilation qui permet d'afficher dans la console toutes les données de ces vigiles. À terme ces données seront récupérées directement par l'application Flutter pour afficher l'office.

## Structure des données fournies par complineDefinitionResolution

On appelle complineDefinitionResolution(calendar, DateTime(x,x,x)) pour obtenir les complies du jour. Si le calendrier n'existe pas déjà ou ne contient pas cette date, il est calculé et stocké dans assets/calendar.json.

Structure de la sortie de la fonction:

- <compline.complineCommentary> donne des commentaires sur l'utilisation des complies (si elles sont facultatives un jour particulier)
- <compline.celebrationType> chaîne qui indique si c'est des complies normales, une solennité ou une veille de solennité ('normal', 'solemnity' ou 'solemnityEve')
- <compline.complineHymns> qui est la liste des hymnes possibles.
  Pour récupérer le texte des hymnes on applique :
  Map<String, Hymns> selectedHymns = filterHymnsByCodes(compline.complineHymns!, complineHymnsContent) et on récupère une Map<String, Hymns> en important '../assets/compline/compline*hymns.dart'
  * <title> et le titre de l'hymne (en code raccourci)
  \_ Hymns est une Map qui contient trois champs: + <title> est le titre officiel de l'hymne + <author> est l'éventuel auteur + <content> est le texte de l'hymne
- <compline.complinePsalm1Antiphon1>: première antienne du premier psaume
- <compline.complinePsalm1Antiphon2>: deuxième antienne du premier psaume
- <compline.psalm1Ref> qui contient la référence du 1er psaume ou cantique. On appelle les détails du psaume ainsi, en important '../assets/psalms.dart':
  - <psalms[compline.psalm1Ref]!.getTitle> récupère le titre du psaume (peut être vide)
  - <psalms[compline.psalm1Ref]!.getSubtitle> récupère le soustitre du psaume (peut être vide)
  - <psalms[compline.psalm1Ref]!.getCommentary> récupère la phrase biblique proposée en commentaire du psaume
  - <psalms[compline.psalm1Ref]!.getBiblicalReference> récupère la référence biblique (utilisé pour les cantiques, autrement vide)
  - <psalms[compline.psalm1Ref]!.getContent> récupère le contenu du psaume en formatage HTML donné par AELF
- si <compline.psalm2Ref> est non nul (s'il y a un deuxième psaume), on applique la même recette pour ce deuxième psaume
- <compline.complineReadingRef>: référence biblique de la lecture biblique
- <compline.complineReading>: texte de la lecture biblique
- <compline.complineResponsory>: texte du répons
- <compline.complineEvangelicAntiphon>: texte de l'antienne du cantique évangélique
- <compline.complineOration>: texte de l'oraison finale
- <compline.marialHymnRef>: liste des hymnes mariales pour clôturer les complies. On récupère les données de la même manière que pour les hymnes de début d'office.

Pour un affichage complet du texte des commlies, il faut évidemment rajouter le cantique évangélique (cantique de Syméon) qui peut être appelé comme pour les psaumes: psalms[NT_3].
