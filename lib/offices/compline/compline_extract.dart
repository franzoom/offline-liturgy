import 'package:yaml/yaml.dart';
import '../../tools/data_loader.dart';
import '../../tools/constants.dart';
import '../../tools/convert_yaml_to_dart.dart';

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
    final data = convertYamlToDart(yamlData);

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