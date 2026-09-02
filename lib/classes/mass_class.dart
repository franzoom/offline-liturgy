/// Classes for the Mass (Eucharistic celebration) structure
library;

import 'office_elements_class.dart';

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

/// One single-key entry (description/PE1/PE2/PE3) of an
/// eucharistic_prayer_communicantes/*.yaml "library" file. Each file is a
/// YAML list where every item holds exactly one of these keys, rather than a
/// single map.
class EucharisticPrayerCommunicantes {
  final String? description;
  final String? pe1;
  final String? pe2;
  final String? pe3;

  const EucharisticPrayerCommunicantes({
    this.description,
    this.pe1,
    this.pe2,
    this.pe3,
  });

  factory EucharisticPrayerCommunicantes.fromJson(List<dynamic> json) {
    String? description;
    String? pe1;
    String? pe2;
    String? pe3;
    for (final entry in json) {
      if (entry is! Map) continue;
      description ??= entry['description']?.toString();
      pe1 ??= entry['PE1']?.toString();
      pe2 ??= entry['PE2']?.toString();
      pe3 ??= entry['PE3']?.toString();
    }
    return EucharisticPrayerCommunicantes(
      description: description,
      pe1: pe1,
      pe2: pe2,
      pe3: pe3,
    );
  }
}

/// The day's proper Communicantes insert for the Eucharistic Prayer,
/// referenced by code (e.g. "assumption", "sundays") and resolved like a
/// hymn -- see resolveOfficeContent. Its data holds all 3 variants
/// (PE1/PE2/PE3); the celebration UI picks the one matching whichever
/// Eucharistic Prayer was chosen.
class EucharisticPrayerCommunicantesEntry {
  final String code;
  EucharisticPrayerCommunicantes? data;

  EucharisticPrayerCommunicantesEntry({required this.code, this.data});

  factory EucharisticPrayerCommunicantesEntry.fromJson(dynamic json) =>
      EucharisticPrayerCommunicantesEntry(code: json.toString());
}

/// One preface text, as found in a mass_missal/prefaces/*.yaml file.
class Preface {
  final String? title;
  final String? subtitle;
  final String? note;
  final String? content;

  const Preface({this.title, this.subtitle, this.note, this.content});

  factory Preface.fromJson(Map<String, dynamic> json) => Preface(
        title: json['title']?.toString(),
        subtitle: json['subtitle']?.toString(),
        note: json['note']?.toString(),
        content: json['content']?.toString(),
      );
}

/// One of the possible prefaces for a Mass, referenced by code (e.g.
/// "the_blessed_virgin_mary_1") and resolved like a hymn -- see
/// resolveOfficeContent. A Mass can offer several alternative prefaces
/// (prefaceList), each resolved independently.
class PrefaceEntry {
  final String code;
  Preface? data;

  PrefaceEntry({required this.code, this.data});

