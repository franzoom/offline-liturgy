class Celebration {
  final String? code;
  Celebration(this.code);
}

class Priorite {
  final int niveau; // 0: octave pascale, 1: fête, etc.
  final List<Celebration> celebrations;
  Priorite(this.niveau, this.celebrations);
}

class JourLiturgique {
  final DateTime date;
  int year;
  int? semaineBreviaire;
  List<Priorite> priorites;

  JourLiturgique({
    required this.date,
    required this.year,
    required this.semaineBreviaire,
    required this.priorites,
  });
}
