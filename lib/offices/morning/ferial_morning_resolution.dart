import '../../classes/morning_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/extract_week_and_day.dart';
import '../../assets/libraries/hymn_list.dart';
import './morning_extract.dart';
import '../../tools/constants.dart';

/// Resolves morning prayer content for ferial days.
/// Handles specific seasons (Advent, Christmas, Lent, Easter).
Future<Morning> ferialMorningResolution(CelebrationContext context) async {
  final celebrationCode = context.ferialCode ?? context.celebrationCode;
  final date = context.date;
  final dataLoader = context.dataLoader;
  Morning ferialMorning = Morning();

  // --- ORDINARY TIME ---
  if (celebrationCode.startsWith('ot')) {
    List dayDatas = extractWeekAndDay(celebrationCode, 'ot');
    int week = dayDatas[0];
    int day = dayDatas[1];

    // Base: 4-week cycle
    ferialMorning = await morningExtract(
        '$ferialFilePath/ot_${((week - 1) % 4) + 1}_$day.yaml', dataLoader);

    // Overlay specific data for weeks > 4
    if (week > 4) {
      Morning aux = await morningExtract(
          '$ferialFilePath/ot_${week}_$day.yaml', dataLoader);
      ferialMorning.overlayWith(aux);
    }
    return ferialMorning;
  }

  // --- ADVENT ---
  if (celebrationCode.startsWith('advent')) {
    final hymns =
        (hymnList["advent"] ?? []).map((e) => HymnEntry(code: e)).toList();

    if (RegExp(r'advent_').hasMatch(celebrationCode)) {
      // Standard Advent weeks
      List dayDatas = extractWeekAndDay(celebrationCode, "advent");
      ferialMorning = await morningExtract(
          '$ferialFilePath/advent_${dayDatas[0]}_${dayDatas[1]}.yaml',
          dataLoader);
    } else {
      // Special Advent (Dec 17 - 24)
      List<String> parts =
          celebrationCode.replaceFirst("advent-", "").split("_");
      int specialDay = int.parse(parts[0]);
      int week = int.parse(parts[1]);
      int day = int.parse(parts[2]);

      // Load base weekday and special day data (the "O" antiphon days)
      ferialMorning = await morningExtract(
          '$ferialFilePath/advent_${week}_$day.yaml', dataLoader);
      Morning specialData = await morningExtract(
          '$specialFilePath/advent_$specialDay.yaml', dataLoader);

      if (day == 0) {
        // Sunday: Keep Sunday psalms but take the special Benedictus Antiphon
        ferialMorning.evangelicAntiphon = specialData.evangelicAntiphon;
      } else {
        // Weekday: The special day content takes precedence
        ferialMorning.overlayWith(specialData);
      }

      // Rule: Week 3 uses Psalm antiphons from Week 4 after Dec 17th
      if (week == 3) {
        Morning weekFour = await morningExtract(
            '$ferialFilePath/advent_4_$day.yaml', dataLoader);
        if (ferialMorning.psalmody?.length == 3 &&
            weekFour.psalmody?.length == 3) {
          ferialMorning.psalmody = List.generate(
              3,
              (i) => PsalmEntry(
                    psalm: ferialMorning.psalmody![i].psalm,
                    antiphon: weekFour.psalmody![i].antiphon,
                  ));
        }
      }
    }
    ferialMorning.hymn = hymns;
    return ferialMorning;
  }

  // --- CHRISTMAS ---
  if (celebrationCode.startsWith('christmas')) {
    List<HymnEntry> hymns =
        (hymnList["christmas"] ?? []).map((e) => HymnEntry(code: e)).toList();

    if (date.month == 12) {
      // Dec 25 to 31
      ferialMorning =
          await morningExtract('$commonsFilePath/christmas.yaml', dataLoader);
      Morning proper = await morningExtract(
          '$specialFilePath/christmas_${date.day}.yaml', dataLoader);
      ferialMorning.overlayWith(proper);
    } else if (celebrationCode.contains('-')) {
      // Jan before Epiphany
      List<String> parts = celebrationCode.split('-')[1].split('_');
      ferialMorning = await morningExtract(
          '$ferialFilePath/christmas_${parts[1]}_${parts[2]}.yaml', dataLoader);
      Morning proper = await morningExtract(
          '$specialFilePath/christmas-ferial_before_epiphany_${parts[0]}.yaml',
          dataLoader);
      ferialMorning.overlayWith(proper);
    } else {
      // After Epiphany
      ferialMorning = await morningExtract(
          '$ferialFilePath/christmas_2_${date.weekday}.yaml', dataLoader);
      hymns = (hymnList["after_epiphany"] ?? [])
          .map((e) => HymnEntry(code: e))
          .toList();
    }
    ferialMorning.hymn = hymns;
    return ferialMorning;
  }

  // --- LENT ---
  if (celebrationCode.startsWith('lent')) {
    List dayDatas = extractWeekAndDay(celebrationCode, 'lent');
    int week = dayDatas[0];
    int day = dayDatas[1];
    ferialMorning = await morningExtract(
        '$ferialFilePath/"lent"_${week}_$day.yaml', dataLoader);
    final String hymnTime = week < 5 ? "lent" : "passion";
    List<HymnEntry> hymns =
        (hymnList[hymnTime] ?? []).map((e) => HymnEntry(code: e)).toList();
    ferialMorning.hymn = hymns;
    return ferialMorning;
  }

  // --- EASTER ---
  if (celebrationCode.startsWith('easter')) {
    List dayDatas = extractWeekAndDay(celebrationCode, 'easter');
    ferialMorning = await morningExtract(
        '$ferialFilePath/easter_${dayDatas[0]}_${dayDatas[1]}.yaml',
        dataLoader);
    List<HymnEntry> hymns =
        (hymnList["easter"] ?? []).map((e) => HymnEntry(code: e)).toList();
    ferialMorning.hymn = hymns;
    return ferialMorning;
  }

  // --- FALLBACK ---
  return await morningExtract(
      '$ferialFilePath/$celebrationCode.yaml', dataLoader);
}
