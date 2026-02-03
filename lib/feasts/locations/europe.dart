import '../../classes/calendar_class.dart';

/// Short alias for FeastDates to allow for a readable const Map.
class F extends FeastDates {
  const F(int m, int d, int p) : super(month: m, day: d, precedence: p);
}

/// Patrons of Europe - Fixed Dates
const Map<String, FeastDates> europeFeastsList = {
  // --- FEBRUARY ---
  'cyril_constantine_the_philosopher_monk_and_methodius_michael_of_thessaloniki_bishop_europe':
      F(2, 14, 4),

  // --- APRIL ---
  'catherine_of_siena_virgin_europe': F(4, 29, 4),

  // --- JULY ---
  'benedict_of_nursia_abbot_europe': F(7, 11, 4),
  'bridget_of_sweden_religious_europe': F(7, 23, 4),

  // --- AUGUST ---
  'teresa_benedicta_of_the_cross_stein_virgin_europe': F(8, 9, 4),
};

Calendar addEuropeFeasts(Calendar calendar, int liturgicalYear,
    Map<String, DateTime> liturgicalMainFeasts) {
  calendar.addFeastsToCalendar(
      europeFeastsList, liturgicalYear, liturgicalMainFeasts);

  return calendar;
}
