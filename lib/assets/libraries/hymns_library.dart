import 'dart:convert';
import '../../../classes/hymns_class.dart';
import '../../../tools/data_loader.dart';

/// Hymns library - loads from JSON file for better memory efficiency
class HymnsLibrary {
  static Map<String, Hymns>? _cache;

  /// Loads all hymns from the JSON file
  /// Uses caching to avoid reloading
  static Future<Map<String, Hymns>> load(DataLoader dataLoader) async {
    if (_cache != null) {
      return _cache!;
    }

    try {
      final content =
          await dataLoader.loadJson('common_data/hymns_library.json');

      if (content.isEmpty) {
        throw Exception('Hymns library JSON file is empty or not found');
      }

      final jsonData = json.decode(content) as Map<String, dynamic>;
      final hymnsMap = <String, Hymns>{};

      jsonData.forEach((key, value) {
        final hymnData = value as Map<String, dynamic>;
        hymnsMap[key] = Hymns(
          title: hymnData['title'] as String,
          author: hymnData['author'] as String?,
          content: hymnData['content'] as String,
        );
      });

      _cache = hymnsMap;
      return hymnsMap;
    } catch (e) {
      print('Error loading hymns library: $e');
      return {};
    }
  }

  /// Clears the cache (useful for testing)
  static void clearCache() {
    _cache = null;
  }

  /// Gets a single hymn by code
  static Future<Hymns?> getHymn(String code, DataLoader dataLoader) async {
    final library = await load(dataLoader);
    return library[code];
  }

  /// Gets multiple hymns by codes
  static Future<Map<String, Hymns>> getHymns(
    List<String> codes,
    DataLoader dataLoader,
  ) async {
    final library = await load(dataLoader);
    final result = <String, Hymns>{};

    for (final code in codes) {
      if (library.containsKey(code)) {
        result[code] = library[code]!;
      }
    }

    return result;
  }
}
