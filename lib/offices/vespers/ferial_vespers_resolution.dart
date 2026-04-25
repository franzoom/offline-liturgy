import '../../classes/vespers_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/extract_week_and_day.dart';
import '../../tools/hymns_management.dart';
import './vespers_extract.dart';
import '../../tools/constants.dart';

/// Resolves vespers prayer for ferial days
Future<Vespers> ferialVespersResolution(CelebrationContext context) async {
  final code = context.ferialCode ?? context.celebrationCode;
  final String section =
      context.celebrationType == 'vespers1' ? 'firstVespers' : 'vespers';

  if (code.startsWith('ot')) return _resolveOrdinaryTime(context, section);
  if (code.startsWith('advent')) return _resolveAdvent(context, section);
  if (code.startsWith('christmas')) return _resolveChristmas(context, section);
  if (code.startsWith('lent')) return _resolveLent(context, section);
  if (code.startsWith('easter')) return _resolveEaster(context, section);
  if (const {'holy_thursday', 'holy_friday', 'holy_saturday'}.contains(code)) {
    return _resolveHolyWeek(context, section);
  }

  return await vespersExtract('$ferialFilePath/$code.yaml', context.dataLoader,
      section: section);
}

// --- ORDINARY TIME ---
Future<Vespers> _resolveOrdinaryTime(
    CelebrationContext context, String section) async {
  final dayDatas = extractWeekAndDay(context.ferialCode!, 'ot');
  final int week = dayDatas[0];
  final int day = dayDatas[1];

  Vespers ferialVespers = await vespersExtract(
      '$ferialFilePath/ot_${((week - 1) % 4) + 1}_$day.yaml',
      context.dataLoader,
      section: section);

  if (week > 4) {
    Vespers auxData = await vespersExtract(
        '$ferialFilePath/ot_${week}_$day.yaml', context.dataLoader,
        section: section);
    ferialVespers.overlayWith(auxData);
  }

  return ferialVespers;
}

// --- ADVENT ---
Future<Vespers> _resolveAdvent(
    CelebrationContext context, String section) async {
  final code = context.ferialCode!;
  final dataLoader = context.dataLoader;
  late Vespers ferialVespers;

  if (code.contains('advent_')) {
    final dayDatas = extractWeekAndDay(code, "advent");
    ferialVespers = await vespersExtract(
        '$ferialFilePath/advent_${dayDatas[0]}_${dayDatas[1]}.yaml',
        dataLoader,
        section: section);
  } else {
    // Special Advent (Dec 17–24)
    List<String> parts = code.replaceFirst("advent-", "").split("_");
    int specialDay = int.parse(parts[0]);
    int week = int.parse(parts[1]);
    int day = int.parse(parts[2]);

    final results = await Future.wait([
      vespersExtract('$specialFilePath/advent_$specialDay.yaml', dataLoader,
          section: section),
      vespersExtract('$ferialFilePath/advent_${week}_$day.yaml', dataLoader,
          section: section),
    ]);
    final specialData = results[0];
    ferialVespers = results[1];

    if (day == 0) {
      // Sunday: base Sunday text + special Evangelic Antiphon
      ferialVespers.evangelicAntiphon = specialData.evangelicAntiphon;
    } else {
      // Weekday: base weekday + special day overlay
      ferialVespers.overlayWith(specialData);
    }

    // Special rule for Week 3: uses Psalm antiphons from Week 4
    if (week == 3) {
      Vespers weekFour = await vespersExtract(
          '$ferialFilePath/advent_4_$day.yaml', dataLoader,
          section: section);
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
Future<Vespers> _resolveChristmas(
    CelebrationContext context, String section) async {
  final code = context.ferialCode!;
  final date = context.date;
  final dataLoader = context.dataLoader;
  late Vespers ferialVespers;
  String hymnSeason = "christmas";

  if (date.month == 12) {
    // Dec 25 to 31
    ferialVespers = await vespersExtract('$commonsFilePath/christmas.yaml',
        dataLoader, section: section);
    Vespers proper = await vespersExtract(
        '$specialFilePath/christmas_${date.day}.yaml', dataLoader,
        section: section);
    ferialVespers.overlayWith(proper);
  } else if (code.contains('-')) {
    // Jan before Epiphany
    List<String> parts = code.split('-')[1].split('_');
    ferialVespers = await vespersExtract(
        '$ferialFilePath/christmas_${parts[1]}_${parts[2]}.yaml', dataLoader,
        section: section);
    Vespers proper = await vespersExtract(
        '$specialFilePath/christmas-ferial_before_epiphany_${parts[0]}.yaml',
        dataLoader,
        section: section);
    ferialVespers.overlayWith(proper);
  } else {
    // After Epiphany
    ferialVespers = await vespersExtract(
        '$ferialFilePath/christmas_2_${date.weekday}.yaml', dataLoader,
        section: section);
    hymnSeason = "after_epiphany";
  }

  ferialVespers.hymn = getHymnsForSeason(hymnSeason);
  return ferialVespers;
}

// --- LENT ---
Future<Vespers> _resolveLent(
    CelebrationContext context, String section) async {
  final dayDatas = extractWeekAndDay(context.ferialCode!, 'lent');
  final week = dayDatas[0];

  Vespers ferialVespers = await vespersExtract(
      '$ferialFilePath/lent_${week}_${dayDatas[1]}.yaml', context.dataLoader,
      section: section);

  final String hymnKey = week < 5 ? "lent" : "passion";
  ferialVespers.hymn = getHymnsForSeason(hymnKey);

  return ferialVespers;
}

// --- HOLY WEEK ---
Future<Vespers> _resolveHolyWeek(
    CelebrationContext context, String section) async {
  final code = context.ferialCode!;
  Vespers ferialVespers = await vespersExtract(
      '$ferialFilePath/$code.yaml', context.dataLoader,
      section: section);
  ferialVespers.hymn = getHymnsForSeason("passion");
  return ferialVespers;
}

// --- EASTER ---
Future<Vespers> _resolveEaster(
    CelebrationContext context, String section) async {
  final dayDatas = extractWeekAndDay(context.ferialCode!, 'easter');

  Vespers ferialVespers = await vespersExtract(
      '$ferialFilePath/easter_${dayDatas[0]}_${dayDatas[1]}.yaml',
      context.dataLoader,
      section: section);

  ferialVespers.hymn = getHymnsForSeason("easter");
  return ferialVespers;
}
