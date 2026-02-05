import '../../classes/calendar_class.dart';
import 'france.dart';

/// Proper feasts for the Archdiocese of Lyon
const Map<String, FeastDates> lyonFeastsList = {
  // --- JANUARY ---
  'lyon_pauline_marie_jaricot': F(1, 9, 12),
  'lyon_gregory_x_pope': F(1, 10, 12),
  'lyon_francis_of_sales_bishop': F(1, 24, 11),

  // --- FEBRUARY ---
  'lyon_marie_of_saint_ignatius_claudine_thevenet_religious': F(2, 3, 12),
  'lyon_jean_pierre_neel_priest': F(2, 19, 12),
  'lyon_polycarp_of_smyrna_bishop': F(2, 23, 11),
  'lyon_baldomerus_of_lyon_religious': F(2, 27, 12),

  // --- APRIL ---
  'lyon_nicetius_of_lyon_bishop': F(4, 2, 12),
  'lyon_epipodius_of_lyon_and_alexander_of_lyon_martyrs': F(4, 22, 12),
  'lyon_peter_chanel_priest': F(4, 28, 12),

  // --- MAY ---
  'lyon_jean_louis_bonnard_priest': F(5, 4, 11),

  // --- JUNE ---
  'lyon_pothinus_of_lyon_bishop_blandina_of_lyon_virgin_and_companions_martyrs':
      F(6, 2, 4),
  'lyon_clotilda_queen_of_the_franks': F(6, 4, 12),
  'lyon_marcellin_champagnat_priest': F(6, 6, 12),
  'lyon_john_francis_regis_priest': F(6, 16, 12),
  'lyon_innocent_v_pope': F(6, 22, 12),
  'lyon_irenaeus_of_lyon_bishop': F(6, 28, 4),

  // --- AUGUST ---
  'lyon_peter_julian_eymard_priest': F(8, 2, 12),
  'lyon_john_mary_vianney_priest': F(8, 2, 8),

  // --- SEPTEMBER ---
  'lyon_jacques_jules_bonnaud_priest_and_companions_martyrs': F(9, 1, 11),
  'lyon_justus_of_lyon_bishop': F(9, 2, 12),
  'lyon_frederic_ozanam': F(9, 9, 12),
  'lyon_peter_claver_priest': F(9, 9, 12),
  'lyon_maurice_of_agaunum_and_companions_martyrs': F(9, 22, 12),
  'lyon_therese_marie_victoire_couderc_virgin': F(9, 26, 12),
  'lyon_annemund_of_lyon_bishop': F(9, 28, 12),

  // --- OCTOBER ---
  'lyon_anthony_chevrier_priest': F(10, 3, 11),
  'lyon_dismas_the_good_thief': F(10, 12, 12),
  'lyon_viator_of_lyon': F(10, 21, 12),
  'lyon_dedication_of_the_cathedral_of_saint_john_the_baptist': F(10, 24, 4),
  'lyon_dedication_of_consecrated_churches_on_october_25': F(10, 25, 4),

  // --- NOVEMBER ---
  'lyon_all_holy_bishops_of_the_archdiocese_of_lyon': F(11, 5, 12),
  'lyon_all_saints_of_the_archdiocese_of': F(11, 8, 12),
  'lyon_eucherius_of_lyon_bishop': F(11, 16, 12),
};

const Map<String, FeastDates> lyonPrimatialeFeastsList = {
  'lyon_dedication_of_the_cathedral_of_saint_john_the_baptist': F(10, 24, 4),
};

Calendar addLyonFeasts(Calendar calendar, int liturgicalYear,
    Map<String, DateTime> liturgicalMainFeasts) {
  addFranceFeasts(calendar, liturgicalYear, liturgicalMainFeasts);

  calendar.addFeastsToCalendar(
      lyonFeastsList, liturgicalYear, liturgicalMainFeasts);

  // Moved item related to Easter - Using '!' to ensure non-null value
  calendar.addItemRelatedToFeast(
      liturgicalMainFeasts['EASTER']!, 13, 4, 'lyon_our_lady_of_fourviere');

  return calendar;
}

Calendar addLyonPrimatialeFeasts(Calendar calendar, int liturgicalYear,
    Map<String, DateTime> liturgicalMainFeasts) {
  addLyonFeasts(calendar, liturgicalYear, liturgicalMainFeasts);

  calendar.addFeastsToCalendar(
      lyonPrimatialeFeastsList, liturgicalYear, liturgicalMainFeasts);

  return calendar;
}
