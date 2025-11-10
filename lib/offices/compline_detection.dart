import 'dart:convert';
import 'dart:io';
import '../classes/calendar_class.dart'; // Calendar class
import '../classes/compline_class.dart';
import '../tools/date_tools.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';

Map<String, ComplineDefinition> complineDetection(
    Calendar calendar, DateTime date) {
  /// Detects which Compline to use for a given day.
  /// Returns a Map "day or feast name" : ComplineDefinition

  DayContent? todayContent = calendar.getDayContent(date);
  String todayName = dayName[date.weekday];
  String liturgicalTime = todayContent!.liturgicalTime;
  String celebrationTitle = todayContent.defaultCelebrationTitle;
  int liturgicalGrade = todayContent.liturgicalGrade;

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
          priority: 1);
      return {celebrationTitle: complineDefinition};
    case 'ashes':
      ComplineDefinition complineDefinition = ComplineDefinition(
          complineDescription: 'Complies du mercredi des Cendres',
          dayOfWeek: 'wednesday',
          liturgicalTime: 'ordinary',
          celebrationType: 'normal',
          priority: 13);
      return {celebrationTitle: complineDefinition};
  }

  String complineDescription = getFrenchComplineDescription(celebrationTitle);

  // Major solemnities (in the root of the day Calendar)
  // for sundays of Advent or other times, the liturgical grade is very high,
  // so we have to check if it's a sunday in the celebrationTitle (finishing with 0).
  // normaly a major solemnity replaces the celebrationTitle of the day,
  // so the check is enough to solve the problem.
  if (liturgicalGrade <= 4 &&
      celebrationTitle[celebrationTitle.length - 1] != '0') {
    ComplineDefinition complineDefinition = ComplineDefinition(
        complineDescription: complineDescription,
        dayOfWeek: 'sunday',
        liturgicalTime: liturgicalTime,
        celebrationType: 'solemnity',
        priority: liturgicalGrade);
    return {complineDescription: complineDefinition};
  }

  // Then look for the solemnities found in a subdirectories of Calendar
  // (a solemnity must be at a higher grade than the root of the day)
  for (var entry in todayContent.priority.entries) {
    if (entry.key <= 4 && entry.key <= liturgicalGrade) {
      String complineDescription = getFrenchComplineDescription(entry.value[0]);
      ComplineDefinition complineDefinition = ComplineDefinition(
          complineDescription: complineDescription,
          dayOfWeek: 'sunday',
          liturgicalTime: liturgicalTime,
          celebrationType: 'solemnity',
          priority: entry.key);
      return {complineDescription: complineDefinition};
    }
  }

  //otherwise, concluding with the simple Complines of the day
  ComplineDefinition complineDefinition = ComplineDefinition(
      complineDescription: complineDescription,
      dayOfWeek: todayName,
      liturgicalTime: liturgicalTime,
      celebrationType: 'normal',
      priority: liturgicalGrade);
  return {complineDescription: complineDefinition};
}

/// function returning the french description of the complines
String getFrenchComplineDescription(String celebrationTitle) {
  // Convert to lowercase to avoid case issues
  final title = celebrationTitle.toLowerCase();

  // Split the parts of celebrationTitle
  final parts = title.split('_');

  // Check if format is valid (aaaa_X_Y)
  if (parts.length == 3) {
    final liturgicalSeasonKey = parts[0];
    final weekNumber = int.tryParse(parts[1]);
    final dayNumber = int.tryParse(parts[2]);

    if (weekNumber != null &&
        dayNumber != null &&
        dayNumber >= 0 &&
        dayNumber <= 6) {
      final liturgicalSeason = liturgicalTimeLabels[liturgicalSeasonKey];
      if (liturgicalSeason != null) {
        final dayName = daysOfWeek[dayNumber];
        final ordinal = getFrenchOrdinal(weekNumber);
        return 'Complies du $ordinal $dayName du $liturgicalSeason';
      }
    }
  }

  // If format is not valid, search in JSON files
  // First in days_special
  String result = _searchInJsonFile(
    'lib/assets/calendar_data/special_days/$title.json',
    title,
  );

  if (result.isNotEmpty) {
    return 'Complies de $result';
  }

  // Then in sanctoral
  result = _searchInJsonFile(
    'lib/assets/calendar_data/sanctoral/$title.json',
    title,
  );

  return 'Complies de $result';
}

/// Helper function to search for celebrationTitle key in a JSON file
String _searchInJsonFile(String filePath, String key) {
  try {
    final file = File(filePath);

    // Check if file exists
    if (!file.existsSync()) {
      return '';
    }

    // Read and parse JSON file
    final content = file.readAsStringSync();
    final jsonData = json.decode(content) as Map<String, dynamic>;

    // Return the celebrationTitle value if it exists
    if (jsonData.containsKey('celebrationTitle')) {
      return jsonData['celebrationTitle'] as String? ?? '';
    }

    return '';
  } catch (e) {
    // If any error occurs (file not found, parse error, etc.), return empty string
    return '';
  }
}
