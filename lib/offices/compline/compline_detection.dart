import '../../classes/calendar_class.dart';
import '../../classes/compline_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/date_tools.dart';
import '../../tools/constants.dart';
import '../office_detection.dart';
import '../../assets/libraries/french_liturgy_labels.dart';

/// Determines the celebration type for Compline based on precedence and code
String _detectCelebrationType(int precedence, String celebrationCode) {
  if (holyWeekCodes.contains(celebrationCode.toLowerCase())) {
    return celebrationCode.toLowerCase();
  }
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
    _ when date.weekday == DateTime.sunday => 'sunday',
    _ => dayName[date.weekday],
  };
}

/// Returns a map of possible Compline Offices, filtered and sorted by precedence
Future<Map<String, ComplineDefinition>> complineDetection(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
) async {
  final Map<String, ComplineDefinition> possibleComplines = {};

  final dayContent = calendar.getDayContent(date);
  if (dayContent == null) return possibleComplines;

  final String liturgicalTime = dayContent.liturgicalTime;
  final String todayName = dayName[date.weekday];

  // --- Special case for octaves ---
  if (liturgicalTime == 'christmasoctave' ||
      liturgicalTime == 'paschaloctave') {
    possibleComplines['Complies du samedi'] = ComplineDefinition(
      context: CelebrationContext(
        celebrationCode: dayContent.defaultCelebrationTitle,
        ferialCode: dayContent.defaultCelebrationTitle,
        date: date,
        liturgicalTime: liturgicalTime,
        precedence: 8,
        liturgicalColor: dayContent.liturgicalColor,
        isCelebrable: true,
        celebrationType: 'solemnityeve',
        officeDescription: 'Complies du samedi',
        dataLoader: dataLoader,
      ),
      dayOfCompline: 'saturday',
    );
    possibleComplines['Complies du dimanche'] = ComplineDefinition(
      context: CelebrationContext(
        celebrationCode: dayContent.defaultCelebrationTitle,
        ferialCode: dayContent.defaultCelebrationTitle,
        date: date,
        liturgicalTime: liturgicalTime,
        precedence: 8,
        liturgicalColor: dayContent.liturgicalColor,
        isCelebrable: true,
        celebrationType: 'solemnity',
        officeDescription: 'Complies du dimanche',
        dataLoader: dataLoader,
      ),
      dayOfCompline: 'sunday',
    );
    return possibleComplines;
  }

  // 1. Detect celebrations (today and tomorrow in parallel)
  final tomorrow = date.shift(1);
  final [rawTodayCelebrations, tomorrowCelebrations] = await Future.wait([
    detectCelebrations(calendar, date, dataLoader),
    detectCelebrations(calendar, tomorrow, dataLoader),
  ]);

  // --- Special case: Holy Friday and Holy Saturday have their own Compline, no other option ---
  const triduumComplineCodes = {'holy_friday', 'holy_saturday'};
  final holyWeekCelebration = rawTodayCelebrations
      .where((c) => triduumComplineCodes.contains(c.celebrationCode))
      .firstOrNull;
  if (holyWeekCelebration != null) {
    final c = holyWeekCelebration;
    final celebrationType =
        _detectCelebrationType(c.precedence ?? 1, c.celebrationCode);
    final dayOfCompline = _detectDayOfWeek(date, celebrationType);
    final description = 'Complies – ${c.celebrationGlobalName}';
    possibleComplines[description] = ComplineDefinition(
      context: CelebrationContext(
        celebrationCode: c.celebrationCode,
        ferialCode: c.ferialCode ?? '',
        date: date,
        liturgicalTime: liturgicalTime,
        precedence: c.precedence ?? 1,
        liturgicalColor: c.liturgicalColor ?? 'purple',
        isCelebrable: true,
        celebrationType: celebrationType,
        officeDescription: description,
        dataLoader: dataLoader,
      ),
      dayOfCompline: dayOfCompline,
    );
    return possibleComplines;
  }

  // 2. Precedence Filter (Today): If any celebration is <= 4, remove all those > 4
  final bool todayHasSolemnity =
      rawTodayCelebrations.any((c) => (c.precedence ?? 13) <= 4);
  final todayCelebrations = todayHasSolemnity
      ? rawTodayCelebrations.where((c) => (c.precedence ?? 13) <= 4).toList()
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

    possibleComplines[description] = ComplineDefinition(
      context: CelebrationContext(
        celebrationCode: c.celebrationCode,
        ferialCode: c.ferialCode ?? '',
        date: date,
        liturgicalTime: liturgicalTime,
        precedence: precedence,
        liturgicalColor: c.liturgicalColor ?? 'green',
        isCelebrable: c.isCelebrable,
        celebrationType: celebrationType,
        officeDescription: description,
        dataLoader: dataLoader,
      ),
      dayOfCompline: dayOfCompline,
      isEveCompline: false,
    );
  }

  // 4. Process tomorrow's celebrations for eve Complines
  // No eve compline when tomorrow is a Holy Week Triduum day
  // No eve compline for ferial days (even high-precedence ones like Ash Wednesday)
  final bool tomorrowIsHolyWeek = tomorrowCelebrations
      .any((c) => holyWeekCodes.contains(c.celebrationCode));
  final bool isTomorrowSunday = tomorrow.weekday == DateTime.sunday;
  bool tomorrowHasSolemnity = false;

  if (!tomorrowIsHolyWeek) {
    for (final c in tomorrowCelebrations) {
      if (ferialDayCheck(c.celebrationCode)) continue;
      final int precedence = c.precedence ?? 13;
      final bool isTomorrowSolemnity = precedence <= 4;
      final bool needsEveCompline = isTomorrowSolemnity;

      if (needsEveCompline) {
        if (isTomorrowSolemnity) tomorrowHasSolemnity = true;

        final String eveDescription =
            'Complies de la veille de ${c.celebrationGlobalName}';
        final String eveCelebrationType =
            isTomorrowSolemnity ? 'solemnityeve' : 'normal';

        possibleComplines[eveDescription] = ComplineDefinition(
          context: CelebrationContext(
            celebrationCode: c.celebrationCode,
            ferialCode: c.ferialCode ?? '',
            date: date,
            liturgicalTime: liturgicalTime,
            precedence: precedence,
            liturgicalColor: c.liturgicalColor ?? 'green',
            isCelebrable: true,
            celebrationType: eveCelebrationType,
            officeDescription: eveDescription,
            dataLoader: dataLoader,
          ),
          dayOfCompline: 'saturday',
          isEveCompline: true,
        );
      }
    }
  }

  // 5. Final cleaning: If tomorrow is a solemnity and today is not (and not a sunday),
  // the eve supersedes today's ferial Compline.
  if (tomorrowHasSolemnity && !todayHasSolemnity) {
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
