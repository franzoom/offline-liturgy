import '../../classes/psalms_class.dart';
import '../../tools/yaml_map_loader.dart';
import 'text_library.dart';

Psalm? _parsePsalm(String content) {
  final data = parseYamlMap(content);
  return data == null ? null : Psalm.fromMap(data);
}

/// Psalms and canticles, from assets/psalms/.
final psalmsLibrary = TextLibrary<Psalm>('psalms', _parsePsalm);

/// Latin text of the evangelic canticles (Magnificat/Benedictus/Nunc
/// dimittis), from assets/psalms/latin/ — same NT_N codes as their French
/// counterpart in [psalmsLibrary].
final latinCanticlesLibrary = TextLibrary<Psalm>('psalms/latin', _parsePsalm);
