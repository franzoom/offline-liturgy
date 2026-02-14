import 'office_elements_class.dart';

/// Class representing the Compline (Night Prayer) structure
class Compline {
  Celebration? celebration;
  String?
      commentary; // displays commentary if needed (for example: "no complines today")
  String?
      celebrationType; // indicates if it's a normal day, a solemnity or eve of solemnity
  List<HymnEntry>? hymns;
  List<PsalmEntry>? psalmody;
  Reading? reading;
  String? responsory;
  EvangelicAntiphon? evangelicAntiphon;
  List<String>? oration;
  List<HymnEntry>? marialHymnRef;

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

  /// Merges another Compline onto this one (non-null fields from other take precedence)
  Compline mergeWith(Compline other) {
    return copyWith(
      commentary: other.commentary,
      celebrationType: other.celebrationType,
      hymns: other.hymns,
      psalmody: other.psalmody,
      reading: other.reading,
      responsory: other.responsory,
      evangelicAntiphon: other.evangelicAntiphon,
      oration: other.oration,
      marialHymnRef: other.marialHymnRef,
    );
  }

  /// Creates a copy of this Compline with some fields replaced
  Compline copyWith({
    Celebration? celebration,
    String? commentary,
    String? celebrationType,
    List<HymnEntry>? hymns,
    List<PsalmEntry>? psalmody,
    Reading? reading,
    String? responsory,
    EvangelicAntiphon? evangelicAntiphon,
    List<String>? oration,
    List<HymnEntry>? marialHymnRef,
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
  final String liturgicalTime; // 'ot', 'lent', 'paschal', 'advent', 'christmas'
  final int precedence;
  final String liturgicalColor;
  final bool
      isCelebrable; // false if a higher precedence celebration prevents this office from being celebrated
  final String
      dayOfCompline; // 'sunday', 'monday', etc. - determines which psalms to use
  final String
      celebrationType; // 'solemnity', 'solemnityeve', 'normal', 'holy_thursday', etc.
  final bool
      isEveCompline; // true if these are Eve Complines (like First Vespers)

  ComplineDefinition({
    required this.complineDescription,
    this.celebrationCode = '',
    this.ferialCode = '',
    required this.liturgicalTime,
    this.precedence = 13,
    this.liturgicalColor = 'green',
    this.isCelebrable = true,
    required this.dayOfCompline,
    required this.celebrationType,
    this.isEveCompline = false,
  });
}
