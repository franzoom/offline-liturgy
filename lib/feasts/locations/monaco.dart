import '../../classes/calendar_class.dart';
import 'europe.dart';

/// Proper feasts for the Principality of Monaco
const Map<String, FeastDates> monacoFeastsList = {
  // --- JANUARY ---
  'monaco_devota_of_corsica_virgin_martyr':
      F(1, 27, 4), // Patron Saint - Solemnity

  // --- MAY ---
  'monaco_dedication_of_the_cathedral_of':
      F(12, 4, 4), // Dedication of St. Nicholas Cathedral

  // --- NOVEMBER ---
  'monaco_rainerius_of_pisa': F(11, 19, 10), // National Day / St. Rainier
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
