import 'office_elements_class.dart';

/// Class representing the Compline (Night Prayer) structure
class Compline {
  Celebration? celebration;
  String? commentary; // displays commentary if needed (for example: "no complines today")
  String? celebrationType; // indicates if it's a normal day, a solemnity or eve of solemnity
  List<String>? hymns;
  List<PsalmEntry>? psalmody;
  Reading? reading;
  String? responsory;
  EvangelicAntiphon? evangelicAntiphon;
  List<String>? oration;
  List<String>? marialHymnRef;

  Compline({
    this.celebration,
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

  /// Creates Compline instance from YAML/JSON data
  factory Compline.fromJson(Map<String, dynamic> json) {
    return Compline(
      celebration: json['celebration'] != null
          ? Celebration.fromJson(json['celebration'] as Map<String, dynamic>)
          : null,
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
    Celebration? celebration,
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
      celebration: celebration ?? this.celebration,
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

  /// Overlays this Compline instance with data from another Compline instance
  /// Non-null fields from the overlay take precedence
  void overlayWith(Compline overlay) {
    if (overlay.celebration != null) {
      celebration = overlay.celebration;
    }
    if (overlay.commentary != null) {
      commentary = overlay.commentary;
    }
    if (overlay.celebrationType != null) {
      celebrationType = overlay.celebrationType;
    }
    if (overlay.hymns != null) {
      hymns = overlay.hymns;
    }
    if (overlay.psalmody != null) {
      // Smart merge of psalmody: if overlay has antiphons without psalms,
      // merge them with existing psalms
      if (psalmody != null && psalmody!.isNotEmpty) {
        List<PsalmEntry> mergedPsalmody = [];
        for (int i = 0; i < overlay.psalmody!.length; i++) {
          final overlayEntry = overlay.psalmody![i];
          if (overlayEntry.psalm != null) {
            mergedPsalmody.add(overlayEntry);
          } else if (i < psalmody!.length) {
            mergedPsalmody.add(PsalmEntry(
              psalm: psalmody![i].psalm,
              antiphon: overlayEntry.antiphon ?? psalmody![i].antiphon,
            ));
          } else {
            mergedPsalmody.add(overlayEntry);
          }
        }
        psalmody = mergedPsalmody;
      } else {
        psalmody = overlay.psalmody;
      }
    }
    if (overlay.reading != null) {
      reading = overlay.reading;
    }
    if (overlay.responsory != null) {
      responsory = overlay.responsory;
    }
    if (overlay.evangelicAntiphon != null) {
      evangelicAntiphon = overlay.evangelicAntiphon;
    }
    if (overlay.oration != null) {
      oration = overlay.oration;
    }
    if (overlay.marialHymnRef != null) {
      marialHymnRef = overlay.marialHymnRef;
    }
  }

  /// Selective overlay for common
  /// Only overlays: reading, responsory, evangelicAntiphon, oration
  /// Does NOT overlay: celebration, commentary, celebrationType, hymns, psalmody, marialHymnRef
  void overlayWithCommon(Compline commonCompline) {
    if (commonCompline.reading != null) {
      reading = commonCompline.reading;
    }
    if (commonCompline.responsory != null) {
      responsory = commonCompline.responsory;
    }
    if (commonCompline.evangelicAntiphon != null) {
      evangelicAntiphon = commonCompline.evangelicAntiphon;
    }
    if (commonCompline.oration != null) {
      oration = commonCompline.oration;
    }
  }

  /// Returns true if all fields are null (empty Compline)
  bool get isEmpty =>
      celebration == null &&
      commentary == null &&
      celebrationType == null &&
      hymns == null &&
      psalmody == null &&
      reading == null &&
      responsory == null &&
      evangelicAntiphon == null &&
      oration == null &&
      marialHymnRef == null;
}

/// Definition of Compline type for a given day
/// This class is used to transmit informations through the resolution of the possible Complines
///
/// Note: Complines are special - they depend on:
/// - dayOfWeek: determines which psalms to use
/// - liturgicalTime: determines variations (Lent, Paschal, etc.)
/// - celebrationType: 'normal', 'solemnity', 'solemnityeve', etc.
class ComplineDefinition {
  final String
      complineDescription; // description of the office (e.g., "Complies du 2ème dimanche de Carême")
  final String
      celebrationCode; // original code used to identify the celebration (e.g., "CHRISTMAS", "advent_1_0")
  final String
      ferialCode; // code given by the root of the day in Calendar: ferial code or Solemnity
  final List<String>? commonList;
  final String liturgicalTime; // 'ot', 'lent', 'paschal', 'advent', 'christmas'
  final String? breviaryWeek;
  final int precedence;
  final String liturgicalColor;
  final bool
      isCelebrable; // false if a higher precedence celebration prevents this office from being celebrated
  final String?
      celebrationDescription; // detailed description of the celebration from YAML
  final String dayOfWeek; // 'sunday', 'monday', etc. - determines which psalms to use
  final String
      celebrationType; // 'solemnity', 'solemnityeve', 'normal', 'holy_thursday', etc.
  final bool
      isEveCompline; // true if these are Eve Complines (like First Vespers)

  ComplineDefinition({
    required this.complineDescription,
    this.celebrationCode = '',
    this.ferialCode = '',
    this.commonList,
    required this.liturgicalTime,
    this.breviaryWeek,
    this.precedence = 13,
    this.liturgicalColor = 'green',
    this.isCelebrable = true,
    this.celebrationDescription,
    required this.dayOfWeek,
    required this.celebrationType,
    this.isEveCompline = false,
  });

  /// Legacy factory for backwards compatibility with existing code
  factory ComplineDefinition.fromJson(Map<String, dynamic> json) {
    return ComplineDefinition(
      complineDescription: json['complineDescription'] as String,
      celebrationCode: json['celebrationCode'] as String? ?? '',
      ferialCode: json['ferialCode'] as String? ?? '',
      liturgicalTime: json['liturgicalTime'] as String,
      precedence: json['precedence'] as int? ?? 13,
      liturgicalColor: json['liturgicalColor'] as String? ?? 'green',
      isCelebrable: json['isCelebrable'] as bool? ?? true,
      dayOfWeek: json['dayOfWeek'] as String,
      celebrationType: json['celebrationType'] as String,
      isEveCompline: json['isEveCompline'] as bool? ?? false,
    );
  }
}
