/// Classes for the Mass (Eucharistic celebration) structure
library;

/// Antiphon with optional biblical reference and text content.
/// Used for both entrance antiphon and communion antiphon.
class MassAntiphon {
  final String? biblicalRef;
  final String? content;

  const MassAntiphon({this.biblicalRef, this.content});

  factory MassAntiphon.fromJson(Map<String, dynamic> json) => MassAntiphon(
        biblicalRef: json['biblicalRef']?.toString(),
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
  final String? sundayAndWeekCycles;
  final String? headline;
  final String? content;
  final String? shortReadingRef;
  final String? shortReadingContent;

  MassReading({
    this.biblicalRef,
    this.sundayAndWeekCycles,
    this.headline,
    this.content,
    this.shortReadingRef,
    this.shortReadingContent,
  });

  factory MassReading.fromJson(Map<String, dynamic> json) => MassReading(
        biblicalRef: json['biblicalRef']?.toString(),
        sundayAndWeekCycles: json['sundayAndWeekCycles']?.toString(),
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
  final String? sundayAndWeekCycles;
  final List<MassChorusEntry>? chorus;
  final String? content;

  MassPsalm({
    this.biblicalRef,
    this.refAbbr,
    this.sundayAndWeekCycles,
    this.chorus,
    this.content,
  });

  factory MassPsalm.fromJson(Map<String, dynamic> json) => MassPsalm(
        biblicalRef: json['biblicalRef']?.toString(),
        refAbbr: json['refAbbr']?.toString(),
        sundayAndWeekCycles: json['sundayAndWeekCycles']?.toString(),
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
  final String? sundayAndWeekCycles;
  final String? headline;
  final String? beforeAcclamationAntiphon;
  final String? acclamationAntiphon;
  final String? afterAcclamationAntiphon;
  final String? content;

  MassGospel({
    this.biblicalRef,
    this.sundayAndWeekCycles,
    this.headline,
    this.beforeAcclamationAntiphon,
    this.acclamationAntiphon,
    this.afterAcclamationAntiphon,
    this.content,
  });

  factory MassGospel.fromJson(Map<String, dynamic> json) => MassGospel(
        biblicalRef: json['biblicalRef']?.toString(),
        sundayAndWeekCycles: json['sundayAndWeekCycles']?.toString(),
        headline: json['headline']?.toString(),
        beforeAcclamationAntiphon:
            json['beforeAcclamationAntiphon']?.toString(),
        acclamationAntiphon: json['acclamationAntiphon']?.toString(),
        afterAcclamationAntiphon: json['afterAcclamationAntiphon']?.toString(),
        content: json['content']?.toString(),
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
  final String? massType;
  final String? name;
  final String? note;
  final List<MassAntiphon>? entranceAntiphon;
  final List<String>? collect;
  final List<MassReadingPart>? readingParts;
  final List<String>? offeringPrayer;
  final List<String>? prefaceList;
  final List<MassAntiphon>? communionAntiphon;
  final List<String>? prayerAfterCommunion;
  final List<String>? solemnBlessingList;

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
      collect:
          (json['collect'] as List?)?.map((e) => e.toString()).toList(),
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
}

/// Container for all Mass types of a given liturgical day.
class Masses {
  final List<Mass>? masses;

  Masses({this.masses});

  factory Masses.fromJson(Map<String, dynamic> json) {
    return Masses(
      masses: (json['mass'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map((e) => Mass.fromJson(e))
          .toList(),
    );
  }
}
