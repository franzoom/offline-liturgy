import '../../classes/calendar_class.dart';

/// Proper feasts for the North American Continent
const Map<String, FeastDates> northAmericaFeastsList = {
  // --- JANUARY ---
  'north-america_elizabeth_ann_seton_religious': F(1, 4, 10),
  'north-america_john_neumann_bishop': F(1, 5, 10),

  // --- MARCH ---
  'north-america_katharine_drexel_virgin': F(3, 3, 12),

  // --- MAY ---
  'north-america_damien_de_veuster_priest': F(5, 10, 12),
  'north-america_isidore_the_farmer': F(5, 15, 12),

  // --- JULY ---
  'north-america_junipero_serra_priest': F(7, 1, 12),
  'north-america_kateri_tekakwitha_virgin': F(7, 14, 10),
  'north-america_camillus_de_lellis_priest':
      F(7, 18, 12), // Shifted in some US regions

  // --- SEPTEMBER ---
  'north-america_peter_claver_priest': F(9, 9, 10),

  // --- OCTOBER ---
  'north-america_john_de_brebeuf_isaac_jogues_priests_and_companions_martyrs':
      F(10, 19, 10),

  // --- NOVEMBER ---
  'north-america_rose_philippine_duchesne_virgin': F(11, 18, 12),

  // --- DECEMBER ---
  'north-america_our_lady_of_guadalupe':
      F(12, 12, 5), // Feast or Solemnity depending on country
};

/// Function to inject North American specific feasts into the calendar
Calendar addNorthAmericaFeasts(Calendar calendar, int liturgicalYear,
    Map<String, DateTime> liturgicalMainFeasts) {
  calendar.addFeastsToCalendar(
      northAmericaFeastsList, liturgicalYear, liturgicalMainFeasts);

  return calendar;
}
