import '../classes/calendar_class.dart'; // calendar definition class
import 'common_calendar_definitions.dart'; //computation of the dates of the variables feasts
import '../tools/date_tools.dart';
import 'common_feasts.dart'; // feast list for the universal Church
import 'locations/lyon.dart';
import 'locations/bordeaux.dart';
import 'locations/paris.dart';
import 'locations/france.dart';
import 'locations/belgium.dart';
import 'locations/canada.dart';
import 'locations/europe.dart';

/// function used to fill the Calendar with local feasts
Calendar localCalendarFill(Calendar calendar, int liturgicalYear,
    String location, Map<String, DateTime> liturgicalMainFeasts) {
  switch (location) {
    case 'lyon':
      calendar = addLyonFeasts(calendar, liturgicalYear, liturgicalMainFeasts);
    case 'lyon_primatiale':
      calendar = addLyonPrimatialeFeasts(
          calendar, liturgicalYear, liturgicalMainFeasts);
    case 'bordeaux':
      calendar =
          addBordeauxFeasts(calendar, liturgicalYear, liturgicalMainFeasts);
    case 'paris':
      calendar = addParisFeasts(calendar, liturgicalYear, liturgicalMainFeasts);
    case 'france':
      calendar =
          addFranceFeasts(calendar, liturgicalYear, liturgicalMainFeasts);
    case 'belgium':
      calendar =
          addBelgiumFeasts(calendar, liturgicalYear, liturgicalMainFeasts);
    case 'canada':
      calendar =
          addCanadaFeasts(calendar, liturgicalYear, liturgicalMainFeasts);
    case 'europe':
      calendar =
          addEuropeFeasts(calendar, liturgicalYear, liturgicalMainFeasts);
  }

  return calendar;
}
