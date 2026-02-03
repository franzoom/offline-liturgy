import '../../classes/calendar_class.dart';
import 'europe.dart';

/// Short alias for FeastDates to allow for a readable const Map.
class F extends FeastDates {
  const F(int m, int d, int p) : super(month: m, day: d, precedence: p);
}

/// Proper feasts for France
const Map<String, FeastDates> franceFeastsList = {
  // --- JANUARY ---
  'genevieve_of_paris_virgin_france': F(1, 3, 12),
  'remigius_of_reims_bishop_france': F(1, 15, 12),

  // --- FEBRUARY ---
  'our_lady_of_lourdes_france': F(2, 11, 10),
  'bernadette_soubirous_virgin_france': F(2, 18, 12),

  // --- MAY ---
  'louise_de_marillac_religious_france': F(5, 9, 12),
  'ivo_of_kermartin_priest_france': F(5, 19, 12),
  'joan_of_arc_virgin_france': F(5, 30, 12),

  // --- JUNE ---
  'pothinus_of_lyon_bishop_blandina_of_lyon_virgin_and_companions_martyrs_france':
      F(6, 2, 12),
  'clotilde_of_burgundy_france': F(6, 5, 12),

  // --- SEPTEMBER ---
  'our_lady_of_la_salette_france': F(9, 19, 12),
};

Calendar addFranceFeasts(Calendar calendar, int liturgicalYear,
    Map<String, DateTime> liturgicalMainFeasts) {
  // Add Europe first
  addEuropeFeasts(calendar, liturgicalYear, liturgicalMainFeasts);

  // Then France
  calendar.addFeastsToCalendar(
      franceFeastsList, liturgicalYear, liturgicalMainFeasts);

  return calendar;
}
