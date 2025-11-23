import 'dart:convert';
import '../feasts/common_calendar_definitions.dart';
import '../classes/calendar_class.dart';
import '../classes/morning_class.dart';
import '../classes/office_structures.dart';
import '../tools/extract_week_and_day.dart';
import '../tools/data_loader.dart';

/// Detects if a celebration is a ferial day
/// Returns true if the celebration name starts with one of the ferial prefixes
bool detectFerialDays(String celebrationName) {
  final prefixes = ['ot', 'advent', 'lent', 'christmas', 'easter'];
  return prefixes.any((prefix) => celebrationName.startsWith(prefix));
}

/// Resolves morning prayer for ferial days
/// Returns a Map with celebration name as key and Morning instance as value
Future<Map<String, Morning>> ferialMorningResolution(
    Calendar calendar, DateTime date, DataLoader dataLoader) async {
  // Paths to liturgical data files (relative to assets/)
  final String ferialFilePath = 'calendar_data/ferial_days';
  final String specialFilePath = 'calendar_data/special_days';
  final String commonsFilePath = 'calendar_data/commons';

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
  if (celebrationName.startsWith('ot')) {
    List dayDatas = extractWeekAndDay(celebrationName, 'ot');
    int weekNumber = dayDatas[0];
    int dayNumber = dayDatas[1];

    if (dayNumber == 0) {
      // Special case: Sunday
      // Use one of the 4 first sundays as reference
      final int referenceWeekNumber = ((weekNumber - 1) % 4) + 1;
      Morning ferialMorning = await morningExtract(
          '$ferialFilePath/ot_${referenceWeekNumber}_0.json', dataLoader);

      if (weekNumber > 4) {
        // Add specific data for sundays after the 4th week
        Morning sundayAuxData = await morningExtract(
            '$ferialFilePath/ot_${weekNumber}_0.json', dataLoader);
        ferialMorning.overlayWith(sundayAuxData);
      }
    } else {
      // Weekday: use only the 4 first weeks (with modulo)
      final int referenceWeekNumber = ((weekNumber - 1) % 4) + 1;
      ferialMorning = await morningExtract(
          '$ferialFilePath/ot_${referenceWeekNumber}_$dayNumber.json',
          dataLoader);
    }

    // Add specific day information from calendar
    ferialMorning.celebration ??= Celebration();
    ferialMorning.celebration = Celebration(
      title: calendarDay?.defaultCelebrationTitle,
      subtitle: ferialMorning.celebration?.subtitle,
      description: ferialMorning.celebration?.description,
      commons: ferialMorning.celebration?.commons,
      grade: calendarDay?.liturgicalGrade,
      color: ferialMorning.celebration?.color,
    );

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
      ferialMorning = await morningExtract(
          '$ferialFilePath/advent_${weekNumber}_$dayNumber.json', dataLoader);
      return {celebrationName: ferialMorning};
    } else {
      // Days from December 17th onwards (special days)
      ferialMorning = await morningExtract(
          '$specialFilePath/advent_${date.day}.json', dataLoader);

      if (weekNumber == 3 && dayNumber == 0 && date.day == 17) {
        // 3rd Sunday of Advent on December 17th
        // Use December 17th data and add the 3rd Sunday oration
        Morning auxData =
            await morningExtract('$ferialFilePath/advent_3_0.json', dataLoader);
        ferialMorning.oration = auxData.oration;
        return {celebrationName: ferialMorning};
      }

      if (weekNumber == 4 && dayNumber == 0 && date.day == 24) {
        // 4th Sunday of Advent on December 24th
        // Use December 24th data and add the 4th Sunday oration
        Morning auxData =
            await morningExtract('$ferialFilePath/advent_4_0.json', dataLoader);
        ferialMorning.oration = auxData.oration;
        return {celebrationName: ferialMorning};
      }

      if (weekNumber == 4 && dayNumber == 0) {
        // 4th Sunday of Advent after December 17th
        // Use 4th Sunday data and add the evangelic antiphon of the day
        Morning sunday4Morning =
            await morningExtract('$ferialFilePath/advent_4_0.json', dataLoader);

        // Keep the evangelic antiphon from ferialMorning
        if (ferialMorning.evangelicAntiphon != null) {
          sunday4Morning.evangelicAntiphon = EvangelicAntiphon(
            common: ferialMorning.evangelicAntiphon!.common,
            yearA: ferialMorning.evangelicAntiphon!.yearA,
            yearB: ferialMorning.evangelicAntiphon!.yearB,
            yearC: ferialMorning.evangelicAntiphon!.yearC,
          );
        }

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
        Morning morningOffice = await morningExtract(
            '$ferialFilePath/christmas_$dayNumber.json', dataLoader);
        Morning baseMorningOffice = await morningExtract(
            '$commonsFilePath/christmas_${breviaryWeek}_${date.weekday}.json',
            dataLoader);
        baseMorningOffice.overlayWith(morningOffice);
        return {celebrationName: baseMorningOffice};
      } else {
        // Days from December 29th to 31st: use Common of Christmas
        Morning morningOffice = await morningExtract(
            '$specialFilePath/christmas_${date.day}.json', dataLoader);
        Morning baseMorningOffice =
            await morningExtract('$commonsFilePath/christmas.json', dataLoader);
        baseMorningOffice.overlayWith(morningOffice);
        return {celebrationName: baseMorningOffice};
      }
    } else {
      // Christmas days in January
      if (date.isBefore(epiphany(date.year))) {
        // Before Epiphany: proper of the day with psalms and antiphons
        // of the 1st week of Christmas time
        Morning morningOffice = await morningExtract(
            '$specialFilePath/christmas-ferial_before_epiphany_${date.day}.json',
            dataLoader);
        Morning baseMorningOffice = await morningExtract(
            '$ferialFilePath/christmas_1_${date.weekday}.json', dataLoader);
        baseMorningOffice.overlayWith(morningOffice);
        return {celebrationName: baseMorningOffice};
      } else {
        // After Epiphany
        Morning morningOffice = await morningExtract(
            '$ferialFilePath/christmas_2_${date.weekday}.json', dataLoader);
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
    ferialMorning = await morningExtract(
        '$ferialFilePath/lent_${weekNumber}_$dayNumber.json', dataLoader);
    return {celebrationName: ferialMorning};
  }

  // ============================================================================
  // PASCHAL TIME
  // ============================================================================
  if (celebrationName.startsWith('PT')) {
    List dayDatas = extractWeekAndDay(celebrationName, "PT");
    int weekNumber = dayDatas[0];
    int dayNumber = dayDatas[1];
    ferialMorning = await morningExtract(
        '$ferialFilePath/PT_${weekNumber}_$dayNumber.json', dataLoader);
    return {celebrationName: ferialMorning};
  }

  // ============================================================================
  // OTHER FERIAL TIMES
  // ============================================================================
  ferialMorning =
      await morningExtract('$ferialFilePath/$celebrationName.json', dataLoader);
  return {celebrationName: ferialMorning};
}

/// Extracts Morning data from a JSON file
/// Reads the file via DataLoader, parses only the 'morning' section
Future<Morning> morningExtract(
    String relativePath, DataLoader dataLoader) async {
  try {
    print('=== morningExtract DEBUG ===');
    print('Loading file: $relativePath');

    String fileContent = await dataLoader.loadJson(relativePath);

    // If file doesn't exist or is empty, return empty Morning
    if (fileContent.isEmpty) {
      print('ERROR: File is empty or does not exist');
      return Morning();
    }

    print('File loaded successfully, length: ${fileContent.length}');

    var jsonData = jsonDecode(fileContent);
    print('JSON decoded successfully');
    print('JSON keys: ${jsonData.keys}');

    // Extract only the "morning" section instead of loading all DayOffices
    if (jsonData['morning'] != null) {
      print('Found "morning" section in JSON');
      print('Morning section keys: ${jsonData['morning'].keys}');

      MorningOffice morningOffice =
          MorningOffice.fromJson(jsonData['morning'] as Map<String, dynamic>);
      print('MorningOffice created');
      print('MorningOffice has hymn: ${morningOffice.hymn != null}');
      print('MorningOffice has psalmody: ${morningOffice.psalmody != null}');
      print(
          'MorningOffice psalmody length: ${morningOffice.psalmody?.length ?? 0}');

      Morning morning = Morning.fromMorningOffice(morningOffice);
      print('Morning created from MorningOffice');
      print('Morning has hymn: ${morning.hymn != null}');
      print('Morning has psalmody: ${morning.psalmody != null}');

      // Extract invitatory if present and convert to Invitatory
      if (jsonData['invitatory'] != null) {
        print('Found "invitatory" section in JSON');
        InvitatoryOffice invitatoryOffice = InvitatoryOffice.fromJson(
            jsonData['invitatory'] as Map<String, dynamic>);
        // Convert InvitatoryOffice to Invitatory
        morning.invitatory = Invitatory(
          antiphon: invitatoryOffice.antiphon,
          psalms:
              invitatoryOffice.psalm != null ? [invitatoryOffice.psalm!] : null,
        );
        print('Invitatory added to morning');
      } else {
        print('No "invitatory" section found');
      }

      // If oration is not in morning section, check in readings section
      if (morning.oration == null && jsonData['readings'] != null) {
        print('Checking "readings" section for oration');
        var readingsData = jsonData['readings'];
        if (readingsData['oration'] != null) {
          morning.oration = List<String>.from(readingsData['oration']);
          print('Oration found in readings section: ${morning.oration}');
        } else {
          print('No oration found in readings section');
        }
      }

      print('=== morningExtract SUCCESS ===');
      return morning;
    } else {
      print('ERROR: No "morning" section found in JSON');
      print('Available keys: ${jsonData.keys}');
    }

    // If no "morning" section exists, return empty Morning
    print('=== morningExtract FAILED - returning empty Morning ===');
    return Morning();
  } catch (e, stackTrace) {
    // In case of error, return empty Morning
    print('=== morningExtract ERROR ===');
    print('Error: $e');
    print('StackTrace: $stackTrace');
    return Morning();
  }
}
