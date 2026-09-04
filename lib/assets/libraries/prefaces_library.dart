import 'dart:developer';

import 'package:yaml/yaml.dart';
import '../../../classes/mass_class.dart';
import '../../../tools/data_loader.dart';

/// Prefaces library - loads from individual YAML files under
/// mass_missal/prefaces/, with lazy loading and caching.
class PrefacesLibrary {
  /// Content-addressed by code — not by which DataLoader instance fetched
  /// it, since a fresh loader is created per call in some consumers (e.g.
  /// Flutter) despite always resolving the same underlying asset source.
  static final Map<String, Preface> _cache = {};

  /// Gets a single preface by code (lazy loading).
  static Future<Preface?> getPreface(String code, DataLoader dataLoader) async {
    final cached = _cache[code];
    if (cached != null) return cached;

    try {
      final content =
          await dataLoader.loadYaml('mass_missal/prefaces/$code.yaml');
      if (content.isEmpty) {
        log('Preface file not found or empty for code: $code',
            name: 'PrefacesLibrary', level: 900);
        return null;
      }
      final yamlData = loadYaml(content) as Map;
      final preface = Preface.fromJson(Map<String, dynamic>.from(yamlData));
      return _cache[code] = preface;
    } catch (e) {
      log('Error loading preface $code',
          name: 'PrefacesLibrary', level: 1000, error: e);
      return null;
    }
  }
}
