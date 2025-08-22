import 'classes/calendar_class.dart'; // cette classe définit calendar
import 'common_calendar_definitions.dart'; //ensemble des fonctions qui calculent les dates de fêtes à date variable
import 'feasts/common_feasts.dart'; //liste des fêtes de l'Église universelle
import './feasts/locations/lyon.dart';
import './feasts/locations/france.dart';
import './feasts/locations/europe.dart';

Calendar calendarFill(Calendar calendar, int liturgicalYear, String location) {
  // function used to fill the mains elemnts of the liturgical calendar.
  // fixed all the movable dates and feast of the Universal Church.
  // it returns a Calendar object with all the days filled.
  Map<String, DateTime> generalCalendar = createLiturgicalDays(liturgicalYear);

  String defaultCelebration = "";
  int liturgicalGrade = 0;
  // add the Avdent Days till Nativity day
  int adventDays = 0;
  // adventDays is the number of days in Advent
  DateTime date = generalCalendar['ADVENT']!;
  while (date.isBefore(generalCalendar['NATIVITY']!)) {
    if ((adventDays % 7 == 0)) {
      liturgicalGrade = 2;
      defaultCelebration = 'ADVENT_SUNDAY_${(adventDays / 7).floor() + 1}';
    } else {
      if (date.day < 17) {
        liturgicalGrade = 13;
        defaultCelebration =
            'ADVENT_FERIALE_${(adventDays / 7).floor() + 1}_${adventDays % 7}';
      } else {
        liturgicalGrade = 9;
        defaultCelebration = 'ADVENT_${date.day}';
      }
    }
    DayContent dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'Advent',
      defaultCelebration: defaultCelebration,
      liturgicalGrade: liturgicalGrade,
      liturgicalColor: 'violet',
      breviaryWeek: (adventDays / 7).floor() % 4 + 1,
      priority: {},
    );
    calendar.addDayContent(date, dayContent);
    date = date.add(Duration(days: 1));
    adventDays++;
  }

  // adding the Nativity of the Lord
  DayContent dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'Christmas',
    defaultCelebration: 'NATIVITY',
    liturgicalGrade: 2,
    liturgicalColor: 'white',
    breviaryWeek: 1,
    priority: {},
  );
  // Christmas is december, 25th of the previous year
  date = DateTime(liturgicalYear - 1, 12, 25);
  calendar.addDayContent(date, dayContent);

  // adding the Christmas Octave
  int christmasOctaveDays = 2;
  date = date.add(Duration(days: 1)); // begins decembre, the 26th
  while (date.isBefore(DateTime(liturgicalYear, 1, 1))) {
    if ((date.weekday % 7 == 0)) {
      defaultCelebration = 'CHRISTMAS_SUNDAY';
      liturgicalGrade = 6;
    } else {
      defaultCelebration = 'CHRISTMAS-OCTAVE_$christmasOctaveDays';
      liturgicalGrade = 9;
    }
    DayContent dayContent = DayContent(
        liturgicalYear: liturgicalYear,
        liturgicalTime: 'ChristmasOctave',
        defaultCelebration: defaultCelebration,
        liturgicalGrade: liturgicalGrade,
        liturgicalColor: 'white',
        breviaryWeek: date.isBefore(generalCalendar['HOLY_FAMILY']!) ? 4 : 1,
        // if the date is before the Holy Family, the breviary week is 4, otherwise it is 1
        priority: {});
    calendar.addDayContent(date, dayContent);
    date = date.add(Duration(days: 1));
    christmasOctaveDays++;
  }

  // adding the Christmasferials, till the Baptisme of the Lord
  int christmasFerialDays = 1;

// days between january, 1st and the Epiphany
  DateTime epiphanyDate = generalCalendar['EPIPHANY']!;
  while (date.isBefore(epiphanyDate)) {
    dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'ChristmasFeriale',
      defaultCelebration:
          'CHRISTMAS-FERIALE_BEFORE_EPIPHANY_$christmasFerialDays',
      liturgicalGrade: 13,
      liturgicalColor: 'white',
      breviaryWeek: 1,
      priority: {},
    );
    calendar.addDayContent(date, dayContent);
    date = date.add(Duration(days: 1));
    christmasFerialDays++;
  }
