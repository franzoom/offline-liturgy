import 'classes/calendar_class.dart'; // calendar definition class
import 'common_calendar_definitions.dart'; //computation of the dates of the variables feasts
import 'tools/date_tools.dart';
import 'feasts/common_feasts.dart'; // feast list for the universal Church
import './feasts/locations/lyon.dart';
import './feasts/locations/paris.dart';
import './feasts/locations/france.dart';
import './feasts/locations/belgium.dart';
import './feasts/locations/canada.dart';
import './feasts/locations/europe.dart';

Calendar calendarFill(Calendar calendar, int liturgicalYear, String location) {
  // function used to fill the main elements of the liturgical calendar.
  // fixes all the movable dates and feast of the Universal Church.
  // it returns a Calendar object with all the days filled.
  Map<String, DateTime> generalCalendar = createLiturgicalDays(liturgicalYear);

  String defaultCelebrationTitle = "";
  int liturgicalGrade = 0;
  // add the Avdent Days till Nativity day
  int adventDays = 0;
  // adventDays is the number of days in Advent
  DateTime date = generalCalendar['ADVENT']!;
  while (date.isBefore(generalCalendar['NATIVITY']!)) {
    if (date.day < 17) {
      liturgicalGrade = (adventDays % 7 == 0)
          ? 2
          : 13; // Sundays are grade 2, other days grade 13
      defaultCelebrationTitle =
          'advent_${(adventDays / 7).floor() + 1}_${adventDays % 7}';
    } else {
      liturgicalGrade = 9;
      defaultCelebrationTitle = 'advent_${date.day}';
    }

    DayContent dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'Advent',
      defaultCelebrationTitle: defaultCelebrationTitle,
      liturgicalGrade: liturgicalGrade,
      liturgicalColor: 'violet',
      breviaryWeek: (adventDays / 7).floor() % 4 + 1,
      priority: {},
    );
    calendar.addDayContent(date, dayContent);
    date = dayShift(date, 1);
    adventDays++;
  }

  // adding the Nativity of the Lord
  DayContent dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'Christmas',
    defaultCelebrationTitle: 'NATIVITY',
    liturgicalGrade: 2,
    liturgicalColor: 'white',
    breviaryWeek: 1,
    priority: {},
  );
  // Christmas is december, 25th of the previous year
  date = DateTime(liturgicalYear - 1, 12, 25);
  calendar.addDayContent(date, dayContent);

  // adding the Christmas Octave
  date = date.add(Duration(days: 1)); // begins decembre, the 26th
  while (date.isBefore(DateTime(liturgicalYear, 1, 1))) {
    if (date == generalCalendar['HOLY_FAMILY']) {
      defaultCelebrationTitle = 'HOLY_FAMILY';
      liturgicalGrade = 6;
    } else {
      liturgicalGrade = 7;
      switch (date.day) {
        case 26:
          defaultCelebrationTitle = 'christmas_26-stephen_the_first_martyr';
          break;
        case 27:
          defaultCelebrationTitle = 'christmas_27-john_apostle';
          break;
        case 28:
          defaultCelebrationTitle = 'christmas_28-holy_innocents_martyrs';
          break;
        default:
          defaultCelebrationTitle = 'christmas_${date.day}';
          liturgicalGrade = 9;
      }
    }
    DayContent dayContent = DayContent(
        liturgicalYear: liturgicalYear,
        liturgicalTime: 'ChristmasOctave',
        defaultCelebrationTitle: defaultCelebrationTitle,
        liturgicalGrade: liturgicalGrade,
        liturgicalColor: 'white',
        breviaryWeek: date.isBefore(generalCalendar['HOLY_FAMILY']!) ? 4 : 1,
        // if the date is before the Holy Family, the breviary week is 4, otherwise it is 1
        priority: {});
    calendar.addDayContent(date, dayContent);
    date = dayShift(date, 1);
  }

  // adding the Nativity of the Lord
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'Christmas',
    defaultCelebrationTitle: 'mary_mother_of_god',
    liturgicalGrade: 2,
    liturgicalColor: 'white',
    breviaryWeek: 1,
    priority: {},
  );
  date = DateTime(liturgicalYear, 1, 1);
  calendar.addDayContent(date, dayContent);

  date = date.add(Duration(days: 1));
  int christmasFerialDays = 2;

// days between january, 2d and the Epiphany
  DateTime epiphanyDate = generalCalendar['EPIPHANY']!;
  while (date.isBefore(epiphanyDate)) {
    dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'Christmas Feriale before Epiphany',
      defaultCelebrationTitle:
          'christmas-ferial_before_epiphany_$christmasFerialDays',
      liturgicalGrade: 13,
      liturgicalColor: 'white',
      breviaryWeek: 1,
      priority: {},
    );
    calendar.addDayContent(date, dayContent);
    date = dayShift(date, 1);
    christmasFerialDays++;
  }
