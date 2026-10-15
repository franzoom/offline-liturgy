import '../../classes/morning_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/hymns_management.dart';
import '../ferial_layers.dart';
import '../compose_office.dart';
import './morning_extract.dart';

/// Resolves morning prayer content for ferial days.
Future<Morning> ferialMorningResolution(CelebrationContext context) async {
  final dataLoader = context.dataLoader;
  final layers =
      ferialLayers(context.ferialCode ?? context.celebrationCode, context.date);

  final morning = await composeLayers<Morning>(
      layers.paths,
      (path) => morningExtract(path, dataLoader),
      (base, overlay) => base.overlayWith(overlay));

  // Dec 17–24: the day's "O" antiphon; on a weekday its whole file
  final specialDay = layers.adventSpecialDay;
  if (specialDay != null) {
    final special = await morningExtract(
        FerialLayers.adventSpecialPath(specialDay), dataLoader);
    if (layers.day == 0) {
      morning.evangelicAntiphon = special.evangelicAntiphon;
    } else {
      morning.overlayWith(special);
    }
  }

  final hymnSeason = layers.hymnSeason;
  if (hymnSeason != null) {
    morning.hymn = [
      ...?morning.hymn,
      ...await getHymnsForSeason(hymnSeason, dataLoader),
    ];
  }
  return morning;
}
