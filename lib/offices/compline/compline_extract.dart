import 'package:yaml/yaml.dart';
import '../../tools/data_loader.dart';
import '../../tools/file_paths.dart';

/// Helper function to search for celebrationTitle key in a YAML file
Future<String> complineTitleExtract(
  String title,
  DataLoader dataLoader,
) async {
  String complineTitle = '';
  try {
    String content = await dataLoader.loadYaml('$specialFilePath/$title.yaml');
    if (content.isEmpty) {
      content = await dataLoader.loadYaml('$sanctoralFilePath/$title.yaml');
    }
    if (content.isEmpty) {
      return '';
    }

    final yamlData = loadYaml(content);
    final data = _convertYamlToDart(yamlData);

    // Return the celebrationTitle value if it exists
    // First, get the 'celebration' Map
    final celebration = data['celebration'] as Map<String, dynamic>?;

    // Then, get the 'title' value from that Map
    if (celebration != null) {
      complineTitle = celebration['title'] as String? ?? '';
    }
  } catch (e) {
    // If any error occurs (file not found, parse error, etc.), return empty string
    return '';
  }
  return complineTitle;
}

/// Recursively converts YamlMap/YamlList to Map<String, dynamic>/List<dynamic>
dynamic _convertYamlToDart(dynamic value) {
  if (value is YamlMap) {
    return value.map((key, val) => MapEntry(key.toString(), _convertYamlToDart(val)));
  } else if (value is YamlList) {
    return value.map((item) => _convertYamlToDart(item)).toList();
  } else {
    return value;
  }
}
