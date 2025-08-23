import 'dart:convert';
import 'dart:io';
import '../classes/calendar_class.dart';
import '../classes/morning_class.dart';
import '../classes/day_offices_class.dart';
import '../assets/psalms_data/morning_psalms.dart';
import '../tools/days_name.dart';
import '../tools/extract_week_and_day.dart';

bool detectFerialDays(String celebrationName) {
  // ferial day detection
  final prefixes = ['OT', 'advent', 'lent', 'christmas', 'easter'];
  return prefixes.any((prefix) => celebrationName.startsWith(prefix));
}

Map<String, Morning> ferialMorningResolution(
    Calendar calendar, DateTime date, location) {
  // if it's a ferial day, execution of the morning prayer resolution.
  // other layers will be added afterwards if needed.
  final String ferialFilePath =
      './lib/assets/calendar_data/days_ferial'; // path to the ferial days data
  final String specialFilePath =
      './lib/assets/calendar_data/days_special'; // path to the special days data
  Morning ferialMorning =
      Morning(); // creation of the instance of ferialMorning
  final calendarDay =
      calendar.getDayContent(date); // retrieval of the calendar day
  final celebrationName = calendarDay?.defaultCelebrationTitle;
  if (!detectFerialDays(celebrationName!)) {
    // if it's not a ferial day, return an empty ferialMorning instance
    return {celebrationName: ferialMorning};
  }

  if (celebrationName.startsWith('OT')) {
    // If it's Ordinary Time, then:
    if (celebrationName.endsWith('0')) {
      // special case of Sunday
      final int weekNumber = int.parse(celebrationName[
          celebrationName.length - 1]); // week number calculation

      // retrieval of the corresponding datas of one of the 4 first sundays,
      final int referenceWeekNumber = ((weekNumber - 1) % 4) + 1;
      Morning ferialMorning = morningExtract(
          File('$ferialFilePath/OT_{$referenceWeekNumber}_0.json'));

      if (weekNumber > 4) {
        // then add the data of the actual sunday if it's over the 4th week
        Morning sundayAuxData =
            morningExtract(File('$ferialFilePath/OT_{$weekNumber}_0.json'));
        //fusion
        ferialMorning.overlayWith(
            sundayAuxData); // adding the elements of auxData to sundayData
      }
    } else {
      // it's a week day. So we use only the 4 first weeks of the Ordinary Time
      // (we use a modulo to retreive the effective day)
      List dayDatas = extractWeekAndDay(celebrationName, "OT");
      int weekNumber = dayDatas[0];
      int dayNumber = dayDatas[1];
      final int referenceWeekNumber = ((weekNumber - 1) % 4) + 1;
      ferialMorning = morningExtract(
          File('$ferialFilePath/OT_${referenceWeekNumber}_$dayNumber.json'));
    }
    // Finishing by adding the specific data of the day and the psalms
    ferialMorning.liturgicalGrade = calendarDay?.liturgicalGrade;
    ferialMorning.celebrationTitle = calendarDay?.defaultCelebrationTitle;
    List<String>? morningPsalmList = morningPsalms(calendarDay!.liturgicalTime,
        calendarDay.breviaryWeek!, dayName[date.weekday]);
    ferialMorning.morningPsalm1 = morningPsalmList![0];
    ferialMorning.morningPsalm2 = morningPsalmList[1];
    ferialMorning.morningPsalm3 = morningPsalmList[2];
    return {celebrationName: ferialMorning};
  } // end of the Ordinary Time

  if (celebrationName.startsWith('advent')) {
    // for the Advent Time
    if (date.day < 17) {
      // days before 17th December
      List dayDatas = extractWeekAndDay(celebrationName, "advent");
      int weekNumber = dayDatas[0];
      int dayNumber = dayDatas[1];
      ferialMorning = morningExtract(
          File('$ferialFilePath/advent_${weekNumber}_$dayNumber.json'));
    } else {
      ferialMorning =
          morningExtract(File('$specialFilePath/advent_${date.day}.json'));
    }
  }
  //for the other ferial times:
  final File fileName = File('$ferialFilePath/$celebrationName');
  ferialMorning = morningExtract(fileName);

  return {celebrationName: ferialMorning};
}

Morning morningExtract(File fileName) {
  String fileContent = fileName.readAsStringSync();
  DayOffices dayOffices = DayOffices.fromJSON(jsonDecode(fileContent));
  return Morning.fromDayOffices(dayOffices);
}
