import 'dart:io';
import 'classes/calendar_class.dart'; // cette classe définit calendar
import 'common_calendar.dart'; //ensemble des fonctions qui calculent les dates de fêtes à date variable
import 'feasts/common_feats.dart'; //liste des fêtes de l'Église universelle
import './feasts/locations/lyon.dart';
import './feasts/locations/france.dart';
import './feasts/locations/europe.dart';

Calendar calendarFill(Calendar calendar, int liturgicalYear, String location) {
  Map<String, DateTime> generalCalendar = createLiturgicalDays(liturgicalYear);

  String defaultCelebration = "";
  int defaultPriority = 0;
  //ajouter des jours de l'Avent jusqu'à Noël
  int adventDays = 0; // jours depuis le début de l'Avent
  DateTime date = generalCalendar['ADVENT']!;
  while (date.isBefore(generalCalendar['NATIVITY']!)) {
    if ((adventDays % 7 == 0)) {
      defaultPriority = 2;
      defaultCelebration = 'ADVENT_SUNDAY_${(adventDays / 7).floor() + 1}';
    } else {
      if (date.day < 17) {
        defaultPriority = 13;
        defaultCelebration =
            'ADVENT_FERIALE_${(adventDays / 7).floor() + 1}_${adventDays % 7}';
      } else {
        defaultPriority = 9;
        defaultCelebration = 'ADVENT_${date.day}';
      }
    }
    DayContent dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'Advent',
      defaultCelebration: defaultCelebration,
      defaultPriority: defaultPriority,
      defaultColor: 'violet',
      breviaryWeek: (adventDays / 7).floor() % 4 + 1,
      priority: {},
    );
    calendar.addDayContent(date, dayContent);
    date = date.add(Duration(days: 1));
    adventDays++;
  }

  //ajout de Noël
  DayContent dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'Christmas',
    defaultCelebration: 'NATIVITY',
    defaultPriority: 2,
    defaultColor: 'white',
    breviaryWeek: 1,
    priority: {},
  );
  // Noël est le 25 décembre de l'année précédente
  date = DateTime(liturgicalYear - 1, 12, 25);
  calendar.addDayContent(date, dayContent);

  // ajout de l'octave de Noël
  int christmasOctaveDays = 2;
  date = date.add(Duration(days: 1)); // commence le 26 décembre
  while (date.isBefore(DateTime(liturgicalYear, 1, 1))) {
    if ((date.weekday % 7 == 0)) {
      defaultCelebration = 'CHRISTMAS_SUNDAY';
      defaultPriority = 6;
    } else {
      defaultCelebration = 'CHRISTMAS-OCTAVE_$christmasOctaveDays';
      defaultPriority = 9;
    }
    DayContent dayContent = DayContent(
        liturgicalYear: liturgicalYear,
        liturgicalTime: 'ChristmasOctave',
        defaultCelebration: defaultCelebration,
        defaultPriority: defaultPriority,
        defaultColor: 'white',
        breviaryWeek: 1,
        priority: {});
    calendar.addDayContent(date, dayContent);
    date = date.add(Duration(days: 1));
    christmasOctaveDays++;
  }

  // ajout de la férie de Noël (jusqu'au Baptême du Seigneur)
  int christmasFerialDays = 1;

//on commence par la "première semaine" (jusqu'à l'Épiphanie)
  while (date.isBefore(generalCalendar['EPIPHANY']!)) {
    dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'ChristmasFeriale',
      defaultCelebration: 'CHRISTMAS-FERIALE_1_$christmasFerialDays',
      defaultPriority: 13,
      defaultColor: 'white',
      breviaryWeek: 1,
      priority: {},
    );
    calendar.addDayContent(date, dayContent);
    date = date.add(Duration(days: 1));
    christmasFerialDays++;
  }
// ajout de l'Épiphanie
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'Christmas',
    defaultCelebration: 'EPIPHANY',
    defaultPriority: 3,
    defaultColor: 'white',
    breviaryWeek: 1,
    priority: {},
  );
  date = generalCalendar['EPIPHANY']!;
  calendar.addDayContent(date, dayContent);
  date = date.add(Duration(days: 1));

  christmasFerialDays = 1;
// on continue avec la "seconde semaine" (jusqu'au Baptême du Seigneur)
  while (date.isBefore(generalCalendar['BAPTISM']!)) {
    dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'ChristmasFeriale',
      defaultCelebration: 'CHRISTMAS-FERIALE_2_$christmasFerialDays',
      defaultPriority: 13,
      defaultColor: 'white',
      breviaryWeek: 2,
      priority: {},
    );
    calendar.addDayContent(date, dayContent);
    date = DateTime(date.year, date.month, date.day + 1);
    christmasFerialDays++;
  }

