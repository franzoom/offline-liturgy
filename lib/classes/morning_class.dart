import 'office_structures.dart';

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

  /// Creates Morning instance directly from MorningOffice JSON structure
  factory Morning.fromMorningOffice(MorningOffice morningOffice) {
    return Morning(
      invitatory:
          null, // Will need to be set separately from invitatory section
      hymn: morningOffice.hymn,
      psalmody: morningOffice.psalmody,
      reading: morningOffice.reading,
      responsory: morningOffice.responsory,
      evangelicAntiphon: morningOffice.evangelicAntiphon,
      intercession: morningOffice.intercession,
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

  Map<String, dynamic> toJson() {
    return {
      if (celebration != null) 'celebration': celebration!.toJson(),
      if (invitatory != null) 'invitatory': invitatory!.toJson(),
      if (hymn != null) 'hymn': hymn,
      if (psalmody != null)
        'psalmody': psalmody!.map((entry) => entry.toJson()).toList(),
      if (reading != null) 'reading': reading!.toJson(),
      if (responsory != null) 'responsory': responsory,
      if (evangelicAntiphon != null)
        'evangelicAntiphon': evangelicAntiphon!.toJson(),
      if (intercession != null) 'intercession': intercession!.toJson(),
      if (oration != null) 'oration': oration,
    };
  }
}
