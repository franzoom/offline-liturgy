import '../../classes/calendar_class.dart';

/// Short alias for FeastDates to allow for a readable const Map.
class F extends FeastDates {
  const F(int m, int d, int p) : super(month: m, day: d, precedence: p);
}

/// Proper feasts for Canada
const Map<String, FeastDates> canadaFeastsList = {
  // --- JANUARY ---
  'andre_bessette_religious_canada': F(1, 7, 10),
  'marguerite_bourgeoys_canada': F(1, 12, 10),
};

/// Function to inject Canada specific feasts into the calendar
Calendar addCanadaFeasts(Calendar calendar, int liturgicalYear,
    Map<String, DateTime> liturgicalMainFeasts) {
  // First, add North-America feasts (currently commented out as per your original)
  // addNorthAmericaFeasts(calendar, liturgicalYear, liturgicalMainFeasts);

  // Add Canada specific feasts
  calendar.addFeastsToCalendar(
      canadaFeastsList, liturgicalYear, liturgicalMainFeasts);

  // Shifting Saint Raymond of Penyafort (usually Jan 7) to Jan 8 to avoid conflict with Andre Bessette
  calendar.moveItemByDays('raymond_of_penyafort_priest', 1);

  return calendar;
}
