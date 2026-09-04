import 'package:yaml/yaml.dart';
import '../../../classes/mass_class.dart';
import '../../../tools/data_loader.dart';

/// Eucharistic prayer Communicantes inserts library - loads from individual
/// YAML files under mass_missal/eucharistic_prayer_communicantes/, with lazy
/// loading and caching.
class EucharisticPrayerCommunicantesLibrary {
  static final Map<DataLoader, Map<String, EucharisticPrayerCommunicantes>>
      _cachesByLoader = {};

  static Map<String, EucharisticPrayerCommunicantes> _cache(
          DataLoader loader) =>
      _cachesByLoader[loader] ??= {};

  /// Gets a single eucharistic prayer Communicantes insert by code (lazy
  /// loading).
  static Future<EucharisticPrayerCommunicantes?>
      getEucharisticPrayerCommunicantes(
    String code,
    DataLoader dataLoader,
  ) async {
    final cache = _cache(dataLoader);
    final cached = cache[code];
    if (cached != null) return cached;

    try {
      final content = await dataLoader
          .loadYaml('mass_missal/eucharistic_prayer_communicantes/$code.yaml');
      if (content.isEmpty) {
        print(
            '⚠️ Warning: Eucharistic prayer Communicantes file not found or empty for code: $code');
        return null;
      }
      final insert =
          EucharisticPrayerCommunicantes.fromJson(loadYaml(content) as List);
      return cache[code] = insert;
    } catch (e) {
      print('❌ Error loading eucharistic prayer Communicantes $code: $e');
      return null;
    }
  }
}
