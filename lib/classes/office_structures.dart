/// Classes for deeply nested structured liturgical office data
///
/// Note: Throughout this file, the key "antiphon" (singular) is used
/// even when it contains a list of multiple antiphons.

/// Represents a single psalm with its antiphons
class PsalmEntry {
  final String psalm;
  final List<String>? antiphon; // singular key name, list value

  PsalmEntry({
    required this.psalm,
    this.antiphon,
  });

  factory PsalmEntry.fromJson(Map<String, dynamic> json) {
    return PsalmEntry(
      psalm: json['psalm'] as String,
      antiphon:
          json['antiphon'] != null ? List<String>.from(json['antiphon']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'psalm': psalm};
    if (antiphon != null && antiphon!.isNotEmpty) {
      map['antiphon'] = antiphon;
    }
    return map;
  }
}

/// Represents a reading with reference and content
class ReadingEntry {
  final String? ref;
  final String? content;

  ReadingEntry({
    this.ref,
    this.content,
  });

  factory ReadingEntry.fromJson(Map<String, dynamic> json) {
    return ReadingEntry(
      ref: json['ref'] as String?,
      content: json['content'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (ref != null) 'ref': ref,
      if (content != null) 'content': content,
    };
  }
}

/// Invitatory office structure
class InvitatoryOffice {
  final List<String>? antiphon; // singular key name, list of antiphons
  final String? psalm;

  InvitatoryOffice({
    this.antiphon,
    this.psalm,
  });

  factory InvitatoryOffice.fromJson(Map<String, dynamic> json) {
    return InvitatoryOffice(
      antiphon: json['antiphon'] != null
          ? (json['antiphon'] is List
              ? List<String>.from(json['antiphon'])
              : [
                  json['antiphon'] as String
                ]) // Handle single string case for backward compatibility
          : null,
      psalm: json['psalm'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (antiphon != null && antiphon!.isNotEmpty) 'antiphon': antiphon,
      if (psalm != null) 'psalm': psalm,
    };
  }
}

/// Hour office for middle of day (tierce, sexte, none)
class HourOffice {
  final String? antiphon;
  final ReadingEntry? reading;
  final String? responsory;

  HourOffice({
    this.antiphon,
    this.reading,
    this.responsory,
  });

  factory HourOffice.fromJson(Map<String, dynamic> json) {
    return HourOffice(
      antiphon: json['antiphon'] as String?,
      reading: json['reading'] != null
          ? ReadingEntry.fromJson(json['reading'] as Map<String, dynamic>)
          : null,
      responsory: json['responsory'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (antiphon != null) 'antiphon': antiphon,
      if (reading != null) 'reading': reading!.toJson(),
      if (responsory != null) 'responsory': responsory,
    };
  }
}

/// Middle of day office structure with tierce/sexte/none
class MiddleOfDayOffice {
  final HourOffice? tierce;
  final HourOffice? sexte;
  final HourOffice? none;
  final List<PsalmEntry>? psalmody;
  final String? oration;
  // Legacy fields for direct psalm references
  final String? psalm1;
  final String? psalm2;
  final String? psalm3;

  MiddleOfDayOffice({
    this.tierce,
    this.sexte,
    this.none,
    this.psalmody,
    this.oration,
    this.psalm1,
    this.psalm2,
    this.psalm3,
  });

