class Compline {
  final String?
      complineCommentary; // sert pour indiquer quand les Complies sont facultatives
  String?
      celebrationType; //indique le nom du jour et si c'est une solennité ou une veille de solennité
  final List<String>? complineHymns;
  final String? complinePsalm1Antiphon;
  final String? complinePsalm1Antiphon2;
  final String? complinePsalm1;
  final String? complinePsalm2Antiphon;
  final String? complinePsalm2Antiphon2;
  final String? complinePsalm2;
  final String? complineReadingRef;
  final String? complineReading;
  final String? complineResponsory;
  final String? complineEvangelicAntiphon;
  final List? complineOration;
  final List<String>? marialHymnRef;

  Compline({
    this.complineCommentary,
    this.celebrationType,
    this.complineHymns,
    this.complinePsalm1Antiphon,
    this.complinePsalm1Antiphon2,
    this.complinePsalm1,
    this.complinePsalm2Antiphon,
    this.complinePsalm2Antiphon2,
    this.complinePsalm2,
    this.complineReadingRef,
    this.complineReading,
    this.complineResponsory,
    this.complineEvangelicAntiphon,
    this.complineOration,
    this.marialHymnRef,
  });
}

class ComplineDefinition {
  /// Cette classe sert à transmettre les information entre la résolution des complies possibles (complineResolution)
  /// et son utilisation (complineDisplay par exemple).
  final String dayOfWeek; // 'sunday', 'monday', etc.
  final String liturgicalTime;
  final String celebrationType; // 'Solemnity', 'SolemnityEve' or 'normal'
  final int priority;

  ComplineDefinition({
    required this.dayOfWeek,
    required this.liturgicalTime,
    required this.celebrationType,
    required this.priority,
  });
}
