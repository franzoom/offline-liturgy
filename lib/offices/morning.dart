import 'dart:convert';
import 'dart:io';
import '../classes/calendar_class.dart'; //classe de calendar
import '../classes/morning_class.dart';
import '../assets/psalms_data/morning_psalms.dart';
import '../tools/days_name.dart';
import '../tools/extract_week_and_day.dart';

bool detectFerialDays(String celebrationName) {
  // ferial day detection
  final prefixes = ['OT', 'ADVENT', 'LENT', 'CHRISMAS', 'PT'];
  return prefixes.any((prefix) => celebrationName.startsWith(prefix));
}

Map<String, Morning> ferialMorningResolution(
    Calendar calendar, DateTime date, location) {
  // if it's a ferial day, execution of the morning prayer resolution.
  // other layers will be added after
  Morning ferialMorning = Morning(); // creation of the instance ferialMorning
  final calendarDay = calendar.getDayContent(date);
  final celebrationName = calendarDay?.defaultCelebration;
  if (!detectFerialDays(celebrationName!)) {
    // if it's not a ferial day, return an empty ferialMorning instance
    return {celebrationName: ferialMorning};
  }

  if (celebrationName.startsWith('OT')) {
    // If it's Ordinary Time, then:
    if (celebrationName.contains('SUNDAY')) {
      // special case of Sunday
      final int weekNumber = int.parse(celebrationName[
          celebrationName.length - 1]); // week number calculation

      // retrieval of the corresponding datas of one of the 4 first sundays,
      final int referenceWeekNumber = ((weekNumber - 1) % 4) + 1;
      final dataFile =
          File('../assets/morning/data/OT_SUNDAY_$referenceWeekNumber');
      String fileContent = dataFile.readAsStringSync();
      final fileExtracted = jsonDecode(fileContent);
      ferialMorning = Morning.fromJson(fileExtracted);

      if (weekNumber > 4) {
        // then add the data of the actuel sunday if it's over the 4th week
        final auxFile = File('./bin/assets/morning/data/OT_SUNDAY_$weekNumber');
        String auxContent = auxFile.readAsStringSync();
        var auxExtracted = jsonDecode(auxContent);
        final sundayAuxData = Morning.fromJson(auxExtracted);
        //récupération
        ferialMorning.mergeWith(
            sundayAuxData); // ajoute les champs de AuxData dans sundayData
      }
    } else {
      // it's a week day. So we use only the 4 1rst weeks of the Ordinary Time
      // (we use a modulo to retreive the effective day)
      List dayDatas = extractWeekAndDay(celebrationName, "OT");
      int weekNumber = dayDatas[0];
      int dayNumber = dayDatas[1];
      final int referenceWeekNumber = ((weekNumber - 1) % 4) + 1;
      final dataFile = File(
          './bin/assets/morning/data/OT_${referenceWeekNumber}_$dayNumber.json');
      String fileContent = dataFile.readAsStringSync();
      final fileExtracted = jsonDecode(fileContent);
      ferialMorning = Morning.fromJson(fileExtracted);
    }
    // on termine en ajoutant le titre et les psaumes correspondants
    ferialMorning.celebrationGrade = calendarDay?.defaultPriority;
    ferialMorning.celebrationTitle = calendarDay?.defaultCelebration;
    List<String>? morningPsalmList = morningPsalms(calendarDay!.liturgicalTime,
        calendarDay.breviaryWeek!, dayName[date.weekday]);
    ferialMorning.psalm1Ref = morningPsalmList?[0];
    ferialMorning.psalm2Ref = morningPsalmList?[1];
    ferialMorning.psalm3Ref = morningPsalmList?[2];
    return {celebrationName: ferialMorning};
  } // end of the Ordinary Time

  //pour les autres temps liturgiques de Férie:
  final dataFile = File('../assets/morning/data/$celebrationName');
  String fileContent = dataFile.readAsStringSync();
  final fileExtracted = jsonDecode(fileContent);
  ferialMorning = Morning.fromJson(fileExtracted);

  return {celebrationName: ferialMorning};
}
