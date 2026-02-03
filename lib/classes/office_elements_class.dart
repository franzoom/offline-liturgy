/// Classes for deeply nested structured liturgical office data
library;

import '../tools/data_loader.dart';

/// Represents celebration information (Title, Color, Precedence)
class Celebration {
  final String? title;
  final String? subtitle;
  final String? description;
  final List<String>? commons;
  final int? precedence;
  final String? color;

  const Celebration({
    this.title,
    this.subtitle,
    this.description,
    this.commons,
    this.precedence,
    this.color,
  });

  factory Celebration.fromJson(Map<String, dynamic> json) {
    return Celebration(
      title: json['title']?.toString(),
      subtitle: json['subtitle']?.toString(),
      description: json['description']?.toString(),
      commons: (json['commons'] as List?)?.map((e) => e.toString()).toList(),
      precedence: json['precedence'] as int?,
      color: json['color']?.toString(),
    );
  }
}

/// Invitatory with antiphon and psalms
class Invitatory {
  final List<String>? antiphon;
  final List<String>? psalms;

  const Invitatory({this.antiphon, this.psalms});

  factory Invitatory.fromJson(Map<String, dynamic> json) {
    return Invitatory(
      antiphon: (json['antiphon'] as List?)?.map((e) => e.toString()).toList(),
      psalms: (json['psalms'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
}

/// Evangelic antiphon (Benedictus / Magnificat)
class EvangelicAntiphon {
  final String? common;
  final String? yearA;
  final String? yearB;
  final String? yearC;

  const EvangelicAntiphon({this.common, this.yearA, this.yearB, this.yearC});

  factory EvangelicAntiphon.fromJson(Map<String, dynamic> json) {
    return EvangelicAntiphon(
      common: json['common']?.toString(),
      yearA: json['yearA']?.toString(),
      yearB: json['yearB']?.toString(),
      yearC: json['yearC']?.toString(),
    );
  }
}

/// Intercessions / Preces
class Intercession {
  final String? description;
  final String? content;

  const Intercession({this.description, this.content});

  factory Intercession.fromJson(Map<String, dynamic> json) {
    return Intercession(
      description: json['description']?.toString(),
      content: json['content']?.toString(),
    );
  }
}

/// Psalm with its antiphons
class PsalmEntry {
  final String? psalm;
  final List<String>? antiphon;

  const PsalmEntry({this.psalm, this.antiphon});

  factory PsalmEntry.fromJson(Map<String, dynamic> json) {
    return PsalmEntry(
      psalm: json['psalm']?.toString(),
      antiphon: (json['antiphon'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
}

/// Biblical short reading (Lauds / Vespers)
class Reading {
  final String? biblicalReference;
  final String? content;

  const Reading({this.biblicalReference, this.content});

  factory Reading.fromJson(Map<String, dynamic> json) {
    return Reading(
      biblicalReference: json['biblicalReference']?.toString(),
      content: json['content']?.toString(),
    );
  }
}

/// Long Biblical reading (Office of Readings)
class BiblicalReading {
  final String? title;
  final String? ref;
  final String? content;
  final String? responsory;

  const BiblicalReading({this.title, this.ref, this.content, this.responsory});

  factory BiblicalReading.fromJson(Map<String, dynamic> json) {
    return BiblicalReading(
      title: json['title']?.toString(),
      ref: json['ref']?.toString(),
      content: json['content']?.toString(),
      responsory: json['responsory']?.toString(),
    );
  }
}

/// Patristic reading (Office of Readings)
class PatristicReading {
  final String? title;
  final String? subtitle;
  final String? content;
  final String? responsory;

  const PatristicReading(
      {this.title, this.subtitle, this.content, this.responsory});

  factory PatristicReading.fromJson(Map<String, dynamic> json) {
    return PatristicReading(
      title: json['title']?.toString(),
      subtitle: json['subtitle']?.toString(),
      content: json['content']?.toString(),
      responsory: json['responsory']?.toString(),
    );
  }
}

/// Midday office structure (Tierce, Sexte, None)
class HourOffice {
  final String? antiphon;
  final Reading? reading;
  final String? responsory;

  const HourOffice({this.antiphon, this.reading, this.responsory});

  factory HourOffice.fromJson(Map<String, dynamic> json) {
    return HourOffice(
      antiphon: json['antiphon']?.toString(),
      reading: json['reading'] is Map<String, dynamic>
          ? Reading.fromJson(json['reading'] as Map<String, dynamic>)
          : null,
      responsory: json['responsory']?.toString(),
    );
  }
}

/// Context class containing all parameters needed for office resolution.
class CelebrationContext {
  final String celebrationCode;
  final String? ferialCode;
  final String? common;
  final DateTime date;
  final String? liturgicalTime;
  final String? breviaryWeek;
  final int? precedence;
  final bool teDeum;
  final DataLoader dataLoader;

  const CelebrationContext({
    required this.celebrationCode,
    this.ferialCode,
    this.common,
    required this.date,
    this.liturgicalTime,
    this.breviaryWeek,
    this.precedence,
    this.teDeum = false,
    required this.dataLoader,
  });
}