  factory PrefaceEntry.fromJson(dynamic json) =>
      PrefaceEntry(code: json.toString());
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
  // Alternative prefaces for this Mass, referenced by code and resolved like
  // a hymn -- see PrefaceEntry.
  List<PrefaceEntry>? prefaceList;
  List<MassAntiphon>? communionAntiphon;
  List<String>? prayerAfterCommunion;
  List<String>? prayerOnThePeople;
  // Solemn blessing, referenced by code and resolved like a hymn (see
  // HymnEntry) -- loaded from mass_missal/blessings instead of hymns/.
  List<HymnEntry>? solemnBlessingList;
  // Proper sequence (e.g. Victimae Paschali Laudes, Veni Sancte Spiritus),
  // referenced by code and resolved like a hymn -- see HymnEntry.
  List<HymnEntry>? sequence;
  // Day's proper Communicantes insert for the Eucharistic Prayer, referenced
  // by code and resolved like a hymn -- see EucharisticPrayerCommunicantesEntry.
  EucharisticPrayerCommunicantesEntry? eucharisticPrayerCommunicantes;

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
    this.prayerOnThePeople,
    this.solemnBlessingList,
    this.sequence,
    this.eucharisticPrayerCommunicantes,
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
      prefaceList: (json['prefaceList'] as List?)
          ?.map((e) => PrefaceEntry.fromJson(e))
          .toList(),
      communionAntiphon: (json['communionAntiphon'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map((e) => MassAntiphon.fromJson(e))
          .toList(),
      prayerAfterCommunion: (json['prayerAfterCommunion'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      prayerOnThePeople: (json['prayerOnThePeople'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      solemnBlessingList: (json['solemnBlessingList'] as List?)
          ?.map((e) => HymnEntry.fromJson(e))
          .toList(),
      sequence: (json['sequence'] as List?)
          ?.map((e) => HymnEntry.fromJson(e))
          .toList(),
      eucharisticPrayerCommunicantes:
          json['eucharisticPrayerCommunicantes'] != null
              ? EucharisticPrayerCommunicantesEntry.fromJson(
                  json['eucharisticPrayerCommunicantes'])
              : null,
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
    if (overlay.prayerOnThePeople != null)
      prayerOnThePeople = overlay.prayerOnThePeople;
    if (overlay.solemnBlessingList != null)
      solemnBlessingList = overlay.solemnBlessingList;
    if (overlay.sequence != null) sequence = overlay.sequence;
    if (overlay.eucharisticPrayerCommunicantes != null)
      eucharisticPrayerCommunicantes = overlay.eucharisticPrayerCommunicantes;
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

  /// Selective overlay of just the prayer-related texts (antiphons,
  /// orations, prefaces...) — never readingParts, which is always governed
  /// separately (the ferial/proper Liturgy of the Word, or a memorial's own
  /// via useProperReadingsForMemorial). Two call sites reuse this: applying
  /// a selected Common (any precedence), and applying a memorial's own
  /// proper texts on top of it (precedence > 5) — see massExport.
  void overlayPrayerFields(Mass source) {
    if (source.entranceAntiphon != null)
      entranceAntiphon = source.entranceAntiphon;
    if (source.collect != null) collect = source.collect;
    if (source.offeringPrayer != null) offeringPrayer = source.offeringPrayer;
    if (source.prefaceList != null) prefaceList = source.prefaceList;
    if (source.communionAntiphon != null)
      communionAntiphon = source.communionAntiphon;
    if (source.prayerAfterCommunion != null)
      prayerAfterCommunion = source.prayerAfterCommunion;
    if (source.prayerOnThePeople != null)
      prayerOnThePeople = source.prayerOnThePeople;
    if (source.solemnBlessingList != null)
      solemnBlessingList = source.solemnBlessingList;
    if (source.sequence != null) sequence = source.sequence;
    if (source.eucharisticPrayerCommunicantes != null)
      eucharisticPrayerCommunicantes = source.eucharisticPrayerCommunicantes;
  }

  /// Fills only the missing readingPart types (e.g. no proper PSALM of its
  /// own) from [common], restricted to [requiredPartTypes] — never replaces
  /// a partType this Mass already supplies. Used when a memorial opts into
  /// "the feast's own readings": the proper's readingParts apply first
  /// (wholesale, see massExport), then this fills whichever part types the
  /// proper didn't cover from the selected Common.
  ///
  /// Safe specifically for Common-of-Saints data: unlike overlayWith's
  /// wholesale readingParts replacement (needed because Sundays/the Easter
  /// Vigil can have several entries sharing the same partType, where a
  /// partType-keyed merge would silently collapse them), a common's mass:
  /// block is always a simple one-entry-per-partType formulary, so merging
  /// by partType key here can't lose data. Do not reuse this for anything
  /// else without re-checking that assumption.
  void fillMissingReadingPartsFromCommon(
      Mass common, List<String> requiredPartTypes) {
    final commonParts = common.readingParts;
    if (commonParts == null || commonParts.isEmpty) return;
    final ownParts = readingParts ??= [];
    final ownPartTypes = ownParts.map((p) => p.partType).toSet();
    for (final partType in requiredPartTypes) {
      if (ownPartTypes.contains(partType)) continue;
      final index = commonParts.indexWhere((p) => p.partType == partType);
      if (index >= 0) ownParts.add(commonParts[index]);
    }
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
      (prayerOnThePeople == null || prayerOnThePeople!.isEmpty) &&
      (solemnBlessingList == null || solemnBlessingList!.isEmpty) &&
      (sequence == null || sequence!.isEmpty) &&
      eucharisticPrayerCommunicantes == null;
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

  /// Selective overlay of just the prayer-related texts — only enriches
  /// massTypes already selected for the day, it never introduces a new mass
  /// type. See Mass.overlayPrayerFields for the two call sites that reuse
  /// this (applying a Common, or a memorial's own proper texts).
  void overlayPrayerFields(Masses source) {
    if (source.masses == null || source.masses!.isEmpty || masses == null) {
      return;
    }
    for (final sourceMass in source.masses!) {
      final index =
          masses!.indexWhere((m) => m.massType == sourceMass.massType);
      if (index >= 0) {
        masses![index].overlayPrayerFields(sourceMass);
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
