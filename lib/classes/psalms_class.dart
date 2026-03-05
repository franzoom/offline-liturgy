class Psalm {
  final String? title;
  final String? subtitle;
  final String? biblicalReference;
  final String? shortReference;
  final String? commentary;
  final String content;

  const Psalm({
    this.title,
    this.subtitle,
    this.biblicalReference,
    this.shortReference,
    this.commentary,
    required this.content,
  });

  factory Psalm.fromMap(Map<String, dynamic> data) {
    return Psalm(
      title: data['title']?.toString(),
      subtitle: data['subtitle']?.toString(),
      biblicalReference: data['biblicalReference']?.toString(),
      shortReference: data['shortReference']?.toString(),
      commentary: data['commentary']?.toString(),
      content: data['content']?.toString() ?? '', // default value if null
    );
  }
}
