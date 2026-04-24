import 'package:yaml/yaml.dart';
import '../../classes/psalms_class.dart';
import '../../tools/data_loader.dart';

/// Psalms library - Handles lazy loading from individual YAML files with caching.
class PsalmsLibrary {
  /// Cache for standard liturgical psalms.
  static final Map<String, Psalm> _cache = {};

  /// Cache for ancient (Hebrew/Greek) versions.
  static final Map<String, Psalm> _cacheAncient = {};

  /// Recursively converts Yaml objects to standard Dart types.
  static dynamic _convertYaml(dynamic value) {
    if (value is YamlMap) {
      return value
          .map((key, val) => MapEntry(key.toString(), _convertYaml(val)));
    } else if (value is YamlList) {
      return value.map((item) => _convertYaml(item)).toList();
    }
    return value;
  }

  /// Internal helper to transform a YAML string into a [Psalm] instance.
  static Psalm? _parsePsalm(String psalmId, String content) {
    if (content.isEmpty) return null;

    try {
      final rawYaml = loadYaml(content);
      if (rawYaml == null) return null;

      // conversion and transfer Map to class constructor
      return Psalm.fromMap(_convertYaml(rawYaml));
    } catch (e) {
      print('❌ Error parsing YAML for $psalmId: $e');
      return null;
    }
  }

  /// Retrieves a single psalm by its code.
  static Future<Psalm?> getPsalm(
    String code,
    DataLoader dataLoader,
  ) async {
    if (_cache.containsKey(code)) return _cache[code];

    try {
      final content = await dataLoader.loadYaml('psalms/$code.yaml');
      final psalm = _parsePsalm(code, content);

      if (psalm != null) {
        _cache[code] = psalm;
        return psalm;
      }
    } catch (e) {
      print('❌ Error loading psalm $code: $e');
    }

    return null;
  }

  /// Gets an ancient version of a psalm. Falls back to standard if missing.
  static Future<Psalm?> getPsalmAncient(
    String code,
    DataLoader dataLoader,
  ) async {
    if (_cacheAncient.containsKey(code)) return _cacheAncient[code];

    try {
      final content =
          await dataLoader.loadYaml('psalms/hebrew-greek/$code.yaml');
      final psalm = _parsePsalm(code, content);

      if (psalm != null) {
        _cacheAncient[code] = psalm;
        return psalm;
      }
    } catch (_) {
      // Silently fail to trigger fallback
    }

    return getPsalm(code, dataLoader);
  }

  /// Fetches multiple psalms in parallel efficiently.
  static Future<Map<String, Psalm>> getPsalms(
    List<String> codes,
    DataLoader dataLoader,
  ) async {
    final results = await Future.wait(
      codes.map((code) async {
        final psalm = await getPsalm(code, dataLoader);
        return psalm != null ? MapEntry(code, psalm) : null;
      }),
    );

    // Filter nulls and construct the map in one go
    return Map.fromEntries(results.whereType<MapEntry<String, Psalm>>());
  }

  /// Clears all caches to free up memory.
  static void clearCache() {
    _cache.clear();
    _cacheAncient.clear();
  }
}
