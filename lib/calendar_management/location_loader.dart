import 'dart:convert';
import 'dart:io';
import 'package:yaml/yaml.dart';
import '../classes/calendar_class.dart';
import '../classes/location_class.dart';
import '../tools/data_loader.dart';
import '../tools/date_tools.dart';

/// Bundles the data sets that must always be loaded together before any
/// calendar computation: the universal Roman feast list, the location tree,
/// and the set of all known celebration codes (from index.json).
class LiturgyData {
  final List<LocationFeast> commonFeasts;
  final Map<String, Location> locationData;
  final Set<String> knownCodes;
  final Set<String> availableSanctoralIds;

  const LiturgyData({
    required this.commonFeasts,
    required this.locationData,
    this.knownCodes = const {},
    this.availableSanctoralIds = const {},
  });

  /// For unit tests that verify calendar structure without feast data.
  const LiturgyData.empty()
      : commonFeasts = const [],
        locationData = const {},
        knownCodes = const {},
        availableSanctoralIds = const {};

  /// Loads from the filesystem — for CLI/Dart use.
  static Future<LiturgyData> load({
    String commonFeastsPath = './assets/calendar_data/common_feasts.yaml',
    String locationsDir = './assets/locations/',
    String indexPath = './assets/calendar_data/index.json',
    String sanctoralDir = './assets/calendar_data/sanctoral',
  }) async {
    final results = await Future.wait([
      _loadCommonFeasts(commonFeastsPath),
      _loadLocationsFromDirectory(locationsDir),
      _loadKnownCodes(indexPath),
    ]);
    final locationData = results[1] as Map<String, Location>;
    final availableSanctoralIds = await _availableSanctoralIdsFromFileSystem(
        sanctoralDir, locationData.keys);
    return LiturgyData(
      commonFeasts: results[0] as List<LocationFeast>,
      locationData: locationData,
      knownCodes: results[2] as Set<String>,
      availableSanctoralIds: availableSanctoralIds,
    );
  }

  /// Loads via a [DataLoader] — for Flutter where assets go through rootBundle.
  static Future<LiturgyData> loadFromDataLoader(
    DataLoader loader, {
    String commonFeastsPath = 'calendar_data/common_feasts.yaml',
    String indexPath = 'calendar_data/index.json',
    String sanctoralPrefix = 'calendar_data/sanctoral',
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
    final availableSanctoralIds = await _availableSanctoralIdsFromLoader(
        loader, sanctoralPrefix, locationData.keys);

    return LiturgyData(
      commonFeasts: commonFeasts,
      locationData: locationData,
      knownCodes: knownCodes,
      availableSanctoralIds: availableSanctoralIds,
    );
  }

  /// The location hierarchy built from the loaded YAML files, pruned to only
  /// the nodes that have usable sanctoral data (see [pruneUnavailableLocations]).
  List<LocationNode> get locationTree => pruneUnavailableLocations(
        buildLocationTree(locationData.values.toList()),
        availableSanctoralIds,
      );
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

/// Returns the ids among [locationIds] that have at least one file directly
/// under `$sanctoralDir/<id>/` on the filesystem.
Future<Set<String>> _availableSanctoralIdsFromFileSystem(
    String sanctoralDir, Iterable<String> locationIds) async {
  final available = <String>{};
  for (final id in locationIds) {
    final dir = Directory('$sanctoralDir/$id');
    if (!await dir.exists()) continue;
    final hasFile = await dir.list().any((entity) => entity is File);
    if (hasFile) available.add(id);
  }
  return available;
}

/// Same as [_availableSanctoralIdsFromFileSystem], but through a [DataLoader]
/// — for asset sources (e.g. Flutter's rootBundle) with no direct filesystem access.
/// The listings are independent, so they run in parallel.
Future<Set<String>> _availableSanctoralIdsFromLoader(DataLoader loader,
    String sanctoralPrefix, Iterable<String> locationIds) async {
  final ids = locationIds.toList();
  final listings = await Future.wait(
      ids.map((id) => loader.listFiles('$sanctoralPrefix/$id/')));
  return {
    for (int i = 0; i < ids.length; i++)
      if (listings[i].isNotEmpty) ids[i],
  };
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
  final endYear = liturgicalMainFeasts['CHRIST_KING']!.shift(6);

  for (final feast in commonFeasts) {
    final feastDates = resolveFixedFeastDate(
      liturgicalYear: liturgicalYear,
      month: feast.month!,
      day: feast.day!,
      beginYear: beginYear,
      endYear: endYear,
    );
    for (final feastDate in feastDates) {
      calendar.addItemToDay(feastDate, feast.precedence!, 'roman/${feast.key}');
    }
  }
}
