// classe des hymnes. sert pour tous les offices
class Hymns {
  final String title;
  final String? author;
  final String content;
  // The Latin and Greek variants of this text (currently only set for the
  // Te Deum and the Our Father), offered as an alternative display, never
  // merged into [content].
  final Hymns? latin;
  final Hymns? greek;

  const Hymns({
    required this.title,
    this.author,
    required this.content,
    this.latin,
    this.greek,
  });

  Hymns withLatin(Hymns? latin) {
    return Hymns(
      title: title,
      author: author,
      content: content,
      latin: latin,
      greek: greek,
    );
  }

  Hymns withGreek(Hymns? greek) {
    return Hymns(
      title: title,
      author: author,
      content: content,
      latin: latin,
      greek: greek,
    );
  }
}
