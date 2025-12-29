import 'dart:convert';
import 'package:yaml/yaml.dart';
import '../../classes/psalms_class.dart';
import '../../tools/data_loader.dart';

/// Psalms library - loads from individual YAML files with lazy loading
class PsalmsLibrary {
  /// Individual psalm cache - only loads psalms as needed
  static final Map<String, Psalm> _cache = {};
  static Map<String, Psalm>? _cacheAncient;

  /// List of all psalm IDs (to know which files to load)
  static const List<String> _psalmIds = [
    'PSALM_1', 'PSALM_2', 'PSALM_3', 'PSALM_4', 'PSALM_5', 'PSALM_6',
    'PSALM_7_1', 'PSALM_7_2', 'PSALM_8', 'PSALM_9A_1', 'PSALM_9A_2',
    'PSALM_9B_1', 'PSALM_9B_2', 'PSALM_10', 'PSALM_11', 'PSALM_12',
    'PSALM_13', 'PSALM_14', 'PSALM_15', 'PSALM_16_1', 'PSALM_16_2',
    'PSALM_17_1', 'PSALM_17_2', 'PSALM_17_3', 'PSALM_17_4', 'PSALM_17_5',
    'PSALM_17_6', 'PSALM_18A', 'PSALM_18B', 'PSALM_19', 'PSALM_20',
    'PSALM_21_1', 'PSALM_21_2', 'PSALM_21_3', 'PSALM_22', 'PSALM_23',
    'PSALM_24_1', 'PSALM_24_2', 'PSALM_25', 'PSALM_26_1', 'PSALM_26_2',
    'PSALM_27', 'PSALM_28', 'PSALM_29', 'PSALM_30_1', 'PSALM_30_2',
    'PSALM_30_3', 'PSALM_31', 'PSALM_32', 'PSALM_32_1', 'PSALM_32_2',
    'PSALM_33_1', 'PSALM_33_2', 'PSALM_34_1', 'PSALM_34_2', 'PSALM_34_3',
    'PSALM_35', 'PSALM_36_1', 'PSALM_36_2', 'PSALM_36_3', 'PSALM_37_1',
    'PSALM_37_2', 'PSALM_37_3', 'PSALM_38_1', 'PSALM_38_2', 'PSALM_39_1',
    'PSALM_39_2', 'PSALM_40', 'PSALM_41', 'PSALM_42', 'PSALM_43_1',
    'PSALM_43_2', 'PSALM_43_3', 'PSALM_44_1', 'PSALM_44_2', 'PSALM_45',
    'PSALM_46', 'PSALM_47', 'PSALM_48_1', 'PSALM_48_2', 'PSALM_49_1',
    'PSALM_49_2', 'PSALM_49_3', 'PSALM_50', 'PSALM_51', 'PSALM_52',
    'PSALM_53', 'PSALM_54_1', 'PSALM_54_2', 'PSALM_55', 'PSALM_56',
    'PSALM_58', 'PSALM_59', 'PSALM_60', 'PSALM_61', 'PSALM_62',
    'PSALM_63', 'PSALM_64', 'PSALM_65_1', 'PSALM_65_2', 'PSALM_66',
    'PSALM_67_1', 'PSALM_67_2', 'PSALM_67_3', 'PSALM_68_1', 'PSALM_68_2',
    'PSALM_68_3', 'PSALM_69', 'PSALM_70_1', 'PSALM_70_2', 'PSALM_71_1',
    'PSALM_71_2', 'PSALM_72_1', 'PSALM_72_2', 'PSALM_72_3', 'PSALM_73_1',
    'PSALM_73_2', 'PSALM_74', 'PSALM_75_1', 'PSALM_75_2', 'PSALM_76',
    'PSALM_78', 'PSALM_79', 'PSALM_80', 'PSALM_81', 'PSALM_83',
    'PSALM_84', 'PSALM_85', 'PSALM_86', 'PSALM_87', 'PSALM_87_1',
    'PSALM_87_2', 'PSALM_88_1', 'PSALM_88_2', 'PSALM_88_3', 'PSALM_88_4',
    'PSALM_88_5', 'PSALM_89', 'PSALM_90', 'PSALM_91', 'PSALM_91_1',
    'PSALM_91_2', 'PSALM_92', 'PSALM_93_1', 'PSALM_93_2', 'PSALM_94',
    'PSALM_95', 'PSALM_96', 'PSALM_97', 'PSALM_98', 'PSALM_99',
    'PSALM_100', 'PSALM_101_1', 'PSALM_101_2', 'PSALM_101_3', 'PSALM_102_1',
    'PSALM_102_2', 'PSALM_102_3', 'PSALM_103_1', 'PSALM_103_2', 'PSALM_103_3',
    'PSALM_104_1', 'PSALM_104_2', 'PSALM_104_3', 'PSALM_105_1', 'PSALM_105_2',
    'PSALM_105_3', 'PSALM_106_1', 'PSALM_106_2', 'PSALM_106_3', 'PSALM_107',
    'PSALM_109', 'PSALM_110', 'PSALM_111', 'PSALM_112', 'PSALM_113A',
    'PSALM_113B', 'PSALM_114', 'PSALM_115', 'PSALM_116', 'PSALM_117',
    'PSALM_117_1', 'PSALM_117_2', 'PSALM_117_3', 'PSALM_118_1', 'PSALM_118_2',
    'PSALM_118_3', 'PSALM_118_4', 'PSALM_118_5', 'PSALM_118_6', 'PSALM_118_7',
    'PSALM_118_8', 'PSALM_118_9', 'PSALM_118_10', 'PSALM_118_11', 'PSALM_118_12',
    'PSALM_118_13', 'PSALM_118_14', 'PSALM_118_15', 'PSALM_118_16', 'PSALM_118_17',
    'PSALM_118_18', 'PSALM_118_19', 'PSALM_118_20', 'PSALM_118_21', 'PSALM_118_22',
    'PSALM_119', 'PSALM_120', 'PSALM_121', 'PSALM_122', 'PSALM_123',
    'PSALM_124', 'PSALM_125', 'PSALM_126', 'PSALM_127', 'PSALM_128',
    'PSALM_129', 'PSALM_130', 'PSALM_131_1', 'PSALM_131_2', 'PSALM_132',
    'PSALM_133', 'PSALM_134_1', 'PSALM_134_2', 'PSALM_135_1', 'PSALM_135_2',
    'PSALM_135_3', 'PSALM_136', 'PSALM_137', 'PSALM_138_1', 'PSALM_138_2',
    'PSALM_139', 'PSALM_140', 'PSALM_141', 'PSALM_142', 'PSALM_143',
    'PSALM_143a', 'PSALM_143_1', 'PSALM_143_2', 'PSALM_144-1', 'PSALM_144_2',
    'PSALM_144_3', 'PSALM_145', 'PSALM_146', 'PSALM_147', 'PSALM_148',
    'PSALM_149', 'PSALM_150',
    'NT_1', 'NT_2', 'NT_3', 'NT_4', 'NT_5', 'NT_6', 'NT_7', 'NT_8',
    'NT_9', 'NT_10', 'NT_11', 'NT_12',
    'OT_1', 'OT_2', 'OT_3', 'OT_4', 'OT_5', 'OT_6', 'OT_7', 'OT_10',
    'OT_15', 'OT_17', 'OT_19', 'OT_20', 'OT_22', 'OT_23', 'OT_25',
    'OT_27', 'OT_30', 'OT_32', 'OT_34', 'OT_36', 'OT_38', 'OT_39',
    'OT_40', 'OT_41', 'OT_43',
  ];

