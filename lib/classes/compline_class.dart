import 'office_elements_class.dart';

/// Class representing the Compline structure
class Compline {
  final String?
      commentary; // displays commentary if needed (for example: "no complines today")
  String?
      celebrationType; // indicates if it's a normal day, a solemnity or eve of solemnity
  final List<String>? hymns;
  final List<PsalmEntry>? psalmody;
  final Reading? reading;
  final String? responsory;
  final EvangelicAntiphon? evangelicAntiphon;
  final List<String>? oration;
  final List<String>? marialHymnRef;

  Compline({
    this.commentary,
    this.celebrationType,
    this.hymns,
    this.psalmody,
    this.reading,
    this.responsory,
    this.evangelicAntiphon,
    this.oration,
    this.marialHymnRef,
  });

  /// Creates Compline instance from JSON data
  factory Compline.fromJson(Map<String, dynamic> json) {
    return Compline(
      commentary: json['commentary'] as String?,
      celebrationType: json['celebrationType'] as String?,
      hymns: json['hymns'] != null ? List<String>.from(json['hymns']) : null,
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
          ? (json['evangelicAntiphon'] is String
              ? EvangelicAntiphon(common: json['evangelicAntiphon'] as String)
              : EvangelicAntiphon.fromJson(
                  json['evangelicAntiphon'] as Map<String, dynamic>))
          : null,
      oration:
          json['oration'] != null ? List<String>.from(json['oration']) : null,
      marialHymnRef: json['marialHymnRef'] != null
          ? List<String>.from(json['marialHymnRef'])
          : null,
    );
  }

  /// Creates a copy of this Compline with some fields replaced
  /// Use this method to merge/overlay Complines: base.copyWith(override)
  Compline copyWith({
    String? commentary,
    String? celebrationType,
    List<String>? hymns,
    List<PsalmEntry>? psalmody,
    Reading? reading,
    String? responsory,
    EvangelicAntiphon? evangelicAntiphon,
    List<String>? oration,
    List<String>? marialHymnRef,
  }) {
    return Compline(
      commentary: commentary ?? this.commentary,
      celebrationType: celebrationType ?? this.celebrationType,
      hymns: hymns ?? this.hymns,
      psalmody: psalmody ?? this.psalmody,
      reading: reading ?? this.reading,
      responsory: responsory ?? this.responsory,
      evangelicAntiphon: evangelicAntiphon ?? this.evangelicAntiphon,
      oration: oration ?? this.oration,
      marialHymnRef: marialHymnRef ?? this.marialHymnRef,
    );
  }
}

/// Definition of Compline type for a given day
/// This class is used to transmit informations through the resolution of the possible Complines
class ComplineDefinition {
  final String
      complineDescription; // description of the office (e.g., "complines of the 2nd sunday of Lent")
  final String dayOfWeek; // 'sunday', 'monday', etc.
  final String liturgicalTime;
  final String celebrationType; // 'solemnity', 'solemnityEve' or 'normal'
  int? precedence;

  ComplineDefinition({
    required this.complineDescription,
    required this.dayOfWeek,
    required this.liturgicalTime,
    required this.celebrationType,
    this.precedence,
  });

  factory ComplineDefinition.fromJson(Map<String, dynamic> json) {
    return ComplineDefinition(
      complineDescription: json['complineDescription'] as String,
      dayOfWeek: json['dayOfWeek'] as String,
      liturgicalTime: json['liturgicalTime'] as String,
      celebrationType: json['celebrationType'] as String,
      precedence: json['precedence'] as int,
    );
  }
}
