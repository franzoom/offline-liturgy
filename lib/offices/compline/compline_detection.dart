import '../../classes/calendar_class.dart';
import '../../classes/compline_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/date_tools.dart';
import '../office_detection.dart';
import '../../assets/libraries/french_liturgy_labels.dart';

/// Determines the celebration type for Compline based on precedence and code
String _detectCelebrationType(int precedence, String celebrationCode) {
  if (holyWeekCodes.contains(celebrationCode.toLowerCase())) {
    return celebrationCode.toLowerCase();
  }
  return (precedence <= 4) ? 'solemnity' : 'normal';
}

/// Determines the day of week to use for Compline psalms
String _detectDayOfWeek(DateTime date, String celebrationType) {
  return switch (celebrationType) {
    'solemnityeve' => 'saturday', // Psalms for Sunday I
    'solemnity' => 'sunday', // Psalms for Sunday II
    _ when date.weekday == DateTime.sunday => 'sunday',
    _ => dayNames[date.weekday] ?? 'monday',
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
  final String todayName = dayNames[date.weekday] ?? 'monday';

  // --- Special case for octaves ---
  if (liturgicalTime == 'christmasoctave' ||
      liturgicalTime == 'paschaloctave') {
    possibleComplines['Complies du samedi'] = ComplineDefinition(
      complineDescription: 'Complies du samedi',
      celebrationCode: dayContent.defaultCelebrationTitle,
      ferialCode: dayContent.defaultCelebrationTitle,
      liturgicalTime: liturgicalTime,
      precedence: 8,
      liturgicalColor: dayContent.liturgicalColor,
      isCelebrable: true,
      dayOfCompline: 'saturday',
      celebrationType: 'solemnityeve',
    );
    possibleComplines['Complies du dimanche'] = ComplineDefinition(
      complineDescription: 'Complies du dimanche',
      celebrationCode: dayContent.defaultCelebrationTitle,
      ferialCode: dayContent.defaultCelebrationTitle,
      liturgicalTime: liturgicalTime,
      precedence: 8,
      liturgicalColor: dayContent.liturgicalColor,
      isCelebrable: true,
      dayOfCompline: 'sunday',
      celebrationType: 'solemnity',
    );
    return possibleComplines;
  }

  // 1. Detect celebrations
  final rawTodayCelebrations =
      await detectCelebrations(calendar, date, dataLoader);
  final tomorrow = date.shift(1);
  final tomorrowCelebrations =
      await detectCelebrations(calendar, tomorrow, dataLoader);

  // 2. Precedence Filter (Today): If any celebration is <= 4, remove all those > 4
  final bool todayHasSolemnity =
      rawTodayCelebrations.any((c) => (c.precedence ?? 13) <= 4);
  final todayCelebrations = todayHasSolemnity
      ? rawTodayCelebrations.where((c) => (c.precedence ?? 13) <= 4).toList()
      : rawTodayCelebrations;

  // 3. Process today's celebrations
  for (final c in todayCelebrations) {
    final int precedence = c.precedence ?? 13;
    final celebrationType =
        _detectCelebrationType(precedence, c.celebrationCode);
    final dayOfCompline = _detectDayOfWeek(date, celebrationType);

    final description = switch (celebrationType) {
      _ when ferialDayCheck(c.celebrationCode) =>
        'Complies du ${dayOfWeekLabels[todayName]} ${liturgicalTimeLabelsDative[liturgicalTime]}',
      'solemnity' => 'Complies de ${c.celebrationGlobalName}',
      _ => 'Complies du ${dayOfWeekLabels[todayName]}',
    };

    possibleComplines[description] = ComplineDefinition(
      complineDescription: description,
      celebrationCode: c.celebrationCode,
      ferialCode: c.ferialCode ?? '',
      liturgicalTime: liturgicalTime,
      precedence: precedence,
      liturgicalColor: c.liturgicalColor ?? 'green',
      isCelebrable: c.isCelebrable,
      dayOfCompline: dayOfCompline,
      celebrationType: celebrationType,
      isEveCompline: false,
    );
  }

  // 4. Process tomorrow's celebrations for eve Complines
  final bool isTomorrowSunday = tomorrow.weekday == DateTime.sunday;
  bool tomorrowHasSolemnity = false;

  for (final c in tomorrowCelebrations) {
    final int precedence = c.precedence ?? 13;
    final bool isTomorrowSolemnity = precedence <= 4;
    final bool needsEveCompline = isTomorrowSolemnity || isTomorrowSunday;

    if (needsEveCompline) {
      if (isTomorrowSolemnity) tomorrowHasSolemnity = true;

      final String eveDescription =
          'Complies de la veille de ${c.celebrationGlobalName}';
      final String eveCelebrationType =
          isTomorrowSolemnity ? 'solemnityeve' : 'normal';

      possibleComplines[eveDescription] = ComplineDefinition(
        complineDescription: eveDescription,
        celebrationCode: c.celebrationCode,
        ferialCode: c.ferialCode ?? '',
        liturgicalTime: liturgicalTime,
        precedence: precedence,
        liturgicalColor: c.liturgicalColor ?? 'green',
        isCelebrable: true,
        dayOfCompline: 'saturday',
        celebrationType: eveCelebrationType,
        isEveCompline: true,
      );
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

  final sortie = Map.fromEntries(sortedEntries);
  return sortie;
}
