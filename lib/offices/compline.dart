import '../classes/calendar_class.dart'; //classe de calendar
import '../classes/compline_class.dart';
import '../assets/libraries/psalms_library.dart';
import '../assets/libraries/hymns_library.dart';
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
import '../tools/date_tools.dart';

List<Map<String, ComplineDefinition>> complineDefinitionResolution(
    Calendar calendar, DateTime date) {
  /// Resolves the Complines choice for a given day: returns a list of possible Complines maps.
  /// Usually returns only today's Complines, but if tomorrow is a Solemnity,
  /// includes Solemnity Eve Complines.
  /// If today is also a Solemnity and tomorrow is a Solemnity, returns both options.

  List<Map<String, ComplineDefinition>> possibleComplines = [];

  Map<String, ComplineDefinition> todayComplineDefinition =
      complineDetection(calendar, date);
  Map<String, ComplineDefinition> tomorrowComplineDefinition =
      complineDetection(calendar, dayShift(date, 1));

  // Check if today is a Solemnity
  bool todayIsSolemnity = todayComplineDefinition.entries
      .any((entry) => entry.value.celebrationType == 'Solemnity');

  // Check if tomorrow is a Solemnity with higher priority
  bool tomorrowIsSolemnity = false;
  MapEntry? tomorrowSolemnityEntry;

  for (var entry in tomorrowComplineDefinition.entries) {
    if (entry.value.celebrationType == 'Solemnity' &&
        entry.value.priority <
            todayComplineDefinition.entries.first.value.priority) {
      tomorrowIsSolemnity = true;
      tomorrowSolemnityEntry = entry;
      break;
    }
  }
  // Decision logic
  if (tomorrowIsSolemnity && todayIsSolemnity) {
    // Both options: today's Solemnity Complines AND Solemnity Eve Complines
    possibleComplines.add(todayComplineDefinition);
    ComplineDefinition eveComplineDefinition = ComplineDefinition(
      dayOfWeek: 'saturday',
      liturgicalTime: tomorrowSolemnityEntry!.value.liturgicalTime,
      celebrationType: 'SolemnityEve',
      priority: tomorrowSolemnityEntry.value.priority,
    );
    possibleComplines.add({tomorrowSolemnityEntry.key: eveComplineDefinition});
  } else if (tomorrowIsSolemnity) {
    // Only Solemnity Eve Complines
    ComplineDefinition eveComplineDefinition = ComplineDefinition(
      dayOfWeek: 'saturday',
      liturgicalTime: tomorrowSolemnityEntry!.value.liturgicalTime,
      celebrationType: 'SolemnityEve',
      priority: tomorrowSolemnityEntry.value.priority,
    );
    possibleComplines.add({tomorrowSolemnityEntry.key: eveComplineDefinition});
  } else {
    // Default: today's Complines
    possibleComplines.add(todayComplineDefinition);
  }

  return possibleComplines;
}

