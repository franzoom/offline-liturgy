/// Regex to check if a line already ends with "alléluia"
final RegExp _alleluiaEndRegex = RegExp(
  r'alléluia[\s\u00A0]?[.!,]?$',
  caseSensitive: false,
);

/// Regex to capture final punctuation . or ! (with optional preceding space)
final RegExp _finalPunctuationRegex = RegExp(
  r'([\s\u00A0]?)([.!])$',
);

/// Regex to detect a trailing comma
final RegExp _finalCommaRegex = RegExp(r',$');

/// Applies the paschal alléluia transformation to a single line.
String _paschalAntiphonLine(String line) {
  final trimmed = line.trim();

  if (trimmed.isEmpty) return line;

  // Already ends with "alléluia"
  if (_alleluiaEndRegex.hasMatch(trimmed)) return line;

  // Line ends with a comma → append " alléluia,"
  if (_finalCommaRegex.hasMatch(trimmed)) {
    return '$trimmed alléluia,';
  }

  // Insert ", alléluia" before final . or !
  if (_finalPunctuationRegex.hasMatch(trimmed)) {
    return trimmed.replaceFirstMapped(_finalPunctuationRegex, (match) {
      final whitespace = match.group(1) ?? '';
      final punctuation = match.group(2) ?? '';
      return ', alléluia$whitespace$punctuation';
    });
  }

  // No final punctuation
  return '$trimmed, alléluia.';
}

/// Transforms an antiphon by adding "alléluia" during Easter time.
///
/// If [liturgicalTime] is "easter" and a line doesn't already end
/// with "alléluia":
/// - line ending with `,`  → appends ` alléluia,`
/// - line ending with `.` or `!` → inserts `, alléluia` before punctuation
/// - no final punctuation → appends `, alléluia.`
///
/// Multi-line strings are processed line by line and rejoined.
String paschalAntiphon(String antiphon, String liturgicalTime) {
  if (liturgicalTime != 'easter') return antiphon;

  final lines = antiphon.split('\n');
  if (lines.length == 1) return _paschalAntiphonLine(antiphon);

  return lines.map(_paschalAntiphonLine).join('\n');
}
