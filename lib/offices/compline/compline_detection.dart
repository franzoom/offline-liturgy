import 'dart:convert';
import '../../classes/calendar_class.dart'; // Calendar class
import '../../classes/compline_class.dart';
import '../../tools/date_tools.dart';
import '../../tools/data_loader.dart'; // Abstract interface for data loading
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';

Future<Map<String, ComplineDefinition>> complineDetection(
    Calendar calendar, DateTime date, DataLoader dataLoader) async {
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

  String complineDescription = await getFrenchComplineDescription(
    celebrationTitle,
    dataLoader,
  );

  // Major solemnities (in the root of the day Calendar)
  // For sundays of Advent or other times, the liturgical grade is very high,
  // so we have to check if it's a sunday in the celebrationTitle (finishing with 0).
  // Normally a major solemnity replaces the celebrationTitle of the day,
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

  // Then look for the solemnities found in subdirectories of Calendar
  // (a solemnity must be at a higher grade than the root of the day)
  for (var entry in todayContent.priority.entries) {
    if (entry.key <= 4 && entry.key <= liturgicalGrade) {
      String complineDescription = await getFrenchComplineDescription(
        entry.value[0],
        dataLoader,
      );
      ComplineDefinition complineDefinition = ComplineDefinition(
          complineDescription: complineDescription,
          dayOfWeek: 'sunday',
          liturgicalTime: liturgicalTime,
          celebrationType: 'solemnity',
          priority: entry.key);
      return {complineDescription: complineDefinition};
    }
  }

  // Otherwise, concluding with the simple Complines of the day
  ComplineDefinition complineDefinition = ComplineDefinition(
      complineDescription: complineDescription,
      dayOfWeek: todayName,
      liturgicalTime: liturgicalTime,
      celebrationType: 'normal',
      priority: liturgicalGrade);
  return {complineDescription: complineDefinition};
}

/// Returns the French description of the Complines
Future<String> getFrenchComplineDescription(
  String celebrationTitle,
  DataLoader dataLoader,
) async {
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
  // First in special_days
  String result = await _searchInJsonFile(
    'calendar_data/special_days/$title.json',
    dataLoader,
  );

  if (result.isNotEmpty) {
    return 'Complies de $result';
  }

  // Then in sanctoral
  result = await _searchInJsonFile(
    'calendar_data/sanctoral/$title.json',
    dataLoader,
  );

  return result.isNotEmpty ? 'Complies de $result' : 'Complies';
}

/// Helper function to search for celebrationTitle key in a JSON file
Future<String> _searchInJsonFile(
  String relativePath,
  DataLoader dataLoader,
) async {
  try {
    // Load via DataLoader instead of File()
    final content = await dataLoader.loadJson(relativePath);

    // If content is empty, file doesn't exist
    if (content.isEmpty) {
      return '';
    }

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
