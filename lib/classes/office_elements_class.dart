/// Classes for deeply nested structured liturgical office data
library;

import '../tools/data_loader.dart';
import 'psalms_class.dart';
import 'hymns_class.dart';

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
  List<Psalm>? psalmsData;

  Invitatory({this.antiphon, this.psalms, this.psalmsData});

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
  Psalm? psalmData;

  PsalmEntry({this.psalm, this.antiphon, this.psalmData});

  factory PsalmEntry.fromJson(Map<String, dynamic> json) {
    return PsalmEntry(
      psalm: json['psalm']?.toString(),
      antiphon: (json['antiphon'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
}

/// Hymn entry with code and resolved data
class HymnEntry {
  final String code;
  Hymns? hymnData;

  HymnEntry({required this.code, this.hymnData});

  factory HymnEntry.fromJson(dynamic json) =>
      HymnEntry(code: json.toString());
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
  final String? subtitle;
  final String? ref;
  final String? content;
  final String? responsory;

  const BiblicalReading(
      {this.title, this.subtitle, this.ref, this.content, this.responsory});

  factory BiblicalReading.fromJson(Map<String, dynamic> json) {
    return BiblicalReading(
      title: json['title']?.toString(),
      subtitle: json['subtitle']?.toString(),
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
/// This class consolidates MorningDefinition, VespersDefinition, and ReadingsDefinition.
class CelebrationContext {
  final String?
      celebrationType; // e.g. morning, vespers1, vespers2, readings, ...
  final String celebrationCode; // given by the liturgical calendar
  final String? celebrationTitle; // display title (from YAML title or ferial name)
  final String? celebrationGlobalName; // full name with subtitle
  final String? ferialCode; // given by the calendar root of the date
  final List<String>? commonList; // list of commons for the celebration
  final DateTime date;
  final String? liturgicalTime; // given by the calendar root of the date
  final int? breviaryWeek; // given by the calendar root of the date
  final int? precedence; // given by the calendar for the celebration
  final bool teDeum; // further calculation needed for Readings
  final bool isCelebrable; // to be determined later
  final DataLoader dataLoader; // to load required data
  final String? officeDescription; // description of the office
  final String? liturgicalColor; // liturgical color of the celebration
  final String? celebrationDescription; // description of the celebration from YAML
  final Map<String, String> commonTitles; // code -> display title for commons

  const CelebrationContext({
    this.celebrationType,
    required this.celebrationCode,
    this.celebrationTitle,
    this.celebrationGlobalName,
    this.ferialCode,
    this.commonList,
    required this.date,
    this.liturgicalTime,
    this.breviaryWeek,
    this.precedence,
    this.teDeum = false,
    this.isCelebrable = false,
    required this.dataLoader,
    this.officeDescription,
    this.liturgicalColor,
    this.celebrationDescription,
    this.commonTitles = const {},
  });

  /// Returns the first common from commonList.
  /// Returns null if no common is available.
  String? get selectedCommon {
    if (commonList != null && commonList!.isNotEmpty) {
      return commonList!.first;
    }
    return null;
  }

  /// Returns true if this is first vespers (vespers1)
  bool get isFirstVespers => celebrationType == 'vespers1';

  /// Returns true if this is second vespers (vespers2)
  bool get isSecondVespers => celebrationType == 'vespers2';

  /// Creates a copy of this context with the given fields replaced
  CelebrationContext copyWith({
    String? celebrationType,
    String? celebrationCode,
    String? celebrationTitle,
    String? celebrationGlobalName,
    String? ferialCode,
    List<String>? commonList,
    DateTime? date,
    String? liturgicalTime,
    int? breviaryWeek,
    int? precedence,
    bool? teDeum,
    bool? isCelebrable,
    DataLoader? dataLoader,
    String? officeDescription,
    String? liturgicalColor,
    String? celebrationDescription,
    Map<String, String>? commonTitles,
  }) {
    return CelebrationContext(
      celebrationType: celebrationType ?? this.celebrationType,
      celebrationCode: celebrationCode ?? this.celebrationCode,
      celebrationTitle: celebrationTitle ?? this.celebrationTitle,
      celebrationGlobalName:
          celebrationGlobalName ?? this.celebrationGlobalName,
      ferialCode: ferialCode ?? this.ferialCode,
      commonList: commonList ?? this.commonList,
      date: date ?? this.date,
      liturgicalTime: liturgicalTime ?? this.liturgicalTime,
      breviaryWeek: breviaryWeek ?? this.breviaryWeek,
      precedence: precedence ?? this.precedence,
      teDeum: teDeum ?? this.teDeum,
      isCelebrable: isCelebrable ?? this.isCelebrable,
      dataLoader: dataLoader ?? this.dataLoader,
      officeDescription: officeDescription ?? this.officeDescription,
      liturgicalColor: liturgicalColor ?? this.liturgicalColor,
      celebrationDescription:
          celebrationDescription ?? this.celebrationDescription,
      commonTitles: commonTitles ?? this.commonTitles,
    );
  }
}
