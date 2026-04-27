import 'dart:io';
import 'package:yaml/yaml.dart';
import '../classes/calendar_class.dart';
import '../classes/location_class.dart';
import 'data_loader.dart';

/// Bundles the two data sets that must always be loaded together before any
/// calendar computation: the universal Roman feast list and the location tree.
class LiturgyData {
  final List<LocationFeast> commonFeasts;
  final Map<String, Location> locationData;

  const LiturgyData({
    required this.commonFeasts,
    required this.locationData,
  });

  /// For unit tests that verify calendar structure without feast data.
  const LiturgyData.empty()
      : commonFeasts = const [],
        locationData = const {};

  /// Loads from the filesystem — for CLI/Dart use.
  static Future<LiturgyData> load({
    String commonFeastsPath = './assets/common_feasts.yaml',
    String locationsDir = './assets/locations/',
  }) async {
    final commonFeasts = await _loadCommonFeasts(commonFeastsPath);
    final locationData = await _loadLocationsFromDirectory(locationsDir);
    return LiturgyData(commonFeasts: commonFeasts, locationData: locationData);
  }

  /// Loads via a [DataLoader] — for Flutter where assets go through rootBundle.
  /// Reads [manifestPath] first to discover location file IDs, then loads each.
  static Future<LiturgyData> loadFromDataLoader(
    DataLoader loader, {
    String commonFeastsPath = 'common_feasts.yaml',
    String manifestPath = 'locations/manifest.yaml',
  }) async {
    final commonFeasts =
        _parseFeastsFromYaml(await loader.loadYaml(commonFeastsPath));

    final manifestYaml = await loader.loadYaml(manifestPath);
    final manifestDoc = loadYaml(manifestYaml) as Map;
    final ids = (manifestDoc['locations'] as List).cast<String>();

    final locationData = <String, Location>{};
    for (final id in ids) {
      final yaml = await loader.loadYaml('locations/$id.yaml');
      if (yaml.isNotEmpty) locationData[id] = Location.fromYaml(id, yaml);
    }

    return LiturgyData(commonFeasts: commonFeasts, locationData: locationData);
  }
}

List<LocationFeast> _parseFeastsFromYaml(String yamlContent) {
  if (yamlContent.isEmpty) return [];
  final doc = loadYaml(yamlContent);
  if (doc is! Map) return [];
  final feastMap = doc['feasts'] as Map? ?? {};
  return [
    for (final e in feastMap.entries)
      LocationFeast.fromYaml(e.key as String, e.value),
  ];
}

Future<List<LocationFeast>> _loadCommonFeasts(String yamlPath) async {
  return _parseFeastsFromYaml(await File(yamlPath).readAsString());
}

Future<Map<String, Location>> _loadLocationsFromDirectory(
    String directoryPath) async {
  final dir = Directory(directoryPath);
  final result = <String, Location>{};

  await for (final entity in dir.list()) {
    if (entity is! File || !entity.path.endsWith('.yaml')) continue;
    final id = entity.uri.pathSegments.last.replaceAll('.yaml', '');
    final content = await entity.readAsString();
    result[id] = Location.fromYaml(id, content);
  }

  return result;
}

/// Applies the universal Roman Calendar feasts to [calendar].
/// These are the mandatory base layer; location feasts are applied on top.
void applyCommonFeastsToCalendar(
  Calendar calendar,
  List<LocationFeast> commonFeasts,
  int liturgicalYear,
  Map<String, DateTime> liturgicalMainFeasts,
) {
  final beginYear = liturgicalMainFeasts['ADVENT']!;
  final endYear =
      liturgicalMainFeasts['CHRIST_KING']!.add(const Duration(days: 6));
  final prevYear = liturgicalYear - 1;

  for (final feast in commonFeasts) {
    var feastDate = DateTime(liturgicalYear, feast.month!, feast.day!);
    if (feastDate.isAfter(endYear)) {
      feastDate = DateTime(prevYear, feast.month!, feast.day!);
    }
    if (!feastDate.isBefore(beginYear) && feastDate.isBefore(endYear)) {
      calendar.addItemToDay(feastDate, feast.precedence!, feast.key);
    }
  }
}
