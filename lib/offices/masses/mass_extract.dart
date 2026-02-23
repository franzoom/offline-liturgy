import 'package:yaml/yaml.dart';
import '../../classes/mass_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/convert_yaml_to_dart.dart';

/// Extracts Mass data from a YAML file.
///
/// Returns a [Masses] instance parsed from the `mass` key of the file.
/// Returns an empty [Masses] if the file is missing or unparseable.
Future<Masses> massExtract(String relativePath, DataLoader dataLoader) async {
  final String fileContent = await dataLoader.loadYaml(relativePath);

  if (fileContent.isEmpty) {
    return Masses();
  }

  try {
    final dynamic yamlData = loadYaml(fileContent);
    final Map<String, dynamic> data = convertYamlToDart(yamlData) ?? {};

    return Masses.fromJson(data);
  } catch (e) {
    print('❌ Error during massExtract for $relativePath: $e');
    return Masses();
  }
}