// adjunction of the Epiphany
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'Christmas',
    defaultCelebrationTitle: 'EPIPHANY',
    liturgicalGrade: 3,
    liturgicalColor: 'white',
    breviaryWeek: epiphanyDate.day > 6 ? 1 : 2,
    // if the Epiphany is after the 6th, the Baptism of the Lord is the next day, on monday.
    // in this case the Epiphany is begining the first week of the new liturgical year,
    // and breviaryWeek is 1.
    // otherwise (if the Epiphany is on the 6th or before), the Baptism will be on the next sunday, so
    // the Epiphany is not the first week of the liturgical year, therefore breviaryWeek is 2.
    priority: {},
  );
  date = epiphanyDate;
  calendar.addDayContent(date, dayContent);
  date = dayShift(date, 1);
  christmasFerialDays = 1;

  // going on with the "second week" till the Baptism of the Lord:
  while (date.isBefore(generalCalendar['BAPTISM']!)) {
    dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'ChristmasFeriale',
      defaultCelebrationTitle: 'christmas_feriale_2_$christmasFerialDays',
      liturgicalGrade: 13,
      liturgicalColor: 'white',
      breviaryWeek: epiphanyDate.day > 6 ? 1 : 2, // see above
      priority: {},
    );
    calendar.addDayContent(date, dayContent);
    date = dayShift(date, 1);
    christmasFerialDays++;
  }

  // adding the Baptism of the Lord
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'Christmas',
    defaultCelebrationTitle: 'BAPTISM',
    liturgicalGrade: 5,
    liturgicalColor: 'white',
    breviaryWeek: 1,
    priority: {},
  );
  date = generalCalendar['BAPTISM']!;
  calendar.addDayContent(date, dayContent);

  // ADDING ORDINARY DAYS TILL LENT
  int ordinaryTimeDays = 1;
  date = date.add(Duration(days: 1)); // begins after Epiphany
  while (date.isBefore(generalCalendar['ASHES']!)) {
    String weekNumber = '${(ordinaryTimeDays / 7).floor() + 1}';
    int dayOfWeek = date.weekday % 7;
    defaultCelebrationTitle = 'OT_${weekNumber}_$dayOfWeek';
    liturgicalGrade = dayOfWeek == 0 ? 6 : 13;
    DayContent dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'OrdinaryTime',
      defaultCelebrationTitle: defaultCelebrationTitle,
      liturgicalGrade: liturgicalGrade,
      liturgicalColor: 'green',
      breviaryWeek: (ordinaryTimeDays / 7).floor() % 4 + 1,
      priority: {},
    );
    calendar.addDayContent(date, dayContent);
    date = dayShift(date, 1);
    ordinaryTimeDays++;
  }
// adding the Ashes Wednesday
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'LentTime',
    defaultCelebrationTitle: 'lent_0_3',
    liturgicalGrade: 2,
    liturgicalColor: 'violet',
    breviaryWeek: 4,
    priority: {},
  );
  date = generalCalendar['ASHES']!;
  calendar.addDayContent(date, dayContent);
  date = dayShift(date, 1);

  // adding the lent days between the Ashes Wednesday
  // and the first sunday of Lent
  int lentDays = 4;
  while (date.isBefore(generalCalendar['ASHES']!.add(Duration(days: 4)))) {
    dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'LentTime',
      defaultCelebrationTitle: 'lent_0_$lentDays',
      liturgicalGrade: 9,
      liturgicalColor: 'violet',
      breviaryWeek: 4,
      priority: {},
    );
    calendar.addDayContent(date, dayContent);
    date = dayShift(date, 1);
    lentDays++;
  }

  //add the Lent days till Palm Sunday (excluded)
  lentDays = 0;
  while (date.isBefore(generalCalendar['PALMS']!)) {
    int dayOfWeek = date.weekday % 7;
    String weekNumber = '${(lentDays / 7).floor() + 1}';
    defaultCelebrationTitle = 'lent_${weekNumber}_$dayOfWeek';
    liturgicalGrade = dayOfWeek == 0 ? 2 : 9;
    DayContent dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'LentTime',
      defaultCelebrationTitle: defaultCelebrationTitle,
      liturgicalGrade: liturgicalGrade,
      liturgicalColor: 'violet',
      breviaryWeek: (lentDays / 7).floor() % 4 + 1,
      priority: {},
    );
    calendar.addDayContent(date, dayContent);
    date = dayShift(date, 1);
    lentDays++;
  }
