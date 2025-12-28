import 'package:yaml/yaml.dart';
import '../../../classes/hymns_class.dart';
import '../../../tools/data_loader.dart';

/// Hymns library - loads from individual YAML files for better memory efficiency
/// Each hymn is stored in a separate YAML file in assets/hymns/
class HymnsLibrary {
  static final Map<String, Hymns> _cache = {};

  /// Loads a single hymn from its YAML file
  /// Uses caching to avoid reloading the same hymn multiple times
  static Future<Hymns?> getHymn(String code, DataLoader dataLoader) async {
    // Check cache first
    if (_cache.containsKey(code)) {
      return _cache[code];
    }

    try {
      // Load the YAML file for this specific hymn
      final content = await dataLoader.loadYaml('hymns/$code.yaml');

      if (content.isEmpty) {
        print('Warning: Hymn file not found for code: $code');
        return null;
      }

      final yamlData = loadYaml(content) as Map;

      final hymn = Hymns(
        title: yamlData['title'] as String,
        author: yamlData['author'] as String?,
        content: yamlData['content'] as String,
      );

      // Cache the loaded hymn
      _cache[code] = hymn;
      return hymn;
    } catch (e) {
      print('Error loading hymn $code: $e');
      return null;
    }
  }

  /// Gets multiple hymns by codes
  /// Loads each hymn individually from its YAML file
  static Future<Map<String, Hymns>> getHymns(
    List<String> codes,
    DataLoader dataLoader,
  ) async {
    final result = <String, Hymns>{};

    for (final code in codes) {
      final hymn = await getHymn(code, dataLoader);
      if (hymn != null) {
        result[code] = hymn;
      }
    }

    return result;
  }

  /// Clears the cache (useful for testing)
  static void clearCache() {
    _cache.clear();
  }

  /// Deprecated: loads all hymns from the old JSON file
  /// This method is kept for backward compatibility but is no longer recommended
  /// Use getHymn() or getHymns() instead to load hymns on-demand
  @Deprecated('Use getHymn() or getHymns() for better memory efficiency')
  static Future<Map<String, Hymns>> load(DataLoader dataLoader) async {
    // This would require loading all YAML files, which defeats the purpose
    // of splitting them. Return empty map and log a warning.
    print(
        'Warning: HymnsLibrary.load() is deprecated. Use getHymn() or getHymns() instead.');
    return {};
  }
}
