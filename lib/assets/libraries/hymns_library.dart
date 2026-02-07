import 'package:yaml/yaml.dart';
import '../../../classes/hymns_class.dart';
import '../../../tools/data_loader.dart';

/// Hymns library - loads from individual YAML files with lazy loading.
class HymnsLibrary {
  static final Map<String, Hymns> _cache = {};

  /// Private helper to transform YAML string into a Hymns instance.
  static Hymns? _parseHymn(String code, String content) {
    if (content.isEmpty) {
      print('⚠️ Warning: Hymn file not found or empty for code: $code');
      return null;
    }

    try {
      final yamlData = loadYaml(content) as Map;
      return Hymns(
        title: yamlData['title'] as String,
        author: yamlData['author'] as String?,
        content: yamlData['content'] as String,
      );
    } catch (e) {
      print('❌ Error parsing YAML for hymn $code: $e');
      return null;
    }
  }

  /// Gets a single hymn by code (lazy loading).
  static Future<Hymns?> getHymn(String code, DataLoader dataLoader) async {
    if (_cache.containsKey(code)) return _cache[code];

    try {
      final content = await dataLoader.loadYaml('hymns/$code.yaml');
      final hymn = _parseHymn(code, content);

      if (hymn != null) {
        _cache[code] = hymn;
        return hymn;
      }
    } catch (e) {
      print('❌ Error loading hymn $code: $e');
    }
    return null;
  }

  /// Gets multiple hymns by codes in parallel.
  static Future<Map<String, Hymns>> getHymns(
    List<String> codes,
    DataLoader dataLoader,
  ) async {
    // Perform all loads concurrently for better performance
    final results = await Future.wait(
      codes.map((code) => getHymn(code, dataLoader)),
    );

    final Map<String, Hymns> resultMap = {};
    for (var i = 0; i < codes.length; i++) {
      final hymn = results[i];
      if (hymn != null) {
        resultMap[codes[i]] = hymn;
      }
    }
    return resultMap;
  }

  /// Clears the cache to free up memory.
  static void clearCache() {
    _cache.clear();
  }
}
