import '../../classes/readings_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/extract_week_and_day.dart';
import '../../assets/libraries/hymn_list.dart';
import './readings_extract.dart';
import '../../tools/constants.dart';

/// Resolves readings prayer for ferial days
/// Returns Readings instanciation
Future<Readings> ferialReadingsResolution(CelebrationContext context) async {
  final celebrationCode = context.ferialCode ?? context.celebrationCode;
  final date = context.date;
  final dataLoader = context.dataLoader;
  Readings ferialReadings = Readings();

  // ============================================================================
  // ORDINARY TIME
  // ============================================================================
  if (celebrationCode.startsWith('ot')) {
    List dayDatas = extractWeekAndDay(celebrationCode, 'ot');
    int weekNumber = dayDatas[0];
    int dayNumber = dayDatas[1];

    // picks the data of the first 4 weeks of the Ordinary Time:
    Readings ferialReadings = await readingsExtract(
        '$ferialFilePath/ot_${((weekNumber - 1) % 4) + 1}_$dayNumber.yaml',
        dataLoader);

    if (weekNumber > 4) {
      // Add specific data after the 4th week
      Readings auxData = await readingsExtract(
          '$ferialFilePath/ot_${weekNumber}_$dayNumber.yaml', dataLoader);
      ferialReadings.overlayWith(auxData);
    }

    return ferialReadings;
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
      ferialReadings = await readingsExtract(
          '$ferialFilePath/advent_${weekNumber}_$dayNumber.yaml', dataLoader);
      ferialReadings.hymn = hymns;
      return ferialReadings;
    }
    // Days from December 17th onwards (special days): is written "advent-17_3_5"
    // extracting the datas of the celebrationCode:
    List<String> parts = celebrationCode.replaceFirst("advent-", "").split("_");
    int adventSpecialDay = int.parse(parts[0]);
    int weekNumber = int.parse(parts[1]);
    int dayNumber = int.parse(parts[2]);

    ferialReadings = await readingsExtract(
        '$specialFilePath/advent_$adventSpecialDay.yaml', dataLoader);

    //sunday after 12/17: use the Sunday texts and overlay with the Special Day
    if (dayNumber == 0) {
      ferialReadings = await readingsExtract(
          '$ferialFilePath/advent_${weekNumber}_$dayNumber.yaml', dataLoader);
      Readings adventSpecialReadings = await readingsExtract(
          '$specialFilePath/advent_$adventSpecialDay.yaml', dataLoader);
      ferialReadings.overlayWith(adventSpecialReadings);
      ferialReadings.hymn = hymns;
      return ferialReadings;
    }

    //after december the 17th we add to the week days the special material of the D day
    ferialReadings = await readingsExtract(
        '$ferialFilePath/advent_${weekNumber}_$dayNumber.yaml', dataLoader);
    Readings adventSpecialReadings = await readingsExtract(
        '$specialFilePath/advent_$adventSpecialDay.yaml', dataLoader);
    ferialReadings.overlayWith(adventSpecialReadings);

    //after december the 17th, in the 3d week we use the psalm antiphons of the 4th week
    if (weekNumber == 3) {
      Readings ferialReadingsFour = await readingsExtract(
          '$ferialFilePath/advent_4_$dayNumber.yaml', dataLoader);
      // Replace only the antiphons, keeping the psalms from ferialReadings
      if (ferialReadings.psalmody != null &&
          ferialReadingsFour.psalmody != null &&
          ferialReadings.psalmody!.length >= 3 &&
          ferialReadingsFour.psalmody!.length >= 3) {
        ferialReadings.psalmody = List.generate(
          3,
          (i) => PsalmEntry(
            psalm: ferialReadings.psalmody![i].psalm,
            antiphon: ferialReadingsFour.psalmody![i].antiphon,
          ),
        );
      }
    }
    ferialReadings.hymn = hymns;
    return ferialReadings;
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
      Readings readingsOffice = await readingsExtract(
          '$specialFilePath/christmas_$dayNumber.yaml', dataLoader);
      Readings baseReadingsOffice =
          await readingsExtract('$commonsFilePath/christmas.yaml', dataLoader);
      baseReadingsOffice.overlayWith(readingsOffice);
      baseReadingsOffice.hymn = hymns;
      return baseReadingsOffice;
    }
    // Christmas days in January
    if (celebrationCode.startsWith('christmas-')) {
      // Before Epiphany: proper of the day with psalms and antiphons
      // of the 1st or 2d week of Christmas time
      List<String> parts = celebrationCode.split('-')[1].split('_');
      String dateDay = parts[0];
      String breviaryWeek = parts[1];
      String breviaryDay = parts[2];
      Readings readingsOffice = await readingsExtract(
          '$specialFilePath/christmas-ferial_before_epiphany_$dateDay.yaml',
          dataLoader);
      Readings baseReadingsOffice = await readingsExtract(
          '$ferialFilePath/christmas_${breviaryWeek}_$breviaryDay.yaml',
          dataLoader);
      baseReadingsOffice.overlayWith(readingsOffice);
      baseReadingsOffice.hymn = hymns;
      return baseReadingsOffice;
    }
    // After Epiphany
    Readings readingsOffice = await readingsExtract(
        '$ferialFilePath/christmas_2_${date.weekday}.yaml', dataLoader);
    readingsOffice.hymn = hymnList["after_epiphany"] ?? [];
    return readingsOffice;
  }

  // ============================================================================
  // LENT TIME
  // ============================================================================
  if (celebrationCode.startsWith('lent')) {
    List dayDatas = extractWeekAndDay(celebrationCode, "lent");
    int weekNumber = dayDatas[0];
    int dayNumber = dayDatas[1];
    ferialReadings = await readingsExtract(
        '$ferialFilePath/lent_${weekNumber}_$dayNumber.yaml', dataLoader);
    return ferialReadings;
  }

  // ============================================================================
  // PASCHAL TIME
  // ============================================================================
  if (celebrationCode.startsWith('PT')) {
    List dayDatas = extractWeekAndDay(celebrationCode, "PT");
    int weekNumber = dayDatas[0];
    int dayNumber = dayDatas[1];
    ferialReadings = await readingsExtract(
        '$ferialFilePath/easter_{$weekNumber}_$dayNumber.yaml', dataLoader);
    return ferialReadings;
  }

  // ============================================================================
  // OTHER FERIAL TIMES
  // ============================================================================
  ferialReadings = await readingsExtract(
      '$ferialFilePath/$celebrationCode.yaml', dataLoader);
  return ferialReadings;
}