// adding Palms Sunday
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'LentTime',
    defaultCelebrationTitle: 'PALMS',
    liturgicalGrade: 2,
    liturgicalColor: 'red',
    breviaryWeek: (lentDays / 7).floor() % 4 + 1,
    priority: {},
  );
  date = generalCalendar['PALMS']!;
  calendar.addDayContent(date, dayContent);
  date = dayShift(date, 1);
  lentDays++;

// adding the Lent days between Palms and Holy Thursday (excluded)
  while (date.isBefore(generalCalendar['HOLY_THURSDAY']!)) {
    dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'HolyWeek',
      defaultCelebrationTitle:
          'lent_${(lentDays / 7).floor() + 1}_${lentDays % 7}',
      liturgicalGrade: 9,
      liturgicalColor: 'violet',
      breviaryWeek: (lentDays / 7).floor() % 4 + 1,
      priority: {},
    );
    calendar.addDayContent(date, dayContent);
    date = dayShift(date, 1);
    lentDays++;
  }

  // ajout du Jeudi Saint
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'HolyWeek',
    defaultCelebrationTitle: 'HOLY_THURSDAY',
    liturgicalGrade: 1,
    liturgicalColor: 'white',
    breviaryWeek: null,
    priority: {},
  );
  date = generalCalendar['HOLY_THURSDAY']!;
  calendar.addDayContent(date, dayContent);

  // ajout du Vendredi Saint
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'HolyWeek',
    defaultCelebrationTitle: 'HOLY_FRIDAY',
    liturgicalGrade: 1,
    liturgicalColor: 'red',
    breviaryWeek: null,
    priority: {},
  );
  date = generalCalendar['HOLY_FRIDAY']!;
  calendar.addDayContent(date, dayContent);

  // ajout du Samedi Saint
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'HolyWeek',
    defaultCelebrationTitle: 'HOLY_SATURDAY',
    liturgicalGrade: 1,
    liturgicalColor: 'black',
    breviaryWeek: null,
    priority: {},
  );
  date = generalCalendar['HOLY_SATURDAY']!;
  calendar.addDayContent(date, dayContent);

  // ajout de Pâques
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'PaschalTime',
    defaultCelebrationTitle: 'EASTER',
    liturgicalGrade: 1,
    liturgicalColor: 'white',
    breviaryWeek: null,
    priority: {},
  );
  date = generalCalendar['EASTER']!;
  calendar.addDayContent(date, dayContent);

  // ADDING PASCHAL DAYS TILL PENTECOST
  int paschalTimeDays = 1;
  date = dayShift(generalCalendar['EASTER']!, 1); // initiates after Easter

  // Paschal Octave (Grade: 2)
  while (date.isBefore(dayShift(generalCalendar['EASTER']!, 7))) {
    DayContent dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'PaschalOctave',
      defaultCelebrationTitle:
          'PT_${(paschalTimeDays / 7).floor() + 1}_${paschalTimeDays % 7}',
      liturgicalGrade: 2,
      liturgicalColor: 'white',
      breviaryWeek: (paschalTimeDays / 7).floor() % 4 + 1,
      priority: {},
    );
    calendar.addDayContent(date, dayContent);
    date = dayShift(date, 1);
    paschalTimeDays++;
  }
  // Sunday of Mercy (2d Sunday of Paschal Time)
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'PaschalTime',
    breviaryWeek: 2,
    defaultCelebrationTitle: 'SUNDAY_OF_DIVINE_MERCY',
    liturgicalGrade: 2,
    liturgicalColor: 'white',
    priority: {},
  );
  calendar.addDayContent(date, dayContent);
  date = dayShift(date, 1);
  paschalTimeDays++;

  // Paschal days after the 2d Sunday till Pentecost
  while (date.isBefore(generalCalendar['PENTECOST']!)) {
    String weekNumber = '${(paschalTimeDays / 7).floor() + 1}';
    int dayOfWeek = date.weekday % 7;
    defaultCelebrationTitle = 'PT_${weekNumber}_$dayOfWeek';
    liturgicalGrade = dayOfWeek == 0 ? 2 : 13;
    DayContent dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'PaschalTime',
      defaultCelebrationTitle: defaultCelebrationTitle,
      liturgicalGrade: liturgicalGrade,
      liturgicalColor: 'white',
      breviaryWeek: (paschalTimeDays / 7).floor() % 4 + 1,
      priority: {},
    );
    calendar.addDayContent(date, dayContent);
    date = dayShift(date, 1);
    paschalTimeDays++;
  }

