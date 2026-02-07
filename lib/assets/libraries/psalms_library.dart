import 'package:yaml/yaml.dart';
import '../../classes/psalms_class.dart';
import '../../tools/data_loader.dart';

/// Psalms library - loads from individual YAML files with lazy loading.
class PsalmsLibrary {
  /// Caches to avoid reloading files already in memory.
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

  /// Gets a single psalm by code with optional imprecatory version.
  /// If [imprecatory] is true, it tries to load 'code_i.yaml' first.
  static Future<Psalm?> getPsalm(
    String code,
    DataLoader dataLoader, {
    bool imprecatory = false,
  }) async {
    // 1. Determine the code to load (handle imprecatory postfix)
    final String targetCode = imprecatory ? '${code}_i' : code;

    // 2. Check cache
    if (_cache.containsKey(targetCode)) return _cache[targetCode];

    try {
      // 3. Try loading the target version
      final content = await dataLoader.loadYaml('psalms/$targetCode.yaml');
      final psalm = _parsePsalm(targetCode, content);

      if (psalm != null) {
        _cache[targetCode] = psalm;
        return psalm;
      }
    } catch (e) {
      // 4. Fallback: If imprecatory failed, try the standard version
      if (imprecatory) {
        print(
            'ℹ️ Imprecatory version $targetCode not found. Falling back to standard $code.');
        return getPsalm(code, dataLoader, imprecatory: false);
      }
      print('⚠️ Psalm $code not found in main library.');
    }

    return null;
  }

  /// Gets a single ancient psalm with a fallback to the standard version.
  static Future<Psalm?> getPsalmAncient(
    String code,
    DataLoader dataLoader,
  ) async {
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

    // 3. Fallback: Use standard getPsalm (which handles its own caching)
    // Note: If you want imprecatory support here, you could pass the param through.
    return await getPsalm(code, dataLoader);
  }

  /// Gets multiple psalms by codes in parallel.
  static Future<Map<String, Psalm>> getPsalms(
    List<String> codes,
    DataLoader dataLoader, {
    bool imprecatory = false,
  }) async {
    // Fetch all requested psalms concurrently
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
    print('🗑️ PsalmsLibrary: Clearing all caches.');
    _cache.clear();
    _cacheAncient.clear();
  }
}
