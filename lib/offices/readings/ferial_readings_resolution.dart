import '../../classes/readings_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/extract_week_and_day.dart';
import '../../tools/hymns_management.dart'; // Contient getHymnsForSeason
import './readings_extract.dart';
import '../../tools/constants.dart';

/// Resolves readings prayer (Office of Readings) for ferial days
Future<Readings> ferialReadingsResolution(CelebrationContext context) async {
  final code = context.ferialCode ?? context.celebrationCode;

  if (code.startsWith('ot')) return _resolveOrdinaryTime(context);
  if (code.startsWith('advent')) return _resolveAdvent(context);
  if (code.startsWith('christmas')) return _resolveChristmas(context);
  if (code.startsWith('lent')) return _resolveLent(context);
  if (code.startsWith('easter')) return _resolveEaster(context);

  // Fallback
  return await readingsExtract(
      '$ferialFilePath/$code.yaml', context.dataLoader);
}

// --- ORDINARY TIME ---
Future<Readings> _resolveOrdinaryTime(CelebrationContext context) async {
  final dayDatas = extractWeekAndDay(context.ferialCode!, 'ot');
  final int week = dayDatas[0];
  final int day = dayDatas[1];

  Readings ferialReadings = await readingsExtract(
      '$ferialFilePath/ot_${((week - 1) % 4) + 1}_$day.yaml',
      context.dataLoader);

  if (week > 4) {
    Readings auxData = await readingsExtract(
        '$ferialFilePath/ot_${week}_$day.yaml', context.dataLoader);
    ferialReadings.overlayWith(auxData);
  }

  return ferialReadings;
}

// --- ADVENT ---
Future<Readings> _resolveAdvent(CelebrationContext context) async {
  final code = context.ferialCode!;
  final dataLoader = context.dataLoader;
  Readings ferialReadings;

  if (RegExp(r'advent_').hasMatch(code)) {
    final dayDatas = extractWeekAndDay(code, "advent");
    ferialReadings = await readingsExtract(
        '$ferialFilePath/advent_${dayDatas[0]}_${dayDatas[1]}.yaml',
        dataLoader);
  } else {
    // Special Advent (Dec 17 - 24)
    List<String> parts = code.replaceFirst("advent-", "").split("_");
    int specialDay = int.parse(parts[0]);
    int week = int.parse(parts[1]);
    int day = int.parse(parts[2]);

    ferialReadings = await readingsExtract(
        '$ferialFilePath/advent_${week}_$day.yaml', dataLoader);
    Readings specialData = await readingsExtract(
        '$specialFilePath/advent_$specialDay.yaml', dataLoader);

    // Overlay special material (biblical/patristic readings and Te Deum logic)
    ferialReadings.overlayWith(specialData);

    // Special rule for Week 3: uses Psalm antiphons from Week 4
    if (week == 3) {
      Readings weekFour = await readingsExtract(
          '$ferialFilePath/advent_4_$day.yaml', dataLoader);
      if (ferialReadings.psalmody?.length == 3 &&
          weekFour.psalmody?.length == 3) {
        ferialReadings.psalmody = List.generate(
            3,
            (i) => PsalmEntry(
                  psalm: ferialReadings.psalmody![i].psalm,
                  antiphon: weekFour.psalmody![i].antiphon,
                ));
      }
    }
  }

  ferialReadings.hymn = getHymnsForSeason("advent");
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
        await readingsExtract('$commonsFilePath/christmas.yaml', dataLoader);
    Readings proper = await readingsExtract(
        '$specialFilePath/christmas_${date.day}.yaml', dataLoader);
    ferialReadings.overlayWith(proper);
  } else if (code.contains('-')) {
    // Jan before Epiphany
    List<String> parts = code.split('-')[1].split('_');
    ferialReadings = await readingsExtract(
        '$ferialFilePath/christmas_${parts[1]}_${parts[2]}.yaml', dataLoader);
    Readings proper = await readingsExtract(
        '$specialFilePath/christmas-ferial_before_epiphany_${parts[0]}.yaml',
        dataLoader);
    ferialReadings.overlayWith(proper);
  } else {
    // After Epiphany
    ferialReadings = await readingsExtract(
        '$ferialFilePath/christmas_2_${date.weekday}.yaml', dataLoader);
    hymnSeason = "after_epiphany";
  }

  ferialReadings.hymn = getHymnsForSeason(hymnSeason);
  return ferialReadings;
}

// --- LENT ---
Future<Readings> _resolveLent(CelebrationContext context) async {
  final dayDatas = extractWeekAndDay(context.ferialCode!, 'lent');
  final week = dayDatas[0];

  Readings ferialReadings = await readingsExtract(
      '$ferialFilePath/lent_${week}_${dayDatas[1]}.yaml', context.dataLoader);

  final String hymnKey = week < 5 ? "lent" : "passion";
  ferialReadings.hymn = getHymnsForSeason(hymnKey);

  return ferialReadings;
}

// --- EASTER ---
Future<Readings> _resolveEaster(CelebrationContext context) async {
  final dayDatas = extractWeekAndDay(context.ferialCode!, 'easter');

  Readings ferialReadings = await readingsExtract(
      '$ferialFilePath/easter_${dayDatas[0]}_${dayDatas[1]}.yaml',
      context.dataLoader);

  ferialReadings.hymn = getHymnsForSeason("easter");
  return ferialReadings;
}
