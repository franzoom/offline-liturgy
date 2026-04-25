import 'package:yaml/yaml.dart';
import '../../classes/psalms_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/convert_yaml_to_dart.dart';

/// Psalms library - Handles lazy loading from individual YAML files with caching.
class PsalmsLibrary {
  /// Cache for standard liturgical psalms.
  static final Map<String, Psalm> _cache = {};

  /// Cache for ancient (Hebrew/Greek) versions.
  static final Map<String, Psalm> _cacheAncient = {};

  /// Internal helper to transform a YAML string into a [Psalm] instance.
  static Psalm? _parsePsalm(String psalmId, String content) {
    if (content.isEmpty) return null;

    try {
      final rawYaml = loadYaml(content);
      if (rawYaml == null) return null;
      return Psalm.fromMap(convertYamlToDart(rawYaml));
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
    final cached = _cache[code];
    if (cached != null) return cached;

    try {
      final content = await dataLoader.loadYaml('psalms/$code.yaml');
      final psalm = _parsePsalm(code, content);
      if (psalm != null) return _cache[code] = psalm;
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
    final cached = _cacheAncient[code];
    if (cached != null) return cached;

    try {
      final content =
          await dataLoader.loadYaml('psalms/hebrew-greek/$code.yaml');
      final psalm = _parsePsalm(code, content);
      if (psalm != null) return _cacheAncient[code] = psalm;
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
      codes.map((code) => getPsalm(code, dataLoader)
          .then((psalm) => psalm != null ? MapEntry(code, psalm) : null)),
    );

    return Map.fromEntries(results.whereType<MapEntry<String, Psalm>>());
  }
}
