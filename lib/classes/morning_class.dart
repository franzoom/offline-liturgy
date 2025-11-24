import 'office_elements_class.dart';

/// Class representing the Morning Prayer (Laudes) structure
class Morning {
  Celebration? celebration;
  Invitatory? invitatory;
  List<String>? hymn;
  List<PsalmEntry>? psalmody;
  Reading? reading;
  String? responsory;
  EvangelicAntiphon? evangelicAntiphon;
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

  /// Creates Morning instance from JSON data
  factory Morning.fromJson(Map<String, dynamic> json) {
    return Morning(
      celebration: json['celebration'] != null
          ? Celebration.fromJson(json['celebration'] as Map<String, dynamic>)
          : null,
      invitatory: json['invitatory'] != null
          ? Invitatory.fromJson(json['invitatory'] as Map<String, dynamic>)
          : null,
      hymn: json['hymn'] != null ? List<String>.from(json['hymn']) : null,
      psalmody: json['psalmody'] != null
          ? (json['psalmody'] as List)
              .map((e) => PsalmEntry.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      reading: json['reading'] != null
          ? Reading.fromJson(json['reading'] as Map<String, dynamic>)
          : null,
      responsory: json['responsory'] as String?,
      evangelicAntiphon: json['evangelicAntiphon'] != null
          ? EvangelicAntiphon.fromJson(
              json['evangelicAntiphon'] as Map<String, dynamic>)
          : null,
      intercession: json['intercession'] != null
          ? Intercession.fromJson(json['intercession'] as Map<String, dynamic>)
          : null,
      oration:
          json['oration'] != null ? List<String>.from(json['oration']) : null,
    );
  }

  /// Overlays this Morning instance with data from another Morning instance
  /// Non-null fields from the overlay take precedence
  void overlayWith(Morning overlay) {
    if (overlay.celebration != null) {
      celebration = overlay.celebration;
    }
    if (overlay.invitatory != null) {
      invitatory = overlay.invitatory;
    }
    if (overlay.hymn != null) {
      hymn = overlay.hymn;
    }
    if (overlay.psalmody != null) {
      psalmody = overlay.psalmody;
    }
    if (overlay.reading != null) {
      reading = overlay.reading;
    }
    if (overlay.responsory != null) {
      responsory = overlay.responsory;
    }
    if (overlay.evangelicAntiphon != null) {
      evangelicAntiphon = overlay.evangelicAntiphon;
    }
    if (overlay.intercession != null) {
      intercession = overlay.intercession;
    }
    if (overlay.oration != null) {
      oration = overlay.oration;
    }
  }
}
