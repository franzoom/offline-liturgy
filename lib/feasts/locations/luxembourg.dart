import '../../classes/calendar_class.dart';
import 'europe.dart';

/// Short alias for FeastDates to allow for a readable const Map.
class F extends FeastDates {
  const F(int m, int d, int p) : super(month: m, day: d, precedence: p);
}

/// Proper feasts for the Archdiocese of Luxembourg
const Map<String, FeastDates> luxembourgFeastsList = {
  // --- NOVEMBER ---
  'willibrord_of_utrecht_bishop_luxembourg':
      F(11, 7, 4), // Patron of the country - Solemnity

  // --- APRIL / MAY (Fixed date for the beginning of the Octave in some calendars) ---
  'our_lady_consoler_of_the_afflicted_luxembourg':
      F(5, 5, 4), // Main Patroness - Solemnity

  // --- OCTOBER ---
  'kunigunde_of_luxembourg_empress':
      F(3, 3, 12), // Can be celebrated in October or March
};

/// Function to inject Luxembourg specific feasts into the calendar
Calendar addLuxembourgFeasts(Calendar calendar, int liturgicalYear,
    Map<String, DateTime> liturgicalMainFeasts) {
  // First, add European feasts
  addEuropeFeasts(calendar, liturgicalYear, liturgicalMainFeasts);

  // Then, add Luxembourg specific feasts
  calendar.addFeastsToCalendar(
      luxembourgFeastsList, liturgicalYear, liturgicalMainFeasts);

  // Movable Feast: Our Lady of Luxembourg (Consolatrix Afflictorum)
  // Traditionally the 3rd Sunday of Easter.
  // We can use addItemRelatedToFeast to mark the beginning of the Octave.
  calendar.addItemRelatedToFeast(liturgicalMainFeasts['EASTER']!, 14, 4,
      'luxembourg_our_lady_consoler_octave_start');

  return calendar;
}
