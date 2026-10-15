import '../classes/hour_prayer_class.dart';
import '../classes/office_elements_class.dart';
import '../tools/celebration_index.dart';
import '../tools/date_tools.dart';

/// Builds a major hour (Lauds or Vespers) for [context] from its layers,
/// loaded in parallel: the ferial day ([ferial]), the celebration's own
/// file ([proper], given its path) and its selected Common ([common]).
///
/// The Common is laid over the ferial base (only some of its parts for a
/// memorial), then the proper over everything: a memorial's own psalmody
/// must win when present.
Future<T> composeHourPrayer<T extends HourPrayer>(
  CelebrationContext context, {
  required T Function() empty,
  required Future<T> Function() ferial,
  required Future<T> Function(String path) proper,
  required Future<T> Function() common,
}) async {
  final (base, properLayer, commonLayer) = await (
    context.hasFerialBase ? ferial() : Future.value(empty()),
    context.hasProper
        ? celebrationFilePath(context.celebrationCode, context.dataLoader)
            .then(proper)
        : Future.value(empty()),
    context.hasSelectedCommon ? common() : Future<T?>.value(null),
  ).wait;

  if (context.hasProper) {
    // The day's year-cycle antiphons (Sundays of Ordinary Time) belong to
    // that day's own office only — never to a celebration replacing it,
    // whatever its rank (First Vespers included). Stripped from the ferial
    // layer before any overlay, so that a celebration's own A/B/C
    // antiphons would be kept.
    base.evangelicAntiphon = withoutYearCycleAntiphons(base.evangelicAntiphon);
  }

  // Memorials and feasts keep the season's hymns selectable after their
  // own; solemnities replace them.
  final keepBaseHymns = context.keepsSeasonHymns;
  if (commonLayer != null) {
    if (context.isMemorial) {
      base.overlayWithCommon(commonLayer);
    } else {
      base.overlayWith(commonLayer, keepBaseHymns: keepBaseHymns);
    }
  }
  base.overlayWith(properLayer, keepBaseHymns: keepBaseHymns);
  return base;
}
