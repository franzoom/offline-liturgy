import '../../classes/middle_of_day_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/extract_week_and_day.dart';
import '../../tools/hymns_management.dart';
import './middle_of_day_extract.dart';
import '../../tools/constants.dart';

/// Resolves middle of day prayer content for ferial days.
/// Assigns hymns for tierce, sexte and none based on liturgical time.
Future<MiddleOfDay> ferialMiddleOfDayResolution(
    CelebrationContext context) async {
  final code = context.ferialCode ?? context.celebrationCode;
  final liturgicalTime = context.liturgicalTime ?? '';

  final season = const ['ot', 'advent', 'christmas', 'lent', 'paschal']
      .firstWhere((s) => code.startsWith(s), orElse: () => '');

  final result = await switch (season) {
    'ot' => _resolveOrdinaryTime(context),
    'advent' => _resolveAdvent(context),
    'christmas' => _resolveChristmas(context),
    'lent' => _resolveLent(context),
    'paschal' => _resolveEaster(context),
    _ => middleOfDayExtract('$ferialFilePath/$code.yaml', context.dataLoader),
  };

  // Assign hymns for each hour based on liturgical time
  result.hymnTierce = getTierceHymns(liturgicalTime);
  result.hymnSexte = getSexteHymns(liturgicalTime);
  result.hymnNone = getNoneHymns(liturgicalTime);

  return result;
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

  if (code.startsWith('advent_')) {
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
Future<MiddleOfDay> _resolveChristmas(CelebrationContext context) =>
    switch ((context.date.month == 12, context.ferialCode!.contains('-'))) {
      (true, _) => _resolveChristmasDec(context.date, context.dataLoader),
      (_, true) => _resolveChristmasBeforeEpiphany(
          context.ferialCode!, context.dataLoader),
      _ => middleOfDayExtract(
          '$ferialFilePath/christmas_2_${context.date.weekday}.yaml',
          context.dataLoader),
    };

Future<MiddleOfDay> _resolveChristmasDec(DateTime date, dataLoader) async {
  final base =
      await middleOfDayExtract('$commonsFilePath/christmas.yaml', dataLoader);
  final proper = await middleOfDayExtract(
      '$specialFilePath/christmas_${date.day}.yaml', dataLoader);
  return base..overlayWith(proper);
}

Future<MiddleOfDay> _resolveChristmasBeforeEpiphany(
    String code, dataLoader) async {
  final parts = code.split('-')[1].split('_');
  final base = await middleOfDayExtract(
      '$ferialFilePath/christmas_${parts[1]}_${parts[2]}.yaml', dataLoader);
  final proper = await middleOfDayExtract(
      '$specialFilePath/christmas-ferial_before_epiphany_${parts[0]}.yaml',
      dataLoader);
  return base..overlayWith(proper);
}

// --- LENT ---
Future<MiddleOfDay> _resolveLent(CelebrationContext context) =>
    _resolveWeekDaySeason(context, 'lent');

// --- EASTER ---
Future<MiddleOfDay> _resolveEaster(CelebrationContext context) =>
    _resolveWeekDaySeason(context, 'easter');

Future<MiddleOfDay> _resolveWeekDaySeason(
    CelebrationContext context, String season) async {
  final dayDatas = extractWeekAndDay(context.ferialCode!, season);
  return middleOfDayExtract(
      '$ferialFilePath/${season}_${dayDatas[0]}_${dayDatas[1]}.yaml',
      context.dataLoader);
}
