import '../../classes/calendar_class.dart';
import 'europe.dart';

/// Short alias for FeastDates to allow for a readable const Map.
class F extends FeastDates {
  const F(int m, int d, int p) : super(month: m, day: d, precedence: p);
}

/// Proper feasts for Belgium
const Map<String, FeastDates> belgiumFeastsList = {
  // --- JANUARY ---
  'gudula_of_brussels_virgin_belgium': F(1, 8, 12),

  // --- FEBRUARY ---
  'amand_of_maastricht_bishop_belgium': F(2, 6, 10),

  // --- MARCH ---
  'mutien_marie_wiaux_religious_belgium':
      F(1, 30, 12), // Souvent déplacé ou célébré fin Janvier

  // --- MAY ---
  'damien_de_veuster_priest_belgium': F(5, 10, 10),

  // --- AUGUST ---
  'juliana_of_cornillon_virgin_belgium': F(8, 7, 12),

  // --- SEPTEMBER ---
  'lambert_of_maastricht_bishop_martyr_belgium': F(9, 17, 10),

  // --- OCTOBER ---
  'bavo_of_ghent_hermit_belgium': F(10, 1, 12),

  // --- NOVEMBER ---
  'hubert_of_liege_bishop_belgium': F(11, 3, 10),
  'john_berchmans_religious_belgium': F(11, 26, 10),
};

/// Function to inject Belgium specific feasts into the calendar
Calendar addBelgiumFeasts(Calendar calendar, int liturgicalYear,
    Map<String, DateTime> liturgicalMainFeasts) {
  // First, add European feasts
  addEuropeFeasts(calendar, liturgicalYear, liturgicalMainFeasts);

  // Then, add Belgian specific feasts
  calendar.addFeastsToCalendar(
      belgiumFeastsList, liturgicalYear, liturgicalMainFeasts);

  return calendar;
}
