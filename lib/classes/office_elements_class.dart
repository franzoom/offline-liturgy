/// Classes for deeply nested structured liturgical office data

/// Represents celebration information
class Celebration {
  final String? title;
  final String? subtitle;
  final String? description;
  final List? commons;
  final int? grade;
  final String? color;

  Celebration({
    this.title,
    this.subtitle,
    this.description,
    this.commons,
    this.grade,
    this.color,
  });

  factory Celebration.fromJson(Map<String, dynamic> json) {
    return Celebration(
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String?,
      commons: json['commons'] as List?,
      grade: json['grade'] as int?,
      color: json['color'] as String?,
    );
  }
}

/// Represents invitatory with antiphon and psalms
class Invitatory {
  final List<String>? antiphon;
  final List? psalms;

  Invitatory({
    this.antiphon,
    this.psalms,
  });

  factory Invitatory.fromJson(Map<String, dynamic> json) {
    return Invitatory(
      antiphon: json['antiphon'] != null
          ? (json['antiphon'] is List
              ? List<String>.from(json['antiphon'])
              : [json['antiphon'] as String])
          : null,
      psalms: json['psalms'] as List?,
    );
  }
}

/// Represents evangelic antiphon with common and yearly variants
class EvangelicAntiphon {
  final String? common;
  final String? yearA;
  final String? yearB;
  final String? yearC;

  EvangelicAntiphon({
    this.common,
    this.yearA,
    this.yearB,
    this.yearC,
  });

  factory EvangelicAntiphon.fromJson(Map<String, dynamic> json) {
    return EvangelicAntiphon(
      common: json['common'] as String?,
      yearA: json['yearA'] as String?,
      yearB: json['yearB'] as String?,
      yearC: json['yearC'] as String?,
    );
  }
}

/// Represents intercession with description and content
class Intercession {
  final String? description;
  final String? content;

  Intercession({
    this.description,
    this.content,
  });

  factory Intercession.fromJson(Map<String, dynamic> json) {
    return Intercession(
      description: json['description'] as String?,
      content: json['content'] as String?,
    );
  }
}

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
}

/// Represents a reading with biblical reference and content
class Reading {
  final String? biblicalReference;
  final String? content;

  Reading({
    this.biblicalReference,
    this.content,
  });

  factory Reading.fromJson(Map<String, dynamic> json) {
    return Reading(
      biblicalReference: json['biblicalReference'] as String?,
      content: json['content'] as String?,
    );
  }
}

/// Legacy class name for backward compatibility in some contexts
/// Use Reading instead for new code
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
}

/// Hour office for middle of day (tierce, sexte, none)
class HourOffice {
  final String? antiphon;
  final Reading? reading;
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
          ? Reading.fromJson(json['reading'] as Map<String, dynamic>)
          : null,
      responsory: json['responsory'] as String?,
    );
  }
}

/// Middle of day office structure with tierce/sexte/none
class MiddleOfDayOffice {
  final HourOffice? tierce;
  final HourOffice? sexte;
  final HourOffice? none;
  final List<PsalmEntry>? psalmody;
  final List<String>? oration;
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
      oration:
          json['oration'] != null ? List<String>.from(json['oration']) : null,
      psalm1: json['psalm1'] as String?,
      psalm2: json['psalm2'] as String?,
      psalm3: json['psalm3'] as String?,
    );
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
  final List<String>? oration;

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
      oration:
          json['oration'] != null ? List<String>.from(json['oration']) : null,
    );
  }
}

/// Vespers office structure with nested reading
class VespersOffice {
  final List<String>? hymn;
  final List<PsalmEntry>? psalmody;
  final Reading? reading;
  final String? responsory;
  final EvangelicAntiphon? evangelicAntiphon;
  final Intercession? intercession;
  final List<String>? oration;

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
}
