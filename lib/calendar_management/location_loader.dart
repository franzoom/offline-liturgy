import 'dart:convert';
import 'package:yaml/yaml.dart';
import '../classes/calendar_class.dart';
import '../classes/location_class.dart';
import '../tools/data_loader.dart';
import '../tools/celebration_index.dart';

/// Bundles the data sets that must always be loaded together before any
/// calendar computation: the universal Roman feast list, the location tree,
/// and the set of all known celebration codes (from index.json).
class LiturgyData {
  final List<LocationFeast> commonFeasts;
  final Map<String, Location> locationData;
  final Set<String> knownCodes;
  final Set<String> validatedLocationIds;

  // Not const: locationTree below is computed once, on first access.
  LiturgyData({
    required this.commonFeasts,
    required this.locationData,
    this.knownCodes = const {},
    this.validatedLocationIds = const {},
  });

  /// For unit tests that verify calendar structure without feast data.
  LiturgyData.empty()
      : commonFeasts = const [],
        locationData = const {},
        knownCodes = const {},
        validatedLocationIds = const {};

  /// Loads from the filesystem — for CLI/Dart use.
  static Future<LiturgyData> load() =>
      loadFromDataLoader(FileSystemDataLoader());

  /// Loads via a [DataLoader] — for Flutter where assets go through rootBundle.
  static Future<LiturgyData> loadFromDataLoader(DataLoader loader) async {
    final (commonFeastsYaml, fileNames, index, validatedLocationsJson) =
        await (
      loader.loadYaml('calendar_data/common_feasts.yaml'),
      loader.listFiles('locations/'),
      celebrationDirIndex(loader),
      loader.loadJson('calendar_data/validated_locations.json'),
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
      validatedLocationIds: _parseValidatedLocations(validatedLocationsJson),
    );
  }

  /// The location hierarchy built from the loaded YAML files, pruned to only
  /// the nodes that have usable data (see [pruneUnavailableLocations]).
  /// [validatedLocationIds] is precomputed by `scripts/make_index.py` (see
  /// CLAUDE.md, "Location picker (locationTree) pruning") rather than
  /// recomputed here, so this is a simple filter, not the actual decision.
  /// Built once, on first access: the data it derives from never changes.
  late final List<LocationNode> locationTree = List.unmodifiable(
    pruneUnavailableLocations(
      buildLocationTree(locationData.values.toList()),
      validatedLocationIds,
    ),
  );
}

/// Parses `validated_locations.json`: a flat JSON array of location ids. An
/// empty or malformed file yields an empty set, same as a missing one — the
/// location picker then shows nothing rather than guessing.
Set<String> _parseValidatedLocations(String jsonContent) {
  if (jsonContent.isEmpty) return const {};
  final decoded = jsonDecode(jsonContent);
  if (decoded is! List) return const {};
  return decoded.whereType<String>().toSet();
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

/// Applies the universal Roman Calendar feasts to [calendar].
/// These are the mandatory base layer; location feasts are applied on top.
void applyCommonFeastsToCalendar(
  Calendar calendar,
  List<LocationFeast> commonFeasts,
  Map<String, DateTime> liturgicalMainFeasts,
) {
  for (final feast in commonFeasts) {
    for (final feastDate in feastDates(feast, liturgicalMainFeasts)) {
      calendar.addItemToDay(feastDate, feast.precedence, 'roman/${feast.key}');
    }
  }
}
