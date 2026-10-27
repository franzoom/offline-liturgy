import '../classes/hour_prayer_class.dart';
import '../classes/office_elements_class.dart';
import '../classes/psalms_class.dart';
import '../tools/celebration_index.dart';
import '../tools/date_tools.dart';
import '../tools/paschal_antiphon.dart';
import '../tools/resolve_office_content.dart';

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
        ? celebrationFilePath(context.properCode, context.dataLoader)
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

/// Completes a major hour once its layers are composed: hydrates its texts
/// (and Lauds' [invitatory]) while the score of its evangelic canticle
/// ([canticleSvgCode], e.g. 'NT_2') loads, keeps the evangelic antiphons of
/// the liturgical year — not the civil one, which differs from the 1st
/// Sunday of Advent to Dec 31 —, adds the paschal alléluia and sets the
/// evangelic [canticle].
Future<void> completeHourPrayer(
  HourPrayer office,
  CelebrationContext context, {
  required Psalm canticle,
  required String canticleSvgCode,
  Invitatory? invitatory,
}) async {
  final liturgicalTime = context.liturgicalTime ?? '';
  final svgSource = context.svgSource;
  final (_, canticleSvg) = await (
    resolveOfficeContent(
      psalmody: office.psalmody,
      invitatory: invitatory,
      hymns: office.hymn,
      dataLoader: context.dataLoader,
      showImprecatoryVerses: context.showImprecatoryVerses,
      svgSource: svgSource,
    ),
    svgSource == null
        ? Future.value('')
        : context.dataLoader.load('svg/$svgSource/$canticleSvgCode.svg'),
  ).wait;

  office.evangelicAntiphon = filterEvangelicAntiphon(
      office.evangelicAntiphon, context.effectiveLiturgicalYear);
  applyPaschalToList(invitatory?.antiphon, liturgicalTime);
  applyPaschalToPsalmody(office.psalmody, liturgicalTime);
  office.evangelicAntiphon =
      applyPaschalToAntiphonMap(office.evangelicAntiphon, liturgicalTime);
  office.evangelicCanticle = canticle;
  if (canticleSvg.isNotEmpty) office.canticleSvgData = [canticleSvg];
}

/// Extracts every file of [paths] in parallel with [extract], then overlays
/// them in order onto the first one, which is returned.
Future<T> composeLayers<T>(
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

/// [offices] (an office's detected celebrations) with commonMakesDifference
/// set for each celebrated saint with Commons: whether one of its Commons
/// [supplies] a text its [proper] layer lacks, as a memorial's or a feast's
/// Common (e.g. HourPrayer.suppliesTextsMissingFrom), each Common loaded by
/// [common].
Future<Map<String, CelebrationContext>> withCommonDifference<T>(
  Map<String, CelebrationContext> offices, {
  required Future<T> Function(CelebrationContext c, String path) proper,
  required Future<T> Function(CelebrationContext c) common,
  required bool Function(T common, T proper, {required bool memorial}) supplies,
}) async {
  Future<CelebrationContext> withDifference(CelebrationContext c) async {
    final commons = c.commonList ?? const [];
    if (!c.hasProper || commons.isEmpty) return c;
    final properLayer =
        await proper(c, await celebrationFilePath(c.properCode, c.dataLoader));
    final commonLayers = await Future.wait(
        commons.map((code) => common(c.copyWith(commonList: [code]))));
    return c.copyWith(
      commonMakesDifference: commonLayers
          .any((layer) => supplies(layer, properLayer, memorial: c.isMemorial)),
    );
  }

  final contexts = await Future.wait(offices.values.map(withDifference));
  return Map.fromIterables(offices.keys, contexts);
}
