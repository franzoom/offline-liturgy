import 'office_elements_class.dart';

/// Class representing the Middle of Day Prayer (Tierce, Sexte, None) structure
class MiddleOfDay {
  Celebration? celebration;
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
    this.celebration,
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
      final hymns = HymnEntry.fromCodes(asYamlList(value));
      return hymns.isEmpty ? null : hymns;
    }

    final sharedHymns = parseHymns(data['hymn']);
    List<HymnEntry>? hourHymns(String hour) {
      final hourData = data[hour];
      return (hourData is Map ? parseHymns(hourData['hymn']) : null) ??
          sharedHymns;
    }

    return MiddleOfDay(
      celebration: data['celebration'] is Map<String, dynamic>
          ? Celebration.fromJson(data['celebration'] as Map<String, dynamic>)
          : null,
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
    if (overlay.celebration != null) celebration = overlay.celebration;

    psalmody = mergePsalmody(psalmody, overlay.psalmody);

    if (overlay.hymnTierce != null) hymnTierce = overlay.hymnTierce;
    if (overlay.hymnSexte != null) hymnSexte = overlay.hymnSexte;
    if (overlay.hymnNone != null) hymnNone = overlay.hymnNone;

    if (overlay.tierce != null) {
      if (tierce == null) {
        tierce = overlay.tierce;
      } else {
        tierce!.overlayWith(overlay.tierce!);
      }
    }
    if (overlay.sexte != null) {
      if (sexte == null) {
        sexte = overlay.sexte;
      } else {
        sexte!.overlayWith(overlay.sexte!);
      }
    }
    if (overlay.none != null) {
      if (none == null) {
        none = overlay.none;
      } else {
        none!.overlayWith(overlay.none!);
      }
    }

    if (overlay.oration != null) oration = overlay.oration;
  }

  /// Selective overlay for Common elements (Precedence > 6)
  void overlayWithCommon(MiddleOfDay common) {
    if (common.tierce != null) {
      if (tierce == null) {
        tierce = common.tierce;
      } else {
        tierce!.overlayWith(common.tierce!);
      }
    }
    if (common.sexte != null) {
      if (sexte == null) {
        sexte = common.sexte;
      } else {
        sexte!.overlayWith(common.sexte!);
      }
    }
    if (common.none != null) {
      if (none == null) {
        none = common.none;
      } else {
        none!.overlayWith(common.none!);
      }
    }
    if (common.oration != null) oration = common.oration;
  }

  bool get isEmpty =>
      celebration == null &&
      psalmody == null &&
      psalmodyTierce == null &&
      psalmodySexte == null &&
      psalmodyNone == null &&
      hymnTierce == null &&
      hymnSexte == null &&
      hymnNone == null &&
      tierce == null &&
      sexte == null &&
      none == null &&
      oration == null;
}
