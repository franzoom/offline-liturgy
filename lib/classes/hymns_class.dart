// classe des hymnes. sert pour tous les offices
class Hymns {
  final String title;
  final String? author;
  final String content;
  // The Latin variant of this text (currently only set for the Te Deum),
  // offered as an alternative display, never merged into [content].
  final Hymns? latin;

  const Hymns({
    required this.title,
    this.author,
    required this.content,
    this.latin,
  });

  Hymns withLatin(Hymns? latin) {
    return Hymns(
      title: title,
      author: author,
      content: content,
      latin: latin,
    );
  }
}
