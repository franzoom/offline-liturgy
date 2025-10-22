import '../classes/calendar_class.dart'; // Calendar class
import '../classes/compline_class.dart';
import '../assets/libraries/psalms_library.dart';
import '../assets/libraries/hymns_library.dart';
import '../assets/libraries/fixed_texts_library.dart';
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
import 'dart:convert';

List<Map<String, ComplineDefinition>> complineDefinitionResolution(
    Calendar calendar, DateTime date) {
  /// Resolves the Complines choice for a given day.
  /// Returns a list of possible Complines maps.
  /// Usually returns only today's Complines,
  /// but if tomorrow is a Solemnity or Sunday, includes Solemnity Eve Complines.
  /// If today has multiple celebrations (Sunday + Solemnity), returns all options.

  List<Map<String, ComplineDefinition>> possibleComplines = [];

  Map<String, ComplineDefinition> todayComplineDefinition =
      complineDetection(calendar, date);
  Map<String, ComplineDefinition> tomorrowComplineDefinition =
      complineDetection(calendar, dayShift(date, 1));

  // If today has multiple Complines (e.g., Sunday + Solemnity), add them all
  if (todayComplineDefinition.length > 1) {
    for (var entry in todayComplineDefinition.entries) {
      possibleComplines.add({entry.key: entry.value});
    }
    return possibleComplines;
  }

  // Check if today is a Solemnity
  bool todayIsSolemnity = todayComplineDefinition.entries
      .any((entry) => entry.value.celebrationType == 'Solemnity');

  // Check if tomorrow requires Eve Complines (Solemnity OR Sunday with higher priority)
  bool tomorrowNeedsEveComplines = false;
  MapEntry? tomorrowEntry;

  for (var entry in tomorrowComplineDefinition.entries) {
    bool isSolemnity = entry.value.celebrationType == 'Solemnity';
    bool isSunday = entry.value.dayOfWeek == 'sunday';
    bool hasHigherPriority = entry.value.priority <
        todayComplineDefinition.entries.first.value.priority;

    if ((isSolemnity || isSunday) && hasHigherPriority) {
      tomorrowNeedsEveComplines = true;
      tomorrowEntry = entry;
      break;
    }
  }

  // Decision logic
  if (tomorrowNeedsEveComplines && todayIsSolemnity) {
    // Both options: today's Solemnity Complines AND Solemnity/Sunday Eve Complines
    possibleComplines.add(todayComplineDefinition);
    ComplineDefinition eveComplineDefinition = ComplineDefinition(
      dayOfWeek: 'saturday',
      liturgicalTime: tomorrowEntry!.value.liturgicalTime,
      celebrationType: 'SolemnityEve',
      priority: tomorrowEntry.value.priority,
    );
    possibleComplines.add({tomorrowEntry.key: eveComplineDefinition});
  } else if (tomorrowNeedsEveComplines) {
    // Only Solemnity/Sunday Eve Complines
    ComplineDefinition eveComplineDefinition = ComplineDefinition(
      dayOfWeek: 'saturday',
      liturgicalTime: tomorrowEntry!.value.liturgicalTime,
      celebrationType: 'SolemnityEve',
      priority: tomorrowEntry.value.priority,
    );
    possibleComplines.add({tomorrowEntry.key: eveComplineDefinition});
  } else {
    // Default: today's Complines
    possibleComplines.add(todayComplineDefinition);
  }

  return possibleComplines;
}

Map<String, ComplineDefinition> complineDetection(
    Calendar calendar, DateTime date) {
  /// Detection of which Compline to use for a given day.
  /// Returns a Map "day or feast name" : ComplineDefinition
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
    // If displayed as a Sunday, check if there's also a solemnity
    bool hasSolemnity = false;
    for (var entry in todayContent.priority.entries) {
      if (entry.key <= 4) {
        // Add the Solemnity Compline option
        ComplineDefinition solemnityComplineDefinition = ComplineDefinition(
            dayOfWeek: todayName,
            liturgicalTime: liturgicalTime,
            celebrationType: 'Solemnity',
            priority: entry.key);
        complineDefined[entry.value[0]] = solemnityComplineDefinition;
        hasSolemnity = true;
        break;
      }
    }
    // Always add the Sunday Compline option
    ComplineDefinition sundayComplineDefinition = ComplineDefinition(
        dayOfWeek: todayName,
        liturgicalTime: liturgicalTime,
        celebrationType: hasSolemnity ? 'Sunday' : 'normal',
        priority: 5);
    complineDefined[celebrationTitle] = sundayComplineDefinition;
    return complineDefined;
  }
  // Add other cases: Complines of the day and solemnity in the week
  if (liturgicalGrade <= 4) {
    // Firstly: major solemnities (in the root of the day Calendar)
    ComplineDefinition complineDefinition = ComplineDefinition(
        dayOfWeek: 'sunday',
        liturgicalTime: liturgicalTime,
        celebrationType: 'Solemnity',
        priority: liturgicalGrade);
    return complineDefined = {celebrationTitle: complineDefinition};
  }
  // Then the added solemnities (in a sub directory of the Calendar)
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
  // Concluding with the simple Complines of the day
  ComplineDefinition complineDefinition = ComplineDefinition(
      dayOfWeek: todayName,
      liturgicalTime: liturgicalTime,
      celebrationType: 'normal',
      priority: liturgicalGrade);
  return complineDefined = {todayName: complineDefinition};
}

Map<String, Compline> complineTextCompilation(
    Map<String, ComplineDefinition> complineDefinitionExported) {
  // Returns the list of compiled Complines from Compline definitions
  // using the getComplineText function.
  // The Map key is the name of the Compline (day or feast)
  // and the value is the text of the Compline.
  return complineDefinitionExported.map((key, value) {
    // Transform each value with getComplineText
    final complineText = getComplineText(value);
    return MapEntry(key, complineText!);
  });
}

Compline? getComplineText(ComplineDefinition complineDefinition) {
  // From the Compline definition, returns the text of the Compline
  // following the Compline class.
  String day = complineDefinition.dayOfWeek;
  Compline? dayCompline = defaultCompline[day];
  Compline? correctionCompline;
  String dayName;
  switch (complineDefinition.celebrationType) {
    case 'holy_thursday':
      // Use Holy Thursday for the Triduum
      correctionCompline = lentTimeCompline['holy_thursday'];
      break;
    case 'holy_friday':
      // Use Holy Friday for the Triduum
      correctionCompline = lentTimeCompline['holy_friday'];
      break;
    case 'holy_saturday':
      // Use Holy Saturday for the Triduum
      correctionCompline = lentTimeCompline['holy_saturday'];
      break;
    case 'Sunday':
      // Use Sunday Complines (same as normal but with Sunday day)
      dayName = 'sunday';
      dayCompline = defaultCompline[dayName];
      switch (complineDefinition.liturgicalTime) {
        case 'OrdinaryTime':
          correctionCompline = dayCompline;
          break;
        case 'LentTime':
          correctionCompline = lentTimeCompline[dayName];
          break;
        case 'PaschalTime':
          correctionCompline = paschalTimeCompline[dayName];
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
    case 'normal':
      // Use the day of the week for Ordinary Time
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
  // Replacement of default Complines elements by specific ones
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
    print('Commentary: ${compline.complineCommentary ?? "No commentary"}');
  }
  if (compline.celebrationType != null &&
      compline.celebrationType != 'normal') {
    print('Celebration Type: ${compline.celebrationType}');
  }
  print('------ HYMNS ------');
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
  print('------ MARIAN HYMNS ------');
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
