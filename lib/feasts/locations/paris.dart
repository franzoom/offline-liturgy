import '../../classes/calendar_class.dart';
import 'france.dart';

/// Proper feasts for the Archdiocese of Paris
const Map<String, FeastDates> parisFeastsList = {
  // --- JANUARY ---
  'paris_genevieve_of_paris_virgin': F(1, 3, 4),
};

/// Function to inject Paris specific feasts into the calendar
Calendar addParisFeasts(Calendar calendar, int liturgicalYear,
    Map<String, DateTime> liturgicalMainFeasts) {
  // First, add feasts for France (which also adds Europe)
  addFranceFeasts(calendar, liturgicalYear, liturgicalMainFeasts);

  // Then, add Paris specific feasts (overriding or adding to the list)
  calendar.addFeastsToCalendar(
      parisFeastsList, liturgicalYear, liturgicalMainFeasts);

  return calendar;
}
