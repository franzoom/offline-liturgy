import '../../classes/middle_of_day_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/extract_week_and_day.dart';
import './middle_of_day_extract.dart';
import '../../tools/constants.dart';

/// Resolves middle of day prayer content for ferial days.
Future<MiddleOfDay> ferialMiddleOfDayResolution(
    CelebrationContext context) async {
  final code = context.ferialCode ?? context.celebrationCode;

  if (code.startsWith('ot')) return _resolveOrdinaryTime(context);
  if (code.startsWith('advent')) return _resolveAdvent(context);
  if (code.startsWith('christmas')) return _resolveChristmas(context);
  if (code.startsWith('lent')) return _resolveLent(context);
  if (code.startsWith('easter')) return _resolveEaster(context);

  // Fallback for codes not matching standard seasons
  return await middleOfDayExtract(
      '$ferialFilePath/$code.yaml', context.dataLoader);
}

// --- ORDINARY TIME ---
Future<MiddleOfDay> _resolveOrdinaryTime(CelebrationContext context) async {
  final dayDatas = extractWeekAndDay(context.ferialCode!, 'ot');
  final int week = dayDatas[0];
  final int day = dayDatas[1];

  // Base: 4-week cycle
  MiddleOfDay ferialMiddleOfDay = await middleOfDayExtract(
      '$ferialFilePath/ot_${((week - 1) % 4) + 1}_$day.yaml',
      context.dataLoader);

  // Overlay specific data for weeks > 4
  if (week > 4) {
    MiddleOfDay aux = await middleOfDayExtract(
        '$ferialFilePath/ot_${week}_$day.yaml', context.dataLoader);
    ferialMiddleOfDay.overlayWith(aux);
  }
  return ferialMiddleOfDay;
}

// --- ADVENT ---
Future<MiddleOfDay> _resolveAdvent(CelebrationContext context) async {
  final code = context.ferialCode!;
  final dataLoader = context.dataLoader;
  MiddleOfDay ferialMiddleOfDay;

  if (RegExp(r'advent_').hasMatch(code)) {
    // Standard Advent weeks
    final dayDatas = extractWeekAndDay(code, "advent");
    ferialMiddleOfDay = await middleOfDayExtract(
        '$ferialFilePath/advent_${dayDatas[0]}_${dayDatas[1]}.yaml',
        dataLoader);
  } else {
    // Special Advent (Dec 17 - 24)
    List<String> parts = code.replaceFirst("advent-", "").split("_");
    int specialDay = int.parse(parts[0]);
    int week = int.parse(parts[1]);
    int day = int.parse(parts[2]);

    ferialMiddleOfDay = await middleOfDayExtract(
        '$ferialFilePath/advent_${week}_$day.yaml', dataLoader);
    MiddleOfDay specialData = await middleOfDayExtract(
        '$specialFilePath/advent_$specialDay.yaml', dataLoader);

    ferialMiddleOfDay.overlayWith(specialData);
  }

  return ferialMiddleOfDay;
}

// --- CHRISTMAS ---
Future<MiddleOfDay> _resolveChristmas(CelebrationContext context) async {
  final code = context.ferialCode!;
  final date = context.date;
  final dataLoader = context.dataLoader;
  MiddleOfDay ferialMiddleOfDay;

  if (date.month == 12) {
    // Dec 25 to 31
    ferialMiddleOfDay = await middleOfDayExtract(
        '$commonsFilePath/christmas.yaml', dataLoader);
    MiddleOfDay proper = await middleOfDayExtract(
        '$specialFilePath/christmas_${date.day}.yaml', dataLoader);
    ferialMiddleOfDay.overlayWith(proper);
  } else if (code.contains('-')) {
    // Jan before Epiphany
    List<String> parts = code.split('-')[1].split('_');
    ferialMiddleOfDay = await middleOfDayExtract(
        '$ferialFilePath/christmas_${parts[1]}_${parts[2]}.yaml', dataLoader);
    MiddleOfDay proper = await middleOfDayExtract(
        '$specialFilePath/christmas-ferial_before_epiphany_${parts[0]}.yaml',
        dataLoader);
    ferialMiddleOfDay.overlayWith(proper);
  } else {
    // After Epiphany
    ferialMiddleOfDay = await middleOfDayExtract(
        '$ferialFilePath/christmas_2_${date.weekday}.yaml', dataLoader);
  }

  return ferialMiddleOfDay;
}

// --- LENT ---
Future<MiddleOfDay> _resolveLent(CelebrationContext context) async {
  final dayDatas = extractWeekAndDay(context.ferialCode!, 'lent');

  MiddleOfDay ferialMiddleOfDay = await middleOfDayExtract(
      '$ferialFilePath/lent_${dayDatas[0]}_${dayDatas[1]}.yaml',
      context.dataLoader);

  return ferialMiddleOfDay;
}

// --- EASTER ---
Future<MiddleOfDay> _resolveEaster(CelebrationContext context) async {
  final dayDatas = extractWeekAndDay(context.ferialCode!, 'easter');

  MiddleOfDay ferialMiddleOfDay = await middleOfDayExtract(
      '$ferialFilePath/easter_${dayDatas[0]}_${dayDatas[1]}.yaml',
      context.dataLoader);

  return ferialMiddleOfDay;
}
