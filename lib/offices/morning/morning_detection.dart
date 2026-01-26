import 'package:yaml/yaml.dart';
import '../../classes/calendar_class.dart';
import '../../classes/morning_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/date_tools.dart';
import '../../tools/constants.dart';
import '../../tools/convert_yaml_to_dart.dart';

/// Data extracted from a celebration YAML file
class _CelebrationYamlData {
  final String? title;
  final String? subtitle;
  final String? description;
  final String? color;
  final List<String> commons;

  const _CelebrationYamlData({
    this.title,
    this.subtitle,
    this.description,
    this.color,
    this.commons = const [],
  });
}

/// Parses celebration data from YAML content
/// Returns null if parsing fails or content is invalid
_CelebrationYamlData? _parseCelebrationYaml(String fileContent) {
  if (fileContent.isEmpty) return null;

  try {
    final yamlData = loadYaml(fileContent);
    final data = convertYamlToDart(yamlData);

    if (data is! Map<String, dynamic> || data['celebration'] == null) {
      return null;
    }

    final celebrationData = data['celebration'];
    if (celebrationData is! Map<String, dynamic>) {
      return null;
    }

    final commons = celebrationData['commons'];
    final commonsList =
        commons is List ? commons.whereType<String>().toList() : <String>[];

    return _CelebrationYamlData(
      title: celebrationData['title'] as String?,
      subtitle: celebrationData['subtitle'] as String?,
      description: celebrationData['description'] as String?,
      color: celebrationData['color'] as String?,
      commons: commonsList,
    );
  } catch (e) {
    return null;
  }
}

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

  // Filter non-ferial celebrations for parallel YAML loading
  final nonFerialCelebrations =
      allCelebrations.where((c) => !ferialDayCheck(c.code)).toList();

  // Load all non-ferial YAML files in parallel (special_days first)
  final specialLoadFutures = nonFerialCelebrations
      .map((c) => dataLoader.loadYaml('$specialFilePath/${c.code}.yaml'));
  final specialResults = await Future.wait(specialLoadFutures);

  // For empty results, try sanctoral in parallel
  final sanctoralIndices = <int>[];
  for (int i = 0; i < specialResults.length; i++) {
    if (specialResults[i].isEmpty) {
      sanctoralIndices.add(i);
    }
  }

  final sanctoralLoadFutures = sanctoralIndices.map((i) => dataLoader
      .loadYaml('$sanctoralFilePath/${nonFerialCelebrations[i].code}.yaml'));
  final sanctoralResults = await Future.wait(sanctoralLoadFutures);

  // Build a map of celebration code -> file content
  final Map<String, String> fileContents = {};
  for (int i = 0; i < nonFerialCelebrations.length; i++) {
    final code = nonFerialCelebrations[i].code;
    if (specialResults[i].isNotEmpty) {
      fileContents[code] = specialResults[i];
    }
  }
  for (int i = 0; i < sanctoralIndices.length; i++) {
    final code = nonFerialCelebrations[sanctoralIndices[i]].code;
    if (sanctoralResults[i].isNotEmpty) {
      fileContents[code] = sanctoralResults[i];
    }
  }

  // Process all celebrations (ferial and non-ferial)
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
      // Non-ferial: use pre-loaded YAML data
      final fileContent = fileContents[celebrationCode] ?? '';
      final yamlData = _parseCelebrationYaml(fileContent);

      if (yamlData != null) {
        celebrationDescription = yamlData.description;
        celebrationLiturgicalColor =
            yamlData.color ?? celebrationLiturgicalColor;
        commonList = yamlData.commons;

        // Use title as map key, build full name with subtitle
        if (yamlData.title != null && yamlData.title!.isNotEmpty) {
          mapKey = yamlData.title!;
          celebrationName = yamlData.title!;
          if (yamlData.subtitle != null && yamlData.subtitle!.isNotEmpty) {
            celebrationName += ', ${yamlData.subtitle}';
          }
        }
      } else if (fileContent.isEmpty) {
        print('Warning: failed to load $celebrationCode.yaml');
      } else {
        print('Warning: failed to parse $celebrationCode.yaml');
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
