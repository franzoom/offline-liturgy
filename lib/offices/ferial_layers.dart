import '../tools/constants.dart';

/// The files making up a ferial day's office, shared by every office (Lauds,
/// Vespers, Readings, Middle of Day, Mass): each office extracts its own
/// section from them and overlays them in order.
class FerialLayers {
  /// Season prefix of the code: 'ot', 'advent', 'christmas', 'lent',
  /// 'easter', or '' for a code outside the seasons.
  final String season;

  /// Week and day (0 = Sunday) of the code, 0 when it has none.
  final int week;
  final int day;

  /// Files to overlay in order, the most general first.
  final List<String> paths;

  /// Key of the season's hymns, appended after the files' own hymns by the
  /// offices that take them (Lauds, Vespers, Readings).
  final String? hymnSeason;

  /// Dec 17–24: day of the month of the great Advent weekday, whose own file
  /// (`advent_17.yaml`...) carries the "O" antiphon. Applied by each office
  /// on top of [paths], in its own way.
  final int? adventSpecialDay;

  const FerialLayers({
    required this.season,
    this.week = 0,
    this.day = 0,
    required this.paths,
    this.hymnSeason,
    this.adventSpecialDay,
  });

  /// Path of the great Advent weekday file for [day] of December.
  static String adventSpecialPath(int day) => '$ferialFilePath/advent_$day.yaml';
}

const _seasons = ['ot', 'advent', 'christmas', 'lent', 'easter'];
final _weekAndDay = RegExp(r'^[a-z]+_(\d+)_(\d+)$');
// advent-17_3_5 (Dec 17, week 3, day 5), christmas-2_1_3 (Jan 2, week 1...)
final _datedCode = RegExp(r'^[a-z]+-(\d+)_(\d+)_(\d+)$');

/// Returns the files of the ferial day [code] (a calendar ferial code such
/// as `ot_12_3`, `advent-18_3_4`, `christmas-3_1_6`) falling on [date].
FerialLayers ferialLayers(String code, DateTime date) {
  final season =
      _seasons.firstWhere((s) => code.startsWith(s), orElse: () => '');
  final plain = _weekAndDay.firstMatch(code);
  final week = plain == null ? 0 : int.parse(plain.group(1)!);
  final day = plain == null ? 0 : int.parse(plain.group(2)!);
  final dated = _datedCode.firstMatch(code);

  switch (season) {
    case 'ot':
      return FerialLayers(
        season: season,
        week: week,
        day: day,
        paths: [
          // 4-week psalter cycle, then the week's own texts
          '$ferialFilePath/ot_${((week - 1) % 4) + 1}_$day.yaml',
          if (week > 4) '$ferialFilePath/ot_${week}_$day.yaml',
        ],
        hymnSeason: 'ot',
      );
    case 'advent' when dated != null:
      final datedWeek = int.parse(dated.group(2)!);
      final datedDay = int.parse(dated.group(3)!);
      return FerialLayers(
        season: season,
        week: datedWeek,
        day: datedDay,
        paths: ['$ferialFilePath/advent_${datedWeek}_$datedDay.yaml'],
        hymnSeason: 'advent',
        adventSpecialDay: int.parse(dated.group(1)!),
      );
    case 'christmas' when date.month == 12:
      // Dec 25 to 31: the Christmas common, then the day's own file
      return FerialLayers(
        season: season,
        paths: [
          '$commonsFilePath/christmas.yaml',
          '$ferialFilePath/christmas_${date.day}.yaml',
        ],
        hymnSeason: 'christmas',
      );
    case 'christmas' when dated != null:
      // January, before Epiphany: the week's day, then the dated day
      final datedWeek = int.parse(dated.group(2)!);
      final datedDay = int.parse(dated.group(3)!);
      return FerialLayers(
        season: season,
        week: datedWeek,
        day: datedDay,
        paths: [
          '$ferialFilePath/christmas_${datedWeek}_$datedDay.yaml',
          '$ferialFilePath/christmas-ferial_before_epiphany_${dated.group(1)}.yaml',
        ],
        hymnSeason: 'christmas',
      );
    case 'christmas':
      // After Epiphany
      return FerialLayers(
        season: season,
        paths: ['$ferialFilePath/christmas_2_${date.weekday}.yaml'],
        hymnSeason: 'after_epiphany',
      );
    case 'lent':
      return FerialLayers(
        season: season,
        week: week,
        day: day,
        paths: ['$ferialFilePath/$code.yaml'],
        hymnSeason: week < 5 ? 'lent' : 'passion',
      );
    case 'easter':
      return FerialLayers(
        season: season,
        week: week,
        day: day,
        paths: ['$ferialFilePath/$code.yaml'],
        hymnSeason: 'easter',
      );
    default:
      // plain Advent days, and codes outside the seasons
      return FerialLayers(
        season: season,
        week: week,
        day: day,
        paths: ['$ferialFilePath/$code.yaml'],
        hymnSeason: season == 'advent' ? 'advent' : null,
      );
  }
}

/// Extracts every file of [paths] in parallel with [extract], then overlays
/// them in order onto the first one, which is returned.
Future<T> composeFerialLayers<T>(
  List<String> paths,
  Future<T> Function(String path) extract,
  void Function(T base, T overlay) overlay,
) async {
  final layers = await Future.wait(paths.map(extract));
  for (final layer in layers.skip(1)) {
    overlay(layers.first, layer);
  }
  return layers.first;
}
