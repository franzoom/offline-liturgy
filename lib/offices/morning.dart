import 'dart:convert';
import 'dart:io';
import '../classes/calendar_class.dart'; //classe de calendar
import '../classes/morning_class.dart';
import '../assets/psalms_data/morning_psalms.dart';
import '../tools/days_name.dart';
import '../tools/extract_week_and_day.dart';

bool detectFerialDays(String celebrationName) {
  // détecte si le nom du jour correspnd à un jour de férie (pour éliminer les jours de fête, à traiter à part)
  final prefixes = ['OT', 'ADVENT', 'LENT', 'CHRISMAS', 'PT'];
  return prefixes.any((prefix) => celebrationName.startsWith(prefix));
}

Map<String, Morning> ferialMorningResolution(
    Calendar calendar, DateTime date, location) {
//fonction de résolution des Laudes pour le cas des féries (on surajoutera le reste ensuite)
  Morning ferialMorning = Morning(); // création de l'instance ferialMorning
  final calendarDay = calendar.getDayContent(date);
  final celebrationName = calendarDay?.defaultCelebration;

  if (detectFerialDays(celebrationName!)) {
    if (celebrationName.startsWith('OT')) {
      //Si on est dans le temps ordinaire
      if (celebrationName.contains('SUNDAY')) {
        final int weekNumber = int.parse(
            celebrationName[celebrationName.length - 1]); // numéro de semaine

        //récupération des infos d'un des 4 premiers dimanches
        // (si on est un des 4 premiers, on prend tout, autrement on ajoutera
        // les infos du dimanche dont un a fait le modulo)
        final int referenceWeekNumber = (weekNumber % 4) + 1;
        final dataFile =
            File('../assets/morning/data/OT_SUNDAY_$referenceWeekNumber');
        String fileContent = dataFile.readAsStringSync();
        final fileExtracted = jsonDecode(fileContent);
        ferialMorning = Morning.fromJson(fileExtracted);

        if (weekNumber > 4) {
          //si c'est un autre dimanche, on intègre les antiennes de ce dimanche aux données des 4 premières semaines
          final auxFile = File('../assets/morning/data/OT_SUNDAY_$weekNumber');
          String auxContent = auxFile.readAsStringSync();
          var auxExtracted = jsonDecode(auxContent);
          final sundayAuxData = Morning.fromJson(auxExtracted);
          //récupération
          ferialMorning.mergeWith(
              sundayAuxData); // ajoute les champs de AuxData dans sundayData
        }
      } else {
        // si c'est en semaine, on prend le modulo à 4 pour n'utiliser les données
        // que des 4 premières semaines
        List dayDatas = extractWeekAndDay(celebrationName, "OT");
        int weekNumber = dayDatas[0];
        int dayNumber = dayDatas[1];
        final int referenceWeekNumber = (weekNumber % 4) + 1;
        final dataFile =
            File('../assets/morning/data/OT_${referenceWeekNumber}_$dayNumber');
        String fileContent = dataFile.readAsStringSync();
        final fileExtracted = jsonDecode(fileContent);
        ferialMorning = Morning.fromJson(fileExtracted);
      }
    }
    // on termine en ajoutant le titre et les psaumes correspondants
    ferialMorning.celebrationGrade = calendarDay?.defaultPriority;
    ferialMorning.celebrationTitle = calendarDay?.defaultCelebration;
    List<String>? morningPsalmList = morningPsalms(calendarDay!.liturgicalTime,
        calendarDay.breviaryWeek!, dayName[date.weekday]);
    ferialMorning.psalm1Ref = morningPsalmList?[0];
    ferialMorning.psalm2Ref = morningPsalmList?[1];
    ferialMorning.psalm3Ref = morningPsalmList?[2];
  }
  return {celebrationName: ferialMorning};
}
