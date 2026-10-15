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

// The real liturgicalTime values for Easter time (see
// french_liturgy_labels.dart) — 'easter' and 'paschal' never occur as such
// a value, only 'paschaloctave' and 'paschaltime' do.
const _paschalTimes = {'paschaloctave', 'paschaltime'};

/// Applies paschal alléluia to each antiphon of [antiphons], in place.
void applyPaschalToList(List<String>? antiphons, String liturgicalTime) {
  if (antiphons == null) return;
  for (int i = 0; i < antiphons.length; i++) {
    antiphons[i] = paschalAntiphon(antiphons[i], liturgicalTime);
  }
}

/// Applies paschal alléluia to all antiphons in a psalmody list, in place.
void applyPaschalToPsalmody(List<PsalmEntry>? psalmody, String liturgicalTime) {
  for (final entry in psalmody ?? const <PsalmEntry>[]) {
    applyPaschalToList(entry.antiphon, liturgicalTime);
  }
}

/// Applies paschal alléluia to all values of an antiphon map.
/// Returns null if the input is null.
Map<String, List<String>>? applyPaschalToAntiphonMap(
    Map<String, List<String>>? antiphonMap, String liturgicalTime) {
  if (antiphonMap == null) return null;
  return antiphonMap.map((k, list) => MapEntry(
      k, list.map((v) => paschalAntiphon(v, liturgicalTime)).toList()));
}

/// Transforms an antiphon by adding "alléluia" during Easter time.
///
/// If [liturgicalTime] is a paschal time and a line doesn't already end
/// with "alléluia":
/// - line ending with `,`  → appends ` alléluia,`
/// - line ending with `.` or `!` → inserts `, alléluia` before punctuation
/// - no final punctuation → appends `, alléluia.`
///
/// Multi-line strings are processed line by line and rejoined.
String paschalAntiphon(String antiphon, String liturgicalTime) {
  if (!_paschalTimes.contains(liturgicalTime)) return antiphon;

  return antiphon.split('\n').map(_paschalAntiphonLine).join('\n');
}
