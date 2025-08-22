import '../../classes/feasts_class.dart';
import '../../classes/calendar_class.dart'; // cette classe définit calendar
import 'europe.dart';

Map<String, FeastDates> franceFeastsList = {
  'genevieve_of_paris_virgin_france':
      FeastDates(month: 1, day: 3, priority: 12),
  'remigius_of_reims_bishop_france':
      FeastDates(month: 1, day: 15, priority: 12),
  'our_lady_of_lourdes_france': FeastDates(month: 2, day: 11, priority: 10),
  'bernadette_soubirous_virgin_france':
      FeastDates(month: 2, day: 18, priority: 12),
  'louise_de_marillac_religious_france':
      FeastDates(month: 5, day: 9, priority: 12),
  'ivo_of_kermartin_priest_france': FeastDates(month: 5, day: 19, priority: 12),
  'joan_of_arc_virgin_france': FeastDates(month: 5, day: 30, priority: 12),
  'pothinus_of_lyon_bishop_blandina_of_lyon_virgin_and_companions_martyrs_france':
      FeastDates(month: 6, day: 2, priority: 12),
  'clotilde_of_burgundy_france': FeastDates(month: 6, day: 5, priority: 12),
  'our_lady_of_la_salette_france': FeastDates(month: 9, day: 19, priority: 12),
};

Calendar addFranceFeasts(
    Calendar calendar, int liturgicalYear, generalCalendar) {
  // ajouter d'abord les fêtes de l'Europe:
  addEuropeFeasts(calendar, liturgicalYear, generalCalendar);
  //puis ajouter les fêtes propres à la France:
  calendar.addFeastsToCalendar(
      franceFeastsList, liturgicalYear, generalCalendar);

  return calendar;
}
