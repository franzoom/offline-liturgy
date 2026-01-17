import '../../classes/calendar_class.dart';
import 'france.dart';

Map<String, FeastDates> lyonFeastsList = {
  'lyon_gregory_x_pope': FeastDates(month: 1, day: 10, precedence: 12),
  'lyon_francis_of_sales_bishop': FeastDates(month: 1, day: 24, precedence: 11),
  'lyon_marie_of_saint_ignatius_claudine_thevenet_religious':
      FeastDates(month: 2, day: 3, precedence: 12),
  'lyon_jean_pierre_neel_priest': FeastDates(month: 2, day: 19, precedence: 12),
  'lyon_polycarp_of_smyrna_bishop':
      FeastDates(month: 2, day: 23, precedence: 11),
  'lyon_baldomerus_of_lyon_religious':
      FeastDates(month: 2, day: 27, precedence: 12),
  'lyon_nicetius_of_lyon_bishop': FeastDates(month: 4, day: 2, precedence: 12),
  'lyon_epipodius_of_lyon_and_alexander_of_lyon_martyrs':
      FeastDates(month: 4, day: 22, precedence: 12),
  'lyon_peter_chanel_priest': FeastDates(month: 4, day: 28, precedence: 12),
  'lyon_jean_louis_bonnard_priest':
      FeastDates(month: 5, day: 4, precedence: 11),
  'lyon_pothinus_of_lyon_bishop_blandina_of_lyon_virgin_and_companions_martyrs':
      FeastDates(month: 6, day: 2, precedence: 4),
  'lyon_clotilda_queen_of_the_franks':
      FeastDates(month: 6, day: 4, precedence: 12),
  'lyon_marcellin_champagnat_priest':
      FeastDates(month: 6, day: 6, precedence: 12),
  'lyon_john_francis_regis_priest':
      FeastDates(month: 6, day: 16, precedence: 12),
  'lyon_innocent_v_pope': FeastDates(month: 6, day: 22, precedence: 12),
  'lyon_irenaeus_of_lyon_bishop': FeastDates(month: 6, day: 28, precedence: 4),
  'lyon_peter_julian_eymard_priest':
      FeastDates(month: 8, day: 2, precedence: 12),
  'lyon_john_mary_vianney_priest': FeastDates(month: 8, day: 2, precedence: 8),
  'lyon_jacques_jules_bonnaud_priest_and_companions_martyrs':
      FeastDates(month: 9, day: 1, precedence: 11),
  'lyon_justus_of_lyon_bishop': FeastDates(month: 9, day: 2, precedence: 12),
  'lyon_frederic_ozanam': FeastDates(month: 9, day: 9, precedence: 12),
  'lyon_peter_claver_priest': FeastDates(month: 9, day: 9, precedence: 12),
  'lyon_maurice_of_agaunum_and_companions_martyrs':
      FeastDates(month: 9, day: 22, precedence: 12),
  'lyon_therese_marie_victoire_couderc_virgin':
      FeastDates(month: 9, day: 26, precedence: 12),
  'lyon_annemund_of_lyon_bishop': FeastDates(month: 9, day: 28, precedence: 12),
  'lyon_anthony_chevrier_priest': FeastDates(month: 10, day: 3, precedence: 11),
  'lyon_dismas_the_good_thief': FeastDates(month: 10, day: 12, precedence: 12),
  'lyon_viator_of_lyon': FeastDates(month: 10, day: 21, precedence: 12),
  'lyon_dedication_of_the_cathedral_of_saint_john_the_baptist_lyon_france':
      FeastDates(month: 10, day: 24, precedence: 4),
  'lyon_dedication_of_consecrated_churches_on_october_25':
      FeastDates(month: 10, day: 25, precedence: 4),
  'lyon_all_holy_bishops_of_the_archdiocese_of_lyon':
      FeastDates(month: 11, day: 5, precedence: 12),
  'lyon_all_saints_of_the_archdiocese_of':
      FeastDates(month: 11, day: 8, precedence: 12),
  'lyon_eucherius_of_lyon_bishop':
      FeastDates(month: 11, day: 16, precedence: 12),
};

Calendar addLyonFeasts(Calendar calendar, int liturgicalYear, generalCalendar) {
  // ajouter les fêtes de la France:
  addFranceFeasts(calendar, liturgicalYear, generalCalendar);

  // puis ajouter les fêtes propres à Lyon:
  calendar.addFeastsToCalendar(lyonFeastsList, liturgicalYear, generalCalendar);

  // enfin ajouter les fêtes qui dépendent d'une fête mobile

  // ND de Fourvière le samedi après le 2ème dimanche de Pâques
  calendar.addItemRelatedToFeast(
      generalCalendar['EASTER'], 13, 4, 'lyon_our_lady_of_fourviere');

  return calendar;
}

Map<String, FeastDates> lyonPrimatialeFeastsList = {
  'lyon_dedication_of_the_cathedral_of_saint_john_the_baptist':
      FeastDates(month: 10, day: 24, precedence: 4),
};

Calendar addLyonPrimatialeFeasts(
    Calendar calendar, int liturgicalYear, generalCalendar) {
  // add feast of France and Lyon
  addLyonFeasts(calendar, liturgicalYear, generalCalendar);

  // then add feast of Primatiale of Lyon
  calendar.addFeastsToCalendar(
      lyonPrimatialeFeastsList, liturgicalYear, generalCalendar);

  return calendar;
}
