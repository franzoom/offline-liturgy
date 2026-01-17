import '../../classes/calendar_class.dart';
//import 'north-america.dart';

Map<String, FeastDates> canadaFeastsList = {
  'andre_bessette_religious_canada':
      FeastDates(month: 1, day: 7, precedence: 10),
  'marguerite_bourgeoys_canada': FeastDates(month: 1, day: 12, precedence: 10),
};

Calendar addCanadaFeasts(
    Calendar calendar, int liturgicalYear, generalCalendar) {
  // firstable add North-America feasts
  // addNorthAmericaFeasts(calendar, liturgicalYear, generalCalendar);
  // then add Canadas feasts
  calendar.addFeastsToCalendar(
      canadaFeastsList, liturgicalYear, generalCalendar);
  calendar.moveItemByDays(
      'raymond_of_penyafort_priest', 1); // shifting the feast as required
  return calendar;
}
