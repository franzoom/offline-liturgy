class Compline {
  final String?
      complineCommentary; // sert pour indiquer quand les Complies sont facultatives
  String?
      celebrationType; //indique le nom du jour et si c'est une solennité ou une veille de solennité
  final List<String>? complineHymns;
  final String? complinePsalm1Antiphon1;
  final String? complinePsalm1Antiphon2;
  final String? psalm1Ref;
  final String? complinePsalm2Antiphon1;
  final String? complinePsalm2Antiphon2;
  final String? psalm2Ref;
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
    this.complinePsalm1Antiphon1,
    this.complinePsalm1Antiphon2,
    this.psalm1Ref,
    this.complinePsalm2Antiphon1,
    this.complinePsalm2Antiphon2,
    this.psalm2Ref,
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