  factory MiddleOfDayOffice.fromJson(Map<String, dynamic> json) {
    return MiddleOfDayOffice(
      tierce: json['tierce'] != null
          ? HourOffice.fromJson(json['tierce'] as Map<String, dynamic>)
          : null,
      sexte: json['sexte'] != null
          ? HourOffice.fromJson(json['sexte'] as Map<String, dynamic>)
          : null,
      none: json['none'] != null
          ? HourOffice.fromJson(json['none'] as Map<String, dynamic>)
          : null,
      psalmody: json['psalmody'] != null
          ? (json['psalmody'] as List)
              .map((e) => PsalmEntry.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      oration: json['oration'] as String?,
      psalm1: json['psalm1'] as String?,
      psalm2: json['psalm2'] as String?,
      psalm3: json['psalm3'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (tierce != null) 'tierce': tierce!.toJson(),
      if (sexte != null) 'sexte': sexte!.toJson(),
      if (none != null) 'none': none!.toJson(),
      if (psalmody != null)
        'psalmody': psalmody!.map((e) => e.toJson()).toList(),
      if (oration != null) 'oration': oration,
      if (psalm1 != null) 'psalm1': psalm1,
      if (psalm2 != null) 'psalm2': psalm2,
      if (psalm3 != null) 'psalm3': psalm3,
    };
  }
}

/// Biblical reading entry
class BiblicalReadingEntry {
  final String? title;
  final String? ref;
  final String? content;
  final String? responsory;

  BiblicalReadingEntry({
    this.title,
    this.ref,
    this.content,
    this.responsory,
  });

  factory BiblicalReadingEntry.fromJson(Map<String, dynamic> json) {
    return BiblicalReadingEntry(
      title: json['title'] as String?,
      ref: json['ref'] as String?,
      content: json['content'] as String?,
      responsory: json['responsory'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (ref != null) 'ref': ref,
      if (content != null) 'content': content,
      if (responsory != null) 'responsory': responsory,
    };
  }
}

/// Patristic reading entry
class PatristicReadingEntry {
  final String? title;
  final String? subtitle;
  final String? content;
  final String? responsory;

  PatristicReadingEntry({
    this.title,
    this.subtitle,
    this.content,
    this.responsory,
  });

  factory PatristicReadingEntry.fromJson(Map<String, dynamic> json) {
    return PatristicReadingEntry(
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      content: json['content'] as String?,
      responsory: json['responsory'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (content != null) 'content': content,
      if (responsory != null) 'responsory': responsory,
    };
  }
}

/// Office of Readings structure with nested reading objects
class ReadingsOffice {
  final List<String>? hymn;
  final List<PsalmEntry>? psalmody;
  final String? verse;
  final BiblicalReadingEntry? biblicalReading;
  final BiblicalReadingEntry? biblicalReading2;
  final PatristicReadingEntry? patristicReading;
  final PatristicReadingEntry? patristicReading2;
  final PatristicReadingEntry? patristicReading3;
  final String? oration;

  ReadingsOffice({
    this.hymn,
    this.psalmody,
    this.verse,
    this.biblicalReading,
    this.biblicalReading2,
    this.patristicReading,
    this.patristicReading2,
    this.patristicReading3,
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
      biblicalReading: json['biblicalReading'] != null
          ? BiblicalReadingEntry.fromJson(
              json['biblicalReading'] as Map<String, dynamic>)
          : null,
      biblicalReading2: json['biblicalReading2'] != null
          ? BiblicalReadingEntry.fromJson(
              json['biblicalReading2'] as Map<String, dynamic>)
          : null,
      patristicReading: json['patristicReading'] != null
          ? PatristicReadingEntry.fromJson(
              json['patristicReading'] as Map<String, dynamic>)
          : null,
      patristicReading2: json['patristicReading2'] != null
          ? PatristicReadingEntry.fromJson(
              json['patristicReading2'] as Map<String, dynamic>)
          : null,
      patristicReading3: json['patristicReading3'] != null
          ? PatristicReadingEntry.fromJson(
              json['patristicReading3'] as Map<String, dynamic>)
          : null,
      oration: json['oration'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (hymn != null) 'hymn': hymn,
      if (psalmody != null)
        'psalmody': psalmody!.map((e) => e.toJson()).toList(),
      if (verse != null) 'verse': verse,
      if (biblicalReading != null) 'biblicalReading': biblicalReading!.toJson(),
      if (biblicalReading2 != null)
        'biblicalReading2': biblicalReading2!.toJson(),
      if (patristicReading != null)
        'patristicReading': patristicReading!.toJson(),
      if (patristicReading2 != null)
        'patristicReading2': patristicReading2!.toJson(),
      if (patristicReading3 != null)
        'patristicReading3': patristicReading3!.toJson(),
      if (oration != null) 'oration': oration,
    };
  }
}

/// Morning prayer office structure with nested reading
class MorningOffice {
  final List<String>? hymn;
  final List<PsalmEntry>? psalmody;
  final ReadingEntry? reading;
  final String? responsory;
  final String? evangelicAntiphon;
  final String? evangelicAntiphonA;
  final String? evangelicAntiphonB;
  final String? evangelicAntiphonC;
  final String? intercessionDescription;
  final String? intercession;
  final String? intercession2;
  final String? oration;

  MorningOffice({
    this.hymn,
    this.psalmody,
    this.reading,
    this.responsory,
    this.evangelicAntiphon,
    this.evangelicAntiphonA,
    this.evangelicAntiphonB,
    this.evangelicAntiphonC,
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
      reading: json['reading'] != null
          ? ReadingEntry.fromJson(json['reading'] as Map<String, dynamic>)
          : null,
      responsory: json['responsory'] as String?,
      evangelicAntiphon: json['evangelicAntiphon'] as String?,
      evangelicAntiphonA: json['evangelicAntiphonA'] as String?,
      evangelicAntiphonB: json['evangelicAntiphonB'] as String?,
      evangelicAntiphonC: json['evangelicAntiphonC'] as String?,
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
      if (reading != null) 'reading': reading!.toJson(),
      if (responsory != null) 'responsory': responsory,
      if (evangelicAntiphon != null) 'evangelicAntiphon': evangelicAntiphon,
      if (evangelicAntiphonA != null) 'evangelicAntiphonA': evangelicAntiphonA,
      if (evangelicAntiphonB != null) 'evangelicAntiphonB': evangelicAntiphonB,
      if (evangelicAntiphonC != null) 'evangelicAntiphonC': evangelicAntiphonC,
      if (intercessionDescription != null)
        'intercessionDescription': intercessionDescription,
      if (intercession != null) 'intercession': intercession,
      if (intercession2 != null) 'intercession2': intercession2,
      if (oration != null) 'oration': oration,
    };
  }
}

/// Vespers office structure with nested reading
class VespersOffice {
  final List<String>? hymn;
  final List<PsalmEntry>? psalmody;
  final ReadingEntry? reading;
  final String? responsory;
  final String? evangelicAntiphon;
  final String? intercession;
  final String? oration;

  VespersOffice({
    this.hymn,
    this.psalmody,
    this.reading,
    this.responsory,
    this.evangelicAntiphon,
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
      reading: json['reading'] != null
          ? ReadingEntry.fromJson(json['reading'] as Map<String, dynamic>)
          : null,
      responsory: json['responsory'] as String?,
      evangelicAntiphon: json['evangelicAntiphon'] as String?,
      intercession: json['intercession'] as String?,
      oration: json['oration'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (hymn != null) 'hymn': hymn,
      if (psalmody != null)
        'psalmody': psalmody!.map((e) => e.toJson()).toList(),
      if (reading != null) 'reading': reading!.toJson(),
      if (responsory != null) 'responsory': responsory,
      if (evangelicAntiphon != null) 'evangelicAntiphon': evangelicAntiphon,
      if (intercession != null) 'intercession': intercession,
      if (oration != null) 'oration': oration,
    };
  }
}
