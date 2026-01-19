/// Classes for deeply nested structured liturgical office data
library;

import '../tools/data_loader.dart';

/// Represents celebration information
class Celebration {
  final String? title;
  final String? subtitle;
  final String? description;
  final List<String>? commons;
  final int? precedence;
  final String? color;

  Celebration({
    this.title,
    this.subtitle,
    this.description,
    this.commons,
    this.precedence,
    this.color,
  });

  factory Celebration.fromJson(Map<String, dynamic> json) {
    return Celebration(
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String?,
      commons: json['commons'] != null
          ? List<String>.from(json['commons'] as List)
          : null,
      precedence: json['precedence'] as int?,
      color: json['color'] as String?,
    );
  }
}

/// Invitatory with antiphon and psalms
class Invitatory {
  final List<String>? antiphon;
  final List<String>? psalms;

  Invitatory({
    this.antiphon,
    this.psalms,
  });

  factory Invitatory.fromJson(Map<String, dynamic> json) {
    return Invitatory(
      antiphon: json['antiphon'] != null
          ? List<String>.from(json['antiphon'] as List)
          : null,
      psalms: json['psalms'] != null
          ? List<String>.from(json['psalms'] as List)
          : null,
    );
  }
}

/// Evangelic antiphon with common and yearly variants
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

/// Intercession
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

/// Psalm with antiphons
class PsalmEntry {
  final String? psalm;
  final List<String>? antiphon;

  PsalmEntry({
    this.psalm,
    this.antiphon,
  });

  factory PsalmEntry.fromJson(Map<String, dynamic> json) {
    return PsalmEntry(
      psalm: json['psalm'] as String?,
      antiphon: json['antiphon'] != null
          ? List<String>.from(json['antiphon'] as List)
          : null,
    );
  }
}

/// Biblical reading
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

/// Biblical reading entry for Readings Office
class BiblicalReading {
  final String? title;
  final String? ref;
  final String? content;
  final String? responsory;

  BiblicalReading({
    this.title,
    this.ref,
    this.content,
    this.responsory,
  });

  factory BiblicalReading.fromJson(Map<String, dynamic> json) {
    return BiblicalReading(
      title: json['title'] as String?,
      ref: json['ref'] as String?,
      content: json['content'] as String?,
      responsory: json['responsory'] as String?,
    );
  }
}

/// Patristic reading entry for Readings Office
class PatristicReading {
  final String? title;
  final String? subtitle;
  final String? content;
  final String? responsory;

  PatristicReading({
    this.title,
    this.subtitle,
    this.content,
    this.responsory,
  });

  factory PatristicReading.fromJson(Map<String, dynamic> json) {
    return PatristicReading(
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      content: json['content'] as String?,
      responsory: json['responsory'] as String?,
    );
  }
}

/// Context class containing all parameters needed for office resolution.
/// Used to simplify function signatures across morning, vespers, and other offices.
class CelebrationContext {
  final String celebrationCode;
  final String? ferialCode;
  final String? common;
  final DateTime date;
  final String? breviaryWeek;
  final int? precedence;
  final bool? teDeum;
  final DataLoader dataLoader;

  const CelebrationContext({
    required this.celebrationCode,
    this.ferialCode,
    this.common,
    required this.date,
    this.breviaryWeek,
    this.precedence,
    this.teDeum,
    required this.dataLoader,
  });
}
