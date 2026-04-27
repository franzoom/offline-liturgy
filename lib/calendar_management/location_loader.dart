import 'dart:io';
import 'package:yaml/yaml.dart';
import '../classes/calendar_class.dart';
import '../classes/location_class.dart';
import '../tools/data_loader.dart';

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
  static Future<LiturgyData> loadFromDataLoader(
    DataLoader loader, {
    String commonFeastsPath = 'common_feasts.yaml',
  }) async {
    final commonFeasts =
        _parseFeastsFromYaml(await loader.loadYaml(commonFeastsPath));

    final fileNames = await loader.listFiles('locations/');
    final yamlNames = fileNames.where((n) => n.endsWith('.yaml')).toList();

    final results = await Future.wait(
      yamlNames.map((name) async {
        final id = name.replaceAll('.yaml', '');
        final yaml = await loader.loadYaml('locations/$name');
        return (id, yaml);
      }),
    );

    final locationData = {
      for (final (id, yaml) in results)
        if (yaml.isNotEmpty) id: Location.fromYaml(id, yaml),
    };

    return LiturgyData(commonFeasts: commonFeasts, locationData: locationData);
  }

  /// The location hierarchy built from the loaded YAML files.
  List<LocationNode> get locationTree =>
      buildLocationTree(locationData.values.toList());
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

  final entities = await dir.list().toList();
  final files = entities
      .whereType<File>()
      .where((f) => f.path.endsWith('.yaml'))
      .toList();

  final entries = await Future.wait(
    files.map((file) async {
      final id = file.uri.pathSegments.last.replaceAll('.yaml', '');
      return (id, await file.readAsString());
    }),
  );

  return {
    for (final (id, content) in entries) id: Location.fromYaml(id, content)
  };
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
