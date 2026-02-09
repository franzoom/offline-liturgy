import '../../classes/calendar_class.dart';
import 'europe.dart';

/// Proper feasts for France
const Map<String, FeastDates> franceFeastsList = {
  // --- JANUARY ---
  'france_genevieve_of_paris_virgin': F(1, 3, 12),
  'france_remigius_of_reims_bishop': F(1, 15, 12),

  // --- FEBRUARY ---
  'our_lady_of_lourdes': F(2, 11, 10),
  'france_bernadette_soubirous_virgin': F(2, 18, 12),

  // --- MAY ---
  'france_louise_de_marillac_religious': F(5, 9, 12),
  'france_ivo_of_kermartin_priest': F(5, 19, 12),
  'france_joan_of_arc_virgin': F(5, 30, 12),

  // --- JUNE ---
  'france_pothinus_of_lyon_bishop_blandina_of_lyon_virgin_and_companions_martyrs':
      F(6, 2, 12),
  'france_clotilde_of_burgundy': F(6, 5, 12),

  // --- SEPTEMBER ---
  'france_our_lady_of_la_salette': F(9, 19, 12),
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
