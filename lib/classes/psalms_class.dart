class Psalm {
  // The verse number is optional: an imprecatory block may start mid-verse
  // (e.g. Psalm 58, inside verse 6).
  static final _imprecatoryBlock =
      RegExp(r'\n?(\{[^}]+\})?\[.*?\]', dotAll: true);

  final String? title;
  final String? subtitle;
  final String? biblicalReference;
  final String? shortReference;
  final String? commentary;
  final String content;
  // The Latin and Greek variants of this text (currently only set for the
  // evangelic canticles: Magnificat, Benedictus, Nunc dimittis), offered as
  // an alternative display, never merged into [content].
  final Psalm? latin;
  final Psalm? greek;
  // The Hebrew variant (set for PSALM_x psalms), same display role.
  final Psalm? hebrew;

  const Psalm({
    this.title,
    this.subtitle,
    this.biblicalReference,
    this.shortReference,
    this.commentary,
    required this.content,
    this.latin,
    this.greek,
    this.hebrew,
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

  Psalm withoutImprecatoryVerses() {
    return Psalm(
      title: title,
      subtitle: subtitle,
      biblicalReference: biblicalReference,
      shortReference: shortReference,
      commentary: commentary,
      content: content.replaceAll(_imprecatoryBlock, ''),
      latin: latin?.withoutImprecatoryVerses(),
      greek: greek?.withoutImprecatoryVerses(),
      hebrew: hebrew?.withoutImprecatoryVerses(),
    );
  }

  Psalm withLatin(Psalm? latin) {
    return Psalm(
      title: title,
      subtitle: subtitle,
      biblicalReference: biblicalReference,
      shortReference: shortReference,
      commentary: commentary,
      content: content,
      latin: latin,
      greek: greek,
      hebrew: hebrew,
    );
  }

  Psalm withGreek(Psalm? greek) {
    return Psalm(
      title: title,
      subtitle: subtitle,
      biblicalReference: biblicalReference,
      shortReference: shortReference,
      commentary: commentary,
      content: content,
      latin: latin,
      greek: greek,
      hebrew: hebrew,
    );
  }

  Psalm withHebrew(Psalm? hebrew) {
    return Psalm(
      title: title,
      subtitle: subtitle,
      biblicalReference: biblicalReference,
      shortReference: shortReference,
      commentary: commentary,
      content: content,
      latin: latin,
      greek: greek,
      hebrew: hebrew,
    );
  }
}
