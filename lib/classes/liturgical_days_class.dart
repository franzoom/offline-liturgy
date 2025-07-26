class Celebration {
  final String? code;
  Celebration(this.code);
}

class Priorities {
  final int niveau; // 0: octave pascale, 1: fête, etc.
  final List<Celebration> celebrations;
  Priorities(this.niveau, this.celebrations);
}

class LiturgicalDay {
  final DateTime date;
  int year;
  int? semaineBreviaire;
  List<Priorities> priorities;

  LiturgicalDay({
    required this.date,
    required this.year,
    required this.semaineBreviaire,
    required this.priorities,
  });
}
