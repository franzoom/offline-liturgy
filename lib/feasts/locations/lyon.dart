import '../../classes/feasts_class.dart';
import '../../classes/calendar_class.dart'; // cette classe définit calendar
import 'france.dart';

//fêtes du calendrier général

Map<String, FeastDates> lyonFeastsList = {
  'gregory_x_pope_lyon': FeastDates(month: 1, day: 10, precedence: 12),
  'francis_of_sales_bishop_lyon': FeastDates(month: 1, day: 24, precedence: 11),
  'marie_of_saint_ignatius_claudine_thevenet_religious_lyon':
      FeastDates(month: 2, day: 3, precedence: 12),
  'jean_pierre_neel_priest_lyon': FeastDates(month: 2, day: 19, precedence: 12),
  'polycarp_of_smyrna_bishop_lyon':
      FeastDates(month: 2, day: 23, precedence: 11),
  'baldomerus_of_lyon_religious_lyon':
      FeastDates(month: 2, day: 27, precedence: 12),
  'nicetius_of_lyon_bishop_lyon': FeastDates(month: 4, day: 2, precedence: 12),
  'epipodius_of_lyon_and_alexander_of_lyon_martyrs_lyon':
      FeastDates(month: 4, day: 22, precedence: 12),
  'peter_chanel_priest_lyon': FeastDates(month: 4, day: 28, precedence: 12),
  'jean_louis_bonnard_priest_lyon':
      FeastDates(month: 5, day: 4, precedence: 11),
  'pothinus_of_lyon_bishop_blandina_of_lyon_virgin_and_companions_martyrs_lyon':
      FeastDates(month: 6, day: 2, precedence: 4),
  'clotilda_queen_of_the_franks': FeastDates(month: 6, day: 4, precedence: 12),
  'marcellin_champagnat_priest_lyon':
      FeastDates(month: 6, day: 6, precedence: 12),
  'john_francis_regis_priest_lyon':
      FeastDates(month: 6, day: 16, precedence: 12),
  'innocent_v_pope_lyon': FeastDates(month: 6, day: 22, precedence: 12),
  'irenaeus_of_lyon_bishop_lyon': FeastDates(month: 6, day: 28, precedence: 4),
  'peter_julian_eymard_priest_lyon':
      FeastDates(month: 8, day: 2, precedence: 12),
  'john_mary_vianney_priest': FeastDates(month: 8, day: 2, precedence: 8),
  'jacques_jules_bonnaud_priest_and_companions_martyrs_lyon':
      FeastDates(month: 9, day: 1, precedence: 11),
  'justus_of_lyon_bishop_lyon': FeastDates(month: 9, day: 2, precedence: 12),
  'frederic_ozanam_lyon': FeastDates(month: 9, day: 9, precedence: 12),
  'peter_claver_priest_lyon': FeastDates(month: 9, day: 9, precedence: 12),
  'maurice_of_agaunum_and_companions_martyrs_lyon':
      FeastDates(month: 9, day: 22, precedence: 12),
  'therese_marie_victoire_couderc_virgin_lyon':
      FeastDates(month: 9, day: 26, precedence: 12),
  'cosmas_of_cilicia_and_damian_of_cilicia_martyrs_lyon':
      FeastDates(month: 9, day: 26, precedence: 12),
  'annemund_of_lyon_bishop_lyon': FeastDates(month: 9, day: 28, precedence: 12),
  'lawrence_ruiz_and_companions_martyrs_lyon':
      FeastDates(month: 9, day: 28, precedence: 12),
  'wenceslaus_i_of_bohemia_martyr_lyon':
      FeastDates(month: 9, day: 28, precedence: 12),
  'anthony_chevrier_priest_lyon': FeastDates(month: 10, day: 3, precedence: 11),
  'dismas_the_good_thief_lyon': FeastDates(month: 10, day: 12, precedence: 12),
  'viator_of_lyon_lyon': FeastDates(month: 10, day: 21, precedence: 12),
  'dedication_of_the_cathedral_of_saint_john_the_baptist_lyon_france_lyon':
      FeastDates(month: 10, day: 24, precedence: 4),
  'dedication_of_consecrated_churches_on_october_25_lyon':
      FeastDates(month: 10, day: 25, precedence: 4),
  'all_holy_bishops_of_the_archdiocese_of_lyon_lyon':
      FeastDates(month: 11, day: 5, precedence: 12),
  'all_saints_of_the_archdiocese_of_lyon':
      FeastDates(month: 11, day: 8, precedence: 12),
  'eucherius_of_lyon_bishop_lyon':
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
      generalCalendar['EASTER'], 13, 4, 'our_lady_of_fourviere');

  return calendar;
}
