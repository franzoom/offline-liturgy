import '../classes/calendar_class.dart'; //classe de calendar
import '../main_calendar_fill.dart';
import '../classes/compline_class.dart';
import '../assets/libraries/hymns_library.dart';
import '../assets/fixed_texts_library.dart';
import '../assets/compline/compline_default.dart';
import '../assets/compline/compline_paschal_time.dart';
import '../assets/compline/compline_lent_time.dart';
import '../assets/compline/compline_solemnity_lent_time.dart';
import '../assets/compline/compline_solemnity_paschal_time.dart';
import '../assets/compline/compline_solmenity_ordinary_time.dart';
import '../assets/compline/compline_advent_time.dart';
import '../assets/compline/compline_christmas_time.dart';
import '../tools/hymns_management.dart';
import '../classes/hymns_class.dart';
import '../assets/libraries/psalms_library.dart';
import '../tools/days_name.dart';
import '../tools/check_and_fill_calendar.dart';
import 'dart:convert';

Map<String, ComplineDefinition> complineDefinitionResolution(
    Calendar calendar, DateTime date, location) {
  /// résout le choix des complies pour un jour donné. Demande à la fonction complineDetection
  /// les complies du jour et celles du lendemain. Si celles du lendemain sont une solennité,
  /// alors celle du jour sont une veille de solennité.
  calendar = checkAndFillCalendar(calendar, date, location);
  Map<String, ComplineDefinition> todayComplineDefinition =
      complineDefinitionDetection(calendar, date);
  Map<String, ComplineDefinition> tomorrowComplineDefinition =
      complineDefinitionDetection(calendar, date.add(Duration(days: 1)));

  Map<String, ComplineDefinition> complineDefinitionResolved =
      todayComplineDefinition;

  // adding the possibility of complines for the eve of solemnity:
  // looking in tomorrowCompline the tag "Solemnity"

  for (var entry in tomorrowComplineDefinition.entries) {
    if (entry.value.celebrationType == 'Solemnity' &&
        entry.value.priority <
            todayComplineDefinition.entries.first.value.priority) {
      // adjunction of the Compline of Eve of Solemnity
      ComplineDefinition complineDefinition = ComplineDefinition(
          dayOfWeek: 'saturday',
          liturgicalTime: entry.value.liturgicalTime,
          celebrationType: 'SolemnityEve',
          priority: entry.value.priority);
      return complineDefinitionResolved = {entry.key: complineDefinition};
    }
  }
  return complineDefinitionResolved;
  // return of the Complines Map to be used
}

