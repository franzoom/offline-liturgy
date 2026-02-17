import 'package:yaml/yaml.dart';
import '../../classes/middle_of_day_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/convert_yaml_to_dart.dart';

/// Extracts MiddleOfDay data from a YAML file
/// Reads the file via DataLoader, parses only the 'middleOfDay' section
Future<MiddleOfDay> middleOfDayExtract(
    String relativePath, DataLoader dataLoader) async {
  print('=== middleOfDayExtract DEBUG == Loading file: $relativePath');

  // Load YAML file
  String fileContent = await dataLoader.loadYaml(relativePath);

  if (fileContent.isEmpty) {
    print('ERROR: File is empty or does not exist');
    return MiddleOfDay();
  }

  // Parse YAML and convert to Dart types
  final yamlData = loadYaml(fileContent);
  final data = convertYamlToDart(yamlData);

  // Extract oration from root level if present
  List<String> oration = List<String>.from(data['oration'] ?? []);

  // Create MiddleOfDay from data (from 'middleOfDay' section if exists, otherwise empty)
  MiddleOfDay middleOfDay;
  if (data['middleOfDay'] != null) {
    middleOfDay =
        MiddleOfDay.fromJson(data['middleOfDay'] as Map<String, dynamic>);
  } else {
    middleOfDay = MiddleOfDay();
  }

  // If oration is not in middleOfDay section, check in main section of the yaml
  middleOfDay.oration ??= oration;

  print('=== middleOfDayExtract SUCCESS ===');
  return middleOfDay;
}
