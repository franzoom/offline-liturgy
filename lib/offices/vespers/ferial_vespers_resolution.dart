import '../../classes/vespers_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/extract_week_and_day.dart';
import '../../tools/hymns_management.dart'; // Contient getHymnsForSeason
import './vespers_extract.dart';
import '../../tools/constants.dart';

/// Resolves vespers prayer for ferial days
Future<Vespers> ferialVespersResolution(CelebrationContext context) async {
  final code = context.ferialCode ?? context.celebrationCode;

  if (code.startsWith('ot')) return _resolveOrdinaryTime(context);
  if (code.startsWith('advent')) return _resolveAdvent(context);
  if (code.startsWith('christmas')) return _resolveChristmas(context);
  if (code.startsWith('lent')) return _resolveLent(context);
  if (code.startsWith('easter')) return _resolveEaster(context);

  // Fallback
  return await vespersExtract('$ferialFilePath/$code.yaml', context.dataLoader);
}

// --- ORDINARY TIME ---
Future<Vespers> _resolveOrdinaryTime(CelebrationContext context) async {
  final dayDatas = extractWeekAndDay(context.ferialCode!, 'ot');
  final int week = dayDatas[0];
  final int day = dayDatas[1];

  Vespers ferialVespers = await vespersExtract(
      '$ferialFilePath/ot_${((week - 1) % 4) + 1}_$day.yaml',
      context.dataLoader);

  if (week > 4) {
    Vespers auxData = await vespersExtract(
        '$ferialFilePath/ot_${week}_$day.yaml', context.dataLoader);
    ferialVespers.overlayWith(auxData);
  }

  return ferialVespers;
}

// --- ADVENT ---
Future<Vespers> _resolveAdvent(CelebrationContext context) async {
  final code = context.ferialCode!;
  final dataLoader = context.dataLoader;
  Vespers ferialVespers;

  if (RegExp(r'advent_').hasMatch(code)) {
    final dayDatas = extractWeekAndDay(code, "advent");
    ferialVespers = await vespersExtract(
        '$ferialFilePath/advent_${dayDatas[0]}_${dayDatas[1]}.yaml',
        dataLoader);
  } else {
    // Special Advent (Dec 17 - 24)
    List<String> parts = code.replaceFirst("advent-", "").split("_");
    int specialDay = int.parse(parts[0]);
    int week = int.parse(parts[1]);
    int day = int.parse(parts[2]);

    Vespers specialData = await vespersExtract(
        '$specialFilePath/advent_$specialDay.yaml', dataLoader);

    if (day == 0) {
      // Sunday: Base Sunday text + Special Evangelic Antiphon
      ferialVespers = await vespersExtract(
          '$ferialFilePath/advent_${week}_$day.yaml', dataLoader);
      ferialVespers.evangelicAntiphon = specialData.evangelicAntiphon;
    } else {
      // Weekday: Base weekday + Special Day Overlay
      ferialVespers = await vespersExtract(
          '$ferialFilePath/advent_${week}_$day.yaml', dataLoader);
      ferialVespers.overlayWith(specialData);
    }

    // Rule for Week 3: uses Psalm antiphons from Week 4
    if (week == 3) {
      Vespers weekFour = await vespersExtract(
          '$ferialFilePath/advent_4_$day.yaml', dataLoader);
      if (ferialVespers.psalmody?.length == 3 &&
          weekFour.psalmody?.length == 3) {
        ferialVespers.psalmody = List.generate(
            3,
            (i) => PsalmEntry(
                  psalm: ferialVespers.psalmody![i].psalm,
                  antiphon: weekFour.psalmody![i].antiphon,
                ));
      }
    }
  }

  ferialVespers.hymn = getHymnsForSeason("advent");
  return ferialVespers;
}

// --- CHRISTMAS ---
Future<Vespers> _resolveChristmas(CelebrationContext context) async {
  final code = context.ferialCode!;
  final date = context.date;
  final dataLoader = context.dataLoader;
  Vespers ferialVespers;
  String hymnSeason = "christmas";

  if (date.month == 12) {
    // Dec 25 to 31
    ferialVespers =
        await vespersExtract('$commonsFilePath/christmas.yaml', dataLoader);
    Vespers proper = await vespersExtract(
        '$specialFilePath/christmas_${date.day}.yaml', dataLoader);
    ferialVespers.overlayWith(proper);
  } else if (code.contains('-')) {
    // Jan before Epiphany
    List<String> parts = code.split('-')[1].split('_');
    ferialVespers = await vespersExtract(
        '$ferialFilePath/christmas_${parts[1]}_${parts[2]}.yaml', dataLoader);
    Vespers proper = await vespersExtract(
        '$specialFilePath/christmas-ferial_before_epiphany_${parts[0]}.yaml',
        dataLoader);
    ferialVespers.overlayWith(proper);
  } else {
    // After Epiphany
    ferialVespers = await vespersExtract(
        '$ferialFilePath/christmas_2_${date.weekday}.yaml', dataLoader);
    hymnSeason = "after_epiphany";
  }

  ferialVespers.hymn = getHymnsForSeason(hymnSeason);
  return ferialVespers;
}

// --- LENT ---
Future<Vespers> _resolveLent(CelebrationContext context) async {
  final dayDatas = extractWeekAndDay(context.ferialCode!, 'lent');
  final week = dayDatas[0];

  Vespers ferialVespers = await vespersExtract(
      '$ferialFilePath/lent_${week}_${dayDatas[1]}.yaml', context.dataLoader);

  final String hymnKey = week < 5 ? "lent" : "passion";
  ferialVespers.hymn = getHymnsForSeason(hymnKey);

  return ferialVespers;
}

// --- EASTER ---
Future<Vespers> _resolveEaster(CelebrationContext context) async {
  final dayDatas = extractWeekAndDay(context.ferialCode!, 'easter');

  Vespers ferialVespers = await vespersExtract(
      '$ferialFilePath/easter_${dayDatas[0]}_${dayDatas[1]}.yaml',
      context.dataLoader);

  ferialVespers.hymn = getHymnsForSeason("easter");
  return ferialVespers;
}
