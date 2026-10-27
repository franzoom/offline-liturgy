import '../../classes/calendar_class.dart';
import '../../classes/compline_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/date_tools.dart';
import '../../tools/constants.dart';
import '../office_detection.dart';
import '../../assets/libraries/french_liturgy_labels.dart';

/// Celebrations ranked with the solemnities whose Compline is still the
/// day's, with no eve Compline: the Commemoration of All the Faithful
/// Departed (Nov 2).
const _complineOfTheDayCodes = {
  'roman/commemoration_of_all_the_faithful_departed',
};

/// Determines the celebration type for Compline based on precedence and code
String _detectCelebrationType(int precedence, String celebrationCode) {
  final triduumLabel = triduumCodes[celebrationCode];
  if (triduumLabel != null) return triduumLabel;
  if (_complineOfTheDayCodes.contains(celebrationCode)) return 'normal';
  // Ferial days (including Sundays of Lent, Advent, etc.) are never solemnities,
  // even if their liturgical rank (precedence) is high.
  if (ferialDayCheck(celebrationCode)) return 'normal';
  return (precedence <= 4) ? 'solemnity' : 'normal';
}

/// Determines the day of week to use for Compline psalms
String _detectDayOfWeek(DateTime date, String celebrationType) {
  return switch (celebrationType) {
    'solemnityeve' => 'saturday', // Psalms for Sunday I
    'solemnity' => 'sunday', // Psalms for Sunday II
    _ => dayName[date.weekday],
  };
}

