import 'package:yaml/yaml.dart';
import '../../classes/vespers_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/convert_yaml_to_dart.dart';

/// Extracts Vespers data from a YAML file
/// Reads the file via DataLoader, parses only the 'vespers' section
Future<Vespers> vespersExtract(
    String relativePath, DataLoader dataLoader) async {
  print('=== vespersExtract DEBUG == Loading file: $relativePath');

  // Load YAML file
  String fileContent = await dataLoader.loadYaml(relativePath);

  if (fileContent.isEmpty) {
    print('ERROR: File is empty or does not exist');
    return Vespers();
  }

  // Parse YAML and convert to Dart types
  final yamlData = loadYaml(fileContent);
  final data = convertYamlToDart(yamlData);

  // Extract oration from root level if present
  List<String> oration = List<String>.from(data['oration'] ?? []);

  // Create Vespers from data (from 'vespers' section if exists, otherwise empty)
  Vespers vespers;
  if (data['vespers'] != null) {
    vespers = Vespers.fromJson(data['vespers'] as Map<String, dynamic>);
  } else {
    vespers = Vespers();
  }

  // If oration is not in vespers section, check in main section of the yaml
  vespers.oration ??= oration;

  // Merge root-level evangelicAntiphon (yearA/B/C) into the vespers map
  final rootAntiphon = parseEvangelicAntiphon(data['evangelicAntiphon']);
  if (rootAntiphon != null) {
    vespers.evangelicAntiphon = {
      ...vespers.evangelicAntiphon ?? {},
      ...rootAntiphon,
    };
  }

  print('=== vespersExtract SUCCESS ===');
  return vespers;
}
