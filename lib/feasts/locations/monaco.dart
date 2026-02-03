import '../../classes/calendar_class.dart';
import 'europe.dart';

/// Short alias for FeastDates to allow for a readable const Map.
class F extends FeastDates {
  const F(int m, int d, int p) : super(month: m, day: d, precedence: p);
}

/// Proper feasts for the Principality of Monaco
const Map<String, FeastDates> monacoFeastsList = {
  // --- JANUARY ---
  'devota_of_corsica_virgin_martyr_monaco':
      F(1, 27, 4), // Patron Saint - Solemnity

  // --- MAY ---
  'dedication_of_the_cathedral_of_monaco':
      F(12, 4, 4), // Dedication of St. Nicholas Cathedral

  // --- NOVEMBER ---
  'rainerius_of_pisa_monaco': F(11, 19, 10), // National Day / St. Rainier
};

/// Function to inject Monaco specific feasts into the calendar
Calendar addMonacoFeasts(Calendar calendar, int liturgicalYear,
    Map<String, DateTime> liturgicalMainFeasts) {
  // First, add European feasts
  addEuropeFeasts(calendar, liturgicalYear, liturgicalMainFeasts);

  // Then, add Monaco specific feasts
  calendar.addFeastsToCalendar(
      monacoFeastsList, liturgicalYear, liturgicalMainFeasts);

  return calendar;
}
