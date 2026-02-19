import 'package:yaml/yaml.dart';
import '../../classes/vespers_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/convert_yaml_to_dart.dart';

/// Extracts Vespers (Evening Prayer) data from a YAML file.
///
/// It parses the 'vespers' section while allowing fallbacks for orations
/// and evangelic antiphons (Magnificat) defined at the root level of the file.
Future<Vespers> vespersExtract(
    String relativePath, DataLoader dataLoader) async {
  // 1. Load the raw YAML content via the data provider
  final String fileContent = await dataLoader.loadYaml(relativePath);

  if (fileContent.isEmpty) {
    return Vespers();
  }

  try {
    // 2. Parse YAML and recursively convert to standard Dart types (Map/List)
    final dynamic yamlData = loadYaml(fileContent);
    final Map<String, dynamic> data = convertYamlToDart(yamlData) ?? {};

    // 3. Extract common elements from the root level for fallback purposes
    final List<String> rootOration = List<String>.from(data['oration'] ?? []);
    final Map<String, dynamic>? rootAntiphon =
        parseEvangelicAntiphon(data['evangelicAntiphon']);

    // 4. Extract the specific Vespers section
    Vespers vespers;
    if (data['vespers'] is Map<String, dynamic>) {
      vespers = Vespers.fromJson(data['vespers'] as Map<String, dynamic>);
    } else {
      vespers = Vespers();
    }

    // 5. Apply Fallbacks: Oration
    // Use the root-level oration if the vespers-specific one is null or empty
    if (vespers.oration == null || vespers.oration!.isEmpty) {
      if (rootOration.isNotEmpty) {
        vespers.oration = rootOration;
      }
    }

    // 6. Apply Fallbacks: Evangelic Antiphon (Magnificat)
    // Merges root-level antiphons (Year A/B/C) into the vespers-specific map
    if (rootAntiphon != null) {
      vespers.evangelicAntiphon = {
        ...vespers.evangelicAntiphon ?? {},
        ...rootAntiphon,
      };
    }

    return vespers;
  } catch (e) {
    // Graceful failure: return an empty instance to avoid blocking the app
    print('❌ Error during vespersExtract for $relativePath: $e');
    return Vespers();
  }
}
