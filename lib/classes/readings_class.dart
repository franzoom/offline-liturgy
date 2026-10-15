import 'office_elements_class.dart';
import 'hymns_class.dart';

/// Class representing the Office of Readings (Leçons) structure
class Readings {
  List<HymnEntry>? hymn;
  List<PsalmEntry>? psalmody;
  List<BiblicalReading>? biblicalReading;
  List<PatristicReading>? patristicReading;
  Hymns? teDeum;
  String? verse;
  List<String>? oration;

  Readings({
    this.hymn,
    this.psalmody,
    this.biblicalReading,
    this.patristicReading,
    this.teDeum,
    this.verse,
    this.oration,
  });

  /// Creates Readings instance from YAML data with robust type safety.
  /// [year] is the liturgical year ('A', 'B', or 'C') used to select
  /// year-specific patristic readings (keys 'patristicReadingA/B/C').
  /// [biblicalCycle] ('Even' or 'Odd') selects the two-year cycle biblical
  /// reading (keys 'biblicalReadingEven/Odd'), falling back to the annual
  /// 'biblicalReading' when the variant is missing. A variant without a
  /// responsory of its own takes the one of the annual reading.
  factory Readings.fromJson(Map<String, dynamic> data,
      {String? year, String? biblicalCycle}) {
    // Helper to parse readings which can be either a single Map or a List of Maps
    List<T>? parseReadings<T>(
        dynamic jsonValue, T Function(Map<String, dynamic>) fromJson) {
      if (jsonValue == null) return null;
      if (jsonValue is List) {
        return jsonValue
            .whereType<Map<String, dynamic>>()
            .map((e) => fromJson(e))
            .toList();
      }
      if (jsonValue is Map<String, dynamic>) {
        return [fromJson(jsonValue)];
      }
      return null;
    }

    final annual =
        parseReadings(data['biblicalReading'], BiblicalReading.fromJson);
    final variant = biblicalCycle == null
        ? null
        : parseReadings(
            data['biblicalReading$biblicalCycle'], BiblicalReading.fromJson);

    return Readings(
      hymn: HymnEntry.listFrom(data['hymn']),
      psalmody: asYamlList(data['psalmody'])
          ?.whereType<Map<String, dynamic>>()
          .map((e) => PsalmEntry.fromJson(e))
          .toList(),
      biblicalReading: variant == null
          ? annual
          : [
              for (final r in variant)
                r.copyWith(
                    responsory:
                        r.responsory ?? annual?.firstOrNull?.responsory),
            ],
      patristicReading: parseReadings(
          year != null
              ? (data['patristicReading$year'] ?? data['patristicReading'])
              : data['patristicReading'],
          PatristicReading.fromJson),
      verse: data['verse']?.toString(),
      oration: asTextList(data['oration']),
    );
  }

  /// Overlays this Readings instance with data from another instance
  /// With [keepBaseHymns] (memorials and feasts), the overlay's hymns come
  /// first and the current ones stay selectable after them; otherwise the
  /// overlay's hymns replace them.
  void overlayWith(Readings overlay, {bool keepBaseHymns = false}) {
    hymn = overlayHymns(hymn, overlay.hymn, keepBaseHymns: keepBaseHymns);

    psalmody = mergePsalmody(psalmody, overlay.psalmody);

    if (overlay.biblicalReading != null) {
      biblicalReading = overlay.biblicalReading;
    }
    if (overlay.patristicReading != null) {
      patristicReading = overlay.patristicReading;
    }
    if (overlay.teDeum != null) teDeum = overlay.teDeum;
    if (overlay.verse != null) verse = overlay.verse;
    if (overlay.oration != null) oration = overlay.oration;
  }

  /// Selective overlay for common (Precedence > 6)
  /// Includes Hymn and Verse to allow "coloring" the office for Memories.
  /// Biblical reading is NOT taken from the common: for a memoria, the ferial
  /// reading is kept by default; only the memoria's own YAML can override it.
  void overlayWithCommon(Readings common) {
    // Memorials only: the Common's hymns first, the season's ones after
    hymn = mergeHymns(hymn, common.hymn);
    if (common.verse != null) verse = common.verse;
    if (common.patristicReading != null) {
      patristicReading = common.patristicReading;
    }
    if (common.oration != null) oration = common.oration;
  }
}
