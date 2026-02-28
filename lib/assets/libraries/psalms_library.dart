import 'package:yaml/yaml.dart';
import '../../classes/psalms_class.dart';
import '../../tools/data_loader.dart';

/// Psalms library - Handles lazy loading from individual YAML files with caching.
class PsalmsLibrary {
  /// Cache for standard liturgical psalms.
  static final Map<String, Psalm> _cache = {};

  /// Cache for ancient (Hebrew/Greek) versions to avoid mixing them with standard ones.
  static final Map<String, Psalm> _cacheAncient = {};

  /// Recursively converts Yaml objects to standard Dart types (Map/List/Primitive).
  /// This provides type safety and better performance than working with YamlMap.
  static dynamic _convertYaml(dynamic value) {
    if (value is YamlMap) {
      return Map<String, dynamic>.fromEntries(
        value.entries
            .map((e) => MapEntry(e.key.toString(), _convertYaml(e.value))),
      );
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

      // Sanitize the data into a standard Dart Map
      final Map<String, dynamic> data = _convertYaml(rawYaml);

      return Psalm(
        title: data['title']?.toString(),
        subtitle: data['subtitle']?.toString(),
        commentary: data['commentary']?.toString(),
        biblicalReference: data['biblicalReference']?.toString(),
        shortReference: data['shortReference']?.toString(),
        content: data['content']?.toString() ?? '',
      );
    } catch (e) {
      print('❌ Error parsing YAML for $psalmId: $e');
      return null;
    }
  }

  /// Retrieves a single psalm by its code with imprecatory fallback logic.
  static Future<Psalm?> getPsalm(
    String code,
    DataLoader dataLoader, {
    bool imprecatory = false,
  }) async {
    final String targetCode = imprecatory ? '${code}_i' : code;

    if (_cache.containsKey(targetCode)) return _cache[targetCode];

    try {
      final content = await dataLoader.loadYaml('psalms/$targetCode.yaml');
      final psalm = _parsePsalm(targetCode, content);

      if (psalm != null) {
        _cache[targetCode] = psalm;
        return psalm;
      } else if (imprecatory) {
        // Fallback to standard version if the imprecatory file is missing (empty content)
        return getPsalm(code, dataLoader, imprecatory: false);
      }
    } catch (e) {
      if (imprecatory) {
        // Fallback to standard version if the imprecatory file threw an error
        return getPsalm(code, dataLoader, imprecatory: false);
      }
    }
    return null;
  }

  /// Gets an ancient version of a psalm. Uses [_cacheAncient].
  /// Falls back to standard [getPsalm] if the ancient version doesn't exist.
  static Future<Psalm?> getPsalmAncient(
    String code,
    DataLoader dataLoader,
  ) async {
    // 1. Check the ancient cache first
    if (_cacheAncient.containsKey(code)) return _cacheAncient[code];

    try {
      // 2. Try loading the specific ancient file
      final content =
          await dataLoader.loadYaml('psalms/hebrew-greek/$code.yaml');
      final psalm = _parsePsalm(code, content);

      if (psalm != null) {
        _cacheAncient[code] = psalm;
        return psalm;
      }
    } catch (e) {
      // If not found, fall back to standard library below
    }

    // 3. Fallback: retrieve the standard psalm
    return await getPsalm(code, dataLoader);
  }

  /// Fetches multiple psalms in parallel.
  static Future<Map<String, Psalm>> getPsalms(
    List<String> codes,
    DataLoader dataLoader, {
    bool imprecatory = false,
  }) async {
    final results = await Future.wait(
      codes.map((code) => getPsalm(code, dataLoader, imprecatory: imprecatory)),
    );

    final Map<String, Psalm> resultMap = {};
    for (var i = 0; i < codes.length; i++) {
      final psalm = results[i];
      if (psalm != null) {
        resultMap[codes[i]] = psalm;
      }
    }
    return resultMap;
  }

  /// Clears all caches to free up memory.
  static void clearCache() {
    _cache.clear();
    _cacheAncient.clear(); // Now properly used in getPsalmAncient
  }
}
