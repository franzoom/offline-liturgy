import '../../classes/readings_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/hymns_management.dart';
import '../../tools/date_tools.dart';
import '../ferial_layers.dart';
import './readings_extract.dart';

/// Resolves readings prayer (Office of Readings) for ferial days
Future<Readings> ferialReadingsResolution(CelebrationContext context) async {
  final layers =
      ferialLayers(context.ferialCode ?? context.celebrationCode, context.date);

  // lent_4_0 and lent_5_0 (4th and 5th Sundays of Lent) have year-specific
  // patristic readings keyed as patristicReadingA/B/C in the YAML.
  final bool hasYearSpecificReading = layers.season == 'lent' &&
      layers.day == 0 &&
      (layers.week == 4 || layers.week == 5);
  final String? year = hasYearSpecificReading
      ? sundayCycle(context.effectiveLiturgicalYear)
      : null;

  final readings = await composeFerialLayers<Readings>([
    ...layers.paths,
    // Dec 17–24: the great Advent weekday's own file
    if (layers.adventSpecialDay != null)
      FerialLayers.adventSpecialPath(layers.adventSpecialDay!),
  ], (path) => readingsExtractFor(context, path, year: year),
      (base, overlay) => base.overlayWith(overlay));

  final hymnSeason = layers.hymnSeason;
  if (hymnSeason != null) {
    readings.hymn = [
      ...?readings.hymn,
      ...await getHymnsForSeason(hymnSeason, context.dataLoader),
    ];
  }
  return readings;
}
