// classe des Psaumes et cantiques
class Psalm {
  final String? title;
  final String? subtitle;
  final String? biblicalReference;
  final String? shortReference;
  final String? commentary;
  final String content;

  Psalm({
    required this.title,
    this.subtitle,
    this.biblicalReference,
    this.shortReference,
    this.commentary,
    required this.content,
  });

// configuration des getters
  String? get getTitle => title;
  String? get getSubtitle => subtitle;
  String? get getBiblicalReference => biblicalReference;
  String? get getShortReference => shortReference;
  String? get getCommentary => commentary;
  String get getContent => content;
}
