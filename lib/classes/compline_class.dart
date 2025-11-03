class Compline {
  final String?
      commentary; // displays commentary if needed (for example: "no complines today")
  String?
      celebrationType; // indicates if it's a normal day, a solemnity or eve of solemnity
  final List<String>? hymns;
  final List<Map<String, dynamic>>? psalmody;
  final Map<String, String>? reading;
  final String? responsory;
  final String? evangelicAntiphon;
  final List? oration;
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
}

class ComplineDefinition {
  /// This class is used to transmit informations througt the resolution fo the possible Complines
  /// and thier use
  final String
      complineDescription; // will receive the description of the office
  // for example "complines of the 2d sunday of Lent"
  final String dayOfWeek; // 'sunday', 'monday', etc.
  final String liturgicalTime;
  final String celebrationType; // 'solemnity', 'solemnityEve' or 'normal'
  final int priority;

  ComplineDefinition({
    required this.complineDescription,
    required this.dayOfWeek,
    required this.liturgicalTime,
    required this.celebrationType,
    required this.priority,
  });
}
