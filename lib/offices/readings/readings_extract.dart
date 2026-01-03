import 'package:yaml/yaml.dart';
import '../../classes/readings_class.dart';
import '../../tools/data_loader.dart';

/// Extracts Readings data from a YAML file
/// Reads the file via DataLoader, parses only the 'readings' section
Future<Readings> readingsExtract(
    String relativePath, DataLoader dataLoader) async {
  print('=== readingsExtract DEBUG == Loading file: $relativePath');

  // Load YAML file
  String fileContent = await dataLoader.loadYaml(relativePath);

  if (fileContent.isEmpty) {
    print('ERROR: File is empty or does not exist');
    return Readings();
  }

  // Parse YAML and convert to Dart types
  final yamlData = loadYaml(fileContent);
  final data = _convertYamlToDart(yamlData);

  // Create Readings from data (from 'readings' section if exists, otherwise empty)
  Readings readings;
  if (data['readings'] != null) {
    readings = Readings.fromJson(data['readings'] as Map<String, dynamic>);
  } else {
    readings = Readings();
  }

  print('=== readingsExtract SUCCESS ===');
  return readings;
}

/// Recursively converts YamlMap/YamlList to Map<String, dynamic>/List<dynamic>
dynamic _convertYamlToDart(dynamic value) {
  if (value is YamlMap) {
    return value
        .map((key, val) => MapEntry(key.toString(), _convertYamlToDart(val)));
  } else if (value is YamlList) {
    return value.map((item) => _convertYamlToDart(item)).toList();
  } else {
    return value;
  }
}
