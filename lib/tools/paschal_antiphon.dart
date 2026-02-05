/// Regex to check if antiphon already ends with "alléluia"
final RegExp _alleluiaEndRegex = RegExp(
  r'alléluia[\s\u00A0]?[.!]?$',
  caseSensitive: false,
);

/// Regex to capture final punctuation (with optional preceding space)
final RegExp _finalPunctuationRegex = RegExp(
  r'([\s\u00A0]?)([.!])$',
);

/// Transforms an antiphon by adding "alléluia" during Easter time.
///
/// If [liturgicalTime] is "easter" and the antiphon doesn't already end
/// with "alléluia", adds ", alléluia" before the final punctuation (. or !).
/// If there's no final punctuation, adds ", alléluia." at the end.
String paschalAntiphon(String antiphon, String liturgicalTime) {
  if (liturgicalTime != 'easter') {
    return antiphon;
  }

  final trimmed = antiphon.trim();

  if (trimmed.isEmpty) return antiphon;

  // Check if already ends with "alléluia"
  if (_alleluiaEndRegex.hasMatch(trimmed)) {
    return antiphon;
  }

  // Insert ", alléluia" before final punctuation
  if (_finalPunctuationRegex.hasMatch(trimmed)) {
    return trimmed.replaceFirstMapped(_finalPunctuationRegex, (match) {
      final whitespace = match.group(1) ?? '';
      final punctuation = match.group(2) ?? '';
      return ', alléluia$whitespace$punctuation';
    });
  }

  // No final punctuation, add ", alléluia."
  return '$trimmed, alléluia.';
}
