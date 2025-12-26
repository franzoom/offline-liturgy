import 'dart:convert';
import '../../classes/calendar_class.dart';
import '../../classes/morning_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/date_tools.dart';
import '../../tools/file_paths.dart';

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

  // Add celebrations from feastList map
  dayContent.feastList.forEach((precedence, titles) {
    for (var title in titles) {
      print('============ MORNING DETECTION: $precedence, $title');
      allCelebrations.add(MapEntry(precedence, title));
    }
  });

  // Add default celebration from calendar root
  String liturgicalColor =
      dayContent.liturgicalColor.isNotEmpty ? dayContent.liturgicalColor : '';
  String defaultCelebrationTitle = dayContent.defaultCelebrationTitle;
  allCelebrations.add(MapEntry(dayContent.precedence, defaultCelebrationTitle));
  print(
      '============ MORNING DETECTION: ${dayContent.precedence}, $defaultCelebrationTitle');
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
    final precedence = celebration.key;

    // Determine if celebrable:
    // - If highest precedence is 1-8: only celebrations with highest precedence are celebrable
    // - If highest precedence is 9+: all celebrations are celebrable
    bool isCelebrable =
        highestPrecedence >= 9 || precedence == highestPrecedence;

    // Initialize liturgicalColor for this celebration (default: liturgical time color)
    String celebrationLiturgicalColor = liturgicalColor;

    // Get display name for celebration
    String celebrationName = celebrationCode;
    String mapKey = celebrationCode; // Default key is the code
    String? celebrationDescription; // Description from JSON

    // Try to load celebration title from JSON files
    if (!isFerialDay(celebrationCode)) {
      // Try to load from special_days first
      String fileContent =
          await dataLoader.loadJson('$specialFilePath/$celebrationCode.json');
      // If not found in special_days, try sanctoral
      if (fileContent.isEmpty) {
        fileContent = await dataLoader
            .loadJson('$sanctoralFilePath/$celebrationCode.json');
      }

      if (fileContent.isNotEmpty) {
        var jsonData = jsonDecode(fileContent);
        if (jsonData['celebration'] != null) {
          final celebrationData = jsonData['celebration'];
          final String? title = celebrationData['title'] as String?;
          final String? subtitle = celebrationData['subtitle'] as String?;
          celebrationDescription = celebrationData['description'] as String?;
          // Update liturgicalColor from celebration data (override if specified)
          celebrationLiturgicalColor =
              celebrationData['color'] as String? ?? celebrationLiturgicalColor;
          commonList = List<String>.from(celebrationData['commons'] ?? []);

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
        bool isCelebrable = false;
      }
      // If file not found or empty, keep the original code as name and key
    } else {
      // For ferial days:
      celebrationName = ferialNameResolution(ferialCode);
      mapKey = celebrationName;
    }

    possibleMornings[mapKey] = MorningDefinition(
      morningDescription: celebrationName,
      celebrationCode: celebrationCode,
      ferialCode: ferialCode,
      commonList: commonList,
      liturgicalTime: dayContent.liturgicalTime,
      breviaryWeek: dayContent.breviaryWeek?.toString(),
      precedence: precedence,
      liturgicalColor: celebrationLiturgicalColor,
      isCelebrable: isCelebrable,
      celebrationDescription: celebrationDescription,
    );
  }
  print(
      '+-+-+-+-+-+-+-+-+-+ MORNING DETECTION - Possible Morning Offices: $possibleMornings');
  return possibleMornings;
}