// ajout du Baptême du Seigneur
  dayContent = DayContent(
    liturgicalYear: liturgicalYear,
    liturgicalTime: 'Christmas',
    defaultCelebration: 'BAPTISM',
    defaultPriority: 5,
    defaultColor: 'white',
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
      defaultPriority = 6;
    } else {
      defaultCelebration = 'OT_$timeCode-${ordinaryTimeDays % 7}';
      defaultPriority = 13;
    }
    DayContent dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'OrdinaryTime',
      defaultCelebration: defaultCelebration,
      defaultPriority: defaultPriority,
      defaultColor: 'green',
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
    defaultPriority: 2,
    defaultColor: 'violet',
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
      defaultPriority: 9,
      defaultColor: 'violet',
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
      defaultPriority;
    } else {
      defaultCelebration = 'LENT_$timeCode-${lentDays % 7}';
      defaultPriority = 9;
    }
    DayContent dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'LentTime',
      defaultCelebration: defaultCelebration,
      defaultPriority: defaultPriority,
      defaultColor: 'violet',
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
    defaultPriority: 2,
    defaultColor: 'red',
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
      defaultPriority: 9,
      defaultColor: 'violet',
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
    defaultPriority: 1,
    defaultColor: 'white',
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
    defaultPriority: 1,
    defaultColor: 'red',
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
    defaultPriority: 1,
    defaultColor: 'black',
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
    defaultPriority: 1,
    defaultColor: 'white',
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
          'PT_${(paschalTimeDays / 7).floor() + 1}-${paschalTimeDays % 7}',
      defaultPriority: 2,
      defaultColor: 'white',
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
    defaultPriority: 2,
    defaultColor: 'white',
    priority: {},
  );
  calendar.addDayContent(date, dayContent);
  date = DateTime(date.year, date.month, date.day + 1);
  paschalTimeDays++;

  while (date.isBefore(generalCalendar['PENTECOST']!)) {
    String timeCode = '${(paschalTimeDays / 7).floor() + 1}';
    if ((date.weekday % 7 == 0)) {
      defaultCelebration = 'PT_SUNDAY_$timeCode';
      defaultPriority = 2;
    } else {
      defaultCelebration = 'PT_$timeCode-${paschalTimeDays % 7}';
      defaultPriority = 13;
    }
    DayContent dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'PaschalTime',
      defaultCelebration: defaultCelebration,
      defaultPriority: defaultPriority,
      defaultColor: 'white',
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
    defaultPriority: 2,
    defaultColor: 'red',
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
      defaultPriority = 6;
    } else {
      defaultCelebration = 'OT_$timeCode-${ordinaryTimeDays % 7}';
      defaultPriority = 13;
    }
    DayContent dayContent = DayContent(
      liturgicalYear: liturgicalYear,
      liturgicalTime: 'OrdinaryTime',
      defaultCelebration: defaultCelebration,
      defaultPriority: defaultPriority,
      defaultColor: 'green',
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
  eventName = 'TRINITY';
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

Calendar checkAndFillCalendar(
    Calendar calendar, DateTime date, String location) {
  // fonction d'ajout des années manquantes si besoin
  final calendarFile = File('./lib/assets/calendar.json');
  // vérification que le fichier existe
  if (!calendarFile.existsSync()) {
    calendar.calendarData
        .addAll(calendarFill(calendar, date.year, location).calendarData);
    calendar.exportToJsonFile('./lib/assets/calendar.json');
    return calendar;
  } else {
    String jsonString = calendarFile.readAsStringSync(); // Lecture synchrone
    if (jsonString.trim().isEmpty) {
      // vérifier que le fichier n'est pas vide, auquel cas le rempli de l'année demandé
      calendar.calendarData
          .addAll(calendarFill(calendar, date.year, location).calendarData);
      calendar.exportToJsonFile('./lib/assets/calendar.json');
      return calendar;
    }
    // si le fichier existe et n'est pas vide, le lire
    calendar = Calendar.importFromJsonFile('./lib/assets/calendar.json');
    if (calendar.calendarData.isEmpty) {
      calendar.calendarData.addAll(calendarFill(calendar, date.year, location)
          as Map<DateTime, DayContent>);
      calendar.exportToJsonFile('./lib/assets/calendar.json');
      return calendar;
    }
  }
// Si le fichier ne contenait pas la date demandée, on rajoute les années manquantes.
  DateTime firstDate = calendar.calendarData.keys.first;
  DateTime lastDate = calendar.calendarData.keys.last;
  if (date.isBefore(firstDate)) {
    calendar = Calendar();
    for (int year = date.year; year <= firstDate.year; year++) {
      calendar = calendarFill(calendar, year, location);
    }
  } else if (date.isAfter(lastDate)) {
    for (int year = lastDate.year + 1; year <= date.year; year++) {
      calendar = calendarFill(calendar, year, location);
    }
  }

  calendar.exportToJsonFile('./lib/assets/calendar.json');

  return calendar;
}
