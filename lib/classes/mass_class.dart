/// Classes for the Mass (Eucharistic celebration) structure
library;

/// Antiphon with optional biblical reference and text content.
/// Used for both entrance antiphon and communion antiphon.
class MassAntiphon {
  final String? biblicalReference;
  final String? content;

  const MassAntiphon({this.biblicalReference, this.content});

  factory MassAntiphon.fromJson(Map<String, dynamic> json) => MassAntiphon(
        biblicalReference: json['biblicalReference']?.toString(),
        content: json['content']?.toString(),
      );
}

/// One chorus entry in a psalm or canticle (refrain + its reference).
class MassChorusEntry {
  final String? chorusRef;
  final String? chorus;

  const MassChorusEntry({this.chorusRef, this.chorus});

  factory MassChorusEntry.fromJson(Map<String, dynamic> json) =>
      MassChorusEntry(
        chorusRef: json['chorusRef']?.toString(),
        chorus: json['chorus']?.toString(),
      );
}

/// Sealed base class for the content of a reading part.
/// Subtype is determined by the partType field of [MassReadingPart].
sealed class MassReadingContent {}

/// Content for READING and EPISTLE parts.
class MassReading extends MassReadingContent {
  final String? biblicalRef;
  final List<String>? cycle;
  final String? headline;
  final String? content;
  final String? shortReadingRef;
  final String? shortReadingContent;

  MassReading({
    this.biblicalRef,
    this.cycle,
    this.headline,
    this.content,
    this.shortReadingRef,
    this.shortReadingContent,
  });

  factory MassReading.fromJson(Map<String, dynamic> json) => MassReading(
        biblicalRef: json['biblicalRef']?.toString(),
        cycle: (json['cycle'] as List?)?.map((e) => e.toString()).toList(),
        headline: json['headline']?.toString(),
        content: json['content']?.toString(),
        shortReadingRef: json['shortReadingRef']?.toString(),
        shortReadingContent: json['shortReadingContent']?.toString(),
      );
}

/// Content for PSALM and CANTICLE parts.
class MassPsalm extends MassReadingContent {
  final String? biblicalRef;
  final String? refAbbr;
  final List<String>? cycle;
  final List<MassChorusEntry>? chorus;
  final String? content;

  MassPsalm({
    this.biblicalRef,
    this.refAbbr,
    this.cycle,
    this.chorus,
    this.content,
  });