// adjunction of the Epiphany
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'Christmas',
    defaultCelebration: 'EPIPHANY',
    liturgicalGrade: 3,
    liturgicalColor: 'white',
    breviaryWeek: epiphanyDate.day > 6 ? 1 : 2,
    // if the Epiphany is after the 6th, the Baptisme of the Lord is the next day, so on monday.
    // in this case the Epiphany is begining the first week of the liturgical year, so breviaryWeek is 1
    // otherwise (if the Epiphany is on the 6th or before), the Baptism will be on the next sunday, so
    // the Epiphany is not the first week of the liturgical year, therefor breviaryWeek is 2.
    priority: {},
  );
  date = epiphanyDate;
  calendar.addDayContent(date, dayContent);
  date = date.add(Duration(days: 1));

  christmasFerialDays = 1;
// going on with the "second week" till the Baptism of the Lord
  while (date.isBefore(generalCalendar['BAPTISM']!)) {
    dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'ChristmasFeriale',
      defaultCelebration: 'CHRISTMAS-FERIALE_2_$christmasFerialDays',
      liturgicalGrade: 13,
      liturgicalColor: 'white',
      breviaryWeek: epiphanyDate.day > 6 ? 1 : 2, // see above
      priority: {},
    );
    calendar.addDayContent(date, dayContent);
    date = DateTime(date.year, date.month, date.day + 1);
    christmasFerialDays++;
  }

// adding the Baptism of the Lord
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'Christmas',
    defaultCelebration: 'BAPTISM',
    liturgicalGrade: 5,
    liturgicalColor: 'white',
    breviaryWeek: 1,
    priority: {},
  );
  date = generalCalendar['BAPTISM']!;
  calendar.addDayContent(date, dayContent);

// AJOUT DES JOURS DU TEMPS ORDINAIRE JUSQU'AU CARÊME
  int ordinaryTimeDays = 1;
  date = date.add(Duration(days: 1)); // commence après l'Épiphanie
  while (date.isBefore(generalCalendar['ASHES']!)) {
    String timeCode = '${(ordinaryTimeDays / 7).floor() + 1}';
    if ((date.weekday % 7 == 0)) {
      defaultCelebration = 'OT_SUNDAY_$timeCode';
      liturgicalGrade = 6;
    } else {
      defaultCelebration = 'OT_${timeCode}_${ordinaryTimeDays % 7}';
      liturgicalGrade = 13;
    }
    DayContent dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'OrdinaryTime',
      defaultCelebration: defaultCelebration,
      liturgicalGrade: liturgicalGrade,
      liturgicalColor: 'green',
      breviaryWeek: (ordinaryTimeDays / 7).floor() % 4 + 1,
      priority: {},
    );
    calendar.addDayContent(date, dayContent);
    date = DateTime(date.year, date.month, date.day + 1);
    ordinaryTimeDays++;
  }
// ajout du Mercredi des Cendres
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'LentTime',
    defaultCelebration: 'ASHES',
    liturgicalGrade: 2,
    liturgicalColor: 'violet',
    breviaryWeek: 4,
    priority: {},
  );
  date = generalCalendar['ASHES']!;
  calendar.addDayContent(date, dayContent);
  date = date.add(Duration(days: 1)); // on avance le calendrier d'un jour

  // ajout des jours de Carême entre le mercredi des cendres
  // et le premier dimanche de Carême
  int lentDays = 4;
  //date = date.add(Duration(days: 1)); // commence après le mercredi des Cendres
  while (date.isBefore(generalCalendar['ASHES']!.add(Duration(days: 4)))) {
    dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'LentTime',
      defaultCelebration: 'LENT_0_$lentDays',
      liturgicalGrade: 9,
      liturgicalColor: 'violet',
      breviaryWeek: 4,
      priority: {},
    );
    calendar.addDayContent(date, dayContent);
    date = date.add(Duration(days: 1));
    lentDays++;
  }

  //ajout des jours de Carême jusqu'au Rameaux exclu
  lentDays = 0;
  //date = date.add(Duration(days: 1)); // commence après l'Épiphanie
  while (date.isBefore(generalCalendar['PALMS']!)) {
    String timeCode = '${(lentDays / 7).floor() + 1}';
    if ((date.weekday % 7 == 0)) {
      defaultCelebration = 'LENT_SUNDAY_$timeCode';
      liturgicalGrade;
    } else {
      defaultCelebration = 'LENT_${timeCode}_${lentDays % 7}';
      liturgicalGrade = 9;
    }
    DayContent dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'LentTime',
      defaultCelebration: defaultCelebration,
      liturgicalGrade: liturgicalGrade,
      liturgicalColor: 'violet',
      breviaryWeek: (lentDays / 7).floor() % 4 + 1,
      priority: {},
    );
    calendar.addDayContent(date, dayContent);
    date = DateTime(date.year, date.month, date.day + 1);
    lentDays++;
  }
