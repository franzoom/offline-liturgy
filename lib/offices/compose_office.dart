import '../classes/hour_prayer_class.dart';
import '../classes/office_elements_class.dart';
import '../tools/celebration_index.dart';
import '../tools/date_tools.dart';

/// Builds an office for [context] from its layers, loaded in parallel: the
/// ferial day ([ferial]), the celebration's own file ([proper], given its
/// path) and its selected Common ([common]).
///
/// The Common is laid over the ferial base — with [overlayCommon] for a
/// memorial, which takes only some of its parts, with [overlay] otherwise —
/// then the proper over everything with [overlay]: a memorial's own
/// psalmody must win when present. [beforeOverlays] lets an office adjust
/// the ferial base first when a celebration replaces the ferial day.
///
/// Returns the office and the proper layer on its own.
Future<({T office, T proper})> composeOffice<T>(
  CelebrationContext context, {
  required T Function() empty,
  required Future<T> Function() ferial,
  required Future<T> Function(String path) proper,
  required Future<T> Function() common,
  required void Function(T base, T layer) overlay,
  required void Function(T base, T common) overlayCommon,
  void Function(T base)? beforeOverlays,
}) async {
  final (base, properLayer, commonLayer) = await (
    context.hasFerialBase ? ferial() : Future.value(empty()),
    context.hasProper
        ? celebrationFilePath(context.celebrationCode, context.dataLoader)
            .then(proper)
        : Future.value(empty()),
    context.hasSelectedCommon ? common() : Future<T?>.value(null),
  ).wait;

  if (context.hasProper) beforeOverlays?.call(base);
  if (commonLayer != null) {
    if (context.isMemorial) {
      overlayCommon(base, commonLayer);
    } else {
      overlay(base, commonLayer);
    }
  }
  overlay(base, properLayer);
  return (office: base, proper: properLayer);
}

/// [composeOffice] for a major hour (Lauds or Vespers): memorials and feasts
/// keep the season's hymns selectable after their own, and the day's
/// year-cycle antiphons (Sundays of Ordinary Time) belong to that day's own
/// office only, never to a celebration replacing it (First Vespers
/// included).
Future<T> composeHourPrayer<T extends HourPrayer>(
  CelebrationContext context, {
  required T Function() empty,
  required Future<T> Function() ferial,
  required Future<T> Function(String path) proper,
  required Future<T> Function() common,
}) async {
  final (office: office, proper: _) = await composeOffice<T>(
    context,
    empty: empty,
    ferial: ferial,
    proper: proper,
    common: common,
    overlay: (base, layer) =>
        base.overlayWith(layer, keepBaseHymns: context.keepsSeasonHymns),
    overlayCommon: (base, common) => base.overlayWithCommon(common),
    beforeOverlays: (base) => base.evangelicAntiphon =
        withoutYearCycleAntiphons(base.evangelicAntiphon),
  );
  return office;
}
