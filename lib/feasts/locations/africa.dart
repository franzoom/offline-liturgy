import '../../classes/calendar_class.dart';

/// Short alias for FeastDates to allow for a readable const Map.
class F extends FeastDates {
  const F(int m, int d, int p) : super(month: m, day: d, precedence: p);
}

/// Proper feasts for the African Continent
const Map<String, FeastDates> africaFeastsList = {
  // --- JANUARY ---
  'joseph_vaz_priest_africa': F(1, 16, 12),

  // --- FEBRUARY ---
  'josephine_bakhita_virgin_africa':
      F(2, 8, 10), // Souvent mémoire obligatoire en Afrique

  // --- MARCH ---
  'perpetua_of_carthage_and_felicity_of_carthage_martyrs_africa': F(3, 7, 10),

  // --- JUNE ---
  'charles_lwanga_and_companions_martyrs_africa': F(6, 3, 10),

  // --- JULY ---
  'our_lady_of_africa':
      F(4, 30, 10), // Célébrée le 30 avril ou en juillet selon les régions

  // --- AUGUST ---
  'cyprian_of_carthage_bishop_africa': F(9, 16, 10),
  'augustine_of_hippo_bishop_africa': F(8, 28, 10),
  'monica_of_hippo_africa': F(8, 27, 10),

  // --- NOVEMBER ---
  'all_saints_of_africa': F(11, 6, 12),

  // --- DECEMBER ---
  'clement_of_alexandria_africa': F(12, 4, 12),
};

/// Function to inject African specific feasts into the calendar
Calendar addAfricaFeasts(Calendar calendar, int liturgicalYear,
    Map<String, DateTime> liturgicalMainFeasts) {
  calendar.addFeastsToCalendar(
      africaFeastsList, liturgicalYear, liturgicalMainFeasts);

  return calendar;
}
