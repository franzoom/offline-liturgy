import '../../classes/calendar_class.dart';
import 'europe.dart';

Map<String, FeastDates> belgiumFeastsList = {
  'amand_bishop_belgium': FeastDates(month: 2, day: 6, precedence: 10),
};

Calendar addBelgiumFeasts(
    Calendar calendar, int liturgicalYear, generalCalendar) {
  // ajouter d'abord les fêtes de l'Europe:
  addEuropeFeasts(calendar, liturgicalYear, generalCalendar);
  //puis ajouter les fêtes propres à la France:
  calendar.addFeastsToCalendar(
      belgiumFeastsList, liturgicalYear, generalCalendar);

  return calendar;
}
