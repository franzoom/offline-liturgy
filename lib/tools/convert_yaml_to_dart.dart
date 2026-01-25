import 'package:yaml/yaml.dart';

/// Recursively converts YamlMap/YamlList to Map<String, dynamic>/List<dynamic>
dynamic convertYamlToDart(dynamic value) {
  if (value is YamlMap) {
    return value
        .map((key, val) => MapEntry(key.toString(), convertYamlToDart(val)));
  } else if (value is YamlList) {
    return value.map((item) => convertYamlToDart(item)).toList();
  } else {
    return value;
  }
}
