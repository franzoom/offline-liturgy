import 'package:yaml/yaml.dart';
import '../../../classes/hymns_class.dart';
import '../../../tools/data_loader.dart';

/// Hymns library - loads from individual YAML files with lazy loading.
class HymnsLibrary {
  /// Content-addressed by code — not by which DataLoader instance fetched
  /// it, since a fresh loader is created per call in some consumers (e.g.
  /// Flutter) despite always resolving the same underlying asset source.
  /// Also memoizes misses (a null value with the key present) so a code
  /// that doesn't resolve to a file isn't reloaded on every lookup.
  static final Map<String, Hymns?> _cache = {};

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

  /// Gets a single hymn by code (lazy loading). [folder] lets non-hymn
  /// content that shares the same title/content format (e.g. solemn
  /// blessings under mass_missal/blessings) reuse this exact mechanism.
  static Future<Hymns?> getHymn(
    String code,
    DataLoader dataLoader, {
    String folder = 'hymns',
  }) async {
    final cacheKey = '$folder/$code';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey];

    try {
      final content = await dataLoader.loadYaml('$folder/$code.yaml');
      return _cache[cacheKey] = _parseHymn(cacheKey, content);
    } catch (e) {
      print('❌ Error loading hymn $cacheKey: $e');
      return _cache[cacheKey] = null;
    }
  }

  /// Gets multiple hymns by codes in parallel.
  static Future<Map<String, Hymns>> getHymns(
    List<String> codes,
    DataLoader dataLoader,
  ) async {
    final results = await Future.wait(
      codes.map((code) => getHymn(code, dataLoader)),
    );

    return {
      for (var i = 0; i < codes.length; i++)
        if (results[i] != null) codes[i]: results[i]!,
    };
  }
}