// ajout du dimanche des Rameaux
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'LentTime',
    defaultCelebration: 'PALMS',
    liturgicalGrade: 2,
    liturgicalColor: 'red',
    breviaryWeek: (lentDays / 7).floor() % 4 + 1,
    priority: {},
  );
  date = generalCalendar['PALMS']!;
  calendar.addDayContent(date, dayContent);
  date = date.add(Duration(days: 1)); // on avance le calendrier d'un jour

//ajout des jours de Carême entre Rameaux et Jeudi Saint exclu
  lentDays++;
  //date = date.add(Duration(days: 1)); // commence après l'Épiphanie
  while (date.isBefore(generalCalendar['HOLY_THURSDAY']!)) {
    dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'HolyWeek',
      defaultCelebration: 'LENT_${(lentDays / 7).floor() + 1}-${lentDays % 7}',
      liturgicalGrade: 9,
      liturgicalColor: 'violet',
      breviaryWeek: (lentDays / 7).floor() % 4 + 1,
      priority: {},
    );
    calendar.addDayContent(date, dayContent);
    date = DateTime(date.year, date.month, date.day + 1);
    lentDays++;
  }

  // ajout du Jeudi Saint
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'HolyWeek',
    defaultCelebration: 'HOLY_THURSDAY',
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
    defaultCelebration: 'HOLY_FRIDAY',
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
    defaultCelebration: 'HOLY_SATURDAY',
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
    defaultCelebration: 'EASTER',
    liturgicalGrade: 1,
    liturgicalColor: 'white',
    breviaryWeek: null,
    priority: {},
  );
  date = generalCalendar['EASTER']!;
  calendar.addDayContent(date, dayContent);

// AJOUT DES JOURS DU TEMPS PASCAL JUSQU'À LA PENTECÔTE
  int paschalTimeDays = 1;
  date = generalCalendar['EASTER']!
      .add(Duration(days: 1)); // commence après Pâques
  // ajout des jours de l'octave pascal (priority 2)
  while (date.isBefore(generalCalendar['EASTER']!.add(Duration(days: 7)))) {
    DayContent dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'PaschalOctave',
      defaultCelebration:
          'PT_${(paschalTimeDays / 7).floor() + 1}_${paschalTimeDays % 7}',
      liturgicalGrade: 2,
      liturgicalColor: 'white',
      breviaryWeek: (paschalTimeDays / 7).floor() % 4 + 1,
      priority: {},
    );
    calendar.addDayContent(date, dayContent);
    date = DateTime(date.year, date.month, date.day + 1);
    paschalTimeDays++;
  }
  //ajout du dimanche de la Miséricorde
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'PaschalTime',
    breviaryWeek: 2,
    defaultCelebration: 'SUNDAY_OF_DIVINE_MERCY',
    liturgicalGrade: 2,
    liturgicalColor: 'white',
    priority: {},
  );
  calendar.addDayContent(date, dayContent);
  date = DateTime(date.year, date.month, date.day + 1);
  paschalTimeDays++;

  while (date.isBefore(generalCalendar['PENTECOST']!)) {
    String timeCode = '${(paschalTimeDays / 7).floor() + 1}';
    if ((date.weekday % 7 == 0)) {
      defaultCelebration = 'PT_SUNDAY_$timeCode';
      liturgicalGrade = 2;
    } else {
      defaultCelebration = 'PT_${timeCode}_${paschalTimeDays % 7}';
      liturgicalGrade = 13;
    }
    DayContent dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'PaschalTime',
      defaultCelebration: defaultCelebration,
      liturgicalGrade: liturgicalGrade,
      liturgicalColor: 'white',
      breviaryWeek: (paschalTimeDays / 7).floor() % 4 + 1,
      priority: {},
    );
    calendar.addDayContent(date, dayContent);
    date = DateTime(date.year, date.month, date.day + 1);
    paschalTimeDays++;
  }

