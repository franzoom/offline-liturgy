import 'dart:math' show min;
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

  // On Ordinary Time Saturdays, add the Marian memory when no obligatory
  // celebration (precedence ≤ 9) is already present.
  if (date.weekday == DateTime.saturday &&
      liturgicalTime == 'ot' &&
      allCelebrations.every((c) => c.precedence > 9)) {
    allCelebrations.add((
      precedence: 12,
      code: 'roman/virgin-mary-memory',
      isFromRoot: false,
    ));
  }

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

  // Load all YAML files in one parallel pass.
  final loadFutures = allCelebrations.map((c) {
    final filePath = ferialDayCheck(c.code) ? ferialFilePath : sanctoralFilePath;
    return dataLoader.loadYaml('$filePath/${c.code}.yaml');
  });
  final List<String> loadResults;
  try {
    loadResults = await Future.wait(loadFutures);
  } catch (e) {
    return [];
  }

  // Build a map of celebration code -> file content
  final Map<String, String> fileContents = {};
  for (int i = 0; i < allCelebrations.length; i++) {
    if (loadResults[i].isNotEmpty) {
      fileContents[allCelebrations[i].code] = loadResults[i];
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
    final int bestPrecedence =
        allCelebrations.map((c) => c.precedence).reduce(min);
    final bool isSundayFerial = date.weekday == DateTime.sunday &&
        ferialDayCheck(celebrationCode) &&
        !(liturgicalTime == 'ot' && bestPrecedence <= 3);
    final bool isCelebrable = hasHighPriority
        ? (precedence <= bestPrecedence || isSundayFerial)
        : true;

    // Initialize with default values
    String celebrationLiturgicalColor = rootColor;
    String celebrationGlobalName = celebrationCode;
    String celebrationTitle = celebrationCode;
    String? celebrationDescription;
    List<String> commonList = [];

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
          final sub = yamlData.subtitle!;
          celebrationGlobalName += ', ${sub[0].toLowerCase()}${sub.substring(1)}';
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
      celebrationOrigin: dayContent.feastOrigins[celebrationCode],
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
  // Celebrations are sorted by ascending precedence (best first).
  // putIfAbsent keeps the first (highest-priority) entry when two celebrations
  // share the same title (e.g. france_pothinus_... vs lyon_pothinus_...).
  final map = <String, CelebrationContext>{};
  for (final c in celebrations) {
    final key = c.celebrationTitle ?? c.celebrationCode;
    map.putIfAbsent(key, () => c.copyWith(
      celebrationType: celebrationType,
      officeDescription: c.celebrationGlobalName,
    ));
  }
  return map;
}
