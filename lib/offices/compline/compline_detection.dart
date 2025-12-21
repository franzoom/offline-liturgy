import 'package:offline_liturgy/offices/compline/compline_extract.dart';
import '../../classes/calendar_class.dart';
import '../../classes/compline_class.dart';
import '../../tools/date_tools.dart';
import '../../tools/data_loader.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';

Future<Map<String, ComplineDefinition>> complineDetection(
    Calendar calendar, DateTime date, DataLoader dataLoader) async {
  /// Detects which Compline to use for a given day.
  /// Returns a Map "day or feast name". One of this offices will be
  /// chosen and given in argument to complineResolution

  DayContent? todayContent = calendar.getDayContent(date);
  String todayName = dayName[date.weekday];
  String liturgicalTime = todayContent!.liturgicalTime;
  String celebrationTitle = todayContent.defaultCelebrationTitle;
  int precedence = todayContent.precedence;

  switch (celebrationTitle) {
    case 'holy_thursday':
    case 'holy_friday':
    case 'holy_saturday':
      ComplineDefinition complineDefinition = ComplineDefinition(
          complineDescription:
              'Complies du ${celebrationTypeLabels[celebrationTitle]!}',
          dayOfWeek: 'sunday',
          liturgicalTime: 'lent',
          celebrationType: celebrationTitle,
          precedence: 1);
      return {celebrationTitle: complineDefinition};
    case 'ashes':
      ComplineDefinition complineDefinition = ComplineDefinition(
          complineDescription: 'Complies du mercredi des Cendres',
          dayOfWeek: 'wednesday',
          liturgicalTime: 'ordinary',
          celebrationType: 'normal',
          precedence: 13);
      return {celebrationTitle: complineDefinition};
  }

  String complineDescription = await getComplineDescription(
    celebrationTitle,
    dataLoader,
  );

  // Major solemnities (in the root of Day Calendar)
  // For sundays of Advent or other times, the precedence is very high,
  // so we have to check if it's a sunday in the celebrationTitle (finishing with 0).
  // Usualy a major solemnity replaces the celebrationTitle of the day,
  // so the check is enough to solve problems.
  if (precedence <= 4 && celebrationTitle[celebrationTitle.length - 1] != '0') {
    ComplineDefinition complineDefinition = ComplineDefinition(
        complineDescription: complineDescription,
        dayOfWeek: 'sunday',
        liturgicalTime: liturgicalTime,
        celebrationType: 'solemnity',
        precedence: precedence);
    return {complineDescription: complineDefinition};
  }

  // Then look for the solemnities found in subdirectories of Calendar
  // (a solemnity must be at a higher grade than the root of the day)
  for (var entry in todayContent.feastList.entries) {
    if (entry.key <= 4 && entry.key <= precedence) {
      String complineDescription = await getComplineDescription(
        entry.value[0],
        dataLoader,
      );
      ComplineDefinition complineDefinition = ComplineDefinition(
          complineDescription: complineDescription,
          dayOfWeek: 'sunday',
          liturgicalTime: liturgicalTime,
          celebrationType: 'solemnity',
          precedence: entry.key);
      return {complineDescription: complineDefinition};
    }
  }

  // Otherwise, concluding with the simple Complines of the day
  ComplineDefinition complineDefinition = ComplineDefinition(
      complineDescription: complineDescription,
      dayOfWeek: todayName,
      liturgicalTime: liturgicalTime,
      celebrationType: 'normal',
      precedence: precedence);
  return {complineDescription: complineDefinition};
}

/// Returns the French description of the Complines
Future<String> getComplineDescription(
  String celebrationTitle,
  DataLoader dataLoader,
) async {
  // Convert to lowercase to avoid case issues
  final title = celebrationTitle.toLowerCase();

  // Check if format is valid (aaaa_X_Y) (normal format for ferial days)
  final ferialCodeParts = title.split('_');

  if (ferialCodeParts.length == 3) {
    var liturgicalSeasonKey = ferialCodeParts[0];
    String specialAdventDay = '';

    // check for specialdays of Advent (17 to 24 decembre, with the symbole '-')
    // e.g. advent-17_5_3 for decembre, 17th, 5th day of the 3rd week.
    if (liturgicalSeasonKey.contains('-')) {
      final parts = liturgicalSeasonKey.split('-');
      liturgicalSeasonKey = parts[0];
      specialAdventDay = parts[1]; // The two digits after '-'
    }

    final dayNumber = int.tryParse(ferialCodeParts[2]);

    final liturgicalSeason = liturgicalTimeLabels[liturgicalSeasonKey];
    if (liturgicalSeason != null) {
      final dayName = daysOfWeek[dayNumber!];
      if (specialAdventDay.isNotEmpty) {
        return 'Complies du $dayName du $liturgicalSeason ($specialAdventDay décembre)';
      }
      return 'Complies du $dayName du $liturgicalSeason';
    }
  }

  final String complineTitle = await complineTitleExtract(
    title,
    dataLoader,
  );

  return complineTitle.isNotEmpty ? 'Complies de $complineTitle' : 'Complies';
}
