import 'package:yaml/yaml.dart';
import '../../classes/morning_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/convert_yaml_to_dart.dart';

/// Extracts Morning (Lauds) office data from a YAML file.
///
/// It handles complex merging of Invitatory psalms, root-level orations,
/// and evangelic antiphons specific to liturgical years (A, B, or C).
Future<Morning> morningExtract(
    String relativePath, DataLoader dataLoader) async {
  // 1. Load the raw YAML content
  final String fileContent = await dataLoader.loadYaml(relativePath);

  if (fileContent.isEmpty) {
    return Morning();
  }

  try {
    // 2. Parse YAML and recursively convert to standard Dart types
    final dynamic yamlData = loadYaml(fileContent);
    final Map<String, dynamic> data = convertYamlToDart(yamlData) ?? {};

    // 3. Extract common elements from root level
    final List<String> rootOration = switch (data['oration']) {
      List list => list.map((e) => e.toString()).toList(),
      String s => [s],
      _ => [],
    };
    final Map<String, List<String>>? rootAntiphon =
        parseEvangelicAntiphon(data['evangelicAntiphon']);

    // 4. Extract specific Morning section
    Morning morning;
    if (data['morning'] is Map<String, dynamic>) {
      morning = Morning.fromJson(data['morning'] as Map<String, dynamic>);
    } else {
      morning = Morning();
    }

    // 5. Invitatory: default candidate psalms if none specified.
    // Repetition with the Morning psalmody is filtered later in morningExport,
    // once the psalmody has been fully resolved across ferial/common/proper layers.
    if (data['invitatory'] is Map<String, dynamic>) {
      final invitatory =
          Invitatory.fromJson(data['invitatory'] as Map<String, dynamic>);

      morning.invitatory = Invitatory(
        antiphon: invitatory.antiphon,
        psalms: invitatory.psalms ??
            const ["PSALM_94", "PSALM_66", "PSALM_99", "PSALM_23"],
      );
    }

    // 6. Merge Fallbacks (Oration and Evangelic Antiphons)
    // Root level orations are used if the morning-specific oration is missing
    morning.oration ??= (rootOration.isNotEmpty ? rootOration : null);

    // Merge root-level evangelicAntiphon (useful for Sundays/Feasts with Year cycles)
    if (rootAntiphon != null) {
      morning.evangelicAntiphon = {
        ...morning.evangelicAntiphon ?? {},
        ...rootAntiphon,
      };
    }

    return morning;
  } catch (e) {
    print('❌ Error during morningExtract for $relativePath: $e');
    return Morning();
  }
}
