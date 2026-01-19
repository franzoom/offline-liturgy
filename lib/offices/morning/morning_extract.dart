import 'package:yaml/yaml.dart';
import '../../classes/morning_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/convert_yaml_to_dart.dart';

/// Extracts Morning data from a YAML file
/// Reads the file via DataLoader, parses only the 'morning' section
Future<Morning> morningExtract(
    String relativePath, DataLoader dataLoader) async {
  print('=== morningExtract DEBUG == Loading file: $relativePath');

  // Load YAML file
  String fileContent = await dataLoader.loadYaml(relativePath);

  if (fileContent.isEmpty) {
    print('ERROR: File is empty or does not exist');
    return Morning();
  }

  // Parse YAML and convert to Dart types
  final yamlData = loadYaml(fileContent);
  final data = convertYamlToDart(yamlData);

  // Extract oration from root level if present
  List<String> oration = List<String>.from(data['oration'] ?? []);

  // Create Morning from data (from 'morning' section if exists, otherwise empty)
  Morning morning;
  if (data['morning'] != null) {
    morning = Morning.fromJson(data['morning'] as Map<String, dynamic>);
  } else {
    morning = Morning();
  }

  if (data['invitatory'] != null) {
    Invitatory invitatory =
        Invitatory.fromJson(data['invitatory'] as Map<String, dynamic>);

    List<String> invitatoryPsalms =
        invitatory.psalms ?? ["PSALM_94", "PSALM_66", "PSALM_99", "PSALM_23"];

    // Removes invitatory psalms that are already in morning psalmody
    if (morning.psalmody != null) {
      final psalmsInPsalmody = morning.psalmody!
          .where((entry) => entry.psalm != null)
          .map((entry) => entry.psalm!)
          .toSet();
      invitatoryPsalms = invitatoryPsalms
          .where((psalm) => !psalmsInPsalmody.contains(psalm))
          .toList();
    }

    morning.invitatory =
        Invitatory(antiphon: invitatory.antiphon, psalms: invitatoryPsalms);
  }

  // If oration is not in morning section, check in main section of the yaml
  morning.oration ??= oration;

  print('=== morningExtract SUCCESS ===');
  return morning;
}