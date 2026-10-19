import 'office_elements_class.dart';
import 'psalms_class.dart';

/// Structure shared by the major hours, Lauds ([Morning]) and Vespers.
class HourPrayer {
  List<HymnEntry>? hymn;
  List<PsalmEntry>? psalmody;
  Reading? reading;
  String? responsory;
  Map<String, List<String>>? evangelicAntiphon;
  Psalm? evangelicCanticle;
  Intercession? intercession;
  List<String>? oration;
  List<String>? canticleSvgData;

  HourPrayer({
    this.hymn,
    this.psalmody,
    this.reading,
    this.responsory,
    this.evangelicAntiphon,
    this.evangelicCanticle,
    this.intercession,
    this.oration,
    this.canticleSvgData,
  });

  /// Reads the hour's section of a YAML file.
  HourPrayer.fromJson(Map<String, dynamic> data)
      : hymn = HymnEntry.listFrom(data['hymn']),
        psalmody = asYamlList(data['psalmody'])
            ?.whereType<Map<String, dynamic>>()
            .map((e) => PsalmEntry.fromJson(e))
            .toList(),
        reading = data['reading'] is Map<String, dynamic>
            ? Reading.fromJson(data['reading'] as Map<String, dynamic>)
            : null,
        responsory = data['responsory']?.toString(),
        evangelicAntiphon = parseEvangelicAntiphon(data['evangelicAntiphon']),
        intercession = data['intercession'] is Map<String, dynamic>
            ? Intercession.fromJson(
                data['intercession'] as Map<String, dynamic>)
            : null,
        oration = asTextList(data['oration']);

  /// Overlays this hour with data from another instance.
  /// With [keepBaseHymns] (memorials and feasts), the overlay's hymns come
  /// first and the current ones stay selectable after them; otherwise the
  /// overlay's hymns replace them.
  void overlayWith(covariant HourPrayer overlay, {bool keepBaseHymns = false}) {
    hymn = overlayHymns(hymn, overlay.hymn, keepBaseHymns: keepBaseHymns);

    psalmody = mergePsalmody(psalmody, overlay.psalmody);

    if (overlay.reading != null) reading = overlay.reading;
    if (overlay.responsory != null) responsory = overlay.responsory;
    evangelicAntiphon =
        mergeEvangelicAntiphons(evangelicAntiphon, overlay.evangelicAntiphon);
    if (overlay.intercession != null) intercession = overlay.intercession;
    if (overlay.oration != null) oration = overlay.oration;
  }

  /// Selective overlay for a memorial's Common: no celebration nor
  /// psalmody, and the Common's hymns first, the season's ones after.
  void overlayWithCommon(covariant HourPrayer common) {
    hymn = mergeHymns(hymn, common.hymn);
    if (common.reading != null) reading = common.reading;
    if (common.responsory != null) responsory = common.responsory;
    evangelicAntiphon =
        _ferialAndCommonAntiphons(evangelicAntiphon, common.evangelicAntiphon);
    if (common.intercession != null) intercession = common.intercession;
    if (common.oration != null) oration = common.oration;
  }

  /// A memorial with no evangelic antiphon of its own says, at choice, the
  /// weekday's or the Common's (PGLH 119): both are offered, the weekday's
  /// first, each introduced by its origin. A memorial's own antiphon, laid
  /// over them afterwards (proper layer), replaces them both.
  static Map<String, List<String>>? _ferialAndCommonAntiphons(
      Map<String, List<String>>? ferial, Map<String, List<String>>? common) {
    final ferialAntiphons = ferial?['antiphon'];
    final commonAntiphons = common?['antiphon'];
    if (ferialAntiphons == null || commonAntiphons == null) {
      return mergeEvangelicAntiphons(ferial, common);
    }
    return {
      ...ferial!,
      'antiphon': [
        for (final a in ferialAntiphons) '$_ferialAntiphonLabel $a',
        for (final a in commonAntiphons) '$_commonAntiphonLabel $a',
      ],
    };
  }

  static const _ferialAntiphonLabel = '%(antienne de la férie :)%';
  static const _commonAntiphonLabel = '%(antienne du commun :)%';
}
