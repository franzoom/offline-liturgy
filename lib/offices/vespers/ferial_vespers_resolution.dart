import '../../classes/vespers_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/extract_week_and_day.dart';
import '../../assets/libraries/hymn_list.dart';
import './vespers_extract.dart';
import '../../tools/constants.dart';

/// Resolves vespers prayer for ferial days
/// Returns Vespers instanciation
Future<Vespers> ferialVespersResolution(CelebrationContext context) async {
  final celebrationCode = context.ferialCode ?? context.celebrationCode;
  final date = context.date;
  final dataLoader = context.dataLoader;
  Vespers ferialVespers = Vespers();

  // ============================================================================
  // ORDINARY TIME
  // ============================================================================
  if (celebrationCode.startsWith('ot')) {
    List dayDatas = extractWeekAndDay(celebrationCode, 'ot');
    int weekNumber = dayDatas[0];
    int dayNumber = dayDatas[1];

    // picks the data of the first 4 weeks of the Ordinary Time:
    Vespers ferialVespers = await vespersExtract(
        '$ferialFilePath/ot_${((weekNumber - 1) % 4) + 1}_$dayNumber.yaml',
        dataLoader);

    if (weekNumber > 4) {
      // Add specific data after the 4th week
      Vespers auxData = await vespersExtract(
          '$ferialFilePath/ot_${weekNumber}_$dayNumber.yaml', dataLoader);
      ferialVespers.overlayWith(auxData);
    }

    return ferialVespers;
  }

  // ============================================================================
  // ADVENT TIME
  // ============================================================================
  if (celebrationCode.startsWith('advent')) {
    final List<HymnEntry> hymns =
        (hymnList["advent"] ?? []).map((e) => HymnEntry(code: e)).toList();

    if (RegExp(r'advent_').hasMatch(celebrationCode)) {
      // Days before December 17th: is written "advent_XXX"
      List dayDatas = extractWeekAndDay(celebrationCode, "advent");
      int weekNumber = dayDatas[0];
      int dayNumber = dayDatas[1];
      ferialVespers = await vespersExtract(
          '$ferialFilePath/advent_${weekNumber}_$dayNumber.yaml', dataLoader);
      ferialVespers.hymn = hymns;
      return ferialVespers;
    }
    // Days from December 17th onwards (special days): is written "advent-17_3_5"
    // extracting the datas of the celebrationCode:
    List<String> parts = celebrationCode.replaceFirst("advent-", "").split("_");
    int adventSpecialDay = int.parse(parts[0]);
    int weekNumber = int.parse(parts[1]);
    int dayNumber = int.parse(parts[2]);

    ferialVespers = await vespersExtract(
        '$specialFilePath/advent_$adventSpecialDay.yaml', dataLoader);

    //sunday after 12/17: use the Sunday texts and add the Evangelic Antiphon of the Special Day
    if (dayNumber == 0) {
      ferialVespers = await vespersExtract(
          '$ferialFilePath/advent_${weekNumber}_$dayNumber.yaml', dataLoader);
      Vespers adventSpecialVespers = await vespersExtract(
          '$specialFilePath/advent_$adventSpecialDay.yaml', dataLoader);
      ferialVespers.evangelicAntiphon = adventSpecialVespers.evangelicAntiphon;
      ferialVespers.hymn = hymns;
      return ferialVespers;
    }

    //after december the 17th we add to the week days the special material of the D day
    ferialVespers = await vespersExtract(
        '$ferialFilePath/advent_${weekNumber}_$dayNumber.yaml', dataLoader);
    Vespers adventSpecialVespers = await vespersExtract(
        '$specialFilePath/advent_$adventSpecialDay.yaml', dataLoader);
    ferialVespers.overlayWith(adventSpecialVespers);

    //after december the 17th, in the 3d week we use the psalm antiphons of the 4th week
    if (weekNumber == 3) {
      Vespers ferialVespersFour = await vespersExtract(
          '$ferialFilePath/advent_4_$dayNumber.yaml', dataLoader);
      // Replace only the antiphons, keeping the psalms from ferialVespers
      if (ferialVespers.psalmody != null &&
          ferialVespersFour.psalmody != null &&
          ferialVespers.psalmody!.length >= 3 &&
          ferialVespersFour.psalmody!.length >= 3) {
        ferialVespers.psalmody = List.generate(
          3,
          (i) => PsalmEntry(
            psalm: ferialVespers.psalmody![i].psalm,
            antiphon: ferialVespersFour.psalmody![i].antiphon,
          ),
        );
      }
    }
    ferialVespers.hymn = hymns;
    return ferialVespers;
  }

  // ============================================================================
  // CHRISTMAS TIME
  // ============================================================================
  if (celebrationCode.startsWith('christmas')) {
    // Note: Holy Family is excluded (not a ferial day)
    int dayNumber = date.day;
    int monthNumber = date.month;
    List<HymnEntry> hymns =
        (hymnList["christmas"] ?? []).map((e) => HymnEntry(code: e)).toList();

    if (monthNumber == 12) {
      // All December days in Christmas time: proper office overlays the Common
      Vespers vespersOffice = await vespersExtract(
          '$specialFilePath/christmas_$dayNumber.yaml', dataLoader);
      Vespers baseVespersOffice =
          await vespersExtract('$commonsFilePath/christmas.yaml', dataLoader);
      baseVespersOffice.overlayWith(vespersOffice);
      baseVespersOffice.hymn = hymns;
      return baseVespersOffice;
    }
    // Christmas days in January
    if (celebrationCode.startsWith('christmas-')) {
      // Before Epiphany: proper of the day with psalms and antiphons
      // of the 1st or 2d week of Christmas time
      List<String> parts = celebrationCode.split('-')[1].split('_');
      String dateDay = parts[0];
      String breviaryWeek = parts[1];
      String breviaryDay = parts[2];
      Vespers vespersOffice = await vespersExtract(
          '$specialFilePath/christmas-ferial_before_epiphany_$dateDay.yaml',
          dataLoader);
      Vespers baseVespersOffice = await vespersExtract(
          '$ferialFilePath/christmas_${breviaryWeek}_$breviaryDay.yaml',
          dataLoader);
      baseVespersOffice.overlayWith(vespersOffice);
      baseVespersOffice.hymn = hymns;
      return baseVespersOffice;
    }
    // After Epiphany
    Vespers vespersOffice = await vespersExtract(
        '$ferialFilePath/christmas_2_${date.weekday}.yaml', dataLoader);
    vespersOffice.hymn =
        (hymnList["after_epiphany"] ?? []).map((e) => HymnEntry(code: e)).toList();
    return vespersOffice;
  }

  // ============================================================================
  // LENT TIME
  // ============================================================================
  if (celebrationCode.startsWith('lent')) {
    List dayDatas = extractWeekAndDay(celebrationCode, "lent");
    int weekNumber = dayDatas[0];
    int dayNumber = dayDatas[1];
    ferialVespers = await vespersExtract(
        '$ferialFilePath/lent_${weekNumber}_$dayNumber.yaml', dataLoader);
    return ferialVespers;
  }

  // ============================================================================
  // PASCHAL TIME
  // ============================================================================
  if (celebrationCode.startsWith('PT')) {
    List dayDatas = extractWeekAndDay(celebrationCode, "PT");
    int weekNumber = dayDatas[0];
    int dayNumber = dayDatas[1];
    ferialVespers = await vespersExtract(
        '$ferialFilePath/easter_${weekNumber}_$dayNumber.yaml', dataLoader);
    return ferialVespers;
  }

  // ============================================================================
  // OTHER FERIAL TIMES
  // ============================================================================
  ferialVespers =
      await vespersExtract('$ferialFilePath/$celebrationCode.yaml', dataLoader);
  return ferialVespers;
}
