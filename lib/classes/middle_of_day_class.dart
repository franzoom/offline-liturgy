import 'office_elements_class.dart';

/// Class representing the Middle of Day Prayer (Tierce, Sexte, None) structure
class MiddleOfDay {
  List<PsalmEntry>? psalmody; // shared psalms (same for all three hours)
  List<PsalmEntry>?
      psalmodyTierce; // gradual psalms for tierce (solemnity weekday)
  List<PsalmEntry>?
      psalmodySexte; // gradual psalms for sexte (solemnity weekday)
  List<PsalmEntry>? psalmodyNone; // gradual psalms for none (solemnity weekday)
  List<HymnEntry>? hymnTierce;
  List<HymnEntry>? hymnSexte;
  List<HymnEntry>? hymnNone;
  HourOffice? tierce;
  HourOffice? sexte;
  HourOffice? none;
  List<String>? oration;

  MiddleOfDay({
    this.psalmody,
    this.psalmodyTierce,
    this.psalmodySexte,
    this.psalmodyNone,
    this.hymnTierce,
    this.hymnSexte,
    this.hymnNone,
    this.tierce,
    this.sexte,
    this.none,
    this.oration,
  });

  /// Creates MiddleOfDay instance from dynamic data (YAML/JSON) with type safety.
  /// Hymns: `hymn` at the middleOfDay level applies to all three hours; a
  /// `hymn` inside tierce/sexte/none overrides it for that hour only.
  factory MiddleOfDay.fromJson(Map<String, dynamic> data) {
    List<HymnEntry>? parseHymns(dynamic value) {
      final hymns = HymnEntry.listFrom(value);
      return (hymns?.isEmpty ?? true) ? null : hymns;
    }

    final sharedHymns = parseHymns(data['hymn']);
    List<HymnEntry>? hourHymns(String hour) {
      final hourData = data[hour];
      return (hourData is Map ? parseHymns(hourData['hymn']) : null) ??
          sharedHymns;
    }

    return MiddleOfDay(
      psalmody: asYamlList(data['psalmody'])
          ?.whereType<Map<String, dynamic>>()
          .map((e) => PsalmEntry.fromJson(e))
          .toList(),
      hymnTierce: hourHymns('tierce'),
      hymnSexte: hourHymns('sexte'),
      hymnNone: hourHymns('none'),
      tierce: data['tierce'] is Map<String, dynamic>
          ? HourOffice.fromJson(data['tierce'] as Map<String, dynamic>)
          : null,
      sexte: data['sexte'] is Map<String, dynamic>
          ? HourOffice.fromJson(data['sexte'] as Map<String, dynamic>)
          : null,
      none: data['none'] is Map<String, dynamic>
          ? HourOffice.fromJson(data['none'] as Map<String, dynamic>)
          : null,
      oration: asTextList(data['oration']),
    );
  }

  /// Overlays this MiddleOfDay instance with data from another instance
  void overlayWith(MiddleOfDay overlay) {
    psalmody = mergePsalmody(psalmody, overlay.psalmody);

    if (overlay.hymnTierce != null) hymnTierce = overlay.hymnTierce;
    if (overlay.hymnSexte != null) hymnSexte = overlay.hymnSexte;
    if (overlay.hymnNone != null) hymnNone = overlay.hymnNone;

    tierce = _overlayHour(tierce, overlay.tierce);
    sexte = _overlayHour(sexte, overlay.sexte);
    none = _overlayHour(none, overlay.none);

    if (overlay.oration != null) oration = overlay.oration;
  }

  /// Removes the psalms and antiphons, shared and of each hour.
  void dropPsalmody() {
    psalmody = null;
    for (final hour in [tierce, sexte, none]) {
      hour?.antiphon = null;
      hour?.psalmody = null;
    }
  }

  /// Selective overlay for Common elements (Precedence > 6)
  void overlayWithCommon(MiddleOfDay common) {
    tierce = _overlayHour(tierce, common.tierce);
    sexte = _overlayHour(sexte, common.sexte);
    none = _overlayHour(none, common.none);
    if (common.oration != null) oration = common.oration;
  }

  /// [overlay] laid over [base], field by field, or whichever exists.
  static HourOffice? _overlayHour(HourOffice? base, HourOffice? overlay) {
    if (base == null || overlay == null) return base ?? overlay;
    return base..overlayWith(overlay);
  }
}
