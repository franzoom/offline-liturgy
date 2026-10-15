import 'dart:developer';

import '../../classes/middle_of_day_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/yaml_map_loader.dart';

/// Extracts MiddleOfDay data from a YAML file.
///
/// Uses the [DataLoader] to read the file content, then parses the YAML
/// and maps it to a [MiddleOfDay] instance.
Future<MiddleOfDay> middleOfDayExtract(
    String relativePath, DataLoader dataLoader) async {
  final data = await loadYamlMap(relativePath, dataLoader);
  if (data == null) return MiddleOfDay();

  try {
    MiddleOfDay middleOfDay;
    if (data['middleOfDay'] is Map<String, dynamic>) {
      // Create instance using the specific section
      middleOfDay =
          MiddleOfDay.fromJson(data['middleOfDay'] as Map<String, dynamic>);
    } else {
      middleOfDay = MiddleOfDay();
    }

    // Fallback: if 'oration' wasn't found in the section, use the root version
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
