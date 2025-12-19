import 'dart:convert';
import '../feasts/common_calendar_definitions.dart';
import '../classes/morning_class.dart';
import '../classes/office_elements_class.dart';
import '../tools/extract_week_and_day.dart';
import '../tools/data_loader.dart';
import '../assets/libraries/hymn_list.dart';

// Paths to liturgical data files
const String ferialFilePath = 'calendar_data/ferial_days';
const String specialFilePath = 'calendar_data/special_days';
const String sanctoralFilePath = 'calendar_data/sanctoral';
const String commonsFilePath = 'calendar_data/commons';

/// Resolves morning prayer for a given celebrationCode.
/// requires onlyOration for the Memories: adding only the Oration of the saint,
/// or adding the chosen Common.
/// Returns a Map with celebration name as key and Morning instance as value
/// (the argument "date" is used for advent calculation)
Future<Morning> morningResolution(
    String celebrationCode,
    String? ferialCode,
    String? common,
    DateTime date,
    String? breviaryWeek,
    DataLoader dataLoader) async {
  Morning morningOffice = Morning();
  Morning properMorning = Morning();

// firstable catches the ferial data if exists (if not feast or solemnity)
  if (ferialCode != null && ferialCode.trim().isNotEmpty) {
    morningOffice = await ferialMorningResolution(
        ferialCode, date, breviaryWeek, dataLoader);
  }
  // then catches the Common, if given in argument
  if (common != null && common.trim().isNotEmpty) {
    Morning commonMorning =
        await morningExtract('$commonsFilePath/$common.json', dataLoader);
    morningOffice.overlayWith(commonMorning);
  }

  // and catches the Proper if the celebration is not ferial:
  if (celebrationCode != ferialCode) {
    // Try special directory first, then sanctoral
    properMorning = await morningExtract(
        '$specialFilePath/$celebrationCode.json', dataLoader);

    if (properMorning.isEmpty()) {
      // File not found in special, try sanctoral
      properMorning = await morningExtract(
          '$sanctoralFilePath/$celebrationCode.json', dataLoader);
    }
  }

  morningOffice.overlayWith(properMorning);
  return morningOffice;
}

