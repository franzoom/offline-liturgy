// ensemble des fonctions qui calculent les dates de fêtes à date variable

DateTime christmas(int year) {
  //renvoie le jour de Noël précédent
  return DateTime(year - 1, 12, 25);
}

DateTime advent(int year) {
  //renvoie le jour du début de l'Avent pour une année donnée
  DateTime christmasDay = christmas(year);
  int dayShift = christmasDay.weekday;
  return christmasDay.subtract(Duration(days: 21 + dayShift));
}

DateTime holyFamily(int year) {
  //renvoie le jour de la fête de la Sainte Famille pour une année donnée
  // c'est le dimanche après Noël, ou le 30 décembre si Noël est un dimanche
  DateTime christmasDay = christmas(year);
  int daystoSunday = (7 - christmasDay.weekday) % 7;
  if (daystoSunday == 0) {
    // si Noël est un dimanche, on renvoie le 30 décembre
    return DateTime(year - 1, 12, 30);
  }
  return christmasDay.add(Duration(days: daystoSunday));
}

DateTime epiphany(int year) {
  // renvoie le jour de l'Épiphanie pour une année donnée.
  // c'est le premier dimanche qui suit le 1er janvier
  int januaryFirstWeekday = DateTime(year, 1, 1).weekday;
  int daysToAdd = (januaryFirstWeekday == 7) ? 7 : (7 - januaryFirstWeekday);
  return DateTime(year, 1, 1 + daysToAdd);
}

DateTime baptism(DateTime epiphanyDay) {
  // renvoie le jour du baptême du Christ pour une année donnée.
  // c'est le dimanche qui suit l'Épiphanie
  // si l'Epiphanie tombe le 7 ou 8, le Baptême est le lendemain
  int daystoAdd = (epiphanyDay.day < 7) ? 7 : 1;
  return epiphanyDay.add(Duration(days: daystoAdd));
}

DateTime secondSundayOT(DateTime epiphanyDay) {
  // renvoie le jour du deuxième dimanche du Temps Ordinaire.
  // Si l'Epiphanie tombe le 7 ou 8, le dimanche suivant est le 2èmeTO
  // autrement c'est 2 dimanches après l'Epiphanie (celui qui suit le Baptême).
  int daystoAdd = (epiphanyDay.day < 7) ? 14 : 7;
  return epiphanyDay.add(Duration(days: daystoAdd));
}

DateTime easter(int year) {
  //renvoie le jour de Pâques pour une année donnée
  // suivant l'algorithme de Meeus/Jones/Butcher
  int C = (year / 100).floor();
  int N = year - 19 * (year / 19).floor();
  int K = ((C - 17) / 25).floor();
  int I = C - (C / 4).floor() - ((C - K) / 3).floor() + 19 * N + 15;
  I = I - 30 * (I / 30).floor();
  I = I -
      (I / 28).floor() *
          (1 -
              (I / 28).floor() *
                  (29 / (I + 1)).floor() *
                  ((21 - N) / 11).floor());
  int J = year + (year / 4).floor() + I + 2 - C + (C / 4).floor();
  J = J - 7 * (J / 7).floor();
  int L = I - J;
  int M = 3 + ((L + 40) / 44).floor();
  int D = L + 28 - 31 * (M / 4).floor();
  return DateTime(year, M, D);
}

DateTime ashes(DateTime easterDay) {
  //renvoie le jour des Cendres pour une année donnée
  // c'est 46 jours avant Pâques
  return DateTime(easterDay.year, easterDay.month, easterDay.day - 46);
}

DateTime palms(DateTime easterDay) {
  //renvoie le jour des Rameaux pour une année donnée
  // c'est 7 jours avant Pâques
  return DateTime(easterDay.year, easterDay.month, easterDay.day - 7);
}

DateTime holyThursday(DateTime easterDay) {
  //renvoie le jour des Rameaux pour une année donnée
  // c'est 7 jours avant Pâques
  return DateTime(easterDay.year, easterDay.month, easterDay.day - 3);
}

