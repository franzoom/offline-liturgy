import '../classes/calendar_class.dart'; // calendar definition class
import '../tools/location_loader.dart';
import 'common_calendar_definitions.dart'; // computation of the dates of the variables feasts
import '../tools/date_tools.dart';
import 'local_calendar_fill.dart';

/// Builds two liturgical years to avoid border problems (around first Sunday of Advent).
/// [data] is mandatory: it carries the universal Roman feasts and the location tree.
Calendar getCalendar(
  Calendar calendar,
  DateTime eventDate,
  String location,
  LiturgyData data,
) {
  calendar = calendarFill(calendar, eventDate, location, data);
  calendar = calendarFill(
      calendar,
      DateTime(eventDate.year + 1, eventDate.month, eventDate.day),
      location,
      data);

  // Downgrade obligatory memorials to optional during privileged times
  calendar.downgradeMemorialsDuringPrivilegedTimes();
  return calendar;
}

/// Fills one liturgical year with fixed solemnities, universal Roman feasts,
/// and the local feast chain for [location].
Calendar calendarFill(
  Calendar calendar,
  DateTime eventDate,
  String location,
  LiturgyData data,
) {
  //detection of the liturgical year
  int liturgicalYear = eventDate.year;
  DateTime adventDate = advent(liturgicalYear + 1);
  if (adventDate.isBefore(eventDate) ||
      adventDate.isAtSameMomentAs(eventDate)) {
    liturgicalYear++;
  }

  Map<String, DateTime> liturgicalMainFeasts =
      createLiturgicalDays(liturgicalYear);
  String defaultCelebrationTitle = "";
  int precedence = 0;

  // --- ADVENT ---
  int adventDays = 0;
  DateTime date = liturgicalMainFeasts['ADVENT']!;
  while (date.isBefore(liturgicalMainFeasts['NATIVITY']!)) {
    precedence = date.isSunday ? 2 : 13;

    if (date.day < 17 || date.month == 11) {
      defaultCelebrationTitle =
          'advent_${(adventDays ~/ 7) + 1}_${adventDays % 7}';
    } else {
      precedence = precedence == 13 ? 9 : 2;
      defaultCelebrationTitle =
          'advent-${date.day}_${(adventDays ~/ 7) + 1}_${adventDays % 7}';
      // grammar of this special days: advent-17_3_5 (12/17, 3d week, 5th day)
    }

    DayContent dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'advent',
      defaultCelebrationTitle: defaultCelebrationTitle,
      precedence: precedence,
      liturgicalColor: 'violet',
      breviaryWeek: (adventDays ~/ 7) % 4 + 1,
      feastList: {},
    );
    calendar.addDayContent(date, dayContent);
    date = date.shift(1);
    adventDays++;
  }

  // adding the Nativity of the Lord
  DayContent dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'nativity',
    defaultCelebrationTitle: 'nativity',
    precedence: 2,
    liturgicalColor: 'white',
    breviaryWeek: 1,
    feastList: {},
  );
  // christmas is december, 25th of the previous year
  date = DateTime(liturgicalYear - 1, 12, 25);
  calendar.addDayContent(date, dayContent);

  // adding the christmas Octave
  date = date.shift(1); // begins decembre, the 26th
  while (date.isBefore(DateTime(liturgicalYear, 1, 1))) {
    defaultCelebrationTitle = 'christmas_${date.day}';
    precedence = (date.day <= 28) ? 7 : 9;

    if (date == liturgicalMainFeasts['HOLY_FAMILY']) {
      defaultCelebrationTitle = 'holy_family';
      precedence = 6;
    }
    DayContent dayContent = DayContent(
        liturgicalYear: liturgicalYear,
        liturgicalTime: 'christmasoctave',
        defaultCelebrationTitle: defaultCelebrationTitle,
        precedence: precedence,
        liturgicalColor: 'white',
        breviaryWeek:
            date.isBefore(liturgicalMainFeasts['HOLY_FAMILY']!) ? 4 : 1,
        // if the date is before the Holy Family, the breviary week is 4, otherwise it is 1
        feastList: {});
    calendar.addDayContent(date, dayContent);
    date = date.shift(1);
  }

  // adding Mary Mother of God
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'christmas',
    defaultCelebrationTitle: 'mary_mother_of_god',
    precedence: 2,
    liturgicalColor: 'white',
    breviaryWeek: 1,
    feastList: {},
  );
  date = DateTime(liturgicalYear, 1, 1);
  calendar.addDayContent(date, dayContent);

  date = date.shift(1);
  int christmasFerialDays =
      date.difference(liturgicalMainFeasts['HOLY_FAMILY']!).inDays;

  // days between january, 2d and the Epiphany
  DateTime epiphanyDate = liturgicalMainFeasts['EPIPHANY']!;
  while (date.isBefore(epiphanyDate)) {
    dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'beforeEpiphany',
      defaultCelebrationTitle:
          'christmas-${date.day}_${(christmasFerialDays ~/ 7) + 1}_${christmasFerialDays % 7}',
      precedence: 13,
      liturgicalColor: 'white',
      breviaryWeek: (christmasFerialDays ~/ 7) % 4 + 1,
      feastList: {},
    );
    calendar.addDayContent(date, dayContent);
    date = date.shift(1);
    christmasFerialDays++;
  }

  // adjunction of the Epiphany
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'epiphany',
    defaultCelebrationTitle: 'epiphany',
    precedence: 3,
    liturgicalColor: 'white',
    breviaryWeek: epiphanyDate.day > 6 ? 1 : 2,
    // if the Epiphany is after the 6th, the Baptism of the Lord is the next day, on monday.
    // in this case the Epiphany is begining the first week of the new liturgical year,
    // and breviaryWeek is 1.
    // otherwise (if the Epiphany is on the 6th or before), the Baptism will be on the next sunday, so
    // the Epiphany is not the first week of the liturgical year, therefore breviaryWeek is 2.
    feastList: {},
  );
  date = epiphanyDate;
  calendar.addDayContent(date, dayContent);
  date = date.shift(1);
  christmasFerialDays = 1;

  // going on with the "second week" till the Baptism of the Lord:
  while (date.isBefore(liturgicalMainFeasts['BAPTISM']!)) {
    dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'christmas',
      defaultCelebrationTitle: 'christmas_2_$christmasFerialDays',
      precedence: 13,
      liturgicalColor: 'white',
      breviaryWeek: epiphanyDate.day > 6 ? 1 : 2, // see above
      feastList: {},
    );
    calendar.addDayContent(date, dayContent);
    date = date.shift(1);
    christmasFerialDays++;
  }

  // adding the Baptism of the Lord
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'christmas',
    defaultCelebrationTitle: 'baptism',
    precedence: 5,
    liturgicalColor: 'white',
    breviaryWeek: 1,
    feastList: {},
  );
  date = liturgicalMainFeasts['BAPTISM']!;
  calendar.addDayContent(date, dayContent);

  // --- ORDINARY TIME TILL LENT ---
  int ordinaryTimeDays = 1;
  date = date.shift(1); // begins after Epiphany
  while (date.isBefore(liturgicalMainFeasts['ASHES']!)) {
    defaultCelebrationTitle =
        'ot_${(ordinaryTimeDays ~/ 7) + 1}_${date.weekday % 7}';
    precedence = date.isSunday ? 6 : 13;
    DayContent dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'ot',
      defaultCelebrationTitle: defaultCelebrationTitle,
      precedence: precedence,
      liturgicalColor: 'green',
      breviaryWeek: (ordinaryTimeDays ~/ 7) % 4 + 1,
      feastList: {},
    );
    calendar.addDayContent(date, dayContent);
    date = date.shift(1);
    ordinaryTimeDays++;
  }

  // adding the Ashes Wednesday
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'lent',
    defaultCelebrationTitle: 'lent_0_3',
    precedence: 2,
    liturgicalColor: 'violet',
    breviaryWeek: 4,
    feastList: {},
  );
  date = liturgicalMainFeasts['ASHES']!;
  calendar.addDayContent(date, dayContent);
  date = date.shift(1);

  // adding the lent days between the Ashes Wednesday
  // and the first sunday of Lent
  int lentDays = 4;
  while (date.isBefore(liturgicalMainFeasts['ASHES']!.shift(4))) {
    dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'lent',
      defaultCelebrationTitle: 'lent_0_$lentDays',
      precedence: 9,
      liturgicalColor: 'violet',
      breviaryWeek: 4,
      feastList: {},
    );
    calendar.addDayContent(date, dayContent);
    date = date.shift(1);
    lentDays++;
  }

  // add the Lent days till Palm Sunday (excluded)
  lentDays = 0;
  while (date.isBefore(liturgicalMainFeasts['PALMS']!)) {
    defaultCelebrationTitle = 'lent_${(lentDays ~/ 7) + 1}_${date.weekday % 7}';
    precedence = date.isSunday ? 2 : 9;
    DayContent dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'lent',
      defaultCelebrationTitle: defaultCelebrationTitle,
      precedence: precedence,
      liturgicalColor: 'violet',
      breviaryWeek: (lentDays ~/ 7) % 4 + 1,
      feastList: {},
    );
    calendar.addDayContent(date, dayContent);
    date = date.shift(1);
    lentDays++;
  }

  // adding Palms Sunday
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'holyweek',
    defaultCelebrationTitle: 'lent_6_0',
    precedence: 2,
    liturgicalColor: 'red',
    breviaryWeek: 2,
    feastList: {},
  );
  date = liturgicalMainFeasts['PALMS']!;
  calendar.addDayContent(date, dayContent);
  date = date.shift(1);
  lentDays++;

  // adding the Holy Week days
  while (date.isBefore(liturgicalMainFeasts['EASTER']!)) {
    precedence = lentDays % 7 < 4
        ? 9
        : 1; // from holy Thursday, the precedence is 1, before it is 9
    String liturgicalColor = switch (lentDays % 7) {
      0 || 1 || 2 || 3 => 'violet',
      4 => 'white',
      5 => 'red',
      6 => 'black',
      _ => ''
    };
    dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'holyweek',
      defaultCelebrationTitle: 'lent_${(lentDays ~/ 7) + 1}_${lentDays % 7}',
      precedence: precedence,
      liturgicalColor: liturgicalColor,
      breviaryWeek: 2,
      feastList: {},
    );
    calendar.addDayContent(date, dayContent);
    date = date.shift(1);
    lentDays++;
  }
  // --- PASCHAL TIME ---
  int paschalTimeDays = 0;
  date = liturgicalMainFeasts['EASTER']!;

  // Paschal Octave (precedence: 2, except Sunday: 1)
  while (date.isBefore(liturgicalMainFeasts['EASTER']!.shift(7))) {
    precedence = date.isSunday ? 1 : 2;
    DayContent dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'paschaloctave',
      defaultCelebrationTitle:
          'easter_${(paschalTimeDays ~/ 7) + 1}_${paschalTimeDays % 7}',
      precedence: precedence,
      liturgicalColor: 'white',
      breviaryWeek: 1,
      feastList: {},
    );
    calendar.addDayContent(date, dayContent);
    date = date.shift(1);
    paschalTimeDays++;
  }

  while (date.isBefore(liturgicalMainFeasts['ASCENSION']!)) {
    precedence = date.isSunday ? 2 : 13;
    DayContent dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'paschaltime',
      defaultCelebrationTitle:
          'easter_${(paschalTimeDays ~/ 7) + 1}_${date.weekday % 7}',
      precedence: precedence,
      liturgicalColor: 'white',
      breviaryWeek: (paschalTimeDays ~/ 7) % 4 + 1,
      feastList: {},
    );
    calendar.addDayContent(date, dayContent);
    date = date.shift(1);
    paschalTimeDays++;
  }

  // Ascension
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'paschaltime',
    defaultCelebrationTitle: 'ascension',
    precedence: 2,
    liturgicalColor: 'white',
    breviaryWeek: 2,
    feastList: {},
  );
  date = liturgicalMainFeasts['ASCENSION']!;
  calendar.addDayContent(date, dayContent);
  paschalTimeDays++;
  date = date.shift(1);

  // days between Ascension and Pentecost
  while (date.isBefore(liturgicalMainFeasts['PENTECOST']!)) {
    precedence = date.isSunday ? 2 : 13;
    DayContent dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'paschaltime',
      defaultCelebrationTitle:
          'easter_${(paschalTimeDays ~/ 7) + 1}_${date.weekday % 7}',
      precedence: precedence,
      liturgicalColor: 'white',
      breviaryWeek: (paschalTimeDays ~/ 7) % 4 + 1,
      feastList: {},
    );
    calendar.addDayContent(date, dayContent);
    date = date.shift(1);
    paschalTimeDays++;
  }

  // Pentecost
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'paschaltime',
    defaultCelebrationTitle: 'pentecost',
    precedence: 2,
    liturgicalColor: 'red',
    breviaryWeek: 2,
    feastList: {},
  );
  date = liturgicalMainFeasts['PENTECOST']!;
  calendar.addDayContent(date, dayContent);
  date = date.shift(1);

  // --- ORDINARY TIME AFTER PENTECOST ---
  int ordinaryDaysLeft =
      liturgicalMainFeasts['CHRIST_KING']!.difference(date).inDays;
  int ordinaryWeeksLeft = ordinaryDaysLeft ~/ 7;
  ordinaryTimeDays = (32 - ordinaryWeeksLeft) * 7 + 1;

  while (date.isBefore(liturgicalMainFeasts['CHRIST_KING']!.shift(7))) {
    precedence = date.isSunday ? 6 : 13;

    DayContent dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'ot',
      defaultCelebrationTitle:
          'ot_${(ordinaryTimeDays ~/ 7) + 1}_${date.weekday % 7}',
      precedence: precedence,
      liturgicalColor: 'green',
      breviaryWeek: (ordinaryTimeDays ~/ 7) % 4 + 1,
      feastList: {},
    );
    calendar.addDayContent(date, dayContent);
    date = date.shift(1);
    ordinaryTimeDays++;
  }

  // --- ADDING SOLEMNITIES AND FEASTS OVER THE ALREADY CREATED DATES ---
  _fillFixedSolemnities(calendar, liturgicalMainFeasts, liturgicalYear);

  applyCommonFeastsToCalendar(
      calendar, data.commonFeasts, liturgicalYear, liturgicalMainFeasts);
  calendar = localCalendarFill(calendar, liturgicalYear, location,
      liturgicalMainFeasts, data.locationData);

  return calendar;
}

