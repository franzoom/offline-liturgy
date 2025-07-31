import '../../classes/feasts_class.dart';
import '../../classes/calendar_class.dart';
//import 'north-america.dart';

Map<String, FeastDates> canadaFeastsList = {
  'marguerite_bourgeoys_canada': FeastDates(month: 1, day: 12, priority: 12),
};

Calendar addCanadaFeasts(
    Calendar calendar, int liturgicalYear, generalCalendar) {
  // firstable add Noth-America feasts
  // addNorthAmericaFeasts(calendar, liturgicalYear, generalCalendar);
  // then add Canadas feasts
  calendar.addFeastsToCalendar(
      canadaFeastsList, liturgicalYear, generalCalendar);

  return calendar;
}
