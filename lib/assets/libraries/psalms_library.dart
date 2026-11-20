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

/// Greek text of the evangelic canticles, from assets/psalms/greek/ — same
/// NT_N codes as their French counterpart in [psalmsLibrary].
final greekCanticlesLibrary = TextLibrary<Psalm>('psalms/greek', _parsePsalm);

/// Hebrew text of the psalms, from assets/psalms/hebrew/ — same PSALM_N
/// codes as their French counterpart in [psalmsLibrary]. Only PSALM_N
/// codes have a Hebrew file today; a lookup for any other code (e.g. an
/// OT_N/NT_N canticle used as psalmody) resolves to null.
final hebrewPsalmsLibrary = TextLibrary<Psalm>('psalms/hebrew', _parsePsalm);
