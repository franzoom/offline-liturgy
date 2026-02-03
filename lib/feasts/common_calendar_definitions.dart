import '../tools/date_tools.dart';

/// Returns the previous Christmas day (relative to the liturgical year starting in late 'year'-1).
DateTime christmas(int year) => DateTime(year - 1, 12, 25);

/// Returns the start of Advent for a given year.
DateTime advent(int year) {
  DateTime christmasDay = christmas(year);
  int dayShift = christmasDay.weekday;
  // Advent starts 3 weeks + the days until the previous Sunday before Christmas
  return christmasDay.shift(-(21 + dayShift));
}

/// Returns the Holy Family feast date.
/// It's the Sunday after Christmas, or Dec 30th if Christmas is a Sunday.
DateTime holyFamily(int year) {
  DateTime christmasDay = christmas(year);
  if (christmasDay.isSunday) {
    return DateTime(year - 1, 12, 30);
  }
  return christmasDay.shift(7 - christmasDay.weekday);
}

/// Returns Epiphany (first Sunday after January 1st).
DateTime epiphany(int year) {
  DateTime jan1 = DateTime(year, 1, 1);
  int daysToAdd = jan1.isSunday ? 7 : (7 - jan1.weekday);
  return jan1.shift(daysToAdd);
}

/// Returns the Baptism of the Lord.
/// If Epiphany is Jan 7 or 8, Baptism is the next day (Monday).
DateTime baptism(DateTime epiphanyDay) {
  int daysToAdd = (epiphanyDay.day < 7) ? 7 : 1;
  return epiphanyDay.shift(daysToAdd);
}

/// Returns the 2nd Sunday of Ordinary Time.
DateTime secondSundayOT(DateTime epiphanyDay) {
  int daysToAdd = (epiphanyDay.day < 7) ? 14 : 7;
  return epiphanyDay.shift(daysToAdd);
}

/// Calculates the date of Easter using the Meeus/Jones/Butcher algorithm.
DateTime easter(int year) {
  int c = year ~/ 100;
  int n = year % 19;
  int k = (c - 17) ~/ 25;
  int i = c - (c ~/ 4) - ((c - k) ~/ 3) + 19 * n + 15;
  i = i % 30;
  i = i - (i ~/ 28) * (1 - (i ~/ 28) * (29 ~/ (i + 1)) * ((21 - n) ~/ 11));
  int j = year + (year ~/ 4) + i + 2 - c + (c ~/ 4);
  j = j % 7;
  int l = i - j;
  int m = 3 + ((l + 40) ~/ 44);
  int d = l + 28 - 31 * (m ~/ 4);
  return DateTime(year, m, d);
}

/// Returns the Annunciation date (March 25th) with transfer logic.
DateTime annunciation(DateTime easterDay) {
  DateTime annunciationDay = DateTime(easterDay.year, 3, 25);
  // If during Holy Week or Easter Octave, move to Monday after 2nd Sunday of Easter
  if (annunciationDay.isAfter(easterDay.shift(-7))) {
    return easterDay.shift(8);
  }
  // If on a Sunday of Lent, move to Monday
  if (annunciationDay.isSunday) {
    return annunciationDay.shift(1);
  }
  return annunciationDay;
}

/// Returns Saint Joseph's day (March 19th) with transfer logic.
DateTime saintJoseph(DateTime easterDay) {
  DateTime stJosephDay = DateTime(easterDay.year, 3, 19);
  // If during Holy Week, move to the Saturday before Palm Sunday
  if (stJosephDay.isAfter(easterDay.shift(-7))) {
    return easterDay.shift(-8);
  }
  // If on a Sunday of Lent, move to Monday
  else if (stJosephDay.isSunday) {
    return stJosephDay.shift(1);
  }
  return stJosephDay;
}

/// Returns St Peter and Paul (June 29), shifting if it hits Sacred Heart.
DateTime saintPieterAndPaul(DateTime sacredHeartDay) {
  DateTime stPeterPaulDay = DateTime(sacredHeartDay.year, 6, 29);
  if (stPeterPaulDay.isSameDayAs(sacredHeartDay)) {
    return stPeterPaulDay.shift(1);
  }
  return stPeterPaulDay;
}

/// Returns St John the Baptist (June 24), shifting if it hits Sacred Heart.
DateTime saintJohnTheBaptist(DateTime sacredHeartDay) {
  DateTime stJohnDay = DateTime(sacredHeartDay.year, 6, 24);
  // If it falls on the same day of the week as Sacred Heart (Friday), shift to Saturday
  if (stJohnDay.weekday == sacredHeartDay.weekday) {
    return stJohnDay.shift(1);
  }
  return stJohnDay;
}

/// Returns Immaculate Conception (Dec 8), shifting to Monday if it hits a Sunday of Advent.
DateTime immaculateConception(DateTime adventDay) {
  DateTime immaculateDay = DateTime(adventDay.year, 12, 8);
  if (immaculateDay.isSunday && immaculateDay.isAfter(adventDay)) {
    return immaculateDay.shift(1);
  }
  return immaculateDay;
}

/// Main function to generate all movable feasts for a liturgical year.
Map<String, DateTime> createLiturgicalDays(int year) {
  print('Defining variable feasts dates for liturgical year $year');
  Map<String, DateTime> liturgicalDays = {};

  final DateTime easterDay = easter(year);
  final DateTime adventDay = advent(year);

  liturgicalDays['NATIVITY'] = christmas(year);
  liturgicalDays['ADVENT'] = adventDay;
  liturgicalDays['IMMACULATE_CONCEPTION'] = immaculateConception(adventDay);
  liturgicalDays['HOLY_FAMILY'] = holyFamily(year);

  final DateTime epiphanyDay = epiphany(year);
  liturgicalDays['EPIPHANY'] = epiphanyDay;
  liturgicalDays['BAPTISM'] = baptism(epiphanyDay);
  liturgicalDays['SECOND_SUNDAY_OT'] = secondSundayOT(epiphanyDay);

  liturgicalDays['EASTER'] = easterDay;
  liturgicalDays['ASHES'] = easterDay.shift(-46);
  liturgicalDays['PALMS'] = easterDay.shift(-7);
  liturgicalDays['HOLY_THURSDAY'] = easterDay.shift(-3);
  liturgicalDays['HOLY_FRIDAY'] = easterDay.shift(-2);
  liturgicalDays['HOLY_SATURDAY'] = easterDay.shift(-1);

  liturgicalDays['ANNUNCIATION'] = annunciation(easterDay);
  liturgicalDays['SAINT_JOSEPH'] = saintJoseph(easterDay);

  liturgicalDays['ASCENSION'] = easterDay.shift(39);
  liturgicalDays['PENTECOST'] = easterDay.shift(49);
  liturgicalDays['HOLY_TRINITY'] = easterDay.shift(56);
  liturgicalDays['CORPUS_DOMINI'] = easterDay.shift(63);

  final DateTime sacredHeartDay = easterDay.shift(68);
  liturgicalDays['SACRED_HEART'] = sacredHeartDay;

  // Use sacredHeartDay for these specific shifts
  liturgicalDays['saint_pieter_and_saint_paul'] =
      saintPieterAndPaul(sacredHeartDay);
  liturgicalDays['saint_john_the_baptist'] =
      saintJohnTheBaptist(sacredHeartDay);

  liturgicalDays['CHRIST_KING'] = advent(year + 1).shift(-7);

  return liturgicalDays;
}
