import '../../classes/feasts_class.dart';
import '../../classes/calendar_class.dart'; // cette classe définit calendar
import 'france.dart';

//fêtes du calendrier général
//hésitations de préséance sur la dédicace, sur Fort, Clair, Simon Stock, Mommolin, Abbon, André, ND de Lorette
//saint André, titulaire de l'Eglise métropolitaine et patron principal du diocèse (je dois mettre tout ça ?), date potentiellement mobile si 1er dimanche de l'Avent

Map<String, FeastDates> bordeauxFeastsList = {
  'delphinus_of_bordeaux_bishop_bordeaux':
      FeastDates(month: 1, day: 10, precedence: 11),
  'joan_de_lestonnac_religious_bordeaux':
      FeastDates(month: 2, day: 3, precedence: 11),
  'gerard_of_corbie_abbot_bordeaux':
      FeastDates(month: 4, day: 27, precedence: 11),
  //Revoir la priorité 'dedication_of_the_cathedral_of_saint_andrew_bordeaux': FeastDates(month: 5, day: 1, precedence: ?),
  'macarius_bishop_bordeaux': FeastDates(month: 5, day: 4, precedence: 12),
  //Revoir la priorité 'fort_of_bordeaux_bishop_martyr_bordeaux': FeastDates(month: 5, day: 16, precedence: ?),
  //Revoir la priorité et les offices car saint ! 'louis_beaulieu_priest_martyr_bordeaux': FeastDates(month: 5, day: 21, precedence: 12),
  //Revoir la priorité 'clair_of_aquitaine_bishop_martyr_bordeaux': FeastDates(month: 6, day: 2, precedence: ?),
  'amandus_of_bordeaux_bishop_bordeaux':
      FeastDates(month: 6, day: 18, precedence: 11),
  'paulinus_of_nola_bishop_bordeaux':
      FeastDates(month: 6, day: 22, precedence: 11),
  'martial_of_limoges_bishop_bordeaux':
      FeastDates(month: 6, day: 30, precedence: 12),
  'bertram_of_le_mans_bishop_bordeaux':
      FeastDates(month: 7, day: 1, precedence: 12),
  'leontius_the_younger_bishop_bordeaux':
      FeastDates(month: 7, day: 10, precedence: 11),
  //Revoir la priorité 'simon_stock_priest_bordeaux': FeastDates(month: 7, day: 17, precedence: ?),
  //Revoir la priorité 'mommolin_of_fleury_abbot_bordeaux': FeastDates(month: 8, day: 9, precedence: ?),
  'jean_joseph_rateau_and_companions_martyrs_bordeaux':
      FeastDates(month: 9, day: 2, precedence: 11),
  'austinde_of_auch_bishop_bordeaux':
      FeastDates(month: 9, day: 25, precedence: 12),
  'severinus_of_bordeaux_bishop_bordeaux':
      FeastDates(month: 9, day: 21, precedence: 11),
  //Revoir la priorité 'abbo_of_fleury_abbot_martyr_bordeaux': FeastDates(month: 11, day: 13, precedence: ?),
  'emilion_hermit_bordeaux': FeastDates(month: 11, day: 16, precedence: 11),
  'romanus_of_blaye_priest_bordeaux':
      FeastDates(month: 11, day: 24, precedence: 11),
  //Revoir la priorité 'andrew_the_apostle_bordeaux': FeastDates(month: 11, day: 30, precedence: ?),
  //Revoir la priorité 'our_lady_of_loreto': FeastDates(month: 12, day: 10, precedence: ?),
};

Calendar addBordeauxFeasts(
    Calendar calendar, int liturgicalYear, generalCalendar) {
  // ajouter les fêtes de la France:
  addFranceFeasts(calendar, liturgicalYear, generalCalendar);

  // puis ajouter les fêtes propres à Bordeaux:
  calendar.addFeastsToCalendar(
      bordeauxFeastsList, liturgicalYear, generalCalendar);

  // enfin ajouter les fêtes qui dépendent d'une fête mobile

  return calendar;
}