Map<String, ComplineDefinition> complineDetection(
    Calendar calendar, DateTime date) {
  /// detection of which Compline to use for a given day.
  /// returns a Map  "day or feast name" : ComplineDefinition
  Map<String, ComplineDefinition> complineDefined = {};

  DayContent? todayContent = calendar.getDayContent(date);
  String todayName = dayName[date.weekday];
  String liturgicalTime = todayContent!.liturgicalTime;
  String celebrationTitle = todayContent.defaultCelebrationTitle.toLowerCase();
  int liturgicalGrade = todayContent.liturgicalGrade;

  if (celebrationTitle == 'commemoration_of_all_the_faithful_departed') {
    ComplineDefinition complineDefinition = ComplineDefinition(
        dayOfWeek: todayName,
        liturgicalTime: 'OrdinaryTime',
        celebrationType: 'normal',
        priority: 13);
    return complineDefined = {celebrationTitle: complineDefinition};
  }

  switch (celebrationTitle) {
    case 'holy_thursday' || 'holy_friday' || 'holy_saturday':
      ComplineDefinition complineDefinition = ComplineDefinition(
          dayOfWeek: 'sunday',
          liturgicalTime: 'LentTime',
          celebrationType: celebrationTitle,
          priority: 1);
      return complineDefined = {celebrationTitle: complineDefinition};
    case 'ashes':
      ComplineDefinition complineDefinition = ComplineDefinition(
          dayOfWeek: 'wednesday',
          liturgicalTime: 'OrdinaryTime',
          celebrationType: 'normal',
          priority: 13);
      return complineDefined = {celebrationTitle: complineDefinition};
  }
  if (celebrationTitle.toLowerCase().contains('sunday')) {
    // si c'est affiché comme un dimanche, (donc qu'il n'y a pas de solenmité "majeure" qui l'a remplacé),
    // ajouter une solemnité si elle existe dans la liste du jour (priority).
    for (var entry in todayContent.priority.entries) {
      if (entry.key <= 4) {
        ComplineDefinition complineDefinition = ComplineDefinition(
            dayOfWeek: todayName,
            liturgicalTime: liturgicalTime,
            celebrationType: 'Solemnity',
            priority: entry.key);
        return complineDefined = {entry.value[0]: complineDefinition};
      }
    }
    ComplineDefinition complineDefinition = ComplineDefinition(
        dayOfWeek: todayName,
        liturgicalTime: liturgicalTime,
        celebrationType: 'normal',
        priority: 5);
    return complineDefined = {celebrationTitle: complineDefinition};
  }
  // add other cases: Complines of the day and solemnity in the week
  if (liturgicalGrade <= 4) {
    // firstable: major solemnities (in the root of the day Calendar)
    ComplineDefinition complineDefinition = ComplineDefinition(
        dayOfWeek: 'sunday',
        liturgicalTime: liturgicalTime,
        celebrationType: 'Solemnity',
        priority: liturgicalGrade);
    return complineDefined = {celebrationTitle: complineDefinition};
  }
  // the the added solemnities (in a sub directory of the Calendar)
  for (var entry in todayContent.priority.entries) {
    if (entry.key <= 4) {
      ComplineDefinition complineDefinition = ComplineDefinition(
          dayOfWeek: 'sunday',
          liturgicalTime: liturgicalTime,
          celebrationType: 'Solemnity',
          priority: entry.key);
      return complineDefined = {entry.value[0]: complineDefinition};
    }
  }
// concluding with the simple Complies if the day
  ComplineDefinition complineDefinition = ComplineDefinition(
      dayOfWeek: todayName,
      liturgicalTime: liturgicalTime,
      celebrationType: 'normal',
      priority: liturgicalGrade);
  return complineDefined = {todayName: complineDefinition};
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
  // replacement of default Complines elements by specifics ones
  return Compline(
    complineCommentary: override.complineCommentary ?? base.complineCommentary,
    celebrationType: override.celebrationType ?? base.celebrationType,
    complineHymns: override.complineHymns ?? base.complineHymns,
    complinePsalm1Antiphon:
        override.complinePsalm1Antiphon ?? base.complinePsalm1Antiphon,
    complinePsalm1Antiphon2:
        override.complinePsalm1Antiphon2 ?? base.complinePsalm1Antiphon2,
    complinePsalm1: override.complinePsalm1 ?? base.complinePsalm1,
    complinePsalm2Antiphon:
        override.complinePsalm2Antiphon ?? base.complinePsalm2Antiphon,
    complinePsalm2Antiphon2:
        override.complinePsalm2Antiphon2 ?? base.complinePsalm2Antiphon2,
    complinePsalm2: override.complinePsalm2 ?? base.complinePsalm2,
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
  // Complines text display (temporary)
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
  print('Psalm 1 Antiphon 1: ${compline.complinePsalm1Antiphon}');
  print('Psalm 1 Antiphon 2: ${compline.complinePsalm1Antiphon2}');
  print('Psalm 1 title: ${psalms[compline.complinePsalm1]!.getTitle}');
  print('Psalm 1 subtitle: ${psalms[compline.complinePsalm1]!.getSubtitle}');
  print(
      'Psalm 1 commentary: ${psalms[compline.complinePsalm1]!.getCommentary}');
  print(
      'Psalm 1 biblical reference: ${psalms[compline.complinePsalm1]!.getBiblicalReference}');
  print('Psalm 1 content: ${psalms[compline.complinePsalm1]!.getContent}');

  if (compline.complinePsalm2 != "") {
    print('Psalm 2 Antiphon 1: ${compline.complinePsalm2Antiphon}');
    print('Psalm 2 Antiphon 2: ${compline.complinePsalm2Antiphon2}');
    print('Psalm 2 title: ${psalms[compline.complinePsalm1]!.getTitle}');
    print('Psalm 2 subtitle: ${psalms[compline.complinePsalm1]!.getSubtitle}');
    print(
        'Psalm 2 commentary: ${psalms[compline.complinePsalm1]!.getCommentary}');
    print(
        'Psalm 2 biblical reference: ${psalms[compline.complinePsalm1]!.getBiblicalReference}');
    print('Psalm 2 content: ${psalms[compline.complinePsalm1]!.getContent}');
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
/*
String exportComplineToAelfJson(Calendar calendar, DateTime date) {
  final complineDef = complineDefinitionResolution(calendar, date);
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
      // Add more fields as needed from calendar or day content
    },
    'complies': {
      'introduction': fixedTexts["officeIntroduction"],
      'hymne': hymnJson,
      'antienne_1': compline.complinePsalm1Antiphon,
      'psaume_1': {
        'reference': psalms[compline.complinePsalm1]?.getTitle,
        'texte': compline.complinePsalm1 != null
            ? psalms[compline.complinePsalm1]?.getContent
            : null,
      },
      'antienne_2': compline.complinePsalm2Antiphon,
      'psaume_2':
          compline.complinePsalm2 != null && compline.complinePsalm2 != ''
              ? {
                  'reference': psalms[compline.complinePsalm1]?.getTitle,
                  'texte': psalms[compline.complinePsalm2]?.getContent,
                }
              : null,
      'pericope': {
        'reference': compline.complineReadingRef,
        'texte': compline.complineReading,
      },
      'repons': compline.complineResponsory,
      'antienne_symeon': compline.complineEvangelicAntiphon,
      'cantique_symeon': null, // Not provided in the original code
      'oraison': compline.complineOration?.join('\n'),
      'benediction': fixedTexts['complineConclusion'],
      'hymne_mariale': marialHymnJson,
    }
  };

  final jsonString = JsonEncoder.withIndent('  ').convert(jsonMap);
  return jsonString;
}
*/