  /// Loads a single psalm by ID from YAML file
  /// Uses individual caching to avoid reloading
  static Future<Psalm?> _loadPsalmById(
      String psalmId, DataLoader dataLoader) async {
    // Check if already cached
    if (_cache.containsKey(psalmId)) {
      return _cache[psalmId];
    }

    // Load from YAML file
    try {
      final content = await dataLoader.loadYaml('psalms/$psalmId.yaml');

      if (content.isEmpty) {
        print('⚠️  Warning: Empty content for $psalmId');
        return null;
      }

      final yamlData = loadYaml(content);

      final psalm = Psalm(
        title: yamlData['title'] as String?,
        subtitle: yamlData['subtitle'] as String?,
        commentary: yamlData['commentary'] as String?,
        biblicalReference: yamlData['biblicalReference'] as String?,
        shortReference: yamlData['shortReference'] as String?,
        content: yamlData['content'] as String,
      );

      // Cache the loaded psalm
      _cache[psalmId] = psalm;
      return psalm;
    } catch (e) {
      print('❌ Error loading psalm $psalmId: $e');
      return null;
    }
  }

  /// Loads all psalms from individual YAML files (for backward compatibility)
  /// NOTE: This loads ALL psalms - prefer using getPsalms() with specific codes
  @Deprecated('Use getPsalms() instead for better memory efficiency')
  static Future<Map<String, Psalm>> load(DataLoader dataLoader) async {
    print('🔄 PsalmsLibrary: Loading all psalms from YAML files...');
    print('⚠️  Note: Consider using getPsalms() for better performance');

    final psalmsMap = <String, Psalm>{};

    // Load each psalm file individually
    for (final psalmId in _psalmIds) {
      final psalm = await _loadPsalmById(psalmId, dataLoader);
      if (psalm != null) {
        psalmsMap[psalmId] = psalm;
      }
    }

    print('✅ PsalmsLibrary: Loaded ${psalmsMap.length} psalms (${_cache.length} cached)');
    return psalmsMap;
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
    print('🗑️  PsalmsLibrary: Clearing cache (${_cache.length} psalms)');
    _cache.clear();
    _cacheAncient = null;
  }

  /// Gets a single psalm by code (uses lazy loading)
  static Future<Psalm?> getPsalm(String code, DataLoader dataLoader) async {
    print('🔍 getPsalm: $code ${_cache.containsKey(code) ? "(cached)" : "(loading)"}');
    final result = await _loadPsalmById(code, dataLoader);
    if (result == null) {
      print('  ❌ NOT FOUND: $code');
    } else {
      print('  ✅ Found: $code');
    }
    return result;
  }

  /// Gets a single psalm by code from ancient languages library
  static Future<Psalm?> getPsalmAncient(
      String code, DataLoader dataLoader) async {
    final library = await loadAncient(dataLoader);
    return library[code];
  }

  /// Gets multiple psalms by codes (uses lazy loading - only loads requested psalms)
  static Future<Map<String, Psalm>> getPsalms(
    List<String> codes,
    DataLoader dataLoader,
  ) async {
    final cachedCount = codes.where((c) => _cache.containsKey(c)).length;
    print('🔍 getPsalms: ${codes.length} requested, $cachedCount cached, ${codes.length - cachedCount} to load');
    final result = <String, Psalm>{};

    // Load only the requested psalms (checking cache first)
    for (final code in codes) {
      final wasCached = _cache.containsKey(code);
      final psalm = await _loadPsalmById(code, dataLoader);
      if (psalm != null) {
        result[code] = psalm;
        print('  ✅ $code ${wasCached ? "(cached)" : "(loaded)"}');
      } else {
        print('  ❌ NOT FOUND: $code');
      }
    }

    print('📊 getPsalms: returning ${result.length}/${codes.length} psalms (total cache: ${_cache.length})');
    return result;
  }
}
