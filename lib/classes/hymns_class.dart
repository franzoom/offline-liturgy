// classe des hymnes. sert pour tous les offices
class Hymns {
  final String title;
  final String? author;
  final String content;

  const Hymns({
    required this.title,
    this.author,
    required this.content,
  });
}
