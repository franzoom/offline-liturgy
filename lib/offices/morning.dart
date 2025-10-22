import 'dart:convert';
import 'dart:io';
import '../feasts/common_calendar_definitions.dart';
import '../classes/calendar_class.dart';
import '../classes/morning_class.dart';
import '../classes/day_offices_class.dart';
import '../tools/extract_week_and_day.dart';

/// Detects if a celebration is a ferial day
/// Returns true if the celebration name starts with one of the ferial prefixes
bool detectFerialDays(String celebrationName) {
  final prefixes = ['OT', 'advent', 'lent', 'christmas', 'easter'];
  return prefixes.any((prefix) => celebrationName.startsWith(prefix));
}

/// Resolves morning prayer for ferial days
/// Returns a Map with celebration name as key and Morning instance as value
Map<String, Morning> ferialMorningResolution(Calendar calendar, DateTime date) {
  // Paths to liturgical data files
  final String ferialFilePath = './lib/assets/calendar_data/days_ferial';
  final String specialFilePath = './lib/assets/calendar_data/days_special';
  final String commonsFilePath = './lib/assets/calendar_data/commons';

  Morning ferialMorning = Morning();

  // Retrieve calendar day information
  final calendarDay = calendar.getDayContent(date);
  final celebrationName = calendarDay?.defaultCelebrationTitle;
  final breviaryWeek = calendarDay?.breviaryWeek;

  // If it's not a ferial day, return empty Morning instance
  if (!detectFerialDays(celebrationName!)) {
    return {celebrationName: ferialMorning};
  }

  // ============================================================================
  // ORDINARY TIME
  // ============================================================================
  if (celebrationName.startsWith('OT')) {
    List dayDatas = extractWeekAndDay(celebrationName, "OT");
    int weekNumber = dayDatas[0];
    int dayNumber = dayDatas[1];

    if (dayNumber == 0) {
      // Special case: Sunday
      // Use one of the 4 first sundays as reference
      final int referenceWeekNumber = ((weekNumber - 1) % 4) + 1;
      Morning ferialMorning = morningExtract(
          File('$ferialFilePath/OT_{$referenceWeekNumber}_0.json'));

      if (weekNumber > 4) {
        // Add specific data for sundays after the 4th week
        Morning sundayAuxData =
            morningExtract(File('$ferialFilePath/OT_{$weekNumber}_0.json'));
        ferialMorning.overlayWith(sundayAuxData);
      }
    } else {
      // Weekday: use only the 4 first weeks (with modulo)
      final int referenceWeekNumber = ((weekNumber - 1) % 4) + 1;
      ferialMorning = morningExtract(
          File('$ferialFilePath/OT_${referenceWeekNumber}_$dayNumber.json'));
    }

    // Add specific day information
    ferialMorning.liturgicalGrade = calendarDay?.liturgicalGrade;
    ferialMorning.celebrationTitle = calendarDay?.defaultCelebrationTitle;
    return {celebrationName: ferialMorning};
  }

  // ============================================================================
  // ADVENT TIME
  // ============================================================================
  if (celebrationName.startsWith('advent')) {
    List dayDatas = extractWeekAndDay(celebrationName, "advent");
    int weekNumber = dayDatas[0];
    int dayNumber = dayDatas[1];

    if (date.day < 17) {
      // Days before December 17th
      ferialMorning = morningExtract(
          File('$ferialFilePath/advent_${weekNumber}_$dayNumber.json'));
      return {celebrationName: ferialMorning};
    } else {
      // Days from December 17th onwards (special days)
      ferialMorning =
          morningExtract(File('$specialFilePath/advent_${date.day}.json'));

      if (weekNumber == 3 && dayNumber == 0 && date.day == 17) {
        // 3rd Sunday of Advent on December 17th
        // Use December 17th data and add the 3rd Sunday oration
        Morning auxData =
            morningExtract(File('$ferialFilePath/advent_3_0.json'));
        ferialMorning.oration = auxData.oration;
        return {celebrationName: ferialMorning};
      }

      if (weekNumber == 4 && dayNumber == 0 && date.day == 24) {
        // 4th Sunday of Advent on December 24th
        // Use December 24th data and add the 4th Sunday oration
        Morning auxData =
            morningExtract(File('$ferialFilePath/advent_4_0.json'));
        ferialMorning.oration = auxData.oration;
        return {celebrationName: ferialMorning};
      }

      if (weekNumber == 4 && dayNumber == 0) {
        // 4th Sunday of Advent after December 17th
        // Use 4th Sunday data and add the evangelic antiphon of the day
        Morning sunday4Morning =
            morningExtract(File('$ferialFilePath/advent_4_0.json'));
        sunday4Morning.evangelicAntiphon = ferialMorning.evangelicAntiphon;
        return {celebrationName: sunday4Morning};
      }

      return {celebrationName: ferialMorning};
    }
  }

  // ============================================================================
  // CHRISTMAS TIME
  // ============================================================================
  if (celebrationName.startsWith('christmas')) {
    // Note: Holy Family is excluded (not a ferial day)
    int dayNumber = date.day;
    int monthNumber = date.month;

    if (monthNumber == 12) {
      if (dayNumber < 29) {
        // Days before December 29th: proper office for Morning Prayer
        Morning morningOffice =
            morningExtract(File('$ferialFilePath/christmas_$dayNumber.json'));
        Morning baseMorningOffice = morningExtract(File(
            '$commonsFilePath/christmas_${breviaryWeek}_${date.weekday}.json'));
        baseMorningOffice.overlayWith(morningOffice);
        return {celebrationName: baseMorningOffice};
      } else {
        // Days from December 29th to 31st: use Common of Christmas
        Morning morningOffice =
            morningExtract(File('$specialFilePath/christmas_${date.day}.json'));
        Morning baseMorningOffice =
            morningExtract(File('$commonsFilePath/christmas.json'));
        baseMorningOffice.overlayWith(morningOffice);
        return {celebrationName: baseMorningOffice};
      }
    } else {
      // Christmas days in January
      if (date.isBefore(epiphany(date.year))) {
        // Before Epiphany: proper of the day with psalms and antiphons
        // of the 1st week of Christmas time
        Morning morningOffice = morningExtract(File(
            '$specialFilePath/christmas-ferial_before_epiphany_${date.day}.json'));
        Morning baseMorningOffice = morningExtract(
            File('$ferialFilePath/christmas_1_${date.weekday}.json'));
        baseMorningOffice.overlayWith(morningOffice);
        return {celebrationName: baseMorningOffice};
      } else {
        // After Epiphany
        Morning morningOffice = morningExtract(
            File('$ferialFilePath/christmas_2_${date.weekday}.json'));
        return {celebrationName: morningOffice};
      }
    }
  }

  // ============================================================================
  // LENT TIME
  // ============================================================================
  if (celebrationName.startsWith('lent')) {
    List dayDatas = extractWeekAndDay(celebrationName, "lent");
    int weekNumber = dayDatas[0];
    int dayNumber = dayDatas[1];
    ferialMorning = morningExtract(
        File('$ferialFilePath/lent_${weekNumber}_$dayNumber.json'));
    return {celebrationName: ferialMorning};
  }

  // ============================================================================
  // PASCHAL TIME
  // ============================================================================
  if (celebrationName.startsWith('PT')) {
    List dayDatas = extractWeekAndDay(celebrationName, "PT");
    int weekNumber = dayDatas[0];
    int dayNumber = dayDatas[1];
    ferialMorning = morningExtract(
        File('$ferialFilePath/PT_${weekNumber}_$dayNumber.json'));
    return {celebrationName: ferialMorning};
  }

  // ============================================================================
  // OTHER FERIAL TIMES
  // ============================================================================
  final File fileName = File('$ferialFilePath/$celebrationName');
  ferialMorning = morningExtract(fileName);
  return {celebrationName: ferialMorning};
}

/// Extracts Morning data from a JSON file
/// Reads the file, parses it as DayOffices, and converts to Morning
Morning morningExtract(File fileName) {
  String fileContent = fileName.readAsStringSync();
  DayOffices dayOffices = DayOffices.fromJSON(jsonDecode(fileContent));
  return Morning.fromDayOffices(dayOffices);
}
