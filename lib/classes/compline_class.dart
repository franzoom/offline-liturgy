class Compline {
  final String?
      commentary; // sert pour indiquer quand les Complies sont facultatives
  String?
      celebrationType; //indique le nom du jour et si c'est une solennité ou une veille de solennité
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
