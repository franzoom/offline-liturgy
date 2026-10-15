import 'package:yaml/yaml.dart';
import '../../classes/hymns_class.dart';
import 'text_library.dart';

Hymns _parseHymn(String content) {
  final yamlData = loadYaml(content) as Map;
  return Hymns(
    title: yamlData['title'] as String,
    author: yamlData['author'] as String?,
    content: yamlData['content'] as String,
  );
}

/// Hymns, from assets/hymns/.
final hymnsLibrary = TextLibrary<Hymns>('hymns', _parseHymn, keepMisses: true);

/// Solemn blessings of the Mass, which share the hymns' title/content
/// format, from assets/mass_missal/blessings/.
final blessingsLibrary =
    TextLibrary<Hymns>('mass_missal/blessings', _parseHymn, keepMisses: true);
