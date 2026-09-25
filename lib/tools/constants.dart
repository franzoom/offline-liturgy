/// library of constants for all the program
library;

// Paths to liturgical data files
const String ferialFilePath = 'calendar_data/ferial_days';
const String sanctoralFilePath = 'calendar_data/sanctoral';
const String commonsFilePath = 'calendar_data/commons';

const privilegedTimes = {'advent', 'lent', 'christmasoctave', 'paschaloctave'};
const timePrefixes = ['ot', 'advent', 'lent', 'christmas', 'easter'];

const List<String> dayName = [
  '',
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

/// The ferial codes of the three Triduum days (Holy Thursday, Good Friday,
/// Holy Saturday) — see main_calendar_fill.dart's Holy Week filling, which
/// tags them 'lent_6_4'/'lent_6_5'/'lent_6_6' like any other Lenten ferial
/// day, never the literal 'holy_thursday'/'holy_friday'/'holy_saturday'
/// words. Comparing against those words instead of these codes is a trap:
/// the check silently never matches (see compline_detection.dart, which
/// needs the words too and keeps its own small translation table for them).
const Set<String> holyWeekCodes = {
  'lent_6_4',
  'lent_6_5',
  'lent_6_6',
};
