import 'package:yaml/yaml.dart';
import '../classes/calendar_class.dart';
import '../classes/office_elements_class.dart';
import '../tools/data_loader.dart';
import '../tools/date_tools.dart';
import '../tools/constants.dart';
import '../tools/convert_yaml_to_dart.dart';

/// function returning the possible offices for a given day

/// Data extracted from a celebration YAML file
class CelebrationYamlData {
  final String? title;
  final String? subtitle;
  final String? description;
  final String? color;
  final List<String> commons;

  const CelebrationYamlData({
    this.title,
    this.subtitle,
    this.description,
    this.color,
    this.commons = const [],
  });
}

/// Parses celebration data from YAML content
/// Returns null if parsing fails or content is invalid
CelebrationYamlData? parseCelebrationYaml(String fileContent) {
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

    return CelebrationYamlData(
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

/// Returns the effective sort precedence for a celebration.
/// Ferial days at precedence 13 rank before optional memorials (12).
double effectivePrecedence(int precedence, String code) {
  if (precedence == 13 && ferialDayCheck(code)) return 11.5;
  return precedence.toDouble();
}

/// Detects all possible celebrations for a given date
/// Returns a list of CelebrationContext sorted by precedence (lowest first)
///
/// This is the common function used by all office detection wrappers
/// (morning, readings, vespers, etc.)
Future<List<CelebrationContext>> detectCelebrations(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
) async {
  // Get day content directly from calendar
  final dayContent = calendar.getDayContent(date);
  if (dayContent == null) {
    return [];
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

  // Check if there's a high priority celebration (feast or above: precedence <= 7)
  final bool hasHighPriority =
      allCelebrations.any((c) => c.precedence >= 1 && c.precedence <= 7);

  // Sort: by precedence ascending, with special rule for ferial days (precedence 13)
  // Ferial days at precedence 13 should come before optional memorials (precedence 12)
  allCelebrations.sort((a, b) {
    final aEff = effectivePrecedence(a.precedence, a.code);
    final bEff = effectivePrecedence(b.precedence, b.code);
    if (aEff != bEff) return aEff.compareTo(bEff);
    if (a.isFromRoot != b.isFromRoot) return a.isFromRoot ? -1 : 1;
    return 0;
  });

  // Filter non-ferial celebrations for parallel YAML loading
  final nonFerialCelebrations =
      allCelebrations.where((c) => !ferialDayCheck(c.code)).toList();

  // Load all non-ferial YAML files in parallel (special_days first)
  final specialLoadFutures = nonFerialCelebrations
      .map((c) => dataLoader.loadYaml('$specialFilePath/${c.code}.yaml'));
  final List<String> specialResults;
  try {
    specialResults = await Future.wait(specialLoadFutures);
  } catch (e) {
    return [];
  }

  // For empty results, try sanctoral in parallel
  final sanctoralIndices = <int>[];
  for (int i = 0; i < specialResults.length; i++) {
    if (specialResults[i].isEmpty) {
      sanctoralIndices.add(i);
    }
  }

  final sanctoralLoadFutures = sanctoralIndices.map((i) => dataLoader
      .loadYaml('$sanctoralFilePath/${nonFerialCelebrations[i].code}.yaml'));
  final List<String> sanctoralResults;
  try {
    sanctoralResults = await Future.wait(sanctoralLoadFutures);
  } catch (e) {
    return [];
  }

  // Load ferial YAML files in parallel
  final ferialCelebrations =
      allCelebrations.where((c) => ferialDayCheck(c.code)).toList();
  final ferialLoadFutures = ferialCelebrations
      .map((c) => dataLoader.loadYaml('$ferialFilePath/${c.code}.yaml'));
  List<String> ferialResults;
  try {
    ferialResults = await Future.wait(ferialLoadFutures);
  } catch (e) {
    print('Error loading ferial YAML files: $e');
    ferialResults = List.filled(ferialCelebrations.length, '');
  }

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
  for (int i = 0; i < ferialCelebrations.length; i++) {
    final code = ferialCelebrations[i].code;
    if (ferialResults[i].isNotEmpty) {
      fileContents[code] = ferialResults[i];
    }
  }

  // Load common titles in parallel for all unique common codes
  final Set<String> allCommonCodes = {};
  for (final celebration in allCelebrations) {
    final fileContent = fileContents[celebration.code] ?? '';
    final yamlData = parseCelebrationYaml(fileContent);
    if (yamlData != null) {
      allCommonCodes.addAll(yamlData.commons);
    }
  }

  final Map<String, String> commonTitlesMap = {};
  if (allCommonCodes.isNotEmpty) {
    final commonCodesList = allCommonCodes.toList();
    final commonLoadFutures = commonCodesList
        .map((code) => dataLoader.loadYaml('$commonsFilePath/$code.yaml'));
    final commonResults = await Future.wait(commonLoadFutures);
    for (int i = 0; i < commonCodesList.length; i++) {
      final code = commonCodesList[i];
      if (commonResults[i].isNotEmpty) {
        try {
          final yamlData = loadYaml(commonResults[i]);
          final data = convertYamlToDart(yamlData);
          commonTitlesMap[code] = (data['commonTitle'] as String?) ?? code;
        } catch (_) {
          commonTitlesMap[code] = code;
        }
      } else {
        commonTitlesMap[code] = code;
      }
    }
  }

  // Build the list of detected celebrations
  final List<CelebrationContext> detectedCelebrations = [];

  for (final celebration in allCelebrations) {
    final String celebrationCode = celebration.code;
    final int precedence = celebration.precedence;

    // Determine isCelebrable based on precedence rules
    final bool isCelebrable = hasHighPriority ? (precedence <= 7) : true;

    // Initialize with default values
    String celebrationLiturgicalColor = rootColor;
    String celebrationGlobalName = celebrationCode;
    String celebrationTitle = celebrationCode;
    String? celebrationDescription;
    List<String> commonList = [];

    // Resolve celebration name and data
    if (ferialDayCheck(celebrationCode)) {
      // Ferial day: resolve name using ferialNameResolution
      celebrationGlobalName = ferialNameResolution(celebrationCode);
      celebrationTitle = celebrationGlobalName;
    }

    // Check YAML data (pre-loaded for non-ferial, may also exist for ferial)
    final fileContent = fileContents[celebrationCode] ?? '';
    final yamlData = parseCelebrationYaml(fileContent);

    if (yamlData != null) {
      celebrationLiturgicalColor = yamlData.color ?? celebrationLiturgicalColor;
      celebrationDescription = yamlData.description;
      commonList = yamlData.commons;

      // Use title as celebrationTitle, build full name with subtitle
      if (yamlData.title != null && yamlData.title!.isNotEmpty) {
        celebrationTitle = yamlData.title!;
        celebrationGlobalName = yamlData.title!;
        if (yamlData.subtitle != null && yamlData.subtitle!.isNotEmpty) {
          celebrationGlobalName += ', ${yamlData.subtitle}';
        }
      }
    }

    // Filter commonTitles for this celebration's commons
    final Map<String, String> celebrationCommonTitles = {
      for (final code in commonList)
        if (commonTitlesMap.containsKey(code)) code: commonTitlesMap[code]!,
    };

    detectedCelebrations.add(CelebrationContext(
      celebrationTitle: celebrationTitle,
      celebrationGlobalName: celebrationGlobalName,
      celebrationCode: celebrationCode,
      ferialCode: ferialCode,
      commonList: commonList,
      date: date,
      liturgicalTime: liturgicalTime,
      breviaryWeek: breviaryWeek,
      precedence: precedence,
      liturgicalColor: celebrationLiturgicalColor,
      isCelebrable: isCelebrable,
      dataLoader: dataLoader,
      celebrationDescription: celebrationDescription,
      commonTitles: celebrationCommonTitles,
    ));
  }

  return detectedCelebrations;
}

/// Generic helper for office detection wrappers (morning, readings, etc.).
/// Converts detected celebrations into a keyed map with the given [celebrationType].
Future<Map<String, CelebrationContext>> buildDetectionMap(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
  String celebrationType,
) async {
  final celebrations = await detectCelebrations(calendar, date, dataLoader);
  return {
    for (final c in celebrations)
      c.celebrationTitle ?? c.celebrationCode: c.copyWith(
        celebrationType: celebrationType,
        officeDescription: c.celebrationGlobalName,
      ),
  };
}
