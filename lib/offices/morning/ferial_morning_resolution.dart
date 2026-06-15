import '../../classes/morning_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/extract_week_and_day.dart';
import '../../tools/hymns_management.dart';
import '../../tools/date_tools.dart';
import './morning_extract.dart';
import '../../tools/constants.dart';

/// Resolves morning prayer content for ferial days.
Future<Morning> ferialMorningResolution(CelebrationContext context) {
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
    _ => morningExtract('$ferialFilePath/$code.yaml', context.dataLoader),
  };
}

// --- ORDINARY TIME ---
Future<Morning> _resolveOrdinaryTime(CelebrationContext context) async {
  final dayDatas = extractWeekAndDay(context.ferialCode!, 'ot');
  final int week = dayDatas[0];
  final int day = dayDatas[1];

  // Base: 4-week cycle
  Morning ferialMorning = await morningExtract(
      '$ferialFilePath/ot_${((week - 1) % 4) + 1}_$day.yaml',
      context.dataLoader);

  // Overlay specific data for weeks > 4
  if (week > 4) {
    Morning aux = await morningExtract(
        '$ferialFilePath/ot_${week}_$day.yaml', context.dataLoader);
    ferialMorning.overlayWith(aux);
  }

  final otHymns = await getHymnsForSeason("ot", context.dataLoader);
  ferialMorning.hymn = [...?ferialMorning.hymn, ...otHymns];
  return ferialMorning;
}

// --- ADVENT ---
Future<Morning> _resolveAdvent(CelebrationContext context) async {
  final code = context.ferialCode!;
  final dataLoader = context.dataLoader;
  late Morning ferialMorning;

  if (code.contains('advent_')) {
    // Standard Advent weeks
    final dayDatas = extractWeekAndDay(code, "advent");
    ferialMorning = await morningExtract(
        '$ferialFilePath/advent_${dayDatas[0]}_${dayDatas[1]}.yaml',
        dataLoader);
  } else {
    // Special Advent (Dec 17–24)
    List<String> parts = code.replaceFirst("advent-", "").split("_");
    int specialDay = int.parse(parts[0]);
    int week = int.parse(parts[1]);
    int day = int.parse(parts[2]);

    final results = await Future.wait([
      morningExtract('$ferialFilePath/advent_${week}_$day.yaml', dataLoader),
      morningExtract('$ferialFilePath/advent_$specialDay.yaml', dataLoader),
    ]);
    ferialMorning = results[0];
    final Morning specialData = results[1];

    if (day == 0) {
      ferialMorning.evangelicAntiphon = specialData.evangelicAntiphon;
    } else {
      ferialMorning.overlayWith(specialData);
    }

    // Special rule for Week 3: uses Psalm antiphons from Week 4
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

  final adventHymns = await getHymnsForSeason("advent", dataLoader);
  ferialMorning.hymn = [...?ferialMorning.hymn, ...adventHymns];
  return ferialMorning;
}

// --- CHRISTMAS ---
Future<Morning> _resolveChristmas(CelebrationContext context) async {
  final code = context.ferialCode!;
  final date = context.date;
  final dataLoader = context.dataLoader;
  Morning ferialMorning;
  String hymnSeason = "christmas";

  if (date.month == 12) {
    // Dec 25 to 31
    ferialMorning =
        await morningExtract('$commonsFilePath/christmas.yaml', dataLoader);
    Morning proper = await morningExtract(
        '$sanctoralFilePath/roman/christmas_${date.day}.yaml', dataLoader);
    ferialMorning.overlayWith(proper);
  } else if (code.contains('-')) {
    // Jan before Epiphany
    List<String> parts = code.split('-')[1].split('_');
    ferialMorning = await morningExtract(
        '$ferialFilePath/christmas_${parts[1]}_${parts[2]}.yaml', dataLoader);
    Morning proper = await morningExtract(
        '$sanctoralFilePath/christmas-ferial_before_epiphany_${parts[0]}.yaml',
        dataLoader);
    ferialMorning.overlayWith(proper);
  } else {
    // After Epiphany
    ferialMorning = await morningExtract(
        '$ferialFilePath/christmas_2_${date.weekday}.yaml', dataLoader);
    hymnSeason = "after_epiphany";
  }

  final christmasHymns = await getHymnsForSeason(hymnSeason, dataLoader);
  ferialMorning.hymn = [...?ferialMorning.hymn, ...christmasHymns];
  return ferialMorning;
}

// --- LENT ---
Future<Morning> _resolveLent(CelebrationContext context) async {
  final dayDatas = extractWeekAndDay(context.ferialCode!, 'lent');
  final week = dayDatas[0];

  Morning ferialMorning = await morningExtract(
      '$ferialFilePath/lent_${week}_${dayDatas[1]}.yaml', context.dataLoader);

  final String hymnKey = week < 5 ? "lent" : "passion";
  final lentHymns = await getHymnsForSeason(hymnKey, context.dataLoader);
  ferialMorning.hymn = [...?ferialMorning.hymn, ...lentHymns];
  return ferialMorning;
}

// --- HOLY WEEK ---
Future<Morning> _resolveHolyWeek(CelebrationContext context) async {
  final code = context.ferialCode!;
  Morning ferialMorning =
      await morningExtract('$ferialFilePath/$code.yaml', context.dataLoader);
  final holyWeekHymns = await getHymnsForSeason("passion", context.dataLoader);
  ferialMorning.hymn = [...?ferialMorning.hymn, ...holyWeekHymns];
  return ferialMorning;
}

// --- EASTER ---
Future<Morning> _resolveEaster(CelebrationContext context) async {
  Morning ferialMorning = await morningExtract(
      '$ferialFilePath/${context.ferialCode!}.yaml', context.dataLoader);

  final easterHymns = await getHymnsForSeason("easter", context.dataLoader);
  ferialMorning.hymn = [...?ferialMorning.hymn, ...easterHymns];
  return ferialMorning;
}
