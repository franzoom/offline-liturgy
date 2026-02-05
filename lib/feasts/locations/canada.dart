import '../../classes/calendar_class.dart';
import 'north_america.dart';

/// Proper feasts for Canada
const Map<String, FeastDates> canadaFeastsList = {
  // --- JANUARY ---
  'canada_andre_bessette_religious': F(1, 7, 10),
  'canada_marguerite_bourgeoys': F(1, 12, 10),
};

/// Function to inject Canada specific feasts into the calendar
Calendar addCanadaFeasts(Calendar calendar, int liturgicalYear,
    Map<String, DateTime> liturgicalMainFeasts) {
  // First, add North-America feasts
  addNorthAmericaFeasts(calendar, liturgicalYear, liturgicalMainFeasts);

  // Add Canada specific feasts
  calendar.addFeastsToCalendar(
      canadaFeastsList, liturgicalYear, liturgicalMainFeasts);

  // Shifting Saint Raymond of Penyafort (usually Jan 7) to Jan 8 to avoid conflict with Andre Bessette
  calendar.moveItemByDays('raymond_of_penyafort_priest', 1);

  return calendar;
}
