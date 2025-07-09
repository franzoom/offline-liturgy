// classe des Psaumes et cantiques
class Psalm {
  final String title;
  final String? subtitle;
  final String? commentary;
  final String content;

  Psalm({
    required this.title,
    this.subtitle,
    this.commentary,
    required this.content,
  });
}

class Canticle {
  final String title;
  final String? subtitle;
  final String? biblicalReference;
  final String? shortReference;
  final String? commentary;
  final String content;

  Canticle({
    required this.title,
    this.subtitle,
    this.biblicalReference,
    this.shortReference,
    this.commentary,
    required this.content,
  });
}
