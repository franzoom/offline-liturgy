import 'package:yaml/yaml.dart';
import '../../classes/calendar_class.dart';
import '../../classes/morning_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/date_tools.dart';
import '../../tools/constants.dart';
import '../../tools/convert_yaml_to_dart.dart';

/// Returns a map of possible Morning Offices, sorted by precedence (lowest first)
/// Key: celebration title from YAML (or resolved ferial name)
/// Value: MorningDefinition with all celebration data
Future<Map<String, MorningDefinition>> morningDetection(
    Calendar calendar, DateTime date, DataLoader dataLoader) async {
  // Get day content directly from calendar
  final dayContent = calendar.getDayContent(date);
  if (dayContent == null) {
    return {};
  }

  // Extract root data
  final String rootColor = dayContent.liturgicalColor;
  final int? breviaryWeek = dayContent.breviaryWeek;
  final String liturgicalTime = dayContent.liturgicalTime;
  final String defaultCelebrationTitle = dayContent.defaultCelebrationTitle;
  final int defaultPrecedence = dayContent.precedence;

  // Determine ferialCode: root code if it's a ferial day
  final String ferialCode =
      ferialDayCheck(defaultCelebrationTitle) ? defaultCelebrationTitle : '';

  // Build list of all celebrations with source tracking
  // Using record type for sorting: (precedence, code, isFromRoot)
  final List<({int precedence, String code, bool isFromRoot})> allCelebrations =
      [];

  // Add celebrations from feastList
  for (final entry in dayContent.feastList.entries) {
    final precedence = entry.key;
    for (final code in entry.value) {
      allCelebrations.add((
        precedence: precedence,
        code: code,
        isFromRoot: false,
      ));
    }
  }

  // Add default celebration from root
  allCelebrations.add((
    precedence: defaultPrecedence,
    code: defaultCelebrationTitle,
    isFromRoot: true,
  ));

  // Check if there's a high priority celebration (precedence <= 6)
  final bool hasHighPriority =
      allCelebrations.any((c) => c.precedence >= 1 && c.precedence <= 6);

  // Sort: by precedence ascending, with special rule for ferial days (precedence 13)
  // Ferial days at precedence 13 should come before optional memorials (precedence 12)
  allCelebrations.sort((a, b) {
    // Calculate effective precedence for sorting
    // Ferial day at 13 becomes 11.5 (between 11 and 12)
    double getEffectivePrecedence(
        ({int precedence, String code, bool isFromRoot}) c) {
      if (c.precedence == 13 && ferialDayCheck(c.code)) {
        return 11.5; // Place ferial 13 before optional memorials (12)
      }
      return c.precedence.toDouble();
    }

    final aEffective = getEffectivePrecedence(a);
    final bEffective = getEffectivePrecedence(b);

    if (aEffective != bEffective) {
      return aEffective.compareTo(bEffective);
    }
    // Same precedence: root first (isFromRoot=true comes before isFromRoot=false)
    if (a.isFromRoot != b.isFromRoot) {
      return a.isFromRoot ? -1 : 1;
    }
    return 0;
  });

  // Build the map of possible morning offices
  final Map<String, MorningDefinition> possibleMornings = {};

  for (final celebration in allCelebrations) {
    final String celebrationCode = celebration.code;
    final int precedence = celebration.precedence;

    // Determine isCelebrable based on precedence rules
    // If hasHighPriority (<=6), celebrations with precedence > 6 are not celebrable
    final bool isCelebrable = hasHighPriority ? (precedence <= 6) : true;

    // Initialize with default values
    String celebrationLiturgicalColor = rootColor;
    String celebrationName = celebrationCode;
    String mapKey = celebrationCode;
    String? celebrationDescription;
    List<String> commonList = [];

    // Resolve celebration name and data
    if (ferialDayCheck(celebrationCode)) {
      // Ferial day: resolve name using ferialNameResolution
      celebrationName = ferialNameResolution(celebrationCode);
      mapKey = celebrationName;
    } else {
      // Non-ferial: load data from YAML files
      // Try special_days first, then sanctoral
      String fileContent =
          await dataLoader.loadYaml('$specialFilePath/$celebrationCode.yaml');
      if (fileContent.isEmpty) {
        fileContent = await dataLoader
            .loadYaml('$sanctoralFilePath/$celebrationCode.yaml');
      }

      if (fileContent.isNotEmpty) {
        final yamlData = loadYaml(fileContent);
        final data = convertYamlToDart(yamlData);
        if (data['celebration'] != null) {
          final celebrationData = data['celebration'] as Map<String, dynamic>;
          final String? title = celebrationData['title'] as String?;
          final String? subtitle = celebrationData['subtitle'] as String?;
          celebrationDescription = celebrationData['description'] as String?;
          celebrationLiturgicalColor =
              celebrationData['color'] as String? ?? celebrationLiturgicalColor;
          commonList = List<String>.from(celebrationData['commons'] ?? []);

          // Use title as map key, build full name with subtitle
          if (title != null && title.isNotEmpty) {
            mapKey = title;
            celebrationName = title;
            if (subtitle != null && subtitle.isNotEmpty) {
              celebrationName += ', $subtitle';
            }
          }
        }
      } else {
        print('Warning: failed to load $celebrationCode.yaml');
      }
    }

    possibleMornings[mapKey] = MorningDefinition(
      morningDescription: celebrationName,
      celebrationCode: celebrationCode,
      ferialCode: ferialCode,
      commonList: commonList,
      liturgicalTime: liturgicalTime,
      breviaryWeek: breviaryWeek?.toString(),
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

/// old morningDetection function. Kept for legacy
/*
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
      ferialDayCheck(defaultCelebrationTitle) ? defaultCelebrationTitle : '';

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
*/
