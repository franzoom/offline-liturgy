import '../../classes/calendar_class.dart';
import '../../classes/compline_class.dart';
import '../../assets/compline/compline_default.dart';
import '../../assets/compline/compline_paschal_time.dart';
import '../../assets/compline/compline_lent_time.dart';
import '../../assets/compline/compline_solemnity_lent_time.dart';
import '../../assets/compline/compline_solemnity_paschal_time.dart';
import '../../assets/compline/compline_solemnity_ordinary_time.dart';
import '../../assets/compline/compline_solemnity_advent_christmas.dart';
import '../../assets/compline/compline_advent_time.dart';
import '../../assets/compline/compline_christmas_time.dart';
import '../../tools/date_tools.dart';
import '../../tools/data_loader.dart';
import 'compline_detection.dart';

Future<Map<String, ComplineDefinition>> complineResolution(
    Calendar calendar, DateTime date, DataLoader dataLoader) async {
  /// Resolves the Complines choice for a given day.
  /// Returns a list of possible Complines maps.
  /// Usually returns only today's Complines,
  /// but if tomorrow is a Solemnity or Sunday, includes Solemnity Eve Complines.
  /// If today has multiple celebrations (Sunday + Solemnity), returns all options.

  Map<String, ComplineDefinition> todayComplineDefinition =
      await complineDetection(calendar, date, dataLoader);
  Map<String, ComplineDefinition> tomorrowComplineDefinition =
      await complineDetection(calendar, dayShift(date, 1), dataLoader);

  Map<String, ComplineDefinition> possibleComplines = todayComplineDefinition;

  // Check if today is a Solemnity or sunday
  bool todayIsSolemnity = todayComplineDefinition.entries.any((entry) =>
      entry.value.celebrationType == 'solemnity' ||
      entry.value.dayOfWeek == 'sunday');

  // work on tommorow's potential Complines :
  // Check if tomorrow requires Eve Complines (Solemnity or Sunday)
  // and adapt their datas to be considered as Eve
  // (using saturdays's office according to the liturgical time)
  bool tomorrowNeedsEveComplines = false;
  Map<String, ComplineDefinition> eveComplineDefinition = {};
  for (var entry in tomorrowComplineDefinition.entries) {
    final value = entry.value;
    if (value.celebrationType == 'solemnity') {
      tomorrowNeedsEveComplines = true;
      String eveComplineDescription =
          eveStringReplacement(entry.value.complineDescription);
      eveComplineDefinition[eveComplineDescription] = ComplineDefinition(
        complineDescription: eveComplineDescription,
        dayOfWeek: 'saturday',
        liturgicalTime: value.liturgicalTime,
        celebrationType: 'solemnityeve',
        priority: value.priority,
      );
    } else if (value.dayOfWeek == 'sunday') {
      tomorrowNeedsEveComplines = true;
      String eveComplineDescription =
          eveStringReplacement(entry.value.complineDescription);
      eveComplineDefinition[eveComplineDescription] = ComplineDefinition(
        complineDescription: eveComplineDescription,
        dayOfWeek: 'saturday',
        liturgicalTime: value.liturgicalTime,
        celebrationType: 'normal',
        priority: value.priority,
      );
    }
  }

  // Decision logic
  if (tomorrowNeedsEveComplines && todayIsSolemnity) {
    // Both options: today's Solemnity Complines AND Solemnity/Sunday Eve Complines
    // ==> adds the eve's Complines to the already existing today's Complines.
    possibleComplines.addAll(eveComplineDefinition);
  } else if (tomorrowNeedsEveComplines) {
    // Only Solemnity/Sunday Eve Complines: juste keep the Eve Complines
    possibleComplines = eveComplineDefinition;
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
        case 'ot':
          correctionCompline = dayCompline;
          break;
        case 'lent':
          correctionCompline = lentTimeCompline[dayName];
          break;
        case 'paschal':
          correctionCompline = paschalTimeCompline[dayName];
          break;
        case 'advent':
          correctionCompline = adventTimeCompline[dayName];
          break;
        case 'christmasoctave':
        case 'christmas':
          correctionCompline = christmasTimeCompline[dayName];
          break;
        default:
          correctionCompline = dayCompline;
      }
      correctionCompline = correctionCompline?.copyWith(
        celebrationType: complineDefinition.celebrationType,
      );
      break;
    case 'normal':
      // Use the day of the week for Ordinary Time
      switch (complineDefinition.liturgicalTime.toLowerCase()) {
        case 'ot':
          return dayCompline;
        case 'lent':
          correctionCompline = lentTimeCompline[day];
          break;
        case 'paschal':
          correctionCompline = paschalTimeCompline[day];
          break;
        case 'advent':
          correctionCompline = adventTimeCompline[day];
          break;
        case 'christmas':
          correctionCompline = christmasTimeCompline[day];
          break;
        default:
          correctionCompline = dayCompline;
      }
      correctionCompline = correctionCompline?.copyWith(
        celebrationType: complineDefinition.celebrationType,
      );
      break;
    case 'solemnity':
    case 'solemnityeve':
      dayName = complineDefinition.celebrationType.toLowerCase() == 'solemnity'
          ? 'sunday'
          : 'saturday';
      dayCompline = defaultCompline[dayName];
      switch (complineDefinition.liturgicalTime) {
        case 'ot':
          correctionCompline = solemnityComplineOrdinaryTime[dayName];
          break;
        case 'lent':
          correctionCompline = solemnityComplineLentTime[dayName];
          break;
        case 'paschal':
          correctionCompline = solemnityComplinePaschalTime[dayName];
          break;
        case 'advent':
        case 'christmas':
          correctionCompline = solemnityComplineAdventChristmas[dayName];
          break;
        default:
          correctionCompline = dayCompline;
      }
      correctionCompline = correctionCompline?.copyWith(
        celebrationType: complineDefinition.celebrationType,
      );
      break;
    default:
      correctionCompline = dayCompline?.copyWith(
        celebrationType: complineDefinition.celebrationType,
      );
  }
  return mergeComplineDay(dayCompline!, correctionCompline!);
}

Compline mergeComplineDay(Compline base, Compline override) {
  // Replacement of default Complines elements by specific ones
  // Using copyWith for immutable merge
  return base.copyWith(
    commentary: override.commentary,
    celebrationType: override.celebrationType,
    hymns: override.hymns,
    psalmody: override.psalmody,
    reading: override.reading,
    responsory: override.responsory,
    evangelicAntiphon: override.evangelicAntiphon,
    oration: override.oration,
    marialHymnRef: override.marialHymnRef,
  );
}

String eveStringReplacement(String complineDescription) {
  return complineDescription.replaceAll(
      'Complies de', 'Complies de la veille de');
}