/// Extracted to keep the main function cleaner without losing logic
void _fillFixedSolemnities(
    Calendar calendar, Map<String, DateTime> feasts, int year) {
  final solemnities = {
    'IMMACULATE_CONCEPTION': 3,
    'ASCENSION': 3,
    'SAINT_JOSEPH': 4,
    'HOLY_TRINITY': 3,
    'CORPUS_DOMINI': 3,
    'SACRED_HEART': 3,
    'CHRIST_KING': 3,
  };

  solemnities.forEach((name, prec) {
    if (feasts.containsKey(name)) {
      calendar.addItemToDay(feasts[name]!, prec, name.toLowerCase());
    }
  });

  // Annunciation key varies by year: 'annunciation-lent' or 'annunciation-easter'
  final annunciationKey = feasts.keys.firstWhere(
    (k) => k.startsWith('annunciation'),
    orElse: () => '',
  );
  if (annunciationKey.isNotEmpty) {
    calendar.addItemToDay(feasts[annunciationKey]!, 3, annunciationKey);
  }

  calendar.addItemToDay(
      feasts['saint_pieter_and_saint_paul']!, 4, 'saint_pieter_and_saint_paul');
  calendar.addItemToDay(
      feasts['saint_john_the_baptist']!, 4, 'saint_john_the_baptist');
  calendar.addItemToDay(DateTime(year, 11, 1), 3, 'all_saints');
  calendar.addItemToDay(
      DateTime(year, 11, 2), 3, 'commemoration_of_all_the_faithful_departed');
  calendar.addItemToDay(
      DateTime(year, 8, 15), 3, 'assumption_of_the_blessed_virgin_mary');

  // Specific removals and relations
  calendar.removeCelebrationFromDay(feasts['CHRIST_KING']!, 'OT_34_0');
  calendar.addItemRelatedToFeast(
      feasts['SACRED_HEART']!, 1, 10, 'immaculate_heart_of_mary');
  calendar.addItemRelatedToFeast(
      feasts['PENTECOST']!, 1, 10, 'mary_mother_of_the_church');
}