// Ajout de la Pentecôte
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'PaschalTime',
    defaultCelebrationTitle: 'PENTECOST',
    liturgicalGrade: 2,
    liturgicalColor: 'red',
    breviaryWeek: 2,
    priority: {},
  );
  date = generalCalendar['PENTECOST']!;
  calendar.addDayContent(date, dayContent);

  // moving on day forward to go the monday of Pentecost:
  date = dayShift(date, 1);

  // ADDING ORDINARY DAYS TILL SATURDAY AFTER CHRIST KING
  // adding the "lost days" after the Ashes Wednesday ands the Holy Week:
  int ordinaryDaysLeft =
      generalCalendar['CHRIST_KING']!.difference(date).inDays;
  int ordinaryWeeksLeft = (ordinaryDaysLeft / 7).floor();
  ordinaryTimeDays = (32 - ordinaryWeeksLeft) * 7 + 1;

  while (
      date.isBefore(generalCalendar['CHRIST_KING']!.add(Duration(days: 7)))) {
    String weekNumber = '${(ordinaryTimeDays / 7).floor() + 1}';
    int dayOfWeek = date.weekday % 7;
    defaultCelebrationTitle = 'OT_${weekNumber}_$dayOfWeek';
    liturgicalGrade = dayOfWeek == 0 ? 6 : 13;

    DayContent dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'OrdinaryTime',
      defaultCelebrationTitle: defaultCelebrationTitle,
      liturgicalGrade: liturgicalGrade,
      liturgicalColor: 'green',
      breviaryWeek: (ordinaryTimeDays / 7).floor() % 4 + 1,
      priority: {},
    );
    calendar.addDayContent(date, dayContent);
    date = dayShift(date, 1);
    ordinaryTimeDays++;
  }

// ADDING THE SOLEMNITIES AND FEASTS OVER THE ALREADY CREATED DATES
  String eventName = 'IMMACULATE_CONCEPTION';
  calendar.addItemToDay(generalCalendar[eventName]!, 3, eventName);
  eventName = 'ASCENSION';
  calendar.addItemToDay(generalCalendar[eventName]!, 3, eventName);
  eventName = 'ANNUNCIATION';
  calendar.addItemToDay(generalCalendar[eventName]!, 3, eventName);
  eventName = 'SAINT_JOSEPH';
  calendar.addItemToDay(generalCalendar[eventName]!, 4, eventName);
  eventName = 'HOLY_TRINITY';
  calendar.addItemToDay(generalCalendar[eventName]!, 3, eventName);
  eventName = 'CORPUS_DOMINI';
  calendar.addItemToDay(generalCalendar[eventName]!, 3, eventName);
  eventName = 'SACRED_HEART';
  calendar.addItemToDay(generalCalendar[eventName]!, 3, eventName);
  eventName = 'saint_pieter_and_saint_paul';
  calendar.addItemToDay(generalCalendar[eventName]!, 4, eventName);
  eventName = 'saint_john_the_baptist';
  calendar.addItemToDay(generalCalendar[eventName]!, 4, eventName);
  calendar.addItemToDay(DateTime(liturgicalYear, 11, 1), 3, 'all_saints');
  calendar.addItemToDay(DateTime(liturgicalYear, 11, 2), 3,
      'commemoration_of_all_the_faithful_departed');
  calendar.addItemToDay(DateTime(liturgicalYear, 8, 15), 3,
      'assumption_of_the_blessed_virgin_mary');
  eventName = 'CHRIST_KING';
  calendar.addItemToDay(generalCalendar[eventName]!, 3, eventName);
  //removing le 34th Sunday, it's the Christ King feast:
  calendar.removeCelebrationFromDay(generalCalendar['CHRIST_KING']!, 'OT_34_0');

  // adding the Immaculate Heart of Mary after Sacred Heart:
  calendar.addItemRelatedToFeast(
      generalCalendar['SACRED_HEART']!, 1, 10, 'immaculate_heart_of_mary');

  // adding Mary Mother of the Church afetr Pentecost:
  calendar.addItemRelatedToFeast(
      generalCalendar['PENTECOST']!, 1, 10, 'mary_mother_of_the_church');

  // ADDING THE FEASTS OF THE ROMAN CALENDAR
  calendar.addFeastsToCalendar(
      commonFeastsList, liturgicalYear, generalCalendar);

  // ADDING THE LOCAL CALENDARS
  switch (location) {
    case 'lyon':
      calendar = addLyonFeasts(calendar, liturgicalYear, generalCalendar);
    case 'paris':
      calendar = addParisFeasts(calendar, liturgicalYear, generalCalendar);
    case 'france':
      calendar = addFranceFeasts(calendar, liturgicalYear, generalCalendar);
    case 'belgium':
      calendar = addBelgiumFeasts(calendar, liturgicalYear, generalCalendar);
    case 'canada':
      calendar = addCanadaFeasts(calendar, liturgicalYear, generalCalendar);
    case 'europe':
      calendar = addEuropeFeasts(calendar, liturgicalYear, generalCalendar);
  }

  return calendar;
}
