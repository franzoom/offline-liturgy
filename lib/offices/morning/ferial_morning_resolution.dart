import '../../classes/morning_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/extract_week_and_day.dart';
import '../../tools/data_loader.dart';
import '../../assets/libraries/hymn_list.dart';
import './morning_extract.dart';
import '../../tools/file_paths.dart';

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
        '$ferialFilePath/ot_${((weekNumber - 1) % 4) + 1}_$dayNumber.yaml',
        dataLoader);

    if (weekNumber > 4) {
      // Add specific data after the 4th week
      Morning auxData = await morningExtract(
          '$ferialFilePath/ot_${weekNumber}_$dayNumber.yaml', dataLoader);
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
          '$ferialFilePath/advent_${weekNumber}_$dayNumber.yaml', dataLoader);
      ferialMorning.hymn = hymns;
      return ferialMorning;
    }
    // Days from December 17th onwards (special days): is written "advent-17_3_5"
    // extracting the datas of the celebrationCode:
    List<String> parts = celebrationCode.replaceFirst("advent-", "").split("_");
    int adventSpecialDay = int.parse(parts[0]);
    int weekNumber = int.parse(parts[1]);
    int dayNumber = int.parse(parts[2]);

    ferialMorning = await morningExtract(
        '$specialFilePath/advent_$adventSpecialDay.yaml', dataLoader);

    //sunday after 12/17: use the Sunday texts and add the Evangelic Antiphon of the Special Day
    if (dayNumber == 0) {
      ferialMorning = await morningExtract(
          '$ferialFilePath/advent_${weekNumber}_$dayNumber.yaml', dataLoader);
      Morning adventSpecialMorning = await morningExtract(
          '$specialFilePath/advent_$adventSpecialDay.yaml', dataLoader);
      ferialMorning.evangelicAntiphon = adventSpecialMorning.evangelicAntiphon;
      ferialMorning.hymn = hymns;
      return ferialMorning;
    }

    //after december the 17th we add to the week days the special material of the D day
    ferialMorning = await morningExtract(
        '$ferialFilePath/advent_${weekNumber}_$dayNumber.yaml', dataLoader);
    Morning adventSpecialMorning = await morningExtract(
        '$specialFilePath/advent_$adventSpecialDay.yaml', dataLoader);
    ferialMorning.overlayWith(adventSpecialMorning);

    //after december the 17th, in the 3d week we use the psalm antiphons of the 4th week
    if (weekNumber == 3) {
      Morning ferialMorningFour = await morningExtract(
          '$ferialFilePath/advent_4_$dayNumber.yaml', dataLoader);
      // Replace only the antiphons, keeping the psalms from ferialMorning
      if (ferialMorning.psalmody != null &&
          ferialMorningFour.psalmody != null &&
          ferialMorning.psalmody!.length >= 3 &&
          ferialMorningFour.psalmody!.length >= 3) {
        ferialMorning.psalmody = List.generate(
          3,
          (i) => PsalmEntry(
            psalm: ferialMorning.psalmody![i].psalm,
            antiphon: ferialMorningFour.psalmody![i].antiphon,
          ),
        );
      }
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
      // All December days in Christmas time: proper office overlays the Common
      Morning morningOffice = await morningExtract(
          '$specialFilePath/christmas_$dayNumber.yaml', dataLoader);
      Morning baseMorningOffice =
          await morningExtract('$commonsFilePath/christmas.yaml', dataLoader);
      baseMorningOffice.overlayWith(morningOffice);
      baseMorningOffice.hymn = hymns;
      return baseMorningOffice;
    }
    // Christmas days in January
    if (celebrationCode.startsWith('christmas-')) {
      // Before Epiphany: proper of the day with psalms and antiphons
      // of the 1st or 2d week of Christmas time
      List<String> parts = celebrationCode.split('-')[1].split('_');
      String dateDay = parts[0];
      String breviaryWeek = parts[1];
      String breviaryDay = parts[2];
      Morning morningOffice = await morningExtract(
          '$specialFilePath/christmas-ferial_before_epiphany_$dateDay.yaml',
          dataLoader);
      Morning baseMorningOffice = await morningExtract(
          '$ferialFilePath/christmas_${breviaryWeek}_$breviaryDay.yaml',
          dataLoader);
      baseMorningOffice.overlayWith(morningOffice);
      baseMorningOffice.hymn = hymns;
      return baseMorningOffice;
    }
    // After Epiphany
    Morning morningOffice = await morningExtract(
        '$ferialFilePath/christmas_2_${date.weekday}.yaml', dataLoader);
    morningOffice.hymn = hymnList["after_epiphany"] ?? [];
    return morningOffice;
  }

  // ============================================================================
  // LENT TIME
  // ============================================================================
  if (celebrationCode.startsWith('lent')) {
    List dayDatas = extractWeekAndDay(celebrationCode, "lent");
    int weekNumber = dayDatas[0];
    int dayNumber = dayDatas[1];
    ferialMorning = await morningExtract(
        '$ferialFilePath/lent_${weekNumber}_$dayNumber.yaml', dataLoader);
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
        '$ferialFilePath/easter_${weekNumber}_$dayNumber.yaml', dataLoader);
    return ferialMorning;
  }

  // ============================================================================
  // OTHER FERIAL TIMES
  // ============================================================================
  ferialMorning =
      await morningExtract('$ferialFilePath/$celebrationCode.yaml', dataLoader);
  return ferialMorning;
}
