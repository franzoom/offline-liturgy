import 'dart:convert';
import '../../classes/psalms_class.dart';
import '../../tools/data_loader.dart';

/// Psalms library - loads from JSON file for better memory efficiency
class PsalmsLibrary {
  static Map<String, Psalm>? _cache;
  static Map<String, Psalm>? _cacheAncient;

  /// Loads all psalms from the JSON file
  /// Uses caching to avoid reloading
  static Future<Map<String, Psalm>> load(DataLoader dataLoader) async {
    if (_cache != null) {
      return _cache!;
    }

    try {
      final content =
          await dataLoader.loadJson('common_data/psalms_library.json');

      if (content.isEmpty) {
        throw Exception('Psalms library JSON file is empty or not found');
      }

      final jsonData = json.decode(content) as Map<String, dynamic>;
      final psalmsMap = <String, Psalm>{};

      jsonData.forEach((key, value) {
        final psalmData = value as Map<String, dynamic>;
        psalmsMap[key] = Psalm(
          title: psalmData['title'] as String?,
          subtitle: psalmData['subtitle'] as String?,
          commentary: psalmData['commentary'] as String?,
          biblicalReference: psalmData['biblicalReference'] as String?,
          shortReference: psalmData['shortReference'] as String?,
          content: psalmData['content'] as String,
        );
      });

      _cache = psalmsMap;
      return psalmsMap;
    } catch (e) {
      print('Error loading psalms library: $e');
      return {};
    }
  }

  /// Loads all psalms from the Greek/Hebrew JSON file
  /// Uses separate caching to avoid reloading
  static Future<Map<String, Psalm>> loadAncient(DataLoader dataLoader) async {
    if (_cacheAncient != null) {
      return _cacheAncient!;
    }

    try {
      final content = await dataLoader
          .loadJson('common_data/psalms_library_greek_hebrew.json');

      if (content.isEmpty) {
        throw Exception(
            'Ancient psalms library JSON file is empty or not found');
      }

      final jsonData = json.decode(content) as Map<String, dynamic>;
      final psalmsMap = <String, Psalm>{};

      jsonData.forEach((key, value) {
        final psalmData = value as Map<String, dynamic>;
        psalmsMap[key] = Psalm(
          title: psalmData['title'] as String?,
          subtitle: psalmData['subtitle'] as String?,
          commentary: psalmData['commentary'] as String?,
          biblicalReference: psalmData['biblicalReference'] as String?,
          shortReference: psalmData['shortReference'] as String?,
          content: psalmData['content'] as String,
        );
      });

      _cacheAncient = psalmsMap;
      return psalmsMap;
    } catch (e) {
      print('Error loading ancient psalms library: $e');
      return {};
    }
  }

  /// Clears the cache (useful for testing)
  static void clearCache() {
    _cache = null;
    _cacheAncient = null;
  }

  /// Gets a single psalm by code
  static Future<Psalm?> getPsalm(String code, DataLoader dataLoader) async {
    final library = await load(dataLoader);
    return library[code];
  }

  /// Gets a single psalm by code from ancient languages library
  static Future<Psalm?> getPsalmAncient(
      String code, DataLoader dataLoader) async {
    final library = await loadAncient(dataLoader);
    return library[code];
  }

  /// Gets multiple psalms by codes
  static Future<Map<String, Psalm>> getPsalms(
    List<String> codes,
    DataLoader dataLoader,
  ) async {
    final library = await load(dataLoader);
    final result = <String, Psalm>{};

    for (final code in codes) {
      if (library.containsKey(code)) {
        result[code] = library[code]!;
      }
    }

    return result;
  }
}
