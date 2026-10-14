import '../../classes/readings_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/extract_week_and_day.dart';
import '../../tools/hymns_management.dart';
import '../../tools/date_tools.dart';
import './readings_extract.dart';
import '../../tools/constants.dart';

/// Resolves readings prayer (Office of Readings) for ferial days
Future<Readings> ferialReadingsResolution(CelebrationContext context) {
  final code = context.ferialCode ?? context.celebrationCode;
  final season = const ['ot', 'advent', 'christmas', 'lent', 'easter']
      .firstWhere((s) => code.startsWith(s), orElse: () => '');

  return switch (season) {
    'ot' => _resolveOrdinaryTime(context),
    'advent' => _resolveAdvent(context),
    'christmas' => _resolveChristmas(context),
    'lent' => _resolveLent(context),
    'easter' => _resolveEaster(context),
    _ when holyWeekCodes.contains(code) => _resolveHolyWeek(context),
    _ => readingsExtractFor(context, '$ferialFilePath/$code.yaml'),
  };
}

// --- ORDINARY TIME ---
Future<Readings> _resolveOrdinaryTime(CelebrationContext context) async {
  final dayDatas = extractWeekAndDay(context.ferialCode!, 'ot');
  final int week = dayDatas[0];
  final int day = dayDatas[1];

  Readings ferialReadings = await readingsExtractFor(
      context, '$ferialFilePath/ot_${((week - 1) % 4) + 1}_$day.yaml');

  if (week > 4) {
    Readings auxData = await readingsExtractFor(
        context, '$ferialFilePath/ot_${week}_$day.yaml');
    ferialReadings.overlayWith(auxData);
  }

  final otHymns = await getHymnsForSeason("ot", context.dataLoader);
  ferialReadings.hymn = [...?ferialReadings.hymn, ...otHymns];
  return ferialReadings;
}

({int specialDay, int week, int day}) _parseSpecialAdventCode(String code) {
  final parts = code.replaceFirst('advent-', '').split('_');
  return (
    specialDay: int.parse(parts[0]),
    week: int.parse(parts[1]),
    day: int.parse(parts[2]),
  );
}

// --- ADVENT ---
Future<Readings> _resolveAdvent(CelebrationContext context) async {
  final code = context.ferialCode!;
  final dataLoader = context.dataLoader;
  late Readings ferialReadings;

  if (code.contains('advent_')) {
    final dayDatas = extractWeekAndDay(code, "advent");
    ferialReadings = await readingsExtractFor(
        context, '$ferialFilePath/advent_${dayDatas[0]}_${dayDatas[1]}.yaml');
  } else {
    // Special Advent (Dec 17–24)
    final (:specialDay, :week, :day) = _parseSpecialAdventCode(code);

    final results = await Future.wait([
      readingsExtractFor(context, '$ferialFilePath/advent_${week}_$day.yaml'),
      readingsExtractFor(context, '$ferialFilePath/advent_$specialDay.yaml'),
    ]);
    ferialReadings = results[0];
    ferialReadings.overlayWith(results[1]);
  }

  final adventHymns = await getHymnsForSeason("advent", dataLoader);
  ferialReadings.hymn = [...?ferialReadings.hymn, ...adventHymns];
  return ferialReadings;
}

// --- CHRISTMAS ---
Future<Readings> _resolveChristmas(CelebrationContext context) async {
  final code = context.ferialCode!;
  final date = context.date;
  final dataLoader = context.dataLoader;
  Readings ferialReadings;
  String hymnSeason = "christmas";

  if (date.month == 12) {
    // Dec 25 to 31
    ferialReadings =
        await readingsExtractFor(context, '$commonsFilePath/christmas.yaml');
    Readings proper = await readingsExtractFor(
        context, '$ferialFilePath/christmas_${date.day}.yaml');
    ferialReadings.overlayWith(proper);
  } else if (code.contains('-')) {
    // Jan before Epiphany
    List<String> parts = code.split('-')[1].split('_');
    ferialReadings = await readingsExtractFor(
        context, '$ferialFilePath/christmas_${parts[1]}_${parts[2]}.yaml');
    Readings proper = await readingsExtractFor(context,
        '$ferialFilePath/christmas-ferial_before_epiphany_${parts[0]}.yaml');
    ferialReadings.overlayWith(proper);
  } else {
    // After Epiphany
    ferialReadings = await readingsExtractFor(
        context, '$ferialFilePath/christmas_2_${date.weekday}.yaml');
    hymnSeason = "after_epiphany";
  }

  final christmasHymns = await getHymnsForSeason(hymnSeason, dataLoader);
  ferialReadings.hymn = [...?ferialReadings.hymn, ...christmasHymns];
  return ferialReadings;
}

// --- LENT ---
Future<Readings> _resolveLent(CelebrationContext context) async {
  final dayDatas = extractWeekAndDay(context.ferialCode!, 'lent');
  final week = dayDatas[0];
  final day = dayDatas[1];

  // lent_4_0 and lent_5_0 (4th and 5th Sundays of Lent) have year-specific
  // patristic readings keyed as patristicReadingA/B/C in the YAML.
  final bool hasYearSpecificReading = day == 0 && (week == 4 || week == 5);
  final String? year = hasYearSpecificReading
      ? sundayCycle(context.effectiveLiturgicalYear)
      : null;

  Readings ferialReadings = await readingsExtractFor(
      context, '$ferialFilePath/lent_${week}_$day.yaml',
      year: year);

  final String hymnKey = week < 5 ? "lent" : "passion";
  final lentHymns = await getHymnsForSeason(hymnKey, context.dataLoader);
  ferialReadings.hymn = [...?ferialReadings.hymn, ...lentHymns];
  return ferialReadings;
}

// --- HOLY WEEK ---
Future<Readings> _resolveHolyWeek(CelebrationContext context) async {
  final code = context.ferialCode!;
  Readings ferialReadings =
      await readingsExtractFor(context, '$ferialFilePath/$code.yaml');
  final holyWeekHymns = await getHymnsForSeason("passion", context.dataLoader);
  ferialReadings.hymn = [...?ferialReadings.hymn, ...holyWeekHymns];
  return ferialReadings;
}

// --- EASTER ---
Future<Readings> _resolveEaster(CelebrationContext context) async {
  Readings ferialReadings = await readingsExtractFor(
      context, '$ferialFilePath/${context.ferialCode!}.yaml');

  final easterHymns = await getHymnsForSeason("easter", context.dataLoader);
  ferialReadings.hymn = [...?ferialReadings.hymn, ...easterHymns];
  return ferialReadings;
}
