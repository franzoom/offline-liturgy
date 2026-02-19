import 'package:yaml/yaml.dart';

/// Recursively converts YamlMap/YamlList to standard Dart Map/List.
/// This is essential for JSON serialization or modifying loaded YAML data.
dynamic convertYamlToDart(dynamic value) {
  if (value is YamlMap) {
    // We explicitly create a Map<String, dynamic> to ensure compatibility
    return Map<String, dynamic>.fromEntries(
      value.entries.map(
        (e) => MapEntry(e.key.toString(), convertYamlToDart(e.value)),
      ),
    );
  } else if (value is YamlList) {
    // Converts YamlList to a standard growable List
    return value.map((item) => convertYamlToDart(item)).toList();
  }

  // Return the primitive value (String, int, bool, null)
  return value;
}