/// Resolves morning prayer for ferial days
/// Returns Morning instanciation
Future<Morning> ferialMorningResolution(String celebrationCode, DateTime date,
    String? breviaryWeek, DataLoader dataLoader) async {
  Morning ferialMorning = Morning();

  // ============================================================================
  // ORDINARY TIME
  // ============================================================================
  if (celebrationCode.startsWith('ot')) {
    List dayDatas = extractWeekAndDay(celebrationCode, 'ot');
    int weekNumber = dayDatas[0];
    int dayNumber = dayDatas[1];

    // picks the data of the first 4 weeks of the Ordinary Time:
    Morning ferialMorning = await morningExtract(
        '$ferialFilePath/ot_${((weekNumber - 1) % 4) + 1}_$dayNumber.json',
        dataLoader);

    if (weekNumber > 4) {
      // Add specific data after the 4th week
      Morning auxData = await morningExtract(
          '$ferialFilePath/ot_${weekNumber}_$dayNumber.json', dataLoader);
      ferialMorning.overlayWith(auxData);
    }

    return ferialMorning;
  }

  // ============================================================================
  // ADVENT TIME
  // ============================================================================
  if (celebrationCode.startsWith('advent')) {
    final List<String> hymns = hymnList["advent"] ?? [];

    if (RegExp(r'advent_').hasMatch(celebrationCode)) {
      // Days before December 17th: is written "advent_XXX"
      List dayDatas = extractWeekAndDay(celebrationCode, "advent");
      int weekNumber = dayDatas[0];
      int dayNumber = dayDatas[1];
      ferialMorning = await morningExtract(
          '$ferialFilePath/advent_${weekNumber}_$dayNumber.json', dataLoader);
      ferialMorning.hymn = hymns;
      return ferialMorning;
    }
    // Days from December 17th onwards (special days): is written "advent-17_3_5"
    // extracting the datas of the celebrationCode:
    List<String> parts = celebrationCode.replaceFirst("advent-", "").split("_");
    int adventSpecialDay = int.parse(parts[0]); // 17
    int weekNumber = int.parse(parts[1]); // 3
    int dayNumber = int.parse(parts[2]); // 5

    ferialMorning = await morningExtract(
        '$specialFilePath/advent_$adventSpecialDay.json', dataLoader);

    //sunday after 12/17: use the Sunday texts and add the Evangelic Antiphon of the Special Day
    if (dayNumber == 0) {
      ferialMorning = await morningExtract(
          '$ferialFilePath/advent_${weekNumber}_$dayNumber.json', dataLoader);
      Morning adventSpecialMorning = await morningExtract(
          '$specialFilePath/advent_$adventSpecialDay.json', dataLoader);
      ferialMorning.evangelicAntiphon = adventSpecialMorning.evangelicAntiphon;
      ferialMorning.hymn = hymns;
      return ferialMorning;
    }

    //after the 12-17 we add to the week days the special material of the D day
    ferialMorning = await morningExtract(
        '$ferialFilePath/advent_${weekNumber}_$dayNumber.json', dataLoader);
    Morning adventSpecialMorning = await morningExtract(
        '$specialFilePath/advent_$adventSpecialDay.json', dataLoader);
    ferialMorning.overlayWith(adventSpecialMorning);

    //after the 12-17, in the 3d week we use the psalm antiphons of the 4th week
    if (weekNumber == 3) {
      Morning ferialMorningFour = await morningExtract(
          '$ferialFilePath/advent_4_$dayNumber.json', dataLoader);
      // Replace only the antiphons, keeping the psalms from ferialMorning
      ferialMorning.psalmody = List.generate(
        3,
        (i) => PsalmEntry(
          psalm: ferialMorning.psalmody![i].psalm,
          antiphon: ferialMorningFour.psalmody![i].antiphon,
        ),
      );
    }
    ferialMorning.hymn = hymns;
    return ferialMorning;
  }

  // ============================================================================
  // CHRISTMAS TIME
  // ============================================================================
  if (celebrationCode.startsWith('christmas')) {
    // Note: Holy Family is excluded (not a ferial day)
    int dayNumber = date.day;
    int monthNumber = date.month;
    List<String> hymns = hymnList["christmas"] ?? [];

    if (monthNumber == 12) {
      if (dayNumber < 29) {
        // Days before December 29th: proper office for Morning Prayer
        Morning morningOffice = await morningExtract(
            '$ferialFilePath/christmas_$dayNumber.json', dataLoader);
        Morning baseMorningOffice = await morningExtract(
            '$commonsFilePath/christmas_${breviaryWeek}_${date.weekday}.json',
            dataLoader);
        baseMorningOffice.overlayWith(morningOffice);
        baseMorningOffice.hymn = hymns;
        return baseMorningOffice;
      } else {
        // Days from December 29th to 31st: use Common of Christmas
        Morning morningOffice = await morningExtract(
            '$specialFilePath/christmas_${date.day}.json', dataLoader);
        Morning baseMorningOffice =
            await morningExtract('$commonsFilePath/christmas.json', dataLoader);
        baseMorningOffice.overlayWith(morningOffice);
        baseMorningOffice.hymn = hymns;
        return baseMorningOffice;
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
        baseMorningOffice.hymn = hymns;
        return baseMorningOffice;
      } else {
        // After Epiphany
        Morning morningOffice = await morningExtract(
            '$ferialFilePath/christmas_2_${date.weekday}.json', dataLoader);
        morningOffice.hymn = hymnList["after_epiphany"] ?? [];
        return morningOffice;
      }
    }
  }

  // ============================================================================
  // LENT TIME
  // ============================================================================
  if (celebrationCode.startsWith('lent')) {
    List dayDatas = extractWeekAndDay(celebrationCode, "lent");
    int weekNumber = dayDatas[0];
    int dayNumber = dayDatas[1];
    ferialMorning = await morningExtract(
        '$ferialFilePath/lent_${weekNumber}_$dayNumber.json', dataLoader);
    return ferialMorning;
  }

  // ============================================================================
  // PASCHAL TIME
  // ============================================================================
  if (celebrationCode.startsWith('PT')) {
    List dayDatas = extractWeekAndDay(celebrationCode, "PT");
    int weekNumber = dayDatas[0];
    int dayNumber = dayDatas[1];
    ferialMorning = await morningExtract(
        '$ferialFilePath/PT_${weekNumber}_$dayNumber.json', dataLoader);
    return ferialMorning;
  }

  // ============================================================================
  // OTHER FERIAL TIMES
  // ============================================================================
  ferialMorning =
      await morningExtract('$ferialFilePath/$celebrationCode.json', dataLoader);
  return ferialMorning;
}

/// Extracts Morning data from a JSON file
/// Reads the file via DataLoader, parses only the 'morning' section
Future<Morning> morningExtract(
    String relativePath, DataLoader dataLoader) async {
  print('=== morningExtract DEBUG == Loading file: $relativePath');

  String fileContent = await dataLoader.loadJson(relativePath);

  // If file doesn't exist or is empty, return empty Morning
  if (fileContent.isEmpty) {
    print('ERROR: File is empty or does not exist');
    return Morning();
  }
  var jsonData = jsonDecode(fileContent);
  if (jsonData['morning'] == null) {
    return Morning();
  }
  List<String> oration = List<String>.from(jsonData['oration'] ?? []);
  // Create Morning directly from JSON
  Morning morning =
      Morning.fromJson(jsonData['morning'] as Map<String, dynamic>);

  // Extract invitatory if present
  if (jsonData['invitatory'] != null) {
    Invitatory invitatory =
        Invitatory.fromJson(jsonData['invitatory'] as Map<String, dynamic>);

    // If invitatory doesn't have psalms, use default list
    List<String> invitatoryPsalms =
        invitatory.psalms ?? ["PSALM_94", "PSALM_66", "PSALM_99", "PSALM_23"];

    // Remove invitatory psalms that are already in morning psalmody
    if (morning.psalmody != null) {
      final psalmsInPsalmody =
          morning.psalmody!.map((entry) => entry.psalm).toSet();
      invitatoryPsalms = invitatoryPsalms
          .where((psalm) => !psalmsInPsalmody.contains(psalm))
          .toList();
    }

    // Assign invitatory with filtered psalms
    morning.invitatory =
        Invitatory(antiphon: invitatory.antiphon, psalms: invitatoryPsalms);
  }

  // If oration is not in morning section, check in main section of the json
  morning.oration ??= oration;

  print('=== morningExtract SUCCESS ===');
  return morning;

  // If no "morning" section exists, return empty Morning
}