/// Returns a map of possible Compline Offices, filtered and sorted by precedence
///
/// [precedenceOverride] gives a celebration of today or tomorrow another
/// rank: a local solemnity has its own Compline, or that of its eve.
Future<Map<String, ComplineDefinition>> complineDetection(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader, {
  PrecedenceOverride? precedenceOverride,
}) async {
  final Map<String, ComplineDefinition> possibleComplines = {};

  final dayContent = calendar.getDayContent(date);
  if (dayContent == null) return possibleComplines;

  // The Saturday before the 1st Sunday of Advent already belongs to Advent
  // from its First Vespers on, and so do its Complines (season and color).
  final tomorrowContent = calendar.getDayContent(date.shift(1));
  final bool isAdventEve = dayContent.liturgicalTime != 'advent' &&
      tomorrowContent?.liturgicalTime == 'advent';
  final String liturgicalTime =
      isAdventEve ? 'advent' : dayContent.liturgicalTime;
  final String todayName = dayName[date.weekday];

  // --- Special case for octaves ---
  if (liturgicalTime == 'christmasoctave' ||
      liturgicalTime == 'paschaloctave') {
    // Either Sunday Compline may be prayed on any day of the octave
    ComplineDefinition octaveCompline(
            String description, String celebrationType, String dayOfCompline) =>
        ComplineDefinition(
          context: CelebrationContext(
            celebrationCode: dayContent.defaultCelebrationTitle,
            ferialCode: dayContent.defaultCelebrationTitle,
            date: date,
            liturgicalTime: liturgicalTime,
            precedence: 8,
            liturgicalColor: dayContent.liturgicalColor,
            isCelebrable: true,
            celebrationType: celebrationType,
            officeDescription: description,
            dataLoader: dataLoader,
          ),
          dayOfCompline: dayOfCompline,
        );
    return {
      'Complies du samedi':
          octaveCompline('Complies du samedi', 'solemnityeve', 'saturday'),
      'Complies du dimanche':
          octaveCompline('Complies du dimanche', 'solemnity', 'sunday'),
    };
  }

  // 1. Detect celebrations (today and tomorrow in parallel)
  final tomorrow = date.shift(1);
  final (today: rawTodayCelebrations, tomorrow: tomorrowCelebrations) =
      await detectTodayAndTomorrow(calendar, date, dataLoader,
          precedenceOverride: precedenceOverride);

  // A Compline option prayed this evening for celebration [c]
  ComplineDefinition complineOf(
    CelebrationContext c, {
    required int precedence,
    required String celebrationType,
    required String description,
    required String dayOfCompline,
    bool isCelebrable = true,
    bool isEveCompline = false,
    String defaultColor = 'green',
  }) =>
      ComplineDefinition(
        context: c.copyWith(
          date: date,
          liturgicalTime: liturgicalTime,
          precedence: precedence,
          liturgicalColor: isAdventEve && ferialDayCheck(c.celebrationCode)
              ? tomorrowContent!.liturgicalColor
              : c.liturgicalColor ?? defaultColor,
          isCelebrable: isCelebrable,
          celebrationType: celebrationType,
          officeDescription: description,
        ),
        dayOfCompline: dayOfCompline,
        isEveCompline: isEveCompline,
      );

  // --- Special case: the Triduum days have their own Compline, no other option ---
  final holyWeekCelebration = triduumCelebration(rawTodayCelebrations);
  if (holyWeekCelebration != null) {
    final c = holyWeekCelebration;
    final precedence = c.precedence ?? 1;
    final celebrationType =
        _detectCelebrationType(precedence, c.celebrationCode);
    final description = 'Complies – ${c.celebrationGlobalName}';
    return {
      description: complineOf(c,
          precedence: precedence,
          celebrationType: celebrationType,
          description: description,
          dayOfCompline: _detectDayOfWeek(date, celebrationType),
          defaultColor: 'purple'),
    };
  }

  // 2. Precedence Filter (Today): If any celebration is <= 4, remove all those > 4,
  // except a Sunday still celebrable beside the solemnity (e.g. the 30th
  // Sunday in a church whose dedication date is known)
  final bool todayHasSolemnity =
      rawTodayCelebrations.any((c) => (c.precedence ?? 13) <= 4);
  final todayCelebrations = todayHasSolemnity
      ? rawTodayCelebrations
          .where((c) =>
              (c.precedence ?? 13) <= 4 ||
              (c.isCelebrable && ferialDayCheck(c.celebrationCode)))
          .toList()
      : rawTodayCelebrations;

  // 3. Process today's celebrations
  // Only solemnities and ferial days produce distinct complines;
  // memorials and feasts use the same compline as the ferial day
  for (final c in todayCelebrations) {
    final int precedence = c.precedence ?? 13;
    if (!ferialDayCheck(c.celebrationCode) && precedence > 4) continue;
    final celebrationType =
        _detectCelebrationType(precedence, c.celebrationCode);
    final dayOfCompline = _detectDayOfWeek(date, celebrationType);

    final description = celebrationType == 'solemnity'
        ? 'Complies de ${c.celebrationGlobalName}'
        : [
            'Complies du ${dayOfWeekLabels[todayName]}',
            if (liturgicalTimeLabelsDative[liturgicalTime] != null)
              liturgicalTimeLabelsDative[liturgicalTime]!,
          ].join(' ');

    possibleComplines[description] = complineOf(c,
        precedence: precedence,
        celebrationType: celebrationType,
        description: description,
        dayOfCompline: dayOfCompline,
        isCelebrable: c.isCelebrable);
  }

  // 4. Process tomorrow's celebrations for eve Complines
  // No eve compline when tomorrow is a Holy Week Triduum day
  // No eve compline for ferial days (even high-precedence ones like Ash Wednesday)
  final bool tomorrowIsHolyWeek =
      triduumCelebration(tomorrowCelebrations) != null;
  final bool isTomorrowSunday = tomorrow.weekday == DateTime.sunday;
  bool tomorrowHasSolemnity = false;

  if (!tomorrowIsHolyWeek) {
    for (final c in tomorrowCelebrations) {
      if (ferialDayCheck(c.celebrationCode) ||
          _complineOfTheDayCodes.contains(c.celebrationCode)) {
        continue;
      }
      final int precedence = c.precedence ?? 13;
      // Only a solemnity has the Compline of its eve
      if (precedence > 4) continue;
      tomorrowHasSolemnity = true;

      final String eveDescription =
          'Complies de la veille de ${c.celebrationGlobalName}';
      possibleComplines[eveDescription] = complineOf(c,
          precedence: precedence,
          celebrationType: 'solemnityeve',
          description: eveDescription,
          dayOfCompline: 'saturday',
          isEveCompline: true);
    }
  }

  // 5. Final cleaning: If tomorrow is a solemnity and today is not (and not a sunday),
  // the eve supersedes today's ferial Compline — unless tomorrow's Sunday stays
  // celebrable beside the solemnity: today's Saturday Compline is then its eve's.
  final bool tomorrowSundayCelebrable = isTomorrowSunday &&
      tomorrowCelebrations
          .any((c) => c.isCelebrable && ferialDayCheck(c.celebrationCode));
  if (tomorrowHasSolemnity && !todayHasSolemnity && !tomorrowSundayCelebrable) {
    possibleComplines.removeWhere((key, value) => !value.isEveCompline);
  }

  // 6. Final sorting
  // Sunday eve complines (first vespers) rank above celebrations with precedence >= 4
  final sortedEntries = possibleComplines.entries.toList()
    ..sort((a, b) {
      if (isTomorrowSunday) {
        if (a.value.isEveCompline && b.value.precedence >= 4) return -1;
        if (b.value.isEveCompline && a.value.precedence >= 4) return 1;
      }
      return a.value.precedence.compareTo(b.value.precedence);
    });

  return Map.fromEntries(sortedEntries);
}
