import '../../classes/calendar_class.dart';

/// Patrons of Europe - Fixed Dates
const Map<String, FeastDates> europeFeastsList = {
  // --- FEBRUARY ---
  'europe_cyril_constantine_the_philosopher_monk_and_methodius_michael_of_thessaloniki_bishop':
      F(2, 14, 4),

  // --- APRIL ---
  'europe_catherine_of_siena_virgin': F(4, 29, 4),

  // --- JULY ---
  'europe_benedict_of_nursia_abbot': F(7, 11, 4),
  'europe_bridget_of_sweden_religious': F(7, 23, 4),

  // --- AUGUST ---
  'europe_teresa_benedicta_of_the_cross_stein_virgin': F(8, 9, 4),
};

Calendar addEuropeFeasts(Calendar calendar, int liturgicalYear,
    Map<String, DateTime> liturgicalMainFeasts) {
  calendar.addFeastsToCalendar(
      europeFeastsList, liturgicalYear, liturgicalMainFeasts);

  return calendar;
}
