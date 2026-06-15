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

/// Special celebration codes for Holy Week
const Set<String> holyWeekCodes = {
  'holy_thursday',
  'holy_friday',
  'holy_saturday',
};
