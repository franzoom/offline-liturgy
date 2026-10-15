import '../../classes/middle_of_day_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/hymns_management.dart';
import '../ferial_layers.dart';
import './middle_of_day_extract.dart';

/// Resolves middle of day prayer content for ferial days.
/// Assigns hymns for tierce, sexte and none based on liturgical time, unless
/// the ferial file declares its own.
Future<MiddleOfDay> ferialMiddleOfDayResolution(
    CelebrationContext context) async {
  final dataLoader = context.dataLoader;
  final liturgicalTime = context.liturgicalTime ?? '';
  final layers =
      ferialLayers(context.ferialCode ?? context.celebrationCode, context.date);

  final result = await composeFerialLayers<MiddleOfDay>(
      [
        ...layers.paths,
        // Dec 17–24: the great Advent weekday's own file
        if (layers.adventSpecialDay != null)
          FerialLayers.adventSpecialPath(layers.adventSpecialDay!),
      ],
      (path) => middleOfDayExtract(path, dataLoader),
      // Ordinary Time weeks > 4 keep the orations of the 4-week cycle
      layers.season == 'ot' ? _overlayKeepingOrations : _overlay);

  // Assign hymns for each hour based on liturgical time, unless the ferial
  // file declares its own (e.g. Good Friday, Holy Saturday)
  result.hymnTierce ??= await getTierceHymns(liturgicalTime, dataLoader);
  result.hymnSexte ??= await getSexteHymns(liturgicalTime, dataLoader);
  result.hymnNone ??= await getNoneHymns(liturgicalTime, dataLoader);

  return result;
}

void _overlay(MiddleOfDay base, MiddleOfDay overlay) =>
    base.overlayWith(overlay);

void _overlayKeepingOrations(MiddleOfDay base, MiddleOfDay overlay) {
  final savedOration = base.oration;
  final savedTierceOration = base.tierce?.oration;
  final savedSexteOration = base.sexte?.oration;
  final savedNoneOration = base.none?.oration;

  base.overlayWith(overlay);

  base.oration = savedOration;
  if (base.tierce != null) base.tierce!.oration = savedTierceOration;
  if (base.sexte != null) base.sexte!.oration = savedSexteOration;
  if (base.none != null) base.none!.oration = savedNoneOration;
}
