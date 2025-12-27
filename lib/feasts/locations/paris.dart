import '../../classes/feasts_class.dart';
import '../../classes/calendar_class.dart'; // cette classe définit calendar
import 'france.dart';

//fêtes du calendrier général

Map<String, FeastDates> parisFeastsList = {
  'genevieve_of_paris_virgin_paris':
      FeastDates(month: 1, day: 3, precedence: 4),
};

Calendar addParisFeasts(
    Calendar calendar, int liturgicalYear, generalCalendar) {
  // ajouter les fêtes de la France:
  addFranceFeasts(calendar, liturgicalYear, generalCalendar);

  // puis ajouter les fêtes propres à Paris:
  calendar.addFeastsToCalendar(
      parisFeastsList, liturgicalYear, generalCalendar);

  return calendar;
}