DateTime holyFriday(DateTime easterDay) {
  //renvoie le jour des Rameaux pour une année donnée
  // c'est 7 jours avant Pâques
  return DateTime(easterDay.year, easterDay.month, easterDay.day - 2);
}

DateTime holySaturday(DateTime easterDay) {
  //renvoie le jour des Rameaux pour une année donnée
  // c'est 7 jours avant Pâques
  return DateTime(easterDay.year, easterDay.month, easterDay.day - 1);
}

DateTime ascension(DateTime easterDay) {
  //renvoie le jour de l'Ascension pour une année donnée
  // c'est 39 jours après Pâques
  return DateTime(easterDay.year, easterDay.month, easterDay.day + 39);
}

DateTime pentecost(DateTime easterDay) {
  //renvoie le jour de la Pentecôte pour une année donnée
  // c'est 49 jours après Pâques
  return DateTime(easterDay.year, easterDay.month, easterDay.day + 49);
}

DateTime trinity(DateTime easterDay) {
  //renvoie le jour de la Trinité pour une année donnée
  // c'est 56 jours après Pâques
  return DateTime(easterDay.year, easterDay.month, easterDay.day + 56);
}

DateTime corpusChristi(DateTime easterDay) {
  //renvoie le jour du Corpus Christi pour une année donnée
  // c'est 63 jours après Pâques
  return DateTime(easterDay.year, easterDay.month, easterDay.day + 63);
}

DateTime sacredHeart(DateTime easterDay) {
  //renvoie le jour du Sacré-Cœur pour une année donnée
  // c'est 68 jours après Pâques
  return DateTime(easterDay.year, easterDay.month, easterDay.day + 68);
}

DateTime annunciation(DateTime easterDay) {
  //renvoie le jour de l'Annonciation pour une année donnée
  // c'est le 25 mars, mais:
  // - si c'est un dimanche de Carême, on renvoie au lundi suivant
  // - si c'est pendant la Semaine Sainte ou l'Octave Pascal, on renvoie au lundi suivante le 2ème dimanche de Pâques
  DateTime annunciationDay = DateTime(easterDay.year, 3, 25);
  if (annunciationDay.isAfter(easterDay.subtract(Duration(days: 7)))) {
    // si le 25 mars est après le dimanche des Rameaux, on renvoie au lundi suivant le 2ème dimanche de Pâques
    return DateTime(easterDay.year, easterDay.month, easterDay.day + 8);
  }
  if (annunciationDay.weekday == DateTime.sunday) {
    // si le 25 mars est un dimanche, on renvoie lau lendemain
    return DateTime(
        annunciationDay.year, annunciationDay.month, annunciationDay.day + 1);
  }
  return annunciationDay;
}

DateTime saintJoseph(DateTime easterDay) {
  //renvoie le jour de la Saint Joseph pour une année donnée
  // c'est le 19 mars, mais:
  // - si elle tombe pendant la Semaine Sainte, on avance au samedi avant les Rameaux
  // - si c'est un dimanche de Carême, on renvoie au lundi suivant
  DateTime saintJosephDay = DateTime(easterDay.year, 3, 19);
  if (saintJosephDay.isAfter(easterDay.subtract(Duration(days: 7)))) {
    // si le 19 mars est après le dimanche des Rameaux, on renvoie au samedi avant les Rameaux
    return easterDay.subtract(Duration(days: 8));
  } else if (saintJosephDay.weekday == DateTime.sunday) {
    // sinon, si la fête tombe un dimanche de Carême, on repousse au lundi suivant
    return saintJosephDay.add(Duration(days: 1));
  }
  return saintJosephDay;
}

DateTime saintPieterAndPaul(DateTime sacredHeartDay) {
  //renvoie le jour de la Saint Pierre et Paul pour une année donnée
  // la décaler d'un jour lorsqu'elle tombe le vendredi du Sacré Coeur
  DateTime saintPieterAndPaulDay = DateTime(sacredHeartDay.year, 6, 29);
  if (saintPieterAndPaulDay == sacredHeartDay) {
    return saintPieterAndPaulDay.add(Duration(days: 1));
  }
  return saintPieterAndPaulDay;
}

