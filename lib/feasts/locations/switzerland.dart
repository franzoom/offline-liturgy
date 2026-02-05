import '../../classes/calendar_class.dart';
import 'europe.dart';

/// Proper feasts for Switzerland
const Map<String, FeastDates> switzerlandFeastsList = {
  // --- JANUARY ---
  'beatus_of_lungern_hermit_switzerland': F(5, 8, 12), // Parfois célébré en mai

  // --- APRIL ---
  'fidelis_of_sigmaringen_priest_martyr_switzerland': F(4, 24, 10),

  // --- AUGUST ---
  'maurice_of_agaunum_and_companions_martyrs_switzerland': F(9, 22, 10),

  // --- SEPTEMBER ---
  'nicholas_of_flue_hermit_patron_of_switzerland':
      F(9, 25, 4), // Solemnity in Switzerland

  // --- OCTOBER ---
  'gall_of_switzerland_abbot': F(10, 16, 10),

  // --- NOVEMBER ---
  'charles_borromeo_bishop_switzerland':
      F(11, 4, 10), // Protector of the Catholic Swiss cantons
  'meinherad_of_einsiedeln_martyr_switzerland': F(1, 21, 12),
};

/// Function to inject Switzerland specific feasts into the calendar
Calendar addSwitzerlandFeasts(Calendar calendar, int liturgicalYear,
    Map<String, DateTime> liturgicalMainFeasts) {
  // First, add European feasts
  addEuropeFeasts(calendar, liturgicalYear, liturgicalMainFeasts);

  // Then, add Swiss specific feasts
  calendar.addFeastsToCalendar(
      switzerlandFeastsList, liturgicalYear, liturgicalMainFeasts);

  return calendar;
}
