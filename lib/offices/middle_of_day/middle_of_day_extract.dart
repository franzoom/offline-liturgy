import 'dart:developer';

import 'package:yaml/yaml.dart';
import '../../classes/middle_of_day_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/convert_yaml_to_dart.dart';

/// Extracts MiddleOfDay data from a YAML file.
///
/// Uses the [DataLoader] to read the file content, then parses the YAML
/// and maps it to a [MiddleOfDay] instance.
Future<MiddleOfDay> middleOfDayExtract(
    String relativePath, DataLoader dataLoader) async {
  // 1. Load the raw YAML content
  final String fileContent = await dataLoader.loadYaml(relativePath);

  if (fileContent.isEmpty) {
    // Return an empty instance if the file is missing or empty
    return MiddleOfDay();
  }

  try {
    // 2. Parse YAML and recursively convert to standard Dart types (Map/List)
    final dynamic yamlData = loadYaml(fileContent);
    final dynamic data = convertYamlToDart(yamlData);

    if (data is! Map<String, dynamic>) {
      return MiddleOfDay();
    }

    MiddleOfDay middleOfDay;
    if (data['middleOfDay'] is Map<String, dynamic>) {
      // Create instance using the specific section
      middleOfDay =
          MiddleOfDay.fromJson(data['middleOfDay'] as Map<String, dynamic>);
    } else {
      middleOfDay = MiddleOfDay();
    }

    // 4. Fallback: If 'oration' wasn't found in the section, use the root version
    // Some files have 'oration' at the root level instead of inside 'middleOfDay'
    middleOfDay.oration ??= asTextList(data['oration']);

    return middleOfDay;
  } catch (e) {
    // In case of parsing error, return an empty office to prevent the app from crashing
    log('middleOfDayExtract error for $relativePath',
        name: 'MiddleOfDayExtract', level: 1000, error: e);
    return MiddleOfDay();
  }
}
