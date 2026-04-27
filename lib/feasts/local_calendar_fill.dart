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
  int liturgicalYear,
  String locationId,
  Map<String, DateTime> liturgicalMainFeasts, [
  Map<String, Location> locationData = const {},
]) {
  if (locationData.isEmpty) return calendar;

  final chain = _ancestorChain(locationId, locationData);
  for (final location in chain) {
    location.applyToCalendar(calendar, liturgicalYear, liturgicalMainFeasts);
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
