import '../classes/office_elements_class.dart';

/// Regex to check if "alléluia" appears anywhere in a line
final RegExp _alleluiaRegex = RegExp(r'alléluia', caseSensitive: false);

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

  // Already contains "alléluia"
  if (_alleluiaRegex.hasMatch(trimmed)) return line;

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

const _paschalTimes = {'easter', 'paschaloctave', 'paschaltime', 'paschal'};

/// Transforms an antiphon by adding "alléluia" during Easter time.
///
/// If [liturgicalTime] is a paschal time and a line doesn't already end
/// with "alléluia":
/// - line ending with `,`  → appends ` alléluia,`
/// - line ending with `.` or `!` → inserts `, alléluia` before punctuation
/// - no final punctuation → appends `, alléluia.`
///
/// Multi-line strings are processed line by line and rejoined.
/// Applies paschal alléluia to all antiphons in a psalmody list, in place.
void applyPaschalToPsalmody(List<PsalmEntry>? psalmody, String liturgicalTime) {
  if (psalmody == null) return;
  for (final entry in psalmody) {
    final antiphon = entry.antiphon;
    if (antiphon != null) {
      for (int i = 0; i < antiphon.length; i++) {
        antiphon[i] = paschalAntiphon(antiphon[i], liturgicalTime);
      }
    }
  }
}

/// Applies paschal alléluia to all values of an antiphon map.
/// Returns null if the input is null.
Map<String, String>? applyPaschalToAntiphonMap(
    Map<String, String>? antiphonMap, String liturgicalTime) {
  if (antiphonMap == null) return null;
  return antiphonMap
      .map((k, v) => MapEntry(k, paschalAntiphon(v, liturgicalTime)));
}

String paschalAntiphon(String antiphon, String liturgicalTime) {
  if (!_paschalTimes.contains(liturgicalTime)) return antiphon;

  final lines = antiphon.split('\n');
  if (lines.length == 1) return _paschalAntiphonLine(antiphon);

  return lines.map(_paschalAntiphonLine).join('\n');
}
