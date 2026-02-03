import '../classes/calendar_class.dart'; // calendar definition class
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
  return switch (location) {
    'europe' => addEuropeFeasts(calendar, liturgicalYear, liturgicalMainFeasts),
    'france' => addFranceFeasts(calendar, liturgicalYear, liturgicalMainFeasts),
    'belgium' =>
      addBelgiumFeasts(calendar, liturgicalYear, liturgicalMainFeasts),
    'canada' => addCanadaFeasts(calendar, liturgicalYear, liturgicalMainFeasts),
    'lyon' => addLyonFeasts(calendar, liturgicalYear, liturgicalMainFeasts),
    'lyon_primatiale' =>
      addLyonPrimatialeFeasts(calendar, liturgicalYear, liturgicalMainFeasts),
    'bordeaux' =>
      addBordeauxFeasts(calendar, liturgicalYear, liturgicalMainFeasts),
    'paris' => addParisFeasts(calendar, liturgicalYear, liturgicalMainFeasts),
    _ => calendar, // default case
  };
}
