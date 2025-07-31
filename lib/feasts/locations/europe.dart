import '../../classes/feasts_class.dart';
import '../../classes/calendar_class.dart';

Map<String, FeastDates> europeFeastsList = {
  'cyril_constantine_the_philosopher_monk_and_methodius_michael_of_thessaloniki_bishop_europe':
      FeastDates(month: 2, day: 14, priority: 4),
  'catherine_of_siena_virgin_europe':
      FeastDates(month: 4, day: 29, priority: 4),
  'benedict_of_nursia_abbot_europe': FeastDates(month: 7, day: 11, priority: 4),
  'bridget_of_sweden_religious_europe':
      FeastDates(month: 7, day: 23, priority: 4),
  'teresa_benedicta_of_the_cross_stein_virgin_europe':
      FeastDates(month: 8, day: 9, priority: 4),
};

Calendar addEuropeFeasts(
    Calendar calendar, int liturgicalYear, generalCalendar) {
  calendar.addFeastsToCalendar(
      europeFeastsList, liturgicalYear, generalCalendar);

  return calendar;
}
