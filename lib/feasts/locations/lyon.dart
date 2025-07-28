import '../../classes/feasts_class.dart';
import '../../classes/calendar_class.dart'; // cette classe définit calendar
import 'france.dart';

//fêtes du calendrier général

Map<String, FeastDates> lyonFeastsList = {
  'gregory_x_pope': FeastDates(month: 1, day: 10, priority: 12),
  'francis_de_sales_bishop_LYON': FeastDates(month: 1, day: 24, priority: 11),
  'marie_of_saint_ignatius_claudine_thevenet_religious':
      FeastDates(month: 2, day: 3, priority: 12),
  'jean_pierre_neel_priest': FeastDates(month: 2, day: 19, priority: 12),
  'polycarp_of_smyrna_bishop': FeastDates(month: 2, day: 23, priority: 112),
  'baldomerus_of_lyon_religious': FeastDates(month: 2, day: 27, priority: 12),
  'nicetius_of_lyon_bishop': FeastDates(month: 4, day: 2, priority: 12),
  'francis_of_paola_hermit': FeastDates(month: 4, day: 2, priority: 12),
  'epipodius_of_lyon_and_alexander_of_lyon_martyrs':
      FeastDates(month: 4, day: 22, priority: 12),
  'peter_chanel_priest': FeastDates(month: 4, day: 28, priority: 12),
  'jean_louis_bonnard_priest': FeastDates(month: 5, day: 4, priority: 11),
  'pothinus_of_lyon_bishop_blandina_of_lyon_virgin_and_companions_martyrs':
      FeastDates(month: 6, day: 2, priority: 4),
  'marcellin_champagnat_priest': FeastDates(month: 6, day: 6, priority: 12),
  'john_francis_regis_priest': FeastDates(month: 6, day: 16, priority: 12),
  'innocent_v_pope': FeastDates(month: 6, day: 22, priority: 12),
  'john_fisher_bishop_and_thomas_more_martyrs':
      FeastDates(month: 6, day: 22, priority: 12),
  'paulinus_of_nola_bishop': FeastDates(month: 6, day: 22, priority: 12),
  'irenaeus_of_lyon_bishop_LYON': FeastDates(month: 6, day: 28, priority: 4),
  'bonaventure_of_bagnoregio_bishop':
      FeastDates(month: 7, day: 15, priority: 11),
  'eusebius_of_vercelli_bishop': FeastDates(month: 8, day: 2, priority: 12),
  'peter_julian_eymard_priest': FeastDates(month: 8, day: 2, priority: 12),
  'john_mary_vianney_priest': FeastDates(month: 8, day: 2, priority: 8),
  'jacques_jules_bonnaud_priest_and_companions_martyrs':
      FeastDates(month: 9, day: 1, priority: 11),
  'justus_of_lyon_bishop': FeastDates(month: 9, day: 2, priority: 12),
  'frederic_ozanam_founder': FeastDates(month: 9, day: 9, priority: 12),
  'peter_claver_priest': FeastDates(month: 9, day: 9, priority: 12),
  'maurice_of_agaunum_and_companions_martyrs':
      FeastDates(month: 9, day: 22, priority: 12),
  'therese_marie_victoire_couderc_virgin':
      FeastDates(month: 9, day: 26, priority: 12),
  'cosmas_of_cilicia_and_damian_of_cilicia_martyrs':
      FeastDates(month: 9, day: 26, priority: 12),
  'annemund_of_lyon_bishop': FeastDates(month: 9, day: 28, priority: 12),
  'lawrence_ruiz_and_companions_martyrs':
      FeastDates(month: 9, day: 28, priority: 12),
  'wenceslaus_i_of_bohemia_martyr': FeastDates(month: 9, day: 28, priority: 12),
  'anthony_chevrier_priest': FeastDates(month: 10, day: 3, priority: 11),
  'dismas_the_good_thief': FeastDates(month: 10, day: 12, priority: 12),
  'viator_of_lyon': FeastDates(month: 10, day: 21, priority: 12),
  'dedication_of_the_cathedral_of_saint_john_the_baptist_lyon_france':
      FeastDates(month: 10, day: 24, priority: 4),
  'dedication_of_consecrated_churches_on_october_25':
      FeastDates(month: 10, day: 25, priority: 4),
  'all_holy_bishops_of_the_archdiocese_of_lyon':
      FeastDates(month: 11, day: 5, priority: 12),
  'all_saints_of_the_archdiocese_of_lyon':
      FeastDates(month: 11, day: 8, priority: 12),
  'eucherius_of_lyon_bishop': FeastDates(month: 11, day: 16, priority: 12),
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
