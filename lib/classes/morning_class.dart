import 'office_elements_class.dart';

/// Class representing the Morning Prayer (Laudes) structure
class Morning {
  Celebration? celebration;
  Invitatory? invitatory;
  List<HymnEntry>? hymn;
  List<PsalmEntry>? psalmody;
  Reading? reading;
  String? responsory;
  Map<String, String>? evangelicAntiphon;
  Intercession? intercession;
  List<String>? oration;

  Morning({
    this.celebration,
    this.invitatory,
    this.hymn,
    this.psalmody,
    this.reading,
    this.responsory,
    this.evangelicAntiphon,
    this.intercession,
    this.oration,
  });

  /// Creates Morning instance from dynamic data (JSON/YAML) with type safety
  factory Morning.fromJson(Map<String, dynamic> data) {
    return Morning(
      celebration: data['celebration'] is Map<String, dynamic>
          ? Celebration.fromJson(data['celebration'] as Map<String, dynamic>)
          : null,
      invitatory: data['invitatory'] is Map<String, dynamic>
          ? Invitatory.fromJson(data['invitatory'] as Map<String, dynamic>)
          : null,
      hymn: (data['hymn'] as List?)?.map((e) => HymnEntry.fromJson(e)).toList(),
      psalmody: (data['psalmody'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map((e) => PsalmEntry.fromJson(e))
          .toList(),
      reading: data['reading'] is Map<String, dynamic>
          ? Reading.fromJson(data['reading'] as Map<String, dynamic>)
          : null,
      responsory: data['responsory']?.toString(),
      evangelicAntiphon: parseEvangelicAntiphon(data['evangelicAntiphon']),
      intercession: data['intercession'] is Map<String, dynamic>
          ? Intercession.fromJson(data['intercession'] as Map<String, dynamic>)
          : null,
      oration: (data['oration'] as List?)?.map((e) => e.toString()).toList(),
    );
  }

  /// Overlays this Morning instance with data from another instance
  void overlayWith(Morning overlay) {
    if (overlay.celebration != null) celebration = overlay.celebration;
    if (overlay.invitatory != null) invitatory = overlay.invitatory;
    if (overlay.hymn != null) hymn = overlay.hymn;

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

    if (overlay.reading != null) reading = overlay.reading;
    if (overlay.responsory != null) responsory = overlay.responsory;
    if (overlay.evangelicAntiphon != null) {
      evangelicAntiphon = {
        ...evangelicAntiphon ?? {},
        ...overlay.evangelicAntiphon!,
      };
    }
    if (overlay.intercession != null) intercession = overlay.intercession;
    if (overlay.oration != null) oration = overlay.oration;
  }

  /// Selective overlay for Common elements (Precedence > 6)
  void overlayWithCommon(Morning common) {
    if (common.invitatory != null) invitatory = common.invitatory;
    if (common.hymn != null) hymn = common.hymn;
    if (common.reading != null) reading = common.reading;
    if (common.responsory != null) responsory = common.responsory;
    if (common.evangelicAntiphon != null) {
      evangelicAntiphon = {
        ...evangelicAntiphon ?? {},
        ...common.evangelicAntiphon!,
      };
    }
    if (common.intercession != null) intercession = common.intercession;
    if (common.oration != null) oration = common.oration;
  }

  bool get isEmpty =>
      celebration == null &&
      invitatory == null &&
      hymn == null &&
      psalmody == null &&
      reading == null &&
      responsory == null &&
      evangelicAntiphon == null &&
      intercession == null &&
      oration == null;
}
