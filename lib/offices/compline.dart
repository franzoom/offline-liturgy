import '../classes/calendar_class.dart'; // Calendar class
import '../classes/compline_class.dart';
import '../assets/compline/compline_default.dart';
import '../assets/compline/compline_paschal_time.dart';
import '../assets/compline/compline_lent_time.dart';
import '../assets/compline/compline_solemnity_lent_time.dart';
import '../assets/compline/compline_solemnity_paschal_time.dart';
import '../assets/compline/compline_solemnity_ordinary_time.dart';
import '../assets/compline/compline_solemnity_advent_christmas.dart';
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
      .any((entry) => entry.value.celebrationType == 'solemnity');

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
        complineDescription: 'Complies de la veille du dimanche',
        dayOfWeek: 'saturday',
        liturgicalTime: value.liturgicalTime,
        celebrationType: 'normal',
        priority: value.priority,
      );
    } else if (value.celebrationType == 'solemnity') {
      tomorrowNeedsEveComplines = true;
      confirmedTomorrowComplineDefinition[entry.key] = ComplineDefinition(
        complineDescription: 'Complies de la veille de solennité',
        dayOfWeek: 'saturday',
        liturgicalTime: value.liturgicalTime,
        celebrationType: 'solemnityeve',
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
  switch (complineDefinition.celebrationType.toLowerCase()) {
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
    case 'sunday':
      // Use Sunday Complines (same as normal but with Sunday day)
      dayName = 'sunday';
      dayCompline = defaultCompline[dayName];
      switch (complineDefinition.liturgicalTime.toLowerCase()) {
        case 'ordinarytime':
          correctionCompline = dayCompline;
          break;
        case 'lenttime':
          correctionCompline = lentTimeCompline[dayName];
          break;
        case 'paschaltime':
          correctionCompline = paschalTimeCompline[dayName];
          break;
        case 'adventtime':
          correctionCompline = adventTimeCompline[dayName];
          break;
        case 'christmasoctave':
        case 'christmastime':
          correctionCompline = christmasTimeCompline[dayName];
          break;
        default:
          correctionCompline = dayCompline;
      }
      correctionCompline?.celebrationType = complineDefinition.celebrationType;
      break;
    case 'normal':
      // Use the day of the week for Ordinary Time
      switch (complineDefinition.liturgicalTime.toLowerCase()) {
        case 'ordinarytime':
          return dayCompline;
        case 'lenttime':
          correctionCompline = lentTimeCompline[day];
          break;
        case 'paschaltime':
          correctionCompline = paschalTimeCompline[day];
          break;
        case 'adventtime':
          correctionCompline = adventTimeCompline[day];
          break;
        case 'christmastime':
          correctionCompline = christmasTimeCompline[day];
          break;
        default:
          correctionCompline = dayCompline;
      }
      correctionCompline?.celebrationType = complineDefinition.celebrationType;
      break;
    case 'solemnity':
    case 'solemnityeve':
      dayName = complineDefinition.celebrationType.toLowerCase() == 'solemnity'
          ? 'sunday'
          : 'saturday';
      dayCompline = defaultCompline[dayName];
      switch (complineDefinition.liturgicalTime) {
        case 'ordinarytime':
          correctionCompline = solemnityComplineOrdinaryTime[dayName];
          break;
        case 'lenttime':
          correctionCompline = solemnityComplineLentTime[dayName];
          break;
        case 'paschaltime':
          correctionCompline = solemnityComplinePaschalTime[dayName];
          break;
        case 'adventtime':
        case 'christmastime':
          correctionCompline = solemnityComplineAdventChristmas[dayName];
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
    commentary: override.commentary ?? base.commentary,
    celebrationType: override.celebrationType ?? base.celebrationType,
    hymns: override.hymns ?? base.hymns,
    psalmody: override.psalmody ?? base.psalmody,
    reading: override.reading ?? base.reading,
    responsory: override.responsory ?? base.responsory,
    evangelicAntiphon: override.evangelicAntiphon ?? base.evangelicAntiphon,
    oration: override.oration ?? base.oration,
    marialHymnRef: override.marialHymnRef ?? base.marialHymnRef,
  );
}
