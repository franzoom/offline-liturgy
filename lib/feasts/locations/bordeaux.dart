import '../../classes/calendar_class.dart';
import 'france.dart';

/// Short alias for FeastDates to allow for a readable const Map.
class F extends FeastDates {
  const F(int m, int d, int p) : super(month: m, day: d, precedence: p);
}

/// Proper feasts for the Archdiocese of Bordeaux
const Map<String, FeastDates> bordeauxFeastsList = {
  // --- JANUARY ---
  'bordeaux_delphinus_of_bordeaux_bishop': F(1, 10, 11),

  // --- FEBRUARY ---
  'bordeaux_joan_de_lestonnac_religious': F(2, 3, 11),

  // --- APRIL ---
  'bordeaux_gerard_of_corbie_abbot': F(4, 27, 11),

  // --- MAY ---
  'bordeaux_dedication_of_the_cathedral_of_saint_andrew':
      F(5, 1, 8), // Feast for the diocese
  'bordeaux_macarius_bishop': F(5, 4, 12),
  'bordeaux_fort_of_bordeaux_bishop_martyr': F(5, 16, 12),
  'bordeaux_louis_beaulieu_priest_martyr': F(5, 21, 12),

  // --- JUNE ---
  'bordeaux_clair_of_aquitaine_bishop_martyr': F(6, 2, 12),
  'bordeaux_amandus_of_bordeaux_bishop': F(6, 18, 11),
  'bordeaux_paulinus_of_nola_bishop': F(6, 22, 11),
  'bordeaux_martial_of_limoges_bishop': F(6, 30, 12),

  // --- JULY ---
  'bordeaux_bertram_of_le_mans_bishop': F(7, 1, 12),
  'bordeaux_leontius_the_younger_bishop': F(7, 10, 11),
  'bordeaux_simon_stock_priest': F(7, 17, 12),

  // --- AUGUST ---
  'bordeaux_mommolin_of_fleury_abbot': F(8, 9, 12),

  // --- SEPTEMBER ---
  'bordeaux_jean_joseph_rateau_and_companions_martyrs': F(9, 2, 11),
  'bordeaux_severinus_of_bordeaux_bishop': F(9, 21, 11),
  'bordeaux_austinde_of_auch_bishop': F(9, 25, 12),

  // --- NOVEMBER ---
  'bordeaux_abbo_of_fleury_abbot_martyr': F(11, 13, 12),
  'bordeaux_emilion_hermit': F(11, 16, 11),
  'bordeaux_romanus_of_blaye_priest': F(11, 24, 11),
  'bordeaux_andrew_the_apostle': F(11, 30, 8), // Patron of diocese: Feast

  // --- DECEMBER ---
  'bordeaux_our_lady_of_loreto': F(12, 10, 12),
};

/// Proper feasts for the Cathedral of Bordeaux (St. André)
const Map<String, FeastDates> bordeauxCathedralFeastsList = {
  'bordeaux_dedication_of_the_cathedral_of_saint_andrew':
      F(5, 1, 4), // Solemnity at Cathedral
  'bordeaux_andrew_the_apostle': F(11, 30, 4), // Titular: Solemnity
};

/// Function to inject Bordeaux specific feasts into the calendar
Calendar addBordeauxFeasts(Calendar calendar, int liturgicalYear,
    Map<String, DateTime> liturgicalMainFeasts) {
  addFranceFeasts(calendar, liturgicalYear, liturgicalMainFeasts);

  calendar.addFeastsToCalendar(
      bordeauxFeastsList, liturgicalYear, liturgicalMainFeasts);

  return calendar;
}

/// Function to inject Cathedral of Bordeaux specific feasts
Calendar addBordeauxCathedralFeasts(Calendar calendar, int liturgicalYear,
    Map<String, DateTime> liturgicalMainFeasts) {
  addBordeauxFeasts(calendar, liturgicalYear, liturgicalMainFeasts);

  calendar.addFeastsToCalendar(
      bordeauxCathedralFeastsList, liturgicalYear, liturgicalMainFeasts);

  return calendar;
}