  factory MassPsalm.fromJson(Map<String, dynamic> json) => MassPsalm(
        biblicalRef: json['biblicalRef']?.toString(),
        refAbbr: json['refAbbr']?.toString(),
        cycle: (json['cycle'] as List?)?.map((e) => e.toString()).toList(),
        chorus: (json['chorus'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map((e) => MassChorusEntry.fromJson(e))
            .toList(),
        content: json['content']?.toString(),
      );
}

/// Content for the GOSPEL part.
class MassGospel extends MassReadingContent {
  final String? biblicalRef;
  final List<String>? cycle;
  final String? headline;
  final String? beforeAcclamationAntiphon;
  final String? acclamationAntiphon;
  final String? acclamationAntiphonReference;
  final String? afterAcclamationAntiphon;
  final String? content;
  // Optional short form (e.g. the Passion narrative's forme brève), with its
  // own biblical reference since the verse range usually differs from content.
  final String? shortBiblicalRef;
  final String? shortContent;

  MassGospel({
    this.biblicalRef,
    this.cycle,
    this.headline,
    this.beforeAcclamationAntiphon,
    this.acclamationAntiphon,
    this.acclamationAntiphonReference,
    this.afterAcclamationAntiphon,
    this.content,
    this.shortBiblicalRef,
    this.shortContent,
  });

  factory MassGospel.fromJson(Map<String, dynamic> json) => MassGospel(
        biblicalRef: json['biblicalRef']?.toString(),
        cycle: (json['cycle'] as List?)?.map((e) => e.toString()).toList(),
        headline: json['headline']?.toString(),
        beforeAcclamationAntiphon:
            json['beforeAcclamationAntiphon']?.toString(),
        acclamationAntiphon: json['acclamationAntiphon']?.toString(),
        acclamationAntiphonReference:
            json['acclamationAntiphonReference']?.toString(),
        afterAcclamationAntiphon: json['afterAcclamationAntiphon']?.toString(),
        content: json['content']?.toString(),
        shortBiblicalRef: json['shortBiblicalRef']?.toString(),
        shortContent: json['shortContent']?.toString(),
      );
}

/// One section of the Liturgy of the Word.
/// The partType determines the concrete subtype of each [MassReadingContent].
class MassReadingPart {
  final String partType;
  final List<MassReadingContent> partContents;

  MassReadingPart({required this.partType, required this.partContents});

  factory MassReadingPart.fromJson(Map<String, dynamic> json) {
    final partType = json['partType']?.toString() ?? '';
    final rawContents = (json['partContents'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        [];

    final List<MassReadingContent> contents;
    switch (partType) {
      case 'PSALM':
      case 'CANTICLE':
        contents = rawContents.map((e) => MassPsalm.fromJson(e)).toList();
      case 'GOSPEL':
        contents = rawContents.map((e) => MassGospel.fromJson(e)).toList();
      default: // READING, EPISTLE
        contents = rawContents.map((e) => MassReading.fromJson(e)).toList();
    }

    return MassReadingPart(partType: partType, partContents: contents);
  }
}

/// A single Mass (e.g. vigil mass, day mass).
class Mass {
  String? massType;
  String? name;
  String? note;
  List<MassAntiphon>? entranceAntiphon;
  List<String>? collect;
  List<MassReadingPart>? readingParts;
  List<String>? offeringPrayer;
  List<String>? prefaceList;
  List<MassAntiphon>? communionAntiphon;
  List<String>? prayerAfterCommunion;
  List<String>? solemnBlessingList;

  Mass({
    this.massType,
    this.name,
    this.note,
    this.entranceAntiphon,
    this.collect,
    this.readingParts,
    this.offeringPrayer,
    this.prefaceList,
    this.communionAntiphon,
    this.prayerAfterCommunion,
    this.solemnBlessingList,
  });

  factory Mass.fromJson(Map<String, dynamic> json) {
    return Mass(
      massType: json['massType']?.toString(),
      name: json['name']?.toString(),
      note: json['note']?.toString(),
      entranceAntiphon: (json['entranceAntiphon'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map((e) => MassAntiphon.fromJson(e))
          .toList(),
      collect: (json['collect'] as List?)?.map((e) => e.toString()).toList(),
      readingParts: (json['readingParts'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map((e) => MassReadingPart.fromJson(e))
          .toList(),
      offeringPrayer:
          (json['offeringPrayer'] as List?)?.map((e) => e.toString()).toList(),
      prefaceList:
          (json['prefaceList'] as List?)?.map((e) => e.toString()).toList(),
      communionAntiphon: (json['communionAntiphon'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map((e) => MassAntiphon.fromJson(e))
          .toList(),
      prayerAfterCommunion: (json['prayerAfterCommunion'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      solemnBlessingList: (json['solemnBlessingList'] as List?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  /// Overlays this Mass instance with data from another instance.
  /// All fields are replaced wholesale if the overlay provides them.
  /// readingParts is replaced as a whole rather than merged part-by-part:
  /// some days (Sundays, the Easter Vigil) have several entries sharing the
  /// same partType (e.g. two READING entries), and every mass: block in the
  /// data is already a complete, self-contained Liturgy of the Word, so a
  /// partType-keyed merge would silently collapse those repeated entries.
  void overlayWith(Mass overlay) {
    if (overlay.massType != null) massType = overlay.massType;
    if (overlay.name != null) name = overlay.name;
    if (overlay.note != null) note = overlay.note;
    if (overlay.entranceAntiphon != null)
      entranceAntiphon = overlay.entranceAntiphon;
    if (overlay.collect != null) collect = overlay.collect;
    if (overlay.readingParts != null && overlay.readingParts!.isNotEmpty) {
      readingParts = overlay.readingParts;
    }
    if (overlay.offeringPrayer != null) offeringPrayer = overlay.offeringPrayer;
    if (overlay.prefaceList != null) prefaceList = overlay.prefaceList;
    if (overlay.communionAntiphon != null)
      communionAntiphon = overlay.communionAntiphon;
    if (overlay.prayerAfterCommunion != null)
      prayerAfterCommunion = overlay.prayerAfterCommunion;
    if (overlay.solemnBlessingList != null)
      solemnBlessingList = overlay.solemnBlessingList;
  }

  /// Fills the 5 Sunday-inherited fields (entrance/communion antiphons and
  /// the 3 orations) from [sunday], only where this Mass doesn't already
  /// have its own value. readingParts stays day-specific and is untouched —
  /// Ordinary Time weekdays share the Sunday's antiphons/orations but keep
  /// their own daily lectionary reading.
  void fillFromSunday(Mass sunday) {
    entranceAntiphon ??= sunday.entranceAntiphon;
    collect ??= sunday.collect;
    offeringPrayer ??= sunday.offeringPrayer;
    communionAntiphon ??= sunday.communionAntiphon;
    prayerAfterCommunion ??= sunday.prayerAfterCommunion;
  }

  /// Selective overlay for Common of Saints Mass texts (no such data exists
  /// yet, added for parity with the other office classes' overlayWithCommon).
  /// readingParts is NOT taken from the common — same rationale as
  /// Readings.overlayWithCommon: the ferial/proper Liturgy of the Word is
  /// kept unless the celebration's own YAML supplies it.
  void overlayWithCommon(Mass common) {
    if (common.entranceAntiphon != null)
      entranceAntiphon = common.entranceAntiphon;
    if (common.collect != null) collect = common.collect;
    if (common.offeringPrayer != null) offeringPrayer = common.offeringPrayer;
    if (common.prefaceList != null) prefaceList = common.prefaceList;
    if (common.communionAntiphon != null)
      communionAntiphon = common.communionAntiphon;
    if (common.prayerAfterCommunion != null)
      prayerAfterCommunion = common.prayerAfterCommunion;
    if (common.solemnBlessingList != null)
      solemnBlessingList = common.solemnBlessingList;
  }

  bool get isEmpty =>
      massType == null &&
      name == null &&
      note == null &&
      (entranceAntiphon == null || entranceAntiphon!.isEmpty) &&
      (collect == null || collect!.isEmpty) &&
      (readingParts == null || readingParts!.isEmpty) &&
      (offeringPrayer == null || offeringPrayer!.isEmpty) &&
      (prefaceList == null || prefaceList!.isEmpty) &&
      (communionAntiphon == null || communionAntiphon!.isEmpty) &&
      (prayerAfterCommunion == null || prayerAfterCommunion!.isEmpty) &&
      (solemnBlessingList == null || solemnBlessingList!.isEmpty);
}

/// Container for all Mass types of a given liturgical day.
class Masses {
  List<Mass>? masses;

  Masses({this.masses});

  factory Masses.fromJson(Map<String, dynamic> json) {
    return Masses(
      masses: (json['mass'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map((e) => Mass.fromJson(e))
          .toList(),
    );
  }

  /// Merges overlay Mass objects into this Masses by matching on massType.
  /// Existing massTypes are overlaid via Mass.overlayWith; massTypes present
  /// in overlay but not in this Masses are appended.
  void overlayWith(Masses overlay) {
    if (overlay.masses == null || overlay.masses!.isEmpty) return;
    masses ??= [];
    for (final overlayMass in overlay.masses!) {
      final index =
          masses!.indexWhere((m) => m.massType == overlayMass.massType);
      if (index >= 0) {
        masses![index].overlayWith(overlayMass);
      } else {
        masses!.add(overlayMass);
      }
    }
  }

  /// Selective overlay for Common of Saints Mass texts: only enriches
  /// massTypes already selected for the day, it never introduces a new
  /// mass type from the common.
  void overlayWithCommon(Masses common) {
    if (common.masses == null || common.masses!.isEmpty || masses == null) {
      return;
    }
    for (final commonMass in common.masses!) {
      final index =
          masses!.indexWhere((m) => m.massType == commonMass.massType);
      if (index >= 0) {
        masses![index].overlayWithCommon(commonMass);
      }
    }
  }

  /// Fills Sunday-inherited fields on each already-selected massType from
  /// [sunday] (see Mass.fillFromSunday). Never introduces a new mass type
  /// from the Sunday — weekdays don't have a vigil_mass to match against.
  void fillFromSunday(Masses sunday) {
    if (sunday.masses == null || sunday.masses!.isEmpty || masses == null) {
      return;
    }
    for (final sundayMass in sunday.masses!) {
      final index =
          masses!.indexWhere((m) => m.massType == sundayMass.massType);
      if (index >= 0) {
        masses![index].fillFromSunday(sundayMass);
      }
    }
  }

  bool get isEmpty => masses == null || masses!.isEmpty;
}
