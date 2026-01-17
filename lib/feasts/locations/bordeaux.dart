import '../../classes/calendar_class.dart';
import 'france.dart';

//fêtes du calendrier général
//hésitations de préséance sur la dédicace, sur Fort, Clair, Simon Stock, Mommolin, Abbon, André, ND de Lorette
//saint André, titulaire de l'Eglise métropolitaine et patron principal du diocèse (je dois mettre tout ça ?), date potentiellement mobile si 1er dimanche de l'Avent

Map<String, FeastDates> bordeauxFeastsList = {
  'bordeaux_delphinus_of_bordeaux_bishop':
      FeastDates(month: 1, day: 10, precedence: 11),
  'bordeaux_joan_de_lestonnac_religious':
      FeastDates(month: 2, day: 3, precedence: 11),
  'bordeaux_gerard_of_corbie_abbot':
      FeastDates(month: 4, day: 27, precedence: 11),
  //Revoir la priorité 'dedication_of_the_cathedral_of_saint_andrew': FeastDates(month: 5, day: 1, precedence: ?),
  'bordeaux_macarius_bishop': FeastDates(month: 5, day: 4, precedence: 12),
  //Revoir la priorité 'fort_of_bordeaux_bishop_martyr': FeastDates(month: 5, day: 16, precedence: ?),
  //Revoir la priorité et les offices car saint ! 'louis_beaulieu_priest_martyr': FeastDates(month: 5, day: 21, precedence: 12),
  //Revoir la priorité 'clair_of_aquitaine_bishop_martyr': FeastDates(month: 6, day: 2, precedence: ?),
  'bordeaux_amandus_of_bordeaux_bishop':
      FeastDates(month: 6, day: 18, precedence: 11),
  'bordeaux_paulinus_of_nola_bishop':
      FeastDates(month: 6, day: 22, precedence: 11),
  'bordeaux_martial_of_limoges_bishop':
      FeastDates(month: 6, day: 30, precedence: 12),
  'bordeaux_bertram_of_le_mans_bishop':
      FeastDates(month: 7, day: 1, precedence: 12),
  'bordeaux_leontius_the_younger_bishop':
      FeastDates(month: 7, day: 10, precedence: 11),
  //Revoir la priorité 'simon_stock_priest': FeastDates(month: 7, day: 17, precedence: ?),
  //Revoir la priorité 'mommolin_of_fleury_abbot': FeastDates(month: 8, day: 9, precedence: ?),
  'bordeaux_jean_joseph_rateau_and_companions_martyrs':
      FeastDates(month: 9, day: 2, precedence: 11),
  'bordeaux_austinde_of_auch_bishop':
      FeastDates(month: 9, day: 25, precedence: 12),
  'bordeaux_severinus_of_bordeaux_bishop':
      FeastDates(month: 9, day: 21, precedence: 11),
  //Revoir la priorité 'abbo_of_fleury_abbot_martyr': FeastDates(month: 11, day: 13, precedence: ?),
  'bordeaux_emilion_hermit': FeastDates(month: 11, day: 16, precedence: 11),
  'bordeaux_romanus_of_blaye_priest':
      FeastDates(month: 11, day: 24, precedence: 11),
  //Revoir la priorité 'andrew_the_apostle': FeastDates(month: 11, day: 30, precedence: ?),
  //Revoir la priorité 'our_lady_of_loreto': FeastDates(month: 12, day: 10, precedence: ?),
};

Calendar addBordeauxFeasts(
    Calendar calendar, int liturgicalYear, generalCalendar) {
  // add feasts fo France:
  addFranceFeasts(calendar, liturgicalYear, generalCalendar);

  // add proper feasts of Bordeaux:
  calendar.addFeastsToCalendar(
      bordeauxFeastsList, liturgicalYear, generalCalendar);

  return calendar;
}

Map<String, FeastDates> bordeauxCathedralFeastsList = {
  'andrew_the_apostle': FeastDates(month: 11, day: 30, precedence: 4),
};

Calendar addBordeauxCathedralFeasts(
    Calendar calendar, int liturgicalYear, generalCalendar) {
  // add feasts of France and Bordeaux:
  addBordeauxFeasts(calendar, liturgicalYear, generalCalendar);

  // add proper feasts of Cathedral of Bordeaux:
  calendar.addFeastsToCalendar(
      bordeauxCathedralFeastsList, liturgicalYear, generalCalendar);

  return calendar;
}
