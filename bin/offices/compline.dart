import '../classes/calendar_class.dart'; //classe de calendar
import '../calendar_fill.dart';
import '../classes/compline_class.dart';
import '../assets/compline/compline_hymns.dart';
import '../assets/compline/compline_default.dart';
import '../assets/compline/compline_paschal_time.dart';
import '../assets/compline/compline_lent_time.dart';
import '../assets/compline/compline_solemnity_lent_time.dart';
import '../assets/compline/compline_solemnity_paschal_time.dart';
import '../assets/compline/compline_solmenity_ordinary_time.dart';
import '../assets/compline/compline_advent_time.dart';
import '../assets/compline/compline_christmas_time.dart';
import '../hymns_management.dart';
import '../classes/hymns_class.dart';

List dayName = [
  '',
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

Map<String, ComplineDefinition> complineDefinitionResolution(
    Calendar calendar, DateTime date) {
  /// résout le choix des complies pour un jour donné. Demande à la fonction complineDetection
  /// les complies du jour et celles du lendemain. Si celles du lendemain sont une solennité,
  /// alors celle du jour sont une veille de solennité.
  calendar = checkAndFillCalendar(calendar, date);
  Map<String, ComplineDefinition> todayComplineDefinition =
      complineDefinitionDetection(calendar, date);
  Map<String, ComplineDefinition> tomorrowComplineDefinition =
      complineDefinitionDetection(calendar, date.add(Duration(days: 1)));

  Map<String, ComplineDefinition> complineDefinitionResolved =
      todayComplineDefinition;

  // on ajoute la complie de veille de solennité si elle existe
  //chercher dans tomorrowCompline si j'ai un tag "Solemnity"

  for (var entry in tomorrowComplineDefinition.entries) {
    if (entry.value.celebrationType == 'Solemnity' &&
        entry.value.priority <
            todayComplineDefinition.entries.first.value.priority) {
      // on ajoute la complie de veille de solemnité
      ComplineDefinition complineDefinition = ComplineDefinition(
          dayOfWeek: 'saturday',
          liturgicalTime: entry.value.liturgicalTime,
          celebrationType: 'SolemnityEve',
          priority: entry.value.priority);
      return complineDefinitionResolved = {entry.key: complineDefinition};
    }
  }
  return complineDefinitionResolved;
  //retourne la Map de définitions de complies
  // qui sera utilisée pour compiler le texte de la complie
  // et l'afficher.
}

Map<String, ComplineDefinition> complineDefinitionDetection(

    /// Fonction que détecte quelle complie utiliser pour un jour donné
    /// envoie une Map  "nom du jour ou de la fête" : ComplineDefinition
    Calendar calendar,
    DateTime date) {
  Map<String, ComplineDefinition> complineDefinitionFinal = {};

  DayContent? todayContent = calendar.getDayContent(date);
  String todayName = dayName[date.weekday];
  String liturgicalTime = todayContent!.liturgicalTime;
  String celebrationName = todayContent.defaultCelebration;
  int celebrationPriority = todayContent.defaultPriority;
  celebrationName = celebrationName.toLowerCase();

  if (celebrationName == 'commemoration_of_all_the_faithful_departed') {
    ComplineDefinition complineDefinition = ComplineDefinition(
        dayOfWeek: todayName,
        liturgicalTime: 'OrdinaryTime',
        celebrationType: 'normal',
        priority: 13);
    return complineDefinitionFinal = {celebrationName: complineDefinition};
  }

  switch (celebrationName) {
    case 'holy_thursday' || 'holy_friday' || 'holy_saturday':
      ComplineDefinition complineDefinition = ComplineDefinition(
          dayOfWeek: 'sunday',
          liturgicalTime: 'LentTime',
          celebrationType: celebrationName,
          priority: 1);
      return complineDefinitionFinal = {celebrationName: complineDefinition};
    case 'ashes':
      ComplineDefinition complineDefinition = ComplineDefinition(
          dayOfWeek: 'wednesday',
          liturgicalTime: 'OrdinaryTime',
          celebrationType: 'normal',
          priority: 13);
      return complineDefinitionFinal = {celebrationName: complineDefinition};
  }
  if (celebrationName.toLowerCase().contains('sunday')) {
    //si c'est affiché comme un dimanche, (donc qu'il n'y a pas de solenmité "majeure" qui l'a remplacé),
    // ajouter une solemnité si elle existe dans la liste du jour (priority).
    for (var entry in todayContent.priority.entries) {
      if (entry.key <= 4) {
        ComplineDefinition complineDefinition = ComplineDefinition(
            dayOfWeek: todayName,
            liturgicalTime: liturgicalTime,
            celebrationType: 'Solemnity',
            priority: entry.key);
        return complineDefinitionFinal = {entry.value[0]: complineDefinition};
      }
    }
    ComplineDefinition complineDefinition = ComplineDefinition(
        dayOfWeek: todayName,
        liturgicalTime: liturgicalTime,
        celebrationType: 'normal',
        priority: 5);
    return complineDefinitionFinal = {celebrationName: complineDefinition};
  }
//ajouter les autres cas: complies du jour et des solemnités de semaine
  if (celebrationPriority <= 4) {
    // on prend d'abord les solemnités majeures
    ComplineDefinition complineDefinition = ComplineDefinition(
        dayOfWeek: 'sunday',
        liturgicalTime: liturgicalTime,
        celebrationType: 'Solemnity',
        priority: celebrationPriority);
    return complineDefinitionFinal = {celebrationName: complineDefinition};
  }
  // ensuite les solennités ajoutées
  for (var entry in todayContent.priority.entries) {
    if (entry.key <= 4) {
      ComplineDefinition complineDefinition = ComplineDefinition(
          dayOfWeek: 'sunday',
          liturgicalTime: liturgicalTime,
          celebrationType: 'Solemnity',
          priority: entry.key);
      return complineDefinitionFinal = {entry.value[0]: complineDefinition};
    }
  }
// on termine en ajoutant les complies des jours sans solennité
  ComplineDefinition complineDefinition = ComplineDefinition(
      dayOfWeek: todayName,
      liturgicalTime: liturgicalTime,
      celebrationType: 'normal',
      priority: celebrationPriority);
  return complineDefinitionFinal = {todayName: complineDefinition};
}

Map<String, Compline> complineTextCompilation(
    Map<String, ComplineDefinition> complineDefinitionExported) {
  // retourne la liste des complies compilées à partir des définitions de complies
  // en utilisant la fonction getComplineText.
  // La clé de la Map est le nom de la complie (jour ou fête)
  // et la valeur est le texte de la complie.
  return complineDefinitionExported.map((key, value) {
    // Transformation de chaque valeur avec getComplineText
    final complineText = getComplineText(value);
    return MapEntry(key, complineText!);
  });
}

Compline? getComplineText(ComplineDefinition complineDefinition) {
  // à partit de la définition de la complie, renvoie le texte de la complie
  // suivant la classe Compline.
  String day = complineDefinition.dayOfWeek;
  Compline? dayCompline = defaultCompline[day];
  Compline? correctionCompline;
  String dayName;
  switch (complineDefinition.celebrationType) {
    case 'holy_thursday':
      // On utilise le jeudi saint pour le Triduum
      correctionCompline = lentTimeCompline['holy_thursday'];
      'Jeudi Saint'; // on ajoute le nom de la fête pour l'affichage
      break;
    case 'holy_friday':
      // On utilise le jeudi saint pour le Triduum
      correctionCompline = lentTimeCompline['holy_friday'];
      break;
    case 'holy_saturday':
      // On utilise le jeudi saint pour le Triduum
      correctionCompline = lentTimeCompline['holy_saturday'];
      break;
    case 'normal':
      // On utilise le jour de la semaine pour le temps ordinaire
      switch (complineDefinition.liturgicalTime) {
        case 'OrdinaryTime':
          return dayCompline;
        case 'LentTime':
          correctionCompline = lentTimeCompline[day];
          break;
        case 'PaschalTime':
          correctionCompline = paschalTimeCompline[day];
          break;
        case 'AdventTime':
          correctionCompline = adventTimeCompline[day];
          break;
        case 'ChristmasTime':
          correctionCompline = christmasTimeCompline[day];
          break;
        default:
          correctionCompline = dayCompline;
      }
      correctionCompline?.celebrationType = complineDefinition.celebrationType;
      break;
    case ('Solemnity' || 'SolemnityEve'):
      complineDefinition.celebrationType == 'Solemnity'
          ? dayName = 'sunday'
          : dayName = 'saturday';
      dayCompline = defaultCompline[dayName];
      switch (complineDefinition.liturgicalTime) {
        case 'OrdinaryTime':
          correctionCompline = solemnityComplineOrdinaryTime[dayName];
          break;
        case 'LentTime':
          correctionCompline = solemnityComplineLentTime[dayName];
          break;
        case 'PaschalTime':
          correctionCompline = solemnityComplinePaschalTime[dayName];
          break;
        case 'AdventTime':
          correctionCompline = adventTimeCompline[dayName];
          break;
        case 'ChristmasTime':
          correctionCompline = christmasTimeCompline[dayName];
          break;
        default:
          correctionCompline = dayCompline;
      }
      correctionCompline?.celebrationType = complineDefinition.celebrationType;
      break;
    default:
      correctionCompline = dayCompline;
      correctionCompline?.celebrationType = complineDefinition.celebrationType;
  }
  return mergeComplineDay(dayCompline!, correctionCompline!);
}

Compline mergeComplineDay(Compline base, Compline override) {
  //fonction de remplacement des élements de complies par défaut par des élements spécifiques
  return Compline(
    complineCommentary: override.complineCommentary ?? base.complineCommentary,
    celebrationType: override.celebrationType ?? base.celebrationType,
    complineHymns: override.complineHymns ?? base.complineHymns,
    complinePsalm1Antiphon1:
        override.complinePsalm1Antiphon1 ?? base.complinePsalm1Antiphon1,
    complinePsalm1Antiphon2:
        override.complinePsalm1Antiphon2 ?? base.complinePsalm1Antiphon2,
    psalm1Ref: override.psalm1Ref ?? base.psalm1Ref,
    complinePsalm2Antiphon1:
        override.complinePsalm2Antiphon1 ?? base.complinePsalm2Antiphon1,
    complinePsalm2Antiphon2:
        override.complinePsalm2Antiphon2 ?? base.complinePsalm2Antiphon2,
    psalm2Ref: override.psalm2Ref ?? base.psalm2Ref,
    complineReadingRef: override.complineReadingRef ?? base.complineReadingRef,
    complineReading: override.complineReading ?? base.complineReading,
    complineResponsory: override.complineResponsory ?? base.complineResponsory,
    complineEvangelicAntiphon:
        override.complineEvangelicAntiphon ?? base.complineEvangelicAntiphon,
    complineOration: override.complineOration ?? base.complineOration,
    marialHymnRef: override.marialHymnRef ?? base.marialHymnRef,
  );
}

// affichage du texte des Complies
void complineDisplay(Compline compline) {
  if (compline.complineCommentary != null) {
    print('Commentary: ${compline.complineCommentary ?? "Aucun commentaire"}');
  }
  if (compline.celebrationType != null &&
      compline.celebrationType != 'normal') {
    print('Celebration Type: ${compline.celebrationType}');
  }
  print('------ HYMNES ------');
  Map<String, Hymns> selectedHymns =
      filterHymnsByCodes(compline.complineHymns!, complineHymnsContent);
  displayHymns(selectedHymns);
  print('Psalm 1 Antiphon 1: ${compline.complinePsalm1Antiphon1}');
  print('Psalm 1 Antiphon 2: ${compline.complinePsalm1Antiphon2}');
  print('Psalm 1 Reference: ${compline.psalm1Ref}');
  print('Psalm 2 Antiphon 1: ${compline.complinePsalm2Antiphon1}');
  print('Psalm 2 Antiphon 2: ${compline.complinePsalm2Antiphon2}');
  print('Psalm 2 Reference: ${compline.psalm2Ref}');
  print('Reading Reference: ${compline.complineReadingRef}');
  print('Reading: ${compline.complineReading}');
  print('Responsory: ${compline.complineResponsory}');
  print('Evangelic Antiphon: ${compline.complineEvangelicAntiphon}');
  print('Oration: ${compline.complineOration}');
  print('------ HYMNES MARIALES ------');
  selectedHymns =
      filterHymnsByCodes(compline.marialHymnRef!, complineHymnsContent);
  displayHymns(selectedHymns);
}
