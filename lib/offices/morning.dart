import 'dart:convert';
import 'dart:io';
import '../common_calendar_definitions.dart';
import '../classes/calendar_class.dart';
import '../classes/morning_class.dart';
import '../classes/day_offices_class.dart';
import '../tools/extract_week_and_day.dart';

bool detectFerialDays(String celebrationName) {
  // ferial day detection: detects if the celebration name starts with
  // one of the following prefixes.
  final prefixes = ['OT', 'advent', 'lent', 'christmas', 'easter'];
  return prefixes.any((prefix) => celebrationName.startsWith(prefix));
}

Map<String, Morning> ferialMorningResolution(Calendar calendar, DateTime date) {
  // if it's a ferial day, runs the morning prayer resolution.
  // other layers will be added afterwards if needed.
  final String ferialFilePath =
      './lib/assets/calendar_data/days_ferial'; // path to the ferial days data
  final String specialFilePath =
      './lib/assets/calendar_data/days_special'; // path to the special days data
  final String commonsFilePath =
      './lib/assets/calendar_data/commons'; // path to the commons data
  Morning ferialMorning =
      Morning(); // creation of the instance of ferialMorning
  final calendarDay =
      calendar.getDayContent(date); // retrieval of the calendar day
  final celebrationName = calendarDay?.defaultCelebrationTitle;
  final breviaryWeek = calendarDay?.breviaryWeek;
  if (!detectFerialDays(celebrationName!)) {
    // if it's not a ferial day, return an empty ferialMorning instance
    return {celebrationName: ferialMorning};
  }

  if (celebrationName.startsWith('OT')) {
    // if it's Ordinary Time, then:
    List dayDatas = extractWeekAndDay(celebrationName, "OT");
    int weekNumber = dayDatas[0];
    int dayNumber = dayDatas[1];
    if (dayNumber == 0) {
      // special case of Sunday:
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
            sundayAuxData); // adding the elements of auxData to ferialMorning
      }
    } else {
      // it's a week day. So we use only the 4 first weeks of the Ordinary Time
      // (we use a modulo to retreive the effective day)

      final int referenceWeekNumber = ((weekNumber - 1) % 4) + 1;
      ferialMorning = morningExtract(
          File('$ferialFilePath/OT_${referenceWeekNumber}_$dayNumber.json'));
    }
    // Finishing by adding the specific data of the day
    ferialMorning.liturgicalGrade = calendarDay?.liturgicalGrade;
    ferialMorning.celebrationTitle = calendarDay?.defaultCelebrationTitle;
    return {celebrationName: ferialMorning};
  } // end of the Ordinary Time

  if (celebrationName.startsWith('advent')) {
    // for the Advent Time
    List dayDatas = extractWeekAndDay(celebrationName, "advent");
    int weekNumber = dayDatas[0];
    int dayNumber = dayDatas[1];
    if (date.day < 17) {
      // days before 17th December
      ferialMorning = morningExtract(
          File('$ferialFilePath/advent_${weekNumber}_$dayNumber.json'));
      return {celebrationName: ferialMorning};
    } else {
      ferialMorning =
          morningExtract(File('$specialFilePath/advent_${date.day}.json'));
      if (weekNumber == 3 && dayNumber == 0 && date.day == 17) {
        // if the 3rd Sunday of Advent occuers on the 17th December,
        // we use the datas of the 17th December and we add the oration
        // of the 3rd Sunday of Advent.
        Morning auxData =
            morningExtract(File('$ferialFilePath/advent_3_0.json'));
        ferialMorning.morningOration = auxData.morningOration;
        return {celebrationName: ferialMorning};
      }
      if (weekNumber == 4 && dayNumber == 0 && date.day == 24) {
        // if the 4rd Sunday of Advent occurs on the 24th December,
        // we use the datas of the 24th December and we add the oration
        // of the 4rd Sunday of Advent.
        Morning auxData =
            morningExtract(File('$ferialFilePath/advent_4_0.json'));
        ferialMorning.morningOration = auxData.morningOration;
        return {celebrationName: ferialMorning};
      }
      if (weekNumber == 4 && dayNumber == 0) {
        // if the day after the 17th december is the 4th sunday of Advent,
        // we use the datas of the 4th Sunday and we add the evangelic antiphon
        // of the day.
        Morning sunday4Morning =
            morningExtract(File('ferialFilePath/advent_4_0.json'));
        sunday4Morning.morningEvangelicAntiphon =
            ferialMorning.morningEvangelicAntiphon;
        return {celebrationName: sunday4Morning};
      }
      return {celebrationName: ferialMorning};
    }
  } // end of the Advent Time

  if (celebrationName.startsWith('christmas')) {
    // for the Christmas Time
    // (Holy Family is excluded, as it is not a ferial day)
    int dayNumber = date.day;
    int monthNumber = date.month;
    if (monthNumber == 12) {
      if (dayNumber < 29) {
        // days before 29th December: proper office for the Morning Prayer
        Morning morningOffice =
            morningExtract(File('$ferialFilePath/christmas_$dayNumber.json'));
        Morning baseMorningOffice = morningExtract(File(
            '$commonsFilePath/christmas_${breviaryWeek}_${date.weekday}.json'));
        baseMorningOffice.overlayWith(morningOffice);
        return {celebrationName: baseMorningOffice};
      } else {
        // days from 29th to 31st December: using the Common of Christmas
        // and adding the specificities of the day
        Morning morningOffice =
            morningExtract(File('$specialFilePath/christmas_${date.day}.json'));
        Morning baseMorningOffice =
            morningExtract(File('$commonsFilePath/christmas.json'));
        baseMorningOffice.overlayWith(morningOffice);
        return {celebrationName: baseMorningOffice};
      }
    } else {
      // christmas days in January
      if (date.isBefore(epiphany(date.year))) {
        // before Epiphany: proper of the day, with the psalms and psalms and
        // antiphons of the 1rst week of christmas time.
        Morning morningOffice = morningExtract(File(
            '$specialFilePath/christmas-ferial_before_epiphany_${date.day}.json'));
        Morning baseMorningOffice = morningExtract(
            File('$ferialFilePath/christmas_1_${date.weekday}.json'));
        baseMorningOffice.overlayWith(morningOffice);
        return {celebrationName: baseMorningOffice};
      } else {
        Morning morningOffice = morningExtract(
            File('$ferialFilePath/christmas_2_${date.weekday}.json'));
        return {celebrationName: morningOffice};
      }
    }
  } //end of the Christmas Time

  if (celebrationName.startsWith('lent')) {
    // for Lent Time
    List dayDatas = extractWeekAndDay(celebrationName, "lent");
    int weekNumber = dayDatas[0];
    int dayNumber = dayDatas[1];
    ferialMorning = morningExtract(
        File('$ferialFilePath/lent_${weekNumber}_$dayNumber.json'));
    return {celebrationName: ferialMorning};
  } // end of Lent Time

  if (celebrationName.startsWith('PT')) {
    // for Paschal Time
    List dayDatas = extractWeekAndDay(celebrationName, "PT");
    int weekNumber = dayDatas[0];
    int dayNumber = dayDatas[1];
    ferialMorning = morningExtract(
        File('$ferialFilePath/PT_${weekNumber}_$dayNumber.json'));
    return {celebrationName: ferialMorning};
  } // end of Paschal Time

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
