import 'package:yaml/yaml.dart';
import '../../classes/calendar_class.dart';
import '../../classes/readings_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/date_tools.dart';
import '../../tools/constants.dart';
import '../../tools/convert_yaml_to_dart.dart';

///returns a list of possible Readings Offices, sorted by precedence (highest first)
Future<Map<String, ReadingsDefinition>> readingsDetection(
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
  // detects if there is a ferialCode in order to pass it to the ReadingsResolution procedure
  String ferialCode =
      ferialDayCheck(defaultCelebrationTitle) ? defaultCelebrationTitle : '';

  // Sort by precedence (lowest number = highest precedence)
  allCelebrations.sort((a, b) => a.key.compareTo(b.key));

  // Find the highest precedence (lowest number)
  final int highestPrecedence =
      allCelebrations.isNotEmpty ? allCelebrations.first.key : 999;

  // Build the map of possible readings offices
  final Map<String, ReadingsDefinition> possibleReadingss = {};

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
    String? celebrationDescription; // Description from YAML

    // Try to load celebration title from YAML files
    if (!ferialDayCheck(celebrationCode)) {
      // Try to load from special_days first
      String fileContent =
          await dataLoader.loadYaml('$specialFilePath/$celebrationCode.yaml');
      // If not found in special_days, try sanctoral
      if (fileContent.isEmpty) {
        fileContent = await dataLoader
            .loadYaml('$sanctoralFilePath/$celebrationCode.yaml');
      }

      if (fileContent.isNotEmpty) {
        // Parse YAML and convert to Dart types
        final yamlData = loadYaml(fileContent);
        final data = convertYamlToDart(yamlData);
        if (data['celebration'] != null) {
          final celebrationData = data['celebration'] as Map<String, dynamic>;
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
        print('failed to load $celebrationCode.yaml');
        isCelebrable = false;
      }
      // If file not found or empty, keep the original code as name and key
    } else {
      // For ferial days:
      celebrationName = ferialNameResolution(ferialCode);
      mapKey = celebrationName;
    }

    // Determine if Te Deum should be displayed
    // Te Deum is displayed when:
    // - It's a Sunday (weekday == 7) AND not during Lent
    // - OR it's a Feast or Solemnity (precedence < 6)
    bool shouldDisplayTeDeum = false;
    print(
        '🔷 TE DEUM CHECK for $celebrationCode: precedence=$precedence, weekday=${date.weekday}, liturgicalTime=${dayContent.liturgicalTime}');
    if (precedence < 6) {
      // Feast or Solemnity
      shouldDisplayTeDeum = true;
      print('🔷 TE DEUM = true (precedence < 6)');
    } else if (date.weekday == DateTime.sunday) {
      // Sunday, but check if it's not Lent
      final liturgicalTime = dayContent.liturgicalTime.toLowerCase();
      print('🔷 Sunday detected, liturgicalTime lowercase = "$liturgicalTime"');
      if (!liturgicalTime.contains('lent') &&
          !liturgicalTime.contains('carême')) {
        shouldDisplayTeDeum = true;
        print('🔷 TE DEUM = true (Sunday not in Lent)');
      } else {
        print('🔷 TE DEUM = false (Sunday in Lent)');
      }
    } else {
      print('🔷 TE DEUM = false (not Sunday, precedence >= 6)');
    }

    possibleReadingss[mapKey] = ReadingsDefinition(
      readingsDescription: celebrationName,
      celebrationCode: celebrationCode,
      ferialCode: ferialCode,
      commonList: commonList,
      liturgicalTime: dayContent.liturgicalTime,
      breviaryWeek: dayContent.breviaryWeek?.toString(),
      precedence: precedence,
      liturgicalColor: celebrationLiturgicalColor,
      isCelebrable: isCelebrable,
      celebrationDescription: celebrationDescription,
      teDeum: shouldDisplayTeDeum,
    );
  }
  print(
      '+-+-+-+-+-+-+-+-+-+ MORNING DETECTION - Possible Readings Offices: $possibleReadingss');
  return possibleReadingss;
}