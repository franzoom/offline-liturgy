import '../../classes/middle_of_day_class.dart';
import '../../classes/office_elements_class.dart';
import '../ferial_layers.dart';
import './middle_of_day_extract.dart';

/// Resolves middle of day prayer content for ferial days.
Future<MiddleOfDay> ferialMiddleOfDayResolution(CelebrationContext context) {
  final dataLoader = context.dataLoader;
  final layers =
      ferialLayers(context.ferialCode ?? context.celebrationCode, context.date);

  return composeFerialLayers<MiddleOfDay>(
      [
        ...layers.paths,
        // Dec 17–24: the great Advent weekday's own file
        if (layers.adventSpecialDay != null)
          FerialLayers.adventSpecialPath(layers.adventSpecialDay!),
      ],
      (path) => middleOfDayExtract(path, dataLoader),
      // Ordinary Time weeks > 4 keep the orations of the 4-week cycle
      layers.season == 'ot' ? _overlayKeepingOrations : _overlay);
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
