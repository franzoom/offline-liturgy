import 'dart:convert';
import '../classes/calendar_class.dart';
import '../classes/morning_class.dart';
import '../tools/data_loader.dart';
import '../tools/date_tools.dart';

///returns a list of possible Morning Offices, sorted by precedence (highest first)
Future<Map<String, MorningDefinition>> morningDetection(
    Calendar calendar, DateTime date, DataLoader dataLoader) async {
  // Get day content from calendar
  final dayContent = calendar.getDayContent(date);
  List<String> commonList = [];
  // If no data for this day, return empty map
  if (dayContent == null) {
    return {};
  }

  // Build list of all possible celebrations
  final List<MapEntry<int, String>> allCelebrations = [];

  // Add celebrations from priority map
  dayContent.priority.forEach((priorityNumber, titles) {
    for (var title in titles) {
      print('============ MORNING DETECTION: $priorityNumber, $title');
      allCelebrations.add(MapEntry(priorityNumber, title));
    }
  });

  // Add default celebration from calendar root
  String defaultCelebrationTitle = dayContent.defaultCelebrationTitle;
  allCelebrations
      .add(MapEntry(dayContent.liturgicalGrade, defaultCelebrationTitle));
  print(
      '============ MORNING DETECTION: ${dayContent.liturgicalGrade}, $defaultCelebrationTitle');
  // detects if there is a ferialCode in order to pass it to the MorningResolution procedure
  String ferialCode =
      isFerialDay(defaultCelebrationTitle) ? defaultCelebrationTitle : '';

  // Sort by precedence (lowest number = highest precedence)
  allCelebrations.sort((a, b) => a.key.compareTo(b.key));

  // Find the highest precedence (lowest number)
  final int highestPrecedence =
      allCelebrations.isNotEmpty ? allCelebrations.first.key : 999;

  // Build the map of possible morning offices
  final Map<String, MorningDefinition> possibleMornings = {};

  for (final celebration in allCelebrations) {
    final celebrationCode = celebration.value;
    final liturgicalGrade = celebration.key;

    // Determine if celebrable:
    // - If highest precedence is 1-8: only celebrations with highest precedence are celebrable
    // - If highest precedence is 9+: all celebrations are celebrable
    final bool isCelebrable =
        highestPrecedence >= 9 || liturgicalGrade == highestPrecedence;

    // Get display name for celebration
    String celebrationName = celebrationCode;
    String mapKey = celebrationCode; // Default key is the code

    // Try to load celebration title from JSON files
    if (!isFerialDay(celebrationCode)) {
      // Not a ferial day - try to load from special_days or sanctoral
      final String specialPath =
          'calendar_data/special_days/$celebrationCode.json';
      final String sanctoralPath =
          'calendar_data/sanctoral/$celebrationCode.json';

      // Try to load from special_days first
      String fileContent = await dataLoader.loadJson(specialPath);
      // If not found in special_days, try sanctoral
      if (fileContent.isEmpty) {
        fileContent = await dataLoader.loadJson(sanctoralPath);
      }

      if (fileContent.isNotEmpty) {
        var jsonData = jsonDecode(fileContent);
        if (jsonData['celebration'] != null) {
          final celebrationData = jsonData['celebration'];
          final String? title = celebrationData['title'] as String?;
          final String? subtitle = celebrationData['subtitle'] as String?;
          commonList = celebrationData['commons'];

          // Build display name from title and subtitle (separated by comma)
          if (title != null && title.isNotEmpty) {
            mapKey = title; // Use title as map key
            celebrationName = title;
            if (subtitle != null && subtitle.isNotEmpty) {
              celebrationName += ', $subtitle';
            }
          }
        }
      } else {
        print('failed to load $celebrationCode.json');
      }
      // If file not found or empty, keep the original code as name and key
    }
    // For ferial days, we'll implement name generation later

    possibleMornings[mapKey] = MorningDefinition(
      morningDescription: celebrationName,
      celebrationCode: celebrationCode,
      ferialCode: ferialCode,
      commonList: commonList,
      liturgicalTime: dayContent.liturgicalTime,
      breviaryWeek: dayContent.breviaryWeek?.toString(),
      liturgicalGrade: liturgicalGrade,
      isCelebrable: isCelebrable,
    );
  }
  print(
      '+-+-+-+-+-+-+-+-+-+ MORNING DETECTION - Possible Morning Offices: $possibleMornings');
  return possibleMornings;
}
