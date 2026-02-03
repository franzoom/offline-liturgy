import '../../classes/calendar_class.dart';

/// Short alias for FeastDates to allow for a readable const Map.
class F extends FeastDates {
  const F(int m, int d, int p) : super(month: m, day: d, precedence: p);
}

/// Proper feasts for the North American Continent
const Map<String, FeastDates> northAmericaFeastsList = {
  // --- JANUARY ---
  'elizabeth_ann_seton_religious_north_america': F(1, 4, 10),
  'john_neumann_bishop_north_america': F(1, 5, 10),

  // --- MARCH ---
  'katharine_drexel_virgin_north_america': F(3, 3, 12),

  // --- MAY ---
  'damien_de_veuster_priest_north_america': F(5, 10, 12),
  'isidore_the_farmer_north_america': F(5, 15, 12),

  // --- JULY ---
  'junipero_serra_priest_north_america': F(7, 1, 12),
  'kateri_tekakwitha_virgin_north_america': F(7, 14, 10),
  'camillus_de_lellis_priest_north_america':
      F(7, 18, 12), // Shifted in some US regions

  // --- SEPTEMBER ---
  'peter_claver_priest_north_america': F(9, 9, 10),

  // --- OCTOBER ---
  'john_de_brebeuf_isaac_jogues_priests_and_companions_martyrs_north_america':
      F(10, 19, 10),

  // --- NOVEMBER ---
  'rose_philippine_duchesne_virgin_north_america': F(11, 18, 12),

  // --- DECEMBER ---
  'our_lady_of_guadalupe_north_america':
      F(12, 12, 5), // Feast or Solemnity depending on country
};

/// Function to inject North American specific feasts into the calendar
Calendar addNorthAmericaFeasts(Calendar calendar, int liturgicalYear,
    Map<String, DateTime> liturgicalMainFeasts) {
  calendar.addFeastsToCalendar(
      northAmericaFeastsList, liturgicalYear, liturgicalMainFeasts);

  return calendar;
}
