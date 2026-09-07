import '../classes/calendar_class.dart'; // calendar definition class
import 'location_loader.dart';
import 'common_calendar_definitions.dart'; // computation of the dates of the variables feasts
import '../tools/date_tools.dart';
import 'local_calendar_fill.dart';

/// Builds two liturgical years to avoid border problems (around first Sunday of Advent).
/// [data] is mandatory: it carries the universal Roman feasts and the location tree.
/// [epiphanyOverride], [ascensionOverride] and [corpusDominiOverride] take precedence
/// over the location-derived values when provided ('day'|'sunday' for epiphany;
/// 'thursday'|'sunday' for ascension and corpusDomini).
Calendar getCalendar(
  Calendar calendar,
  DateTime eventDate,
  String location,
  LiturgyData data, {
  String? epiphanyOverride,
  String? ascensionOverride,
  String? corpusDominiOverride,
}) {
  final String epiphanyMode =
      epiphanyOverride ?? getEpiphanyDate(location, data.locationData);
  final bool ascensionOnSunday =
      (ascensionOverride ?? getAscensionDate(location, data.locationData)) ==
          'sunday';
  final bool corpusDominiOnThursday = (corpusDominiOverride ??
          getCorpusDominiDate(location, data.locationData)) ==
      'thursday';

  final cal1 = calendarFill(Calendar(), eventDate, location, data, epiphanyMode,
      ascensionOnSunday, corpusDominiOnThursday);
  final cal2 = calendarFill(
      Calendar(),
      DateTime(eventDate.year + 1, eventDate.month, eventDate.day),
      location,
      data,
      epiphanyMode,
      ascensionOnSunday,
      corpusDominiOnThursday);

  calendar.calendarData.addAll(cal1.calendarData);
  calendar.calendarData.addAll(cal2.calendarData);

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
  String epiphanyMode,
  bool ascensionOnSunday,
  bool corpusDominiOnThursday,
) {
  //detection of the liturgical year
  int liturgicalYear = eventDate.year;
  DateTime adventDate = advent(liturgicalYear + 1);
  if (adventDate.isBefore(eventDate) ||
      adventDate.isAtSameMomentAs(eventDate)) {
    liturgicalYear++;
  }

  Map<String, DateTime> liturgicalMainFeasts = createLiturgicalDays(
    liturgicalYear,
    epiphanyMode,
  );

  if (ascensionOnSunday) {
    final easterDay = liturgicalMainFeasts['ASCENSION']!.shift(-39);
    liturgicalMainFeasts['ASCENSION'] = easterDay.shift(42);
  }

  if (corpusDominiOnThursday) {
    final easterDay = liturgicalMainFeasts['CORPUS_DOMINI']!.shift(-63);
    liturgicalMainFeasts['CORPUS_DOMINI'] = easterDay.shift(60);
  }

  // Each season fills itself from liturgicalMainFeasts, which already holds
  // every pivot date (Advent, Nativity, Epiphany, Baptism, Ashes, Palms,
  // Easter, Ascension, Pentecost, Christ the King) — so these calls have no
  // ordering dependency on each other beyond readability.
  _fillAdvent(calendar, liturgicalMainFeasts, liturgicalYear);
  _fillChristmasToBaptism(calendar, liturgicalMainFeasts, liturgicalYear);
  _fillOrdinaryTimeBeforeLent(calendar, liturgicalMainFeasts, liturgicalYear);
  _fillLentAndHolyWeek(calendar, liturgicalMainFeasts, liturgicalYear);
  _fillPaschalTime(
      calendar, liturgicalMainFeasts, liturgicalYear, ascensionOnSunday);
  _fillOrdinaryTimeAfterPentecost(
      calendar, liturgicalMainFeasts, liturgicalYear);

  // --- ADDING SOLEMNITIES AND FEASTS OVER THE ALREADY CREATED DATES ---
  _fillFixedSolemnities(calendar, liturgicalMainFeasts, liturgicalYear);

  applyCommonFeastsToCalendar(
      calendar, data.commonFeasts, liturgicalYear, liturgicalMainFeasts);
  calendar = localCalendarFill(calendar, liturgicalYear, location,
      liturgicalMainFeasts, data.locationData, data.knownCodes);

  return calendar;
}

