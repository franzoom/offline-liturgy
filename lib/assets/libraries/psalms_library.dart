import '../../classes/psalms_class.dart';
import '../../tools/yaml_map_loader.dart';
import 'text_library.dart';

/// Psalms and canticles, from assets/psalms/.
final psalmsLibrary = TextLibrary<Psalm>('psalms', (content) {
  final data = parseYamlMap(content);
  return data == null ? null : Psalm.fromMap(data);
});
