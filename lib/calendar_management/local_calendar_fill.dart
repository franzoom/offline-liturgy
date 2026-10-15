import '../classes/calendar_class.dart';
import '../classes/location_class.dart';

/// Applies the feast chain for [locationId] to [calendar].
/// The ancestor chain is walked from root (continent/community) down to the
/// requested location, so each level can override or suppress what the parent
/// declared — without any location file needing to import its parent.
///
/// [locationData] is the map returned by loadLocationsFromDirectory().
/// When empty (e.g. in tests), the function returns the calendar unchanged.
Calendar localCalendarFill(
  Calendar calendar,
  String locationId,
  Map<String, DateTime> liturgicalMainFeasts, [
  Map<String, Location> locationData = const {},
  Set<String> knownCodes = const {},
]) {
  if (locationData.isEmpty) return calendar;

  final chain = _ancestorChain(locationId, locationData);
  for (final location in chain) {
    location.applyToCalendar(calendar, liturgicalMainFeasts,
        knownCodes: knownCodes);
  }
  return calendar;
}

/// Returns the ancestor chain for [locationId], root first.
List<Location> _ancestorChain(
    String locationId, Map<String, Location> locationData) {
  final chain = <Location>[];
  String? currentId = locationId;
  while (currentId != null) {
    final loc = locationData[currentId];
    if (loc == null) break;
    chain.insert(0, loc);
    currentId = loc.parent;
  }
  return chain;
}

/// Returns [setting] of the nearest location, from [locationId] up its
/// ancestor chain, that defines it; null if none does.
String? _inheritedSetting(String locationId, Map<String, Location> locationData,
    String? Function(Location) setting) {
  String? currentId = locationId;
  while (currentId != null) {
    final loc = locationData[currentId];
    if (loc == null) break;
    final value = setting(loc);
    if (value != null) return value;
    currentId = loc.parent;
  }
  return null;
}

/// Returns the effective ascensionDate for a location, walking up the ancestor
/// chain from most specific to root. Returns 'thursday' if none is found.
String getAscensionDate(
        String locationId, Map<String, Location> locationData) =>
    _inheritedSetting(locationId, locationData, (loc) => loc.ascensionDate) ??
    'thursday';

/// Returns the effective epiphanyDate for a location, walking up the ancestor
/// chain from most specific to root. Returns 'sunday' if none is found.
String getEpiphanyDate(String locationId, Map<String, Location> locationData) =>
    _inheritedSetting(locationId, locationData, (loc) => loc.epiphanyDate) ??
    'sunday';

/// Returns the effective corpusDominiDate for a location, walking up the ancestor
/// chain from most specific to root. Returns 'sunday' if none is found.
String getCorpusDominiDate(
        String locationId, Map<String, Location> locationData) =>
    _inheritedSetting(
        locationId, locationData, (loc) => loc.corpusDominiDate) ??
    'sunday';
