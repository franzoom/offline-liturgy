import 'dart:developer';

import '../../classes/vespers_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/yaml_map_loader.dart';

/// Extracts Vespers (Evening Prayer) data from a YAML file.
///
/// It parses the [section] key ('vespers' or 'firstVespers') while allowing
/// fallbacks for orations and evangelic antiphons defined at the root level.
Future<Vespers> vespersExtract(String relativePath, DataLoader dataLoader,
    {String section = 'vespers'}) async {
  final data = await loadYamlMap(relativePath, dataLoader);
  if (data == null) return Vespers();

  try {
    // 1. Extract common elements from the root level for fallback purposes
    final Map<String, List<String>>? rootAntiphon =
        parseEvangelicAntiphon(data['evangelicAntiphon']);

    // 2. Extract the specific Vespers section
    Vespers vespers;
    if (data[section] is Map<String, dynamic>) {
      vespers = Vespers.fromJson(data[section] as Map<String, dynamic>);
    } else {
      vespers = Vespers();
    }

    // 3. Apply Fallbacks: Oration
    // Use the root-level oration if the vespers-specific one is missing
    vespers.oration ??= asTextList(data['oration']);

    // 4. Apply Fallbacks: Evangelic Antiphon (Magnificat)
    // Merges root-level antiphons (Year A/B/C) into the vespers-specific map
    vespers.evangelicAntiphon =
        mergeEvangelicAntiphons(vespers.evangelicAntiphon, rootAntiphon);

    return vespers;
  } catch (e) {
    // Graceful failure: return an empty instance to avoid blocking the app
    log('Error during vespersExtract for $relativePath',
        name: 'VespersExtract', level: 1000, error: e);
    return Vespers();
  }
}