DateTime saintJohnTheBaptist(DateTime sacredHeartDay) {
  //renvoie le jour de la Saint Jean Bpatiste pour une année donnée
  // la décaler d'un jour lorsqu'elle tombe le vendredi du Sacré Coeur
  DateTime saintJohnBaptistDay = DateTime(sacredHeartDay.year, 6, 24);
  if (saintJohnBaptistDay.weekday == sacredHeartDay.weekday) {
    return saintJohnBaptistDay.add(Duration(days: 1));
  }
  return saintJohnBaptistDay;
}

DateTime immaculateConception(DateTime adventDay) {
  //renvoie le jour de l'Immaculée Conception pour une année donnée
  // c'est le 8 décembre, mais si c'est un dimanche de l'Avent, on renvoie au lendemain
  DateTime immaculateConceptionDay = DateTime(adventDay.year, 12, 8);
  if (immaculateConceptionDay.weekday == DateTime.sunday &&
      immaculateConceptionDay.isAfter(adventDay)) {
    return immaculateConceptionDay.add(Duration(days: 1));
  }
  return immaculateConceptionDay;
}

DateTime christKing(int year) {
  // Christ King feast, last sunday of the liturgical year.
  // calculated by beeing the previous sunday before new liturgical year
  DateTime adventDay = advent(year + 1);
  return adventDay.subtract(Duration(days: 7));
}

createLiturgicalDays(int year) {
  // creates the list of variable feasts and their date
  print('defining variable feasts dates for liturgical year $year');
  Map<String, DateTime> liturgicalDays = {};
  liturgicalDays['NATIVITY'] = christmas(year);
  liturgicalDays['ADVENT'] = advent(year);
  liturgicalDays['IMMACULATE_CONCEPTION'] =
      immaculateConception(liturgicalDays['ADVENT']!);
  liturgicalDays['HOLY_FAMILY'] = holyFamily(year);
  liturgicalDays['EPIPHANY'] = epiphany(year);
  liturgicalDays['BAPTISM'] = baptism(liturgicalDays['EPIPHANY']!);
  liturgicalDays['SECOND_SUNDAY_OT'] =
      secondSundayOT(liturgicalDays['EPIPHANY']!);
  liturgicalDays['EASTER'] = easter(year);
  liturgicalDays['ASHES'] = ashes(liturgicalDays['EASTER']!);
  liturgicalDays['PALMS'] = palms(liturgicalDays['EASTER']!);
  liturgicalDays['HOLY_THURSDAY'] = holyThursday(liturgicalDays['EASTER']!);
  liturgicalDays['HOLY_FRIDAY'] = holyFriday(liturgicalDays['EASTER']!);
  liturgicalDays['HOLY_SATURDAY'] = holySaturday(liturgicalDays['EASTER']!);
  liturgicalDays['ANNUNCIATION'] = annunciation(liturgicalDays['EASTER']!);
  liturgicalDays['SAINT_JOSEPH'] = saintJoseph(liturgicalDays['EASTER']!);
  liturgicalDays['ASCENSION'] = ascension(liturgicalDays['EASTER']!);
  liturgicalDays['PENTECOST'] = pentecost(liturgicalDays['EASTER']!);
  liturgicalDays['HOLY_TRINITY'] = trinity(liturgicalDays['EASTER']!);
  liturgicalDays['CORPUS_DOMINI'] = corpusChristi(liturgicalDays['EASTER']!);
  liturgicalDays['SACRED_HEART'] = sacredHeart(liturgicalDays['EASTER']!);
  liturgicalDays['saint_pieter_and_saint_paul'] =
      saintPieterAndPaul(liturgicalDays['EASTER']!);
  liturgicalDays['saint_john_the_baptist'] =
      saintJohnTheBaptist(liturgicalDays['EASTER']!);
  liturgicalDays['CHRIST_KING'] = christKing(year);
  return liturgicalDays;
}
