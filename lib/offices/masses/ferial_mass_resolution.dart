import '../../classes/mass_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/extract_week_and_day.dart';
import '../../tools/constants.dart';
import './mass_extract.dart';

/// Resolves Mass content for ferial days.
Future<Masses> ferialMassResolution(CelebrationContext context) async {
  final code = context.ferialCode ?? context.celebrationCode;

  if (code.startsWith('ot')) return _resolveOrdinaryTime(context);
  if (code.startsWith('advent')) return _resolveAdvent(context);
  if (code.startsWith('christmas')) return _resolveChristmas(context);
  if (code.startsWith('lent')) return _resolveLent(context);
  if (code.startsWith('easter')) return _resolveEaster(context);

  // Fallback for codes not matching standard seasons
  return await massExtract('$ferialFilePath/$code.yaml', context.dataLoader);
}

// --- ORDINARY TIME ---
// Unlike the Divine Office psalmody, each ot_N_D.yaml file (weeks 1-34)
// has its own daily lectionary reading — there is no real 4-week repeat to
// overlay onto for readingParts. But weekdays (D 1-6) share the Sunday's
// (D 0) antiphons and orations, so those 5 fields are filled in from the
// week's Sunday file when the weekday doesn't provide its own.
Future<Masses> _resolveOrdinaryTime(CelebrationContext context) async {
  final dayDatas = extractWeekAndDay(context.ferialCode!, 'ot');
  final week = dayDatas[0];
  final day = dayDatas[1];
  final weekdayMasses = await massExtract(
      '$ferialFilePath/ot_${week}_$day.yaml', context.dataLoader);

  if (day == 0) return weekdayMasses;

  final sundayMasses = await massExtract(
      '$ferialFilePath/ot_${week}_0.yaml', context.dataLoader);
  weekdayMasses.fillFromSunday(sundayMasses);
  return weekdayMasses;
}

// --- ADVENT ---
Future<Masses> _resolveAdvent(CelebrationContext context) async {
  final code = context.ferialCode!;
  final dataLoader = context.dataLoader;

  if (RegExp(r'advent_').hasMatch(code)) {
    // Standard Advent weeks
    final dayDatas = extractWeekAndDay(code, 'advent');
    return await massExtract(
        '$ferialFilePath/advent_${dayDatas[0]}_${dayDatas[1]}.yaml',
        dataLoader);
  } else {
    // Special Advent (Dec 17 - 24)
    List<String> parts = code.replaceFirst('advent-', '').split('_');
    int specialDay = int.parse(parts[0]);
    int week = int.parse(parts[1]);
    int day = int.parse(parts[2]);

    Masses ferialMasses = await massExtract(
        '$ferialFilePath/advent_${week}_$day.yaml', dataLoader);
    Masses specialData = await massExtract(
        '$ferialFilePath/advent_$specialDay.yaml', dataLoader);
    ferialMasses.overlayWith(specialData);

    return ferialMasses;
  }
}

// --- CHRISTMAS ---
Future<Masses> _resolveChristmas(CelebrationContext context) async {
  final code = context.ferialCode!;
  final date = context.date;
  final dataLoader = context.dataLoader;

  if (date.month == 12) {
    // Dec 25 to 31
    Masses ferialMasses =
        await massExtract('$commonsFilePath/christmas.yaml', dataLoader);
    Masses proper = await massExtract(
        '$ferialFilePath/christmas_${date.day}.yaml', dataLoader);
    ferialMasses.overlayWith(proper);
    return ferialMasses;
  } else if (code.contains('-')) {
    // Jan before Epiphany
    List<String> parts = code.split('-')[1].split('_');
    Masses ferialMasses = await massExtract(
        '$ferialFilePath/christmas_${parts[1]}_${parts[2]}.yaml', dataLoader);
    Masses proper = await massExtract(
        '$ferialFilePath/christmas-ferial_before_epiphany_${parts[0]}.yaml',
        dataLoader);
    ferialMasses.overlayWith(proper);
    return ferialMasses;
  } else {
    // After Epiphany
    return await massExtract(
        '$ferialFilePath/christmas_2_${date.weekday}.yaml', dataLoader);
  }
}

// --- LENT ---
Future<Masses> _resolveLent(CelebrationContext context) async {
  final dayDatas = extractWeekAndDay(context.ferialCode!, 'lent');
  return await massExtract(
      '$ferialFilePath/lent_${dayDatas[0]}_${dayDatas[1]}.yaml',
      context.dataLoader);
}

// --- EASTER ---
Future<Masses> _resolveEaster(CelebrationContext context) async {
  final code = context.ferialCode!;

  // Special compound codes (e.g. easter_6_3_before_ascension) don't match the
  // plain easter_N_D shape extractWeekAndDay expects; use the code as-is.
  if (!RegExp(r'^easter_\d+_\d+$').hasMatch(code)) {
    return await massExtract('$ferialFilePath/$code.yaml', context.dataLoader);
  }

  final dayDatas = extractWeekAndDay(code, 'easter');
  return await massExtract(
      '$ferialFilePath/easter_${dayDatas[0]}_${dayDatas[1]}.yaml',
      context.dataLoader);
}
