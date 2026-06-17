class Psalm {
  static final _imprecatoryBlock = RegExp(r'\n?\{[^}]+\}\[.*?\]', dotAll: true);

  final String? title;
  final String? subtitle;
  final String? biblicalReference;
  final String? shortReference;
  final String? commentary;
  final String content;
  final List<String>? psalmSVG;

  const Psalm({
    this.title,
    this.subtitle,
    this.biblicalReference,
    this.shortReference,
    this.commentary,
    required this.content,
    this.psalmSVG,
  });

  factory Psalm.fromMap(Map<String, dynamic> data) {
    return Psalm(
      title: data['title']?.toString(),
      subtitle: data['subtitle']?.toString(),
      biblicalReference: data['biblicalReference']?.toString(),
      shortReference: data['shortReference']?.toString(),
      commentary: data['commentary']?.toString(),
      content: data['content']?.toString() ?? '',
      psalmSVG: switch (data['psalmSVG']) {
        String s => [s],
        List l => l.map((e) => e.toString()).toList(),
        _ => null,
      },
    );
  }

  Psalm withoutImprecatoryVerses() {
    return Psalm(
      title: title,
      subtitle: subtitle,
      biblicalReference: biblicalReference,
      shortReference: shortReference,
      commentary: commentary,
      content: content.replaceAll(_imprecatoryBlock, ''),
      psalmSVG: psalmSVG,
    );
  }
}