// Ajout de la Pentecôte
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'PaschalTime',
    defaultCelebration: 'PENTECOST',
    liturgicalGrade: 2,
    liturgicalColor: 'red',
    breviaryWeek: 2,
    priority: {},
  );
  date = generalCalendar['PENTECOST']!;
  calendar.addDayContent(date, dayContent);

  date = date.add(Duration(days: 1));
  // on avance le calendrier d'un jour pour arriver au lundi de Pentecôte

  // AJOUT DES JOURS DU TEMPS ORDINAIRE JUSQU'APRÈS LE CHRIST ROI
  //ajout des jours "perdus" après mercredi des cendres et semaine sainte :
  int ordinaryDaysLeft =
      generalCalendar['CHRIST_KING']!.difference(date).inDays;
  int ordinaryWeeksLeft = (ordinaryDaysLeft / 7).floor();
  ordinaryTimeDays = (32 - ordinaryWeeksLeft) * 7 + 1;

  while (
      date.isBefore(generalCalendar['CHRIST_KING']!.add(Duration(days: 7)))) {
    String timeCode = '${(ordinaryTimeDays / 7).floor() + 1}';
    if ((date.weekday % 7 == 0)) {
      defaultCelebration = 'OT_SUNDAY_$timeCode';
      liturgicalGrade = 6;
    } else {
      defaultCelebration = 'OT_${timeCode}_${ordinaryTimeDays % 7}';
      liturgicalGrade = 13;
    }
    DayContent dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'OrdinaryTime',
      defaultCelebration: defaultCelebration,
      liturgicalGrade: liturgicalGrade,
      liturgicalColor: 'green',
      breviaryWeek: (ordinaryTimeDays / 7).floor() % 4 + 1,
      priority: {},
    );
    calendar.addDayContent(date, dayContent);
    date = DateTime(date.year, date.month, date.day + 1);
    ordinaryTimeDays++;
  }

// AJOUT DES JOURS QUI SE SUPERPOSENT AUX JOURS DÉJA CRÉÉS
  String eventName = 'IMMACULATE_CONCEPTION';
  calendar.addItemToDay(generalCalendar[eventName]!, 3, eventName);
  eventName = 'HOLY_FAMILY';
  calendar.addItemToDay(generalCalendar[eventName]!, 6, eventName);
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
  calendar.removeCelebrationFromDay(generalCalendar['CHRIST_KING']!,
      'OT_SUNDAY_34'); //suprimer le 34ème dimanche, vu que c'est le Christ Roi

//ajout du cœur immaculé de Marie après la fête du Sacré Cœur:
  calendar.addItemRelatedToFeast(
      generalCalendar['SACRED_HEART']!, 1, 10, 'immaculate_heart_of_mary');
//ajout de la fête de Marie mère de l'Église le lendemain de la Pentecôte:
  calendar.addItemRelatedToFeast(
      generalCalendar['PENTECOST']!, 1, 10, 'mary_mother_of_the_church');

//AJOUT DE TOUTES LES FÊTES DES CALENDRIERS LOCAUX
  calendar.addFeastsToCalendar(
      commonFeastsList, liturgicalYear, generalCalendar);

  switch (location) {
    case 'lyon':
      calendar = addLyonFeasts(calendar, liturgicalYear, generalCalendar);
    case 'france':
      calendar = addFranceFeasts(calendar, liturgicalYear, generalCalendar);
    case 'europe':
      calendar = addEuropeFeasts(calendar, liturgicalYear, generalCalendar);
  }

  return calendar;
}
