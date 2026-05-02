import 'package:yaml/yaml.dart';
import '../../classes/compline_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/convert_yaml_to_dart.dart';

/// Loads a compline YAML file and extracts the data for a specific day key.
///
/// The YAML file may contain an optional root-level [marialHymns] list (codes)
/// that is applied to the returned Compline if the day section exists and does
/// not define its own marialHymnRef.
///
/// Returns an empty [Compline] if the file is missing or the day key is absent.
Future<Compline> complineExtract(
    String relativePath, String dayKey, DataLoader dataLoader) async {
  final String fileContent = await dataLoader.loadYaml(relativePath);
  if (fileContent.isEmpty) return Compline();

  try {
    final dynamic yamlData = loadYaml(fileContent);
    final Map<String, dynamic> data = convertYamlToDart(yamlData) ?? {};

    final List<HymnEntry>? rootMarialHymns =
        (data['marialHymns'] as List?)?.map((e) => HymnEntry.fromJson(e)).toList();

    final dynamic dayData = data[dayKey];
    if (dayData is! Map<String, dynamic>) return Compline();

    final Compline compline = Compline.fromJson(dayData);
    return compline.marialHymnRef != null
        ? compline
        : compline.copyWith(marialHymnRef: rootMarialHymns);
  } catch (e) {
    print('❌ Error in complineExtract for $relativePath[$dayKey]: $e');
    return Compline();
  }
}
