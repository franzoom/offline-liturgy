import '../../classes/calendar_class.dart';
import './lyon.dart';

Map<String, FeastDates> lyonPrimatialFeastsList = {
  'dedication_of_the_cathedral_of_saint_john_the_baptist_lyon_france_lyon':
      FeastDates(month: 10, day: 24, precedence: 4),
};

Calendar addLyonPrimatialeFeasts(
    Calendar calendar, int liturgicalYear, generalCalendar) {
  // add feast of France and Lyon
  addLyonFeasts(calendar, liturgicalYear, generalCalendar);

  // then add feast of Primatiale of Lyon
  calendar.addFeastsToCalendar(
      lyonPrimatialFeastsList, liturgicalYear, generalCalendar);

  return calendar;
}
