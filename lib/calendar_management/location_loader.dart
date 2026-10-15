import 'package:yaml/yaml.dart';
import '../classes/calendar_class.dart';
import '../classes/location_class.dart';
import '../tools/data_loader.dart';
import '../tools/date_tools.dart';
import '../tools/celebration_index.dart';

/// Bundles the data sets that must always be loaded together before any
/// calendar computation: the universal Roman feast list, the location tree,
/// and the set of all known celebration codes (from index.json).
class LiturgyData {
  final List<LocationFeast> commonFeasts;
  final Map<String, Location> locationData;
  final Set<String> knownCodes;
  final Set<String> availableSanctoralIds;

  // Not const: locationTree below is computed once, on first access.
  LiturgyData({
    required this.commonFeasts,
    required this.locationData,
    this.knownCodes = const {},
    this.availableSanctoralIds = const {},
  });

  /// For unit tests that verify calendar structure without feast data.
  LiturgyData.empty()
      : commonFeasts = const [],
        locationData = const {},
        knownCodes = const {},
        availableSanctoralIds = const {};

  /// Loads from the filesystem — for CLI/Dart use.
  static Future<LiturgyData> load() =>
      loadFromDataLoader(FileSystemDataLoader());

  /// Loads via a [DataLoader] — for Flutter where assets go through rootBundle.
  static Future<LiturgyData> loadFromDataLoader(DataLoader loader) async {
    final (commonFeastsYaml, fileNames, index) = await (
      loader.loadYaml('calendar_data/common_feasts.yaml'),
      loader.listFiles('locations/'),
      celebrationDirIndex(loader),
    ).wait;

    final results = await Future.wait(
      fileNames.where((n) => n.endsWith('.yaml')).map((name) async {
        final id = name.replaceAll('.yaml', '');
        final yaml = await loader.loadYaml('locations/$name');
        return (id, yaml);
      }),
    );

    final locationData = {
      for (final (id, yaml) in results)
        if (yaml.isNotEmpty) id: Location.fromYaml(id, yaml),
    };

    return LiturgyData(
      commonFeasts: _parseFeastsFromYaml(commonFeastsYaml),
      locationData: locationData,
      knownCodes: index.keys.toSet(),
      availableSanctoralIds:
          await _availableSanctoralIds(loader, locationData.keys),
    );
  }

  /// The location hierarchy built from the loaded YAML files, pruned to only
  /// the nodes that have usable sanctoral data (see [pruneUnavailableLocations]).
  /// Built once, on first access: the data it derives from never changes.
  late final List<LocationNode> locationTree = List.unmodifiable(
    pruneUnavailableLocations(
      buildLocationTree(locationData.values.toList()),
      availableSanctoralIds,
    ),
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

/// Returns the ids among [locationIds] that have at least one file directly
/// under `calendar_data/sanctoral/<id>/`. The listings are independent, so
/// they run in parallel.
Future<Set<String>> _availableSanctoralIds(
    DataLoader loader, Iterable<String> locationIds) async {
  final ids = locationIds.toList();
  final listings = await Future.wait(
      ids.map((id) => loader.listFiles('calendar_data/sanctoral/$id/')));
  return {
    for (int i = 0; i < ids.length; i++)
      if (listings[i].isNotEmpty) ids[i],
  };
}

/// Applies the universal Roman Calendar feasts to [calendar].
/// These are the mandatory base layer; location feasts are applied on top.
void applyCommonFeastsToCalendar(
  Calendar calendar,
  List<LocationFeast> commonFeasts,
  Map<String, DateTime> liturgicalMainFeasts,
) {
  final beginYear = liturgicalMainFeasts['ADVENT']!;
  final endYear = liturgicalMainFeasts['CHRIST_KING']!.shift(6);

  for (final feast in commonFeasts) {
    final feastDates = resolveFixedFeastDate(
      month: feast.month!,
      day: feast.day!,
      beginYear: beginYear,
      endYear: endYear,
    );
    for (final feastDate in feastDates) {
      calendar.addItemToDay(feastDate, feast.precedence, 'roman/${feast.key}');
    }
  }
}