Map<String, ComplineDefinition> complineDefinitionDetection(

    /// detection of which Compline to use for a given day.
    /// returns a Map  "day or feast name" : ComplineDefinition
    Calendar calendar,
    DateTime date) {
  Map<String, ComplineDefinition> complineDefinitionFinal = {};

  DayContent? todayContent = calendar.getDayContent(date);
  String todayName = dayName[date.weekday];
  String liturgicalTime = todayContent!.liturgicalTime;
  String celebrationName = todayContent.defaultCelebration.toLowerCase();
  int celebrationPriority = todayContent.defaultPriority;

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

void complineDisplay(Compline compline) {
  // affichage du texte des Complies
  if (compline.complineCommentary != null) {
    print('Commentary: ${compline.complineCommentary ?? "Aucun commentaire"}');
  }
  if (compline.celebrationType != null &&
      compline.celebrationType != 'normal') {
    print('Celebration Type: ${compline.celebrationType}');
  }
  print('------ HYMNES ------');
  Map<String, Hymns> selectedHymns =
      filterHymnsByCodes(compline.complineHymns!, hymnsLibraryContent);
  displayHymns(selectedHymns);
  print('Psalm 1 Antiphon 1: ${compline.complinePsalm1Antiphon1}');
  print('Psalm 1 Antiphon 2: ${compline.complinePsalm1Antiphon2}');
  print('Psalm 1 title: ${psalms[compline.psalm1Ref]!.getTitle}');
  print('Psalm 1 subtitle: ${psalms[compline.psalm1Ref]!.getSubtitle}');
  print('Psalm 1 commentary: ${psalms[compline.psalm1Ref]!.getCommentary}');
  print(
      'Psalm 1 biblical reference: ${psalms[compline.psalm1Ref]!.getBiblicalReference}');
  print('Psalm 1 content: ${psalms[compline.psalm1Ref]!.getContent}');

  if (compline.psalm2Ref != "") {
    print('Psalm 2 Antiphon 1: ${compline.complinePsalm2Antiphon1}');
    print('Psalm 2 Antiphon 2: ${compline.complinePsalm2Antiphon2}');
    print('Psalm 2 title: ${psalms[compline.psalm1Ref]!.getTitle}');
    print('Psalm 2 subtitle: ${psalms[compline.psalm1Ref]!.getSubtitle}');
    print('Psalm 2 commentary: ${psalms[compline.psalm1Ref]!.getCommentary}');
    print(
        'Psalm 2 biblical reference: ${psalms[compline.psalm1Ref]!.getBiblicalReference}');
    print('Psalm 2 content: ${psalms[compline.psalm1Ref]!.getContent}');
  }
  print('Reading Reference: ${compline.complineReadingRef}');
  print('Reading: ${compline.complineReading}');
  print('Responsory: ${compline.complineResponsory}');
  print('Evangelic Antiphon: ${compline.complineEvangelicAntiphon}');
  print('Oration: ${compline.complineOration}');
  print('------ HYMNES MARIALES ------');
  selectedHymns =
      filterHymnsByCodes(compline.marialHymnRef!, hymnsLibraryContent);
  displayHymns(selectedHymns);
}

String exportComplineToAelfJson(
    Calendar calendar, DateTime date, String location) {
  final complineDef = complineDefinitionResolution(calendar, date, location);
  final complineMap = complineTextCompilation(complineDef);
  final compline = complineMap.values.first;

  // Extract hymn
  Map<String, dynamic>? hymnJson;
  if (compline.complineHymns != null && compline.complineHymns!.isNotEmpty) {
    final hymn = hymnsLibraryContent[compline.complineHymns!.first];
    if (hymn != null) {
      hymnJson = {
        'auteur': hymn.author,
        'titre': hymn.title,
        'texte': hymn.content,
      };
    }
  }

  // Extract marial hymn
  Map<String, dynamic>? marialHymnJson;
  if (compline.marialHymnRef != null && compline.marialHymnRef!.isNotEmpty) {
    final marialHymn = hymnsLibraryContent[compline.marialHymnRef!.first];
    if (marialHymn != null) {
      marialHymnJson = {
        'titre': marialHymn.title,
        'texte': marialHymn.content,
      };
    }
  }

  final jsonMap = {
    'informations': {
      'date': date.toIso8601String().split('T').first,
      'zone': location,
      // Add more fields as needed from calendar or day content
    },
    'complies': {
      'introduction': fixedTexts["officeIntroduction"],
      'hymne': hymnJson,
      'antienne_1': compline.complinePsalm1Antiphon1,
      'psaume_1': {
        'reference': psalms[compline.psalm1Ref]?.getTitle,
        'texte': compline.psalm1Ref != null
            ? psalms[compline.psalm1Ref]?.getContent
            : null,
      },
      'antienne_2': compline.complinePsalm2Antiphon1,
      'psaume_2': compline.psalm2Ref != null && compline.psalm2Ref != ''
          ? {
              'reference': psalms[compline.psalm1Ref]?.getTitle,
              'texte': psalms[compline.psalm2Ref]?.getContent,
            }
          : null,
      'pericope': {
        'reference': compline.complineReadingRef,
        'texte': compline.complineReading,
      },
      'repons': compline.complineResponsory,
      'antienne_symeon': compline.complineEvangelicAntiphon,
      'cantique_symeon': null, // Not available in current data
      'oraison': compline.complineOration?.join('\n'),
      'benediction': null, // Not available in current data
      'hymne_mariale': marialHymnJson,
    }
  };

  final jsonString = JsonEncoder.withIndent('  ').convert(jsonMap);
  return jsonString;
}
