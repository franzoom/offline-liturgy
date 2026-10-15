import 'dart:developer';

import 'package:yaml/yaml.dart';
import '../../classes/psalms_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/convert_yaml_to_dart.dart';

/// Psalms library - Handles lazy loading from individual YAML files with caching.
class PsalmsLibrary {
  /// Cache for standard liturgical psalms, content-addressed by code — not
  /// by which DataLoader instance fetched it, since a fresh loader is
  /// created per call in some consumers (e.g. Flutter) despite always
  /// resolving the same underlying asset source.
  static final Map<String, Psalm> _cache = {};

  /// Internal helper to transform a YAML string into a [Psalm] instance.
  static Psalm? _parsePsalm(String psalmId, String content) {
    if (content.isEmpty) return null;

    try {
      final rawYaml = loadYaml(content);
      if (rawYaml == null) return null;
      return Psalm.fromMap(convertYamlToDart(rawYaml));
    } catch (e) {
      log('Error parsing YAML for $psalmId: $e', name: 'PsalmsLibrary');
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
      log('Error loading psalm $code: $e', name: 'PsalmsLibrary');
    }

    return null;
  }
}
