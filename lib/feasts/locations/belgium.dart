import '../../classes/calendar_class.dart';
import 'europe.dart';

/// Proper feasts for Belgium
const Map<String, FeastDates> belgiumFeastsList = {
  // --- JANUARY ---
  'belgium_gudula_of_brussels_virgin': F(1, 8, 12),

  // --- FEBRUARY ---
  'belgium_amand_of_maastricht_bishop': F(2, 6, 10),

  // --- MARCH ---
  'belgium_mutien_marie_wiaux_religious':
      F(1, 30, 12), // Souvent déplacé ou célébré fin Janvier

  // --- MAY ---
  'belgium_damien_de_veuster_priest': F(5, 10, 10),

  // --- AUGUST ---
  'belgium_juliana_of_cornillon_virgin': F(8, 7, 12),

  // --- SEPTEMBER ---
  'belgium_lambert_of_maastricht_bishop_martyr': F(9, 17, 10),

  // --- OCTOBER ---
  'belgium_bavo_of_ghent_hermit': F(10, 1, 12),

  // --- NOVEMBER ---
  'belgium_hubert_of_liege_bishop': F(11, 3, 10),
  'belgium_john_berchmans_religious': F(11, 26, 10),
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
