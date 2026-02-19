import 'package:yaml/yaml.dart';
import '../../classes/readings_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/convert_yaml_to_dart.dart';

/// Extracts Readings (Office of Readings) data from a YAML file.
///
/// It focuses on the 'readings' section which typically includes
/// biblical lessons, patristic texts, and their respective responsories.
Future<Readings> readingsExtract(
    String relativePath, DataLoader dataLoader) async {
  // 1. Load the raw YAML content from the data provider
  final String fileContent = await dataLoader.loadYaml(relativePath);

  if (fileContent.isEmpty) {
    return Readings();
  }

  try {
    // 2. Parse YAML and recursively convert to standard Dart types
    final dynamic yamlData = loadYaml(fileContent);
    final Map<String, dynamic> data = convertYamlToDart(yamlData) ?? {};

    // 3. Extract the specific Readings section
    Readings readings;
    if (data['readings'] is Map<String, dynamic>) {
      final Map<String, dynamic> readingsData =
          data['readings'] as Map<String, dynamic>;
      readings = Readings.fromJson(readingsData);

      // 4. Fallback for Oration:
      // If the specific section doesn't have an oration, look at the root level
      if ((readings.oration == null || readings.oration!.isEmpty) &&
          data['oration'] != null) {
        readings.oration = List<String>.from(data['oration']);
      }
    } else {
      // Return empty instance if the 'readings' key is missing
      readings = Readings();
    }

    return readings;
  } catch (e) {
    // Graceful error handling to prevent UI blocking
    print('❌ Error during readingsExtract for $relativePath: $e');
    return Readings();
  }
}