/// Fills Advent: the weekdays and Sundays from the 1st Sunday of Advent up
/// to (not including) Christmas Eve.
void _fillAdvent(
    Calendar calendar, Map<String, DateTime> feasts, int liturgicalYear) {
  int adventDays = 0;
  DateTime date = feasts['ADVENT']!;
  while (date.isBefore(feasts['NATIVITY']!)) {
    String defaultCelebrationTitle;
    int precedence;
    if (date.day < 17 || date.month == 11) {
      precedence = date.isSunday ? 2 : 13;
      defaultCelebrationTitle =
          'advent_${(adventDays ~/ 7) + 1}_${adventDays % 7}';
    } else {
      precedence = date.isSunday ? 2 : 9;
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
}

/// Fills the Nativity, the Christmas Octave, Mary Mother of God, the days
/// up to and including Epiphany, and up to and including the Baptism of
/// the Lord.
void _fillChristmasToBaptism(
    Calendar calendar, Map<String, DateTime> feasts, int liturgicalYear) {
  // adding the Nativity of the Lord
  DayContent dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'nativity',
    defaultCelebrationTitle: 'roman/nativity',
    precedence: 2,
    liturgicalColor: 'white',
    breviaryWeek: 1,
    feastList: {},
  );
  // christmas is december, 25th of the previous year
  DateTime date = DateTime(liturgicalYear - 1, 12, 25);
  calendar.addDayContent(date, dayContent);

  // adding the christmas Octave
  date = date.shift(1); // begins decembre, the 26th
  while (date.isBefore(DateTime(liturgicalYear, 1, 1))) {
    String defaultCelebrationTitle = 'christmas_${date.day}';
    int precedence = (date.day <= 28) ? 7 : 9;

    if (date == feasts['HOLY_FAMILY']) {
      defaultCelebrationTitle = 'roman/holy_family';
      precedence = 5;
    }
    DayContent dayContent = DayContent(
        liturgicalYear: liturgicalYear,
        liturgicalTime: 'christmasoctave',
        defaultCelebrationTitle: defaultCelebrationTitle,
        precedence: precedence,
        liturgicalColor: 'white',
        breviaryWeek: date.isBefore(feasts['HOLY_FAMILY']!) ? 4 : 1,
        // if the date is before the Holy Family, the breviary week is 4, otherwise it is 1
        feastList: {});
    calendar.addDayContent(date, dayContent);
    date = date.shift(1);
  }

  // adding Mary Mother of God
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'christmas',
    defaultCelebrationTitle: 'roman/mary_mother_of_god',
    precedence: 2,
    liturgicalColor: 'white',
    breviaryWeek: 1,
    feastList: {},
  );
  date = DateTime(liturgicalYear, 1, 1);
  calendar.addDayContent(date, dayContent);

  date = date.shift(1);
  int christmasFerialDays = date.difference(feasts['HOLY_FAMILY']!).inDays;

  // days between january, 2d and the Epiphany
  DateTime epiphanyDate = feasts['EPIPHANY']!;
  while (date.isBefore(epiphanyDate)) {
    dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'christmas',
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
    liturgicalTime: 'christmas',
    defaultCelebrationTitle: 'roman/epiphany',
    precedence: 3,
    liturgicalColor: 'white',
    breviaryWeek: epiphanyDate.day > 6 ? 1 : 2,
    // if the Epiphany is after the 6th, the Baptism of the Lord is next day, on monday.
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
  while (date.isBefore(feasts['BAPTISM']!)) {
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
    defaultCelebrationTitle: 'roman/baptism',
    precedence: 5,
    liturgicalColor: 'white',
    breviaryWeek: 1,
    feastList: {},
  );
  date = feasts['BAPTISM']!;
  calendar.addDayContent(date, dayContent);
}

/// Fills Ordinary Time weeks between the Baptism of the Lord and Ash
/// Wednesday.
void _fillOrdinaryTimeBeforeLent(
    Calendar calendar, Map<String, DateTime> feasts, int liturgicalYear) {
  DateTime date = feasts['BAPTISM']!.shift(1); // begins after Epiphany
  int ordinaryTimeDays = feasts['BAPTISM']!.isSunday
      ? 1
      : 2; // if Baptism is on monday, initiate the days count to 2
  while (date.isBefore(feasts['ASHES']!)) {
    String defaultCelebrationTitle =
        'ot_${(ordinaryTimeDays ~/ 7) + 1}_${date.weekday % 7}';
    int precedence = date.isSunday ? 6 : 13;
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
}

/// Fills Ash Wednesday, the rest of Lent, and Holy Week up to (not
/// including) Easter Sunday.
void _fillLentAndHolyWeek(
    Calendar calendar, Map<String, DateTime> feasts, int liturgicalYear) {
  // adding the Ashes Wednesday
  DayContent dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'lent',
    defaultCelebrationTitle: 'lent_0_3',
    precedence: 2,
    liturgicalColor: 'violet',
    breviaryWeek: 4,
    feastList: {},
  );
  DateTime date = feasts['ASHES']!;
  calendar.addDayContent(date, dayContent);
  date = date.shift(1);

  // adding the lent days between the Ashes Wednesday
  // and the first sunday of Lent
  int lentDays = 4;
  while (date.isBefore(feasts['ASHES']!.shift(4))) {
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
  while (date.isBefore(feasts['PALMS']!)) {
    String defaultCelebrationTitle =
        'lent_${(lentDays ~/ 7) + 1}_${date.weekday % 7}';
    int precedence = date.isSunday ? 2 : 9;
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
  date = feasts['PALMS']!;
  calendar.addDayContent(date, dayContent);
  date = date.shift(1);
  lentDays++;

  // adding the Holy Week days
  while (date.isBefore(feasts['EASTER']!)) {
    int precedence = lentDays % 7 < 4
        ? 2
        : 1; // from holy Thursday, the precedence is 1, before it is 2
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
}

/// Fills the Paschal Octave, the days up to the Ascension, the Ascension
/// itself, the days up to Pentecost, and Pentecost.
void _fillPaschalTime(Calendar calendar, Map<String, DateTime> feasts,
    int liturgicalYear, bool ascensionOnSunday) {
  int paschalTimeDays = 0;
  DateTime date = feasts['EASTER']!;

  // Paschal Octave (precedence: 2, except Sunday: 1)
  while (date.isBefore(feasts['EASTER']!.shift(7))) {
    int precedence = date.isSunday ? 1 : 2;
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

  while (date.isBefore(feasts['ASCENSION']!)) {
    int precedence = date.isSunday ? 2 : 13;
    final bool beforeAscensionSunday =
        ascensionOnSunday && paschalTimeDays >= 39;
    DayContent dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'paschaltime',
      defaultCelebrationTitle: beforeAscensionSunday
          ? 'easter_${(paschalTimeDays ~/ 7) + 1}_${date.weekday % 7}_before_ascension'
          : 'easter_${(paschalTimeDays ~/ 7) + 1}_${date.weekday % 7}',
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
  DayContent dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'paschaltime',
    defaultCelebrationTitle: 'roman/ascension',
    precedence: 2,
    liturgicalColor: 'white',
    breviaryWeek: 2,
    feastList: {},
  );
  date = feasts['ASCENSION']!;
  calendar.addDayContent(date, dayContent);
  paschalTimeDays++;
  date = date.shift(1);

  // days between Ascension and Pentecost
  while (date.isBefore(feasts['PENTECOST']!)) {
    int precedence = date.isSunday ? 2 : 13;
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
    defaultCelebrationTitle: 'roman/pentecost',
    precedence: 2,
    liturgicalColor: 'red',
    breviaryWeek: 2,
    feastList: {},
  );
  date = feasts['PENTECOST']!;
  calendar.addDayContent(date, dayContent);
}

/// Fills Ordinary Time from the day after Pentecost through Christ the
/// King, and the week following it.
void _fillOrdinaryTimeAfterPentecost(
    Calendar calendar, Map<String, DateTime> feasts, int liturgicalYear) {
  DateTime date = feasts['PENTECOST']!.shift(1);

  final int ordinaryWeeksLeft =
      feasts['CHRIST_KING']!.difference(date).inDays ~/ 7;
  int ordinaryTimeDays = (32 - ordinaryWeeksLeft) * 7 + 1;

  while (date.isBefore(feasts['CHRIST_KING']!)) {
    DayContent dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'ot',
      defaultCelebrationTitle:
          'ot_${(ordinaryTimeDays ~/ 7) + 1}_${date.weekday % 7}',
      precedence: date.isSunday ? 6 : 13,
      liturgicalColor: 'green',
      breviaryWeek: (ordinaryTimeDays ~/ 7) % 4 + 1,
      feastList: {},
    );
    calendar.addDayContent(date, dayContent);
    date = date.shift(1);
    ordinaryTimeDays++;
  }

  // Christ the King Sunday
  calendar.addDayContent(
      date,
      DayContent(
        liturgicalYear: liturgicalYear,
        liturgicalTime: 'ot',
        defaultCelebrationTitle: 'roman/christ_king',
        precedence: 3,
        liturgicalColor: 'white',
        breviaryWeek: (ordinaryTimeDays ~/ 7) % 4 + 1,
        feastList: {},
      ));
  date = date.shift(1);
  ordinaryTimeDays++;

  while (date.isBefore(feasts['CHRIST_KING']!.shift(7))) {
    DayContent dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'ot',
      defaultCelebrationTitle:
          'ot_${(ordinaryTimeDays ~/ 7) + 1}_${date.weekday % 7}',
      precedence: 13,
      liturgicalColor: 'green',
      breviaryWeek: (ordinaryTimeDays ~/ 7) % 4 + 1,
      feastList: {},
    );
    calendar.addDayContent(date, dayContent);
    date = date.shift(1);
    ordinaryTimeDays++;
  }
}

/// Extracted to keep the main function cleaner without losing logic
void _fillFixedSolemnities(
    Calendar calendar, Map<String, DateTime> feasts, int year) {
  final solemnities = {
    'IMMACULATE_CONCEPTION': 3,
    'SAINT_JOSEPH': 3,
    'HOLY_TRINITY': 3,
    'CORPUS_DOMINI': 3,
    'SACRED_HEART': 3,
  };

  for (final MapEntry(:key, :value) in solemnities.entries) {
    if (feasts.containsKey(key)) {
      calendar.addItemToDay(feasts[key]!, value, 'roman/${key.toLowerCase()}');
    }
  }

  // Annunciation key varies by year: 'annunciation-lent' or 'annunciation-easter'
  final annunciationKey = feasts.keys.firstWhere(
    (k) => k.startsWith('annunciation'),
    orElse: () => '',
  );
  if (annunciationKey.isNotEmpty) {
    calendar.addItemToDay(
        feasts[annunciationKey]!, 3, 'roman/$annunciationKey');
  }

  calendar.addItemToDay(feasts['saint_pieter_and_saint_paul']!, 3,
      'roman/saint_pieter_and_saint_paul');
  calendar.addItemToDay(
      feasts['saint_john_the_baptist']!, 3, 'roman/saint_john_the_baptist');
  calendar.addItemToDay(
      DateTime(year, 8, 6), 5, 'roman/transfiguration_of_the_lord');
  calendar.addItemToDay(
      DateTime(year, 8, 15), 3, 'roman/assumption_of_the_blessed_virgin_mary');
  calendar.addItemToDay(DateTime(year, 11, 1), 3, 'roman/all_saints');
  calendar.addItemToDay(DateTime(year, 11, 2), 3,
      'roman/commemoration_of_all_the_faithful_departed');

  // Specific relations
  calendar.addItemRelatedToFeast(
      feasts['SACRED_HEART']!, 1, 10, 'roman/immaculate_heart_of_mary');
  calendar.addItemRelatedToFeast(
      feasts['PENTECOST']!, 1, 10, 'roman/mary_mother_of_the_church');
}
