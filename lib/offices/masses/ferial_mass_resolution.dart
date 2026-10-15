import '../../classes/mass_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/constants.dart';
import '../ferial_layers.dart';
import './mass_extract.dart';

/// Resolves Mass content for ferial days.
Future<Masses> ferialMassResolution(CelebrationContext context) async {
  final dataLoader = context.dataLoader;
  final layers = ferialLayers(
      context.ferialCode ?? context.celebrationCode, context.date);

  if (layers.season == 'ot') return _resolveOrdinaryTime(layers, context);

  return composeFerialLayers<Masses>(
      [
        ...layers.paths,
        // Dec 17–24: the great Advent weekday's own file
        if (layers.adventSpecialDay != null)
          FerialLayers.adventSpecialPath(layers.adventSpecialDay!),
      ],
      (path) => massExtract(path, dataLoader),
      (base, overlay) => base.overlayWith(overlay));
}

// --- ORDINARY TIME ---
// Unlike the Divine Office psalmody, each ot_N_D.yaml file (weeks 1-34)
// has its own daily lectionary reading — there is no real 4-week repeat to
// overlay onto for readingParts. But weekdays (D 1-6) share the Sunday's
// (D 0) antiphons and orations, so those 5 fields are filled in from the
// week's Sunday file when the weekday doesn't provide its own.
Future<Masses> _resolveOrdinaryTime(
    FerialLayers layers, CelebrationContext context) async {
  final week = layers.week;
  final day = layers.day;
  final weekdayMasses = await massExtract(
      '$ferialFilePath/ot_${week}_$day.yaml', context.dataLoader);

  if (day == 0) return weekdayMasses;

  final sundayMasses = await massExtract(
      '$ferialFilePath/ot_${week}_0.yaml', context.dataLoader);
  weekdayMasses.fillFromSunday(sundayMasses);
  return weekdayMasses;
}
