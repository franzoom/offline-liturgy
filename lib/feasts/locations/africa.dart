import '../../classes/calendar_class.dart';

/// Proper feasts for the African Continent
const Map<String, FeastDates> africaFeastsList = {
  // --- JANUARY ---
  'africa_joseph_vaz_priest': F(1, 16, 12),

  // --- FEBRUARY ---
  'africa_celerina_and_compagnions_martyrs': F(2, 4, 12),
  'africa_josephine_bakhita_virgin':
      F(2, 8, 10), // Souvent mémoire obligatoire en Afrique

  // --- MARCH ---
  'africa_perpetua_of_carthage_and_felicity_of_carthage_martyrs': F(3, 7, 10),

  // --- JUNE ---
  'africa_charles_lwanga_and_companions_martyrs': F(6, 3, 10),

  // --- JULY ---
  'africa_our_lady_of_africa':
      F(4, 30, 10), // Célébrée le 30 avril ou en juillet selon les régions

  // --- AUGUST ---
  'africa_cyprian_of_carthage_bishop': F(9, 16, 10),
  'africa_augustine_of_hippo_bishop': F(8, 28, 10),
  'africa_monica_of_hippo': F(8, 27, 10),

  // --- NOVEMBER ---
  'africa_all_saints_of': F(11, 6, 12),

  // --- DECEMBER ---
  'africa_clement_of_alexandria': F(12, 4, 12),
};

/// Function to inject African specific feasts into the calendar
Calendar addAfricaFeasts(Calendar calendar, int liturgicalYear,
    Map<String, DateTime> liturgicalMainFeasts) {
  calendar.addFeastsToCalendar(
      africaFeastsList, liturgicalYear, liturgicalMainFeasts);

  return calendar;
}
