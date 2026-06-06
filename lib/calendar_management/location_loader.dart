import 'dart:convert';
import 'dart:io';
import 'package:yaml/yaml.dart';
import '../classes/calendar_class.dart';
import '../classes/location_class.dart';
import '../tools/data_loader.dart';

/// Bundles the data sets that must always be loaded together before any
/// calendar computation: the universal Roman feast list, the location tree,
/// and the set of all known celebration codes (from index.json).
class LiturgyData {
  final List<LocationFeast> commonFeasts;
  final Map<String, Location> locationData;
  final Set<String> knownCodes;

  const LiturgyData({
    required this.commonFeasts,
    required this.locationData,
    this.knownCodes = const {},
  });

  /// For unit tests that verify calendar structure without feast data.
  const LiturgyData.empty()
      : commonFeasts = const [],
        locationData = const {},
        knownCodes = const {};

  /// Loads from the filesystem — for CLI/Dart use.
  static Future<LiturgyData> load({
    String commonFeastsPath = './assets/calendar_data/common_feasts.yaml',
    String locationsDir = './assets/locations/',
    String indexPath = './assets/calendar_data/index.json',
  }) async {
    final results = await Future.wait([
      _loadCommonFeasts(commonFeastsPath),
      _loadLocationsFromDirectory(locationsDir),
      _loadKnownCodes(indexPath),
    ]);
    return LiturgyData(
      commonFeasts: results[0] as List<LocationFeast>,
      locationData: results[1] as Map<String, Location>,
      knownCodes: results[2] as Set<String>,
    );
  }

  /// Loads via a [DataLoader] — for Flutter where assets go through rootBundle.
  static Future<LiturgyData> loadFromDataLoader(
    DataLoader loader, {
    String commonFeastsPath = 'calendar_data/common_feasts.yaml',
    String indexPath = 'calendar_data/index.json',
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

    final knownCodes = _parseKnownCodes(await loader.loadJson(indexPath));

    return LiturgyData(
      commonFeasts: commonFeasts,
      locationData: locationData,
      knownCodes: knownCodes,
    );
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

Set<String> _parseKnownCodes(String raw) {
  if (raw.isEmpty) return {};
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  return decoded.keys.toSet();
}

Future<Set<String>> _loadKnownCodes(String jsonPath) async {
  return _parseKnownCodes(await File(jsonPath).readAsString());
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
      calendar.addItemToDay(feastDate, feast.precedence!, 'roman/${feast.key}');
    }
  }
}
