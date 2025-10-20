/// Classes for structured liturgical office data
/// Supports nested JSON structure with psalmody arrays

/// Represents a single psalm with its antiphons
class PsalmEntry {
  final String psalm;
  final List<String>? antiphons;

  PsalmEntry({
    required this.psalm,
    this.antiphons,
  });

  factory PsalmEntry.fromJson(Map<String, dynamic> json) {
    return PsalmEntry(
      psalm: json['psalm'] as String,
      antiphons: json['antiphons'] != null
          ? List<String>.from(json['antiphons'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'psalm': psalm};
    if (antiphons != null && antiphons!.isNotEmpty) {
      map['antiphons'] = antiphons;
    }
    return map;
  }
}

/// Invitatory office structure
class InvitatoryOffice {
  final String? antiphon;
  final String? antiphon2;
  final String? psalm;

  InvitatoryOffice({
    this.antiphon,
    this.antiphon2,
    this.psalm,
  });

  factory InvitatoryOffice.fromJson(Map<String, dynamic> json) {
    return InvitatoryOffice(
      antiphon: json['antiphon'] as String?,
      antiphon2: json['antiphon2'] as String?,
      psalm: json['psalm'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (antiphon != null) 'antiphon': antiphon,
      if (antiphon2 != null) 'antiphon2': antiphon2,
      if (psalm != null) 'psalm': psalm,
    };
  }
}

/// Morning prayer office structure
class MorningOffice {
  final List<String>? hymn;
  final List<PsalmEntry>? psalmody;
  final String? evangelicAntiphon;
  final String? evangelicAntiphonA;
  final String? evangelicAntiphonB;
  final String? evangelicAntiphonC;
  final String? readingRef;
  final String? reading;
  final String? responsory;
  final String? intercessionDescription;
  final String? intercession;
  final String? intercession2;
  final String? oration;

  MorningOffice({
    this.hymn,
    this.psalmody,
    this.evangelicAntiphon,
    this.evangelicAntiphonA,
    this.evangelicAntiphonB,
    this.evangelicAntiphonC,
    this.readingRef,
    this.reading,
    this.responsory,
    this.intercessionDescription,
    this.intercession,
    this.intercession2,
    this.oration,
  });

  factory MorningOffice.fromJson(Map<String, dynamic> json) {
    return MorningOffice(
      hymn: json['hymn'] != null ? List<String>.from(json['hymn']) : null,
      psalmody: json['psalmody'] != null
          ? (json['psalmody'] as List)
              .map((e) => PsalmEntry.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      evangelicAntiphon: json['evangelicAntiphon'] as String?,
      evangelicAntiphonA: json['evangelicAntiphonA'] as String?,
      evangelicAntiphonB: json['evangelicAntiphonB'] as String?,
      evangelicAntiphonC: json['evangelicAntiphonC'] as String?,
      readingRef: json['readingRef'] as String?,
      reading: json['reading'] as String?,
      responsory: json['responsory'] as String?,
      intercessionDescription: json['intercessionDescription'] as String?,
      intercession: json['intercession'] as String?,
      intercession2: json['intercession2'] as String?,
      oration: json['oration'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (hymn != null) 'hymn': hymn,
      if (psalmody != null)
        'psalmody': psalmody!.map((e) => e.toJson()).toList(),
      if (evangelicAntiphon != null) 'evangelicAntiphon': evangelicAntiphon,
      if (evangelicAntiphonA != null) 'evangelicAntiphonA': evangelicAntiphonA,
      if (evangelicAntiphonB != null) 'evangelicAntiphonB': evangelicAntiphonB,
      if (evangelicAntiphonC != null) 'evangelicAntiphonC': evangelicAntiphonC,
      if (readingRef != null) 'readingRef': readingRef,
      if (reading != null) 'reading': reading,
      if (responsory != null) 'responsory': responsory,
      if (intercessionDescription != null)
        'intercessionDescription': intercessionDescription,
      if (intercession != null) 'intercession': intercession,
      if (intercession2 != null) 'intercession2': intercession2,
      if (oration != null) 'oration': oration,
    };
  }
}

/// Office of Readings structure
class ReadingsOffice {
  final List<String>? hymn;
  final List<PsalmEntry>? psalmody;
  final String? verse;
  final String? biblicalReadingTitle;
  final String? biblicalReadingRef;
  final String? biblicalReadingContent;
  final String? biblicalReadingResponsory;
  final String? biblicalReadingTitle2;
  final String? biblicalReadingRef2;
  final String? biblicalReadingContent2;
  final String? biblicalReadingResponsory2;
  final String? patristicReadingTitle;
  final String? patristicReadingSubtitle;
  final String? patristicReadingContent;
  final String? patristicReadingResponsory;
  final String? patristicReadingTitle2;
  final String? patristicReadingSubtitle2;
  final String? patristicReadingContent2;
  final String? patristicReadingResponsory2;
  final String? patristicReadingTitle3;
  final String? patristicReadingSubtitle3;
  final String? patristicReadingContent3;
  final String? patristicReadingResponsory3;
  final String? oration;

  ReadingsOffice({
    this.hymn,
    this.psalmody,
    this.verse,
    this.biblicalReadingTitle,
    this.biblicalReadingRef,
    this.biblicalReadingContent,
    this.biblicalReadingResponsory,
    this.biblicalReadingTitle2,
    this.biblicalReadingRef2,
    this.biblicalReadingContent2,
    this.biblicalReadingResponsory2,
    this.patristicReadingTitle,
    this.patristicReadingSubtitle,
    this.patristicReadingContent,
    this.patristicReadingResponsory,
    this.patristicReadingTitle2,
    this.patristicReadingSubtitle2,
    this.patristicReadingContent2,
    this.patristicReadingResponsory2,
    this.patristicReadingTitle3,
    this.patristicReadingSubtitle3,
    this.patristicReadingContent3,
    this.patristicReadingResponsory3,
    this.oration,
  });

  factory ReadingsOffice.fromJson(Map<String, dynamic> json) {
    return ReadingsOffice(
      hymn: json['hymn'] != null ? List<String>.from(json['hymn']) : null,
      psalmody: json['psalmody'] != null
          ? (json['psalmody'] as List)
              .map((e) => PsalmEntry.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      verse: json['verse'] as String?,
      biblicalReadingTitle: json['biblicalReadingTitle'] as String?,
      biblicalReadingRef: json['biblicalReadingRef'] as String?,
      biblicalReadingContent: json['biblicalReadingContent'] as String?,
      biblicalReadingResponsory: json['biblicalReadingResponsory'] as String?,
      biblicalReadingTitle2: json['biblicalReadingTitle2'] as String?,
      biblicalReadingRef2: json['biblicalReadingRef2'] as String?,
      biblicalReadingContent2: json['biblicalReadingContent2'] as String?,
      biblicalReadingResponsory2: json['biblicalReadingResponsory2'] as String?,
      patristicReadingTitle: json['patristicReadingTitle'] as String?,
      patristicReadingSubtitle: json['patristicReadingSubtitle'] as String?,
      patristicReadingContent: json['patristicReadingContent'] as String?,
      patristicReadingResponsory: json['patristicReadingResponsory'] as String?,
      patristicReadingTitle2: json['patristicReadingTitle2'] as String?,
      patristicReadingSubtitle2: json['patristicReadingSubtitle2'] as String?,
      patristicReadingContent2: json['patristicReadingContent2'] as String?,
      patristicReadingResponsory2:
          json['patristicReadingResponsory2'] as String?,
      patristicReadingTitle3: json['patristicReadingTitle3'] as String?,
      patristicReadingSubtitle3: json['patristicReadingSubtitle3'] as String?,
      patristicReadingContent3: json['patristicReadingContent3'] as String?,
      patristicReadingResponsory3:
          json['patristicReadingResponsory3'] as String?,
      oration: json['oration'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (hymn != null) 'hymn': hymn,
      if (psalmody != null)
        'psalmody': psalmody!.map((e) => e.toJson()).toList(),
      if (verse != null) 'verse': verse,
      if (biblicalReadingTitle != null)
        'biblicalReadingTitle': biblicalReadingTitle,
      if (biblicalReadingRef != null) 'biblicalReadingRef': biblicalReadingRef,
      if (biblicalReadingContent != null)
        'biblicalReadingContent': biblicalReadingContent,
      if (biblicalReadingResponsory != null)
        'biblicalReadingResponsory': biblicalReadingResponsory,
      if (biblicalReadingTitle2 != null)
        'biblicalReadingTitle2': biblicalReadingTitle2,
      if (biblicalReadingRef2 != null)
        'biblicalReadingRef2': biblicalReadingRef2,
      if (biblicalReadingContent2 != null)
        'biblicalReadingContent2': biblicalReadingContent2,
      if (biblicalReadingResponsory2 != null)
        'biblicalReadingResponsory2': biblicalReadingResponsory2,
      if (patristicReadingTitle != null)
        'patristicReadingTitle': patristicReadingTitle,
      if (patristicReadingSubtitle != null)
        'patristicReadingSubtitle': patristicReadingSubtitle,
      if (patristicReadingContent != null)
        'patristicReadingContent': patristicReadingContent,
      if (patristicReadingResponsory != null)
        'patristicReadingResponsory': patristicReadingResponsory,
      if (patristicReadingTitle2 != null)
        'patristicReadingTitle2': patristicReadingTitle2,
      if (patristicReadingSubtitle2 != null)
        'patristicReadingSubtitle2': patristicReadingSubtitle2,
      if (patristicReadingContent2 != null)
        'patristicReadingContent2': patristicReadingContent2,
      if (patristicReadingResponsory2 != null)
        'patristicReadingResponsory2': patristicReadingResponsory2,
      if (patristicReadingTitle3 != null)
        'patristicReadingTitle3': patristicReadingTitle3,
      if (patristicReadingSubtitle3 != null)
        'patristicReadingSubtitle3': patristicReadingSubtitle3,
      if (patristicReadingContent3 != null)
        'patristicReadingContent3': patristicReadingContent3,
      if (patristicReadingResponsory3 != null)
        'patristicReadingResponsory3': patristicReadingResponsory3,
      if (oration != null) 'oration': oration,
    };
  }
}

/// Vespers office structure
class VespersOffice {
  final List<String>? hymn;
  final List<PsalmEntry>? psalmody;
  final String? evangelicAntiphon;
  final String? readingRef;
  final String? reading;
  final String? responsory;
  final String? intercession;
  final String? oration;

  VespersOffice({
    this.hymn,
    this.psalmody,
    this.evangelicAntiphon,
    this.readingRef,
    this.reading,
    this.responsory,
    this.intercession,
    this.oration,
  });

  factory VespersOffice.fromJson(Map<String, dynamic> json) {
    return VespersOffice(
      hymn: json['hymn'] != null ? List<String>.from(json['hymn']) : null,
      psalmody: json['psalmody'] != null
          ? (json['psalmody'] as List)
              .map((e) => PsalmEntry.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      evangelicAntiphon: json['evangelicAntiphon'] as String?,
      readingRef: json['readingRef'] as String?,
      reading: json['reading'] as String?,
      responsory: json['responsory'] as String?,
      intercession: json['intercession'] as String?,
      oration: json['oration'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (hymn != null) 'hymn': hymn,
      if (psalmody != null)
        'psalmody': psalmody!.map((e) => e.toJson()).toList(),
      if (evangelicAntiphon != null) 'evangelicAntiphon': evangelicAntiphon,
      if (readingRef != null) 'readingRef': readingRef,
      if (reading != null) 'reading': reading,
      if (responsory != null) 'responsory': responsory,
      if (intercession != null) 'intercession': intercession,
      if (oration != null) 'oration': oration,
    };
  }
}

/// Middle of day office structure
class MiddleOfDayOffice {
  final String? tierceAntiphon;
  final String? sexteAntiphon;
  final String? noneAntiphon;
  final String? reading1Ref;
  final String? reading1Content;
  final String? reading2Ref;
  final String? reading2Content;
  final String? reading3Ref;
  final String? reading3Content;
  final String? responsory1;
  final String? responsory2;
  final String? responsory3;
  final String? oration;
  final String? psalm1;
  final String? psalm2;
  final String? psalm3;

  MiddleOfDayOffice({
    this.tierceAntiphon,
    this.sexteAntiphon,
    this.noneAntiphon,
    this.reading1Ref,
    this.reading1Content,
    this.reading2Ref,
    this.reading2Content,
    this.reading3Ref,
    this.reading3Content,
    this.responsory1,
    this.responsory2,
    this.responsory3,
    this.oration,
    this.psalm1,
    this.psalm2,
    this.psalm3,
  });

  factory MiddleOfDayOffice.fromJson(Map<String, dynamic> json) {
    return MiddleOfDayOffice(
      tierceAntiphon: json['tierceAntiphon'] as String?,
      sexteAntiphon: json['sexteAntiphon'] as String?,
      noneAntiphon: json['noneAntiphon'] as String?,
      reading1Ref: json['reading1Ref'] as String?,
      reading1Content: json['reading1Content'] as String?,
      reading2Ref: json['reading2Ref'] as String?,
      reading2Content: json['reading2Content'] as String?,
      reading3Ref: json['reading3Ref'] as String?,
      reading3Content: json['reading3Content'] as String?,
      responsory1: json['responsory1'] as String?,
      responsory2: json['responsory2'] as String?,
      responsory3: json['responsory3'] as String?,
      oration: json['oration'] as String?,
      psalm1: json['psalm1'] as String?,
      psalm2: json['psalm2'] as String?,
      psalm3: json['psalm3'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (tierceAntiphon != null) 'tierceAntiphon': tierceAntiphon,
      if (sexteAntiphon != null) 'sexteAntiphon': sexteAntiphon,
      if (noneAntiphon != null) 'noneAntiphon': noneAntiphon,
      if (reading1Ref != null) 'reading1Ref': reading1Ref,
      if (reading1Content != null) 'reading1Content': reading1Content,
      if (reading2Ref != null) 'reading2Ref': reading2Ref,
      if (reading2Content != null) 'reading2Content': reading2Content,
      if (reading3Ref != null) 'reading3Ref': reading3Ref,
      if (reading3Content != null) 'reading3Content': reading3Content,
      if (responsory1 != null) 'responsory1': responsory1,
      if (responsory2 != null) 'responsory2': responsory2,
      if (responsory3 != null) 'responsory3': responsory3,
      if (oration != null) 'oration': oration,
      if (psalm1 != null) 'psalm1': psalm1,
      if (psalm2 != null) 'psalm2': psalm2,
      if (psalm3 != null) 'psalm3': psalm3,
    };
  }
}
