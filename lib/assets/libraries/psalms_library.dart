import 'package:yaml/yaml.dart';
import '../../classes/psalms_class.dart';
import '../../tools/data_loader.dart';

/// Psalms library - loads from individual YAML files with lazy loading.
class PsalmsLibrary {
  static final Map<String, Psalm> _cache = {};
  static final Map<String, Psalm> _cacheAncient = {};

  /// Private helper to transform YAML string into a Psalm instance.
  static Psalm? _parsePsalm(String psalmId, String content) {
    if (content.isEmpty) return null;

    try {
      final yamlData = loadYaml(content);
      return Psalm(
        title: yamlData['title'] as String?,
        subtitle: yamlData['subtitle'] as String?,
        commentary: yamlData['commentary'] as String?,
        biblicalReference: yamlData['biblicalReference'] as String?,
        shortReference: yamlData['shortReference'] as String?,
        content: yamlData['content']?.toString() ?? '',
      );
    } catch (e) {
      print('❌ Error parsing YAML for $psalmId: $e');
      return null;
    }
  }

  /// Gets a single psalm by code.
  static Future<Psalm?> getPsalm(String code, DataLoader dataLoader) async {
    if (_cache.containsKey(code)) return _cache[code];

    try {
      final content = await dataLoader.loadYaml('psalms/$code.yaml');
      final psalm = _parsePsalm(code, content);
      if (psalm != null) _cache[code] = psalm;
      return psalm;
    } catch (e) {
      print('⚠️ Psalm $code not found in main library.');
      return null;
    }
  }

  /// Gets a single ancient psalm with a fallback to the standard version.
  static Future<Psalm?> getPsalmAncient(
      String code, DataLoader dataLoader) async {
    // 1. Check Ancient Cache
    if (_cacheAncient.containsKey(code)) return _cacheAncient[code];

    try {
      // 2. Try loading Ancient version
      final content =
          await dataLoader.loadYaml('psalms/hebrew-greek/$code.yaml');
      final psalm = _parsePsalm(code, content);

      if (psalm != null) {
        _cacheAncient[code] = psalm;
        return psalm;
      }
    } catch (e) {
      print(
          'ℹ️ Ancient version of $code missing. Trying fallback to standard...');
    }

    // 3. Fallback: Try loading the standard version
    // We don't save it in _cacheAncient to avoid duplicating memory,
    // getPsalm will handle its own caching in _cache.
    return await getPsalm(code, dataLoader);
  }

  /// Gets multiple psalms by codes in parallel.
  static Future<Map<String, Psalm>> getPsalms(
    List<String> codes,
    DataLoader dataLoader,
  ) async {
    final results = await Future.wait(
      codes.map((code) => getPsalm(code, dataLoader)),
    );

    final Map<String, Psalm> resultMap = {};
    for (var i = 0; i < codes.length; i++) {
      final psalm = results[i];
      if (psalm != null) resultMap[codes[i]] = psalm;
    }
    return resultMap;
  }

  static void clearCache() {
    _cache.clear();
    _cacheAncient.clear();
  }
}
