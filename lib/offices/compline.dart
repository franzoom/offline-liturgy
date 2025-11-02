import '../classes/calendar_class.dart'; // Calendar class
import '../classes/compline_class.dart';
import '../assets/compline/compline_default.dart';
import '../assets/compline/compline_paschal_time.dart';
import '../assets/compline/compline_lent_time.dart';
import '../assets/compline/compline_solemnity_lent_time.dart';
import '../assets/compline/compline_solemnity_paschal_time.dart';
import '../assets/compline/compline_solmenity_ordinary_time.dart';
import '../assets/compline/compline_advent_time.dart';
import '../assets/compline/compline_christmas_time.dart';
import '../tools/date_tools.dart';
import 'compline_detection.dart';

Map<String, ComplineDefinition> complineDefinitionResolution(
    Calendar calendar, DateTime date) {
  /// Resolves the Complines choice for a given day.
  /// Returns a list of possible Complines maps.
  /// Usually returns only today's Complines,
  /// but if tomorrow is a Solemnity or Sunday, includes Solemnity Eve Complines.
  /// If today has multiple celebrations (Sunday + Solemnity), returns all options.

  Map<String, ComplineDefinition> todayComplineDefinition =
      complineDetection(calendar, date);
  Map<String, ComplineDefinition> tomorrowComplineDefinition =
      complineDetection(calendar, dayShift(date, 1));

  Map<String, ComplineDefinition> possibleComplines = todayComplineDefinition;

  // Check if today is a Solemnity
  bool todayIsSolemnity = todayComplineDefinition.entries
      .any((entry) => entry.value.celebrationType == 'Solemnity');

  // work on tommorow's potential Complines :
  // Check if tomorrow requires Eve Complines (Solemnity or Sunday)
  // and adapt their datas to be considered as Eve (using saturdays's office)
  bool tomorrowNeedsEveComplines = false;
  final confirmedTomorrowComplineDefinition = <String, ComplineDefinition>{};
  for (var entry in tomorrowComplineDefinition.entries) {
    final value = entry.value;
    if (value.dayOfWeek.toLowerCase() == 'sunday') {
      tomorrowNeedsEveComplines = true;
      confirmedTomorrowComplineDefinition[entry.key] = ComplineDefinition(
        dayOfWeek: 'saturday',
        liturgicalTime: value.liturgicalTime,
        celebrationType: 'SundayEve',
        priority: value.priority,
      );
    } else if (value.celebrationType == 'Solemnity') {
      tomorrowNeedsEveComplines = true;
      confirmedTomorrowComplineDefinition[entry.key] = ComplineDefinition(
        dayOfWeek: 'saturday',
        liturgicalTime: value.liturgicalTime,
        celebrationType: 'SolemnityEve',
        priority: value.priority,
      );
    }
  }

  // Decision logic
  if (tomorrowNeedsEveComplines && todayIsSolemnity) {
    // Both options: today's Solemnity Complines AND Solemnity/Sunday Eve Complines
    // ==> adds the eve's Complines to the already existing today's Complines.
    possibleComplines.addAll(confirmedTomorrowComplineDefinition);
  } else if (tomorrowNeedsEveComplines) {
    // Only Solemnity/Sunday Eve Complines: juste keep the Eve Complines
    possibleComplines = confirmedTomorrowComplineDefinition;
  }
  return possibleComplines;
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
