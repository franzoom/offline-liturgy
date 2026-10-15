import '../../classes/vespers_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/hymns_management.dart';
import '../ferial_layers.dart';
import './vespers_extract.dart';

/// Resolves vespers prayer for ferial days
Future<Vespers> ferialVespersResolution(CelebrationContext context) async {
  final dataLoader = context.dataLoader;
  final String section = context.vespersSection;
  final layers = ferialLayers(
      context.ferialCode ?? context.celebrationCode, context.date);

  final vespers = await composeFerialLayers<Vespers>(
      layers.paths,
      (path) => vespersExtract(path, dataLoader, section: section),
      (base, overlay) => base.overlayWith(overlay));

  // Dec 17–24: the day's "O" antiphon; on a weekday its whole file
  var specialDay = layers.adventSpecialDay;
  if (specialDay != null) {
    // First Vespers of a Sunday is prayed the evening BEFORE — its "O"
    // antiphon follows that evening's own date, not the Sunday being
    // anticipated (e.g. First Vespers of the 4th Sunday on Dec 22 uses
    // Dec 21's "O Oriens", not Dec 22's "O Rex Gentium" — confirmed
    // against AELF).
    if (section == 'firstVespers' && layers.day == 0) specialDay -= 1;

    // The special day's own file (Dec 17-24) never has a firstVespers:
    // section of its own — it's a weekday, with a single vespers: block
    // (the O antiphon) reused as-is for a Sunday's First Vespers. Always
    // read it as 'vespers', regardless of which Vespers is being resolved.
    final special = await vespersExtract(
        FerialLayers.adventSpecialPath(specialDay), dataLoader,
        section: 'vespers');
    if (layers.day == 0) {
      vespers.evangelicAntiphon = special.evangelicAntiphon;
    } else {
      vespers.overlayWith(special);
    }
  }

  final hymnSeason = layers.hymnSeason;
  if (hymnSeason != null) {
    vespers.hymn = [
      ...?vespers.hymn,
      ...await getHymnsForSeason(hymnSeason, dataLoader),
    ];
  }
  return vespers;
}
