import 'package:yaml/yaml.dart';
import 'calendar_class.dart';

enum LocationGeography {
  continent,
  country,
  diocese,
  city,
  church,
  community;

  static LocationGeography fromString(String s) => switch (s) {
        'continent' => continent,
        'country' => country,
        'diocese' => diocese,
        'city' => city,
        'church' => church,
        'community' => community,
        _ => throw FormatException('Unknown geography type: $s'),
      };

  int get priority => switch (this) {
        continent || community => 1,
        country => 2,
        diocese => 3,
        city || church => 4,
      };
}

class LocationFeast {
  final String key;
  final int? month;
  final int? day;
  final int? precedence;
  final bool suppress;
  final String? relativeTo;
  final int? shift;

  const LocationFeast({
    required this.key,
    this.month,
    this.day,
    this.precedence,
    this.suppress = false,
    this.relativeTo,
    this.shift,
  });

  factory LocationFeast.fromYaml(String key, dynamic data) {
    if (data is! Map) throw FormatException('Feast "$key" must be a YAML map');
    return LocationFeast(
      key: key,
      month: data['month'] as int?,
      day: data['day'] as int?,
      precedence: data['precedence'] as int?,
      suppress: data['suppress'] as bool? ?? false,
      relativeTo: data['relativeTo'] as String?,
      shift: data['shift'] as int?,
    );
  }
}

class Location {
  final String id;
  final String language;
  final LocationGeography geography;
  final String? parent;
  final String frenchName;
  final String? epiphanyDate;
  final String? ascensionDate;
  final List<LocationFeast> feasts;

  const Location({
    required this.id,
    required this.language,
    required this.geography,
    this.parent,
    required this.frenchName,
    this.epiphanyDate,
    this.ascensionDate,
    required this.feasts,
  });

  factory Location.fromYaml(String id, String yamlContent) {
    final doc = loadYaml(yamlContent) as Map;
    final feastMap = doc['feasts'] as Map? ?? {};
    final feasts = [
      for (final entry in feastMap.entries)
        LocationFeast.fromYaml(entry.key as String, entry.value),
    ];
    return Location(
      id: id,
      language: doc['language'] as String,
      geography: LocationGeography.fromString(doc['geography'] as String),
      parent: doc['parent'] as String?,
      frenchName: doc['frenchName'] as String,
      epiphanyDate: doc['epiphanyDate'] as String?,
      ascensionDate: doc['ascensionDate'] as String?,
      feasts: feasts,
    );
  }

  /// Applies this location's feasts to the calendar.
  /// Fixed-date feasts are moved if already present (e.g. override from Roman calendar),
  /// or added if new. Relative feasts are anchored to a key liturgical date.
  /// Suppressed feasts are removed wherever they appear.
  void applyToCalendar(
    Calendar calendar,
    int liturgicalYear,
    Map<String, DateTime> liturgicalMainFeasts,
  ) {
    final beginYear = liturgicalMainFeasts['ADVENT']!;
    final endYear =
        liturgicalMainFeasts['CHRIST_KING']!.add(const Duration(days: 6));
    final prevYear = liturgicalYear - 1;

    for (final feast in feasts) {
      if (feast.suppress) {
        calendar.removeFeastFromCalendar(feast.key);
      } else if (feast.relativeTo != null) {
        final baseDate = liturgicalMainFeasts[feast.relativeTo];
        if (baseDate != null) {
          calendar.addItemRelatedToFeast(
              baseDate, feast.shift ?? 0, feast.precedence!, feast.key);
        }
      } else {
        var feastDate = DateTime(liturgicalYear, feast.month!, feast.day!);
        if (feastDate.isAfter(endYear)) {
          feastDate = DateTime(prevYear, feast.month!, feast.day!);
        }
        if (!feastDate.isBefore(beginYear) && feastDate.isBefore(endYear)) {
          calendar.moveItemToDate(feast.key, feastDate, feast.precedence!);
        }
      }
    }
  }
}

/// Immutable node in the location hierarchy tree.
class LocationNode {
  final Location location;
  final List<LocationNode> children;

  const LocationNode({required this.location, this.children = const []});
}

/// Builds the location hierarchy from a flat list, using each location's [parent] field.
/// Returns root nodes sorted by priority (continent/community first).
List<LocationNode> buildLocationTree(List<Location> locations) {
  final nodeMap = <String, _MutableNode>{
    for (final loc in locations) loc.id: _MutableNode(loc),
  };

  final roots = <_MutableNode>[];
  for (final node in nodeMap.values) {
    final parentId = node.location.parent;
    if (parentId == null) {
      roots.add(node);
    } else {
      nodeMap[parentId]?.children.add(node);
    }
  }

  int byPriority(_MutableNode a, _MutableNode b) =>
      a.location.geography.priority.compareTo(b.location.geography.priority);

  void sort(List<_MutableNode> nodes) {
    nodes.sort(byPriority);
    for (final n in nodes) {
      sort(n.children);
    }
  }

  sort(roots);
  return roots.map((n) => n.toImmutable()).toList();
}

class _MutableNode {
  final Location location;
  final List<_MutableNode> children = [];
  _MutableNode(this.location);

  LocationNode toImmutable() => LocationNode(
        location: location,
        children: children.map((c) => c.toImmutable()).toList(),
      );
}
