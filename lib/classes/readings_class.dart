import 'office_elements_class.dart';

/// Class representing the Office of Readings (Leçons) structure
class Readings {
  Celebration? celebration;
  List<HymnEntry>? hymn;
  List<PsalmEntry>? psalmody;
  List<BiblicalReading>? biblicalReading;
  List<PatristicReading>? patristicReading;
  bool? tedeum;
  String? tedeumContent;
  String? verse;
  List<String>? oration;

  Readings({
    this.celebration,
    this.hymn,
    this.psalmody,
    this.biblicalReading,
    this.patristicReading,
    this.tedeum,
    this.tedeumContent,
    this.verse,
    this.oration,
  });

  /// Creates Readings instance from YAML data with robust type safety
  factory Readings.fromJson(Map<String, dynamic> data) {
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

    return Readings(
      celebration: data['celebration'] is Map<String, dynamic>
          ? Celebration.fromJson(data['celebration'] as Map<String, dynamic>)
          : null,
      hymn: (data['hymn'] as List?)?.map((e) => HymnEntry.fromJson(e)).toList(),
      psalmody: (data['psalmody'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map((e) => PsalmEntry.fromJson(e))
          .toList(),
      biblicalReading:
          parseReadings(data['biblicalReading'], BiblicalReading.fromJson),
      patristicReading:
          parseReadings(data['patristicReading'], PatristicReading.fromJson),
      tedeum: data['tedeum'] as bool?,
      verse: data['verse']?.toString(),
      oration: (data['oration'] as List?)?.map((e) => e.toString()).toList(),
    );
  }

  /// Overlays this Readings instance with data from another instance
  void overlayWith(Readings overlay) {
    if (overlay.celebration != null) celebration = overlay.celebration;
    if (overlay.hymn != null) hymn = overlay.hymn;

    // Smart merge of psalmody
    if (overlay.psalmody != null && overlay.psalmody!.isNotEmpty) {
      if (psalmody != null && psalmody!.isNotEmpty) {
        List<PsalmEntry> merged = [];
        for (int i = 0; i < overlay.psalmody!.length; i++) {
          final overlayEntry = overlay.psalmody![i];
          if (overlayEntry.psalm != null) {
            merged.add(overlayEntry);
          } else if (i < psalmody!.length) {
            merged.add(PsalmEntry(
              psalm: psalmody![i].psalm,
              antiphon: overlayEntry.antiphon ?? psalmody![i].antiphon,
            ));
          } else {
            merged.add(overlayEntry);
          }
        }
        psalmody = merged;
      } else {
        psalmody = overlay.psalmody;
      }
    }

    if (overlay.biblicalReading != null)
      biblicalReading = overlay.biblicalReading;
    if (overlay.patristicReading != null)
      patristicReading = overlay.patristicReading;
    if (overlay.tedeum != null) tedeum = overlay.tedeum;
    if (overlay.verse != null) verse = overlay.verse;
    if (overlay.oration != null) oration = overlay.oration;
  }

  /// Selective overlay for common (Precedence > 6)
  /// Includes Hymn and Verse to allow "coloring" the office for Memories
  void overlayWithCommon(Readings common) {
    if (common.hymn != null) hymn = common.hymn; // Added for precedence 12
    if (common.verse != null) verse = common.verse; // Added for precedence 12
    if (common.biblicalReading != null)
      biblicalReading = common.biblicalReading;
    if (common.patristicReading != null)
      patristicReading = common.patristicReading;
    if (common.oration != null) oration = common.oration;
  }

  bool get isEmpty =>
      celebration == null &&
      (hymn == null || hymn!.isEmpty) &&
      (psalmody == null || psalmody!.isEmpty) &&
      (biblicalReading == null || biblicalReading!.isEmpty) &&
      (patristicReading == null || patristicReading!.isEmpty) &&
      tedeum == null &&
      (verse == null || verse!.isEmpty) &&
      (oration == null || oration!.isEmpty);
}
