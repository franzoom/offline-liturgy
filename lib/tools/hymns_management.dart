import '../classes/hymns_class.dart';
import '../classes/office_elements_class.dart';
import '../assets/libraries/hymns_library.dart';
import '../assets/libraries/hymn_list.dart';
import '../tools/data_loader.dart';

/// Filters hymns by their codes from the hymns library.
Future<Map<String, Hymns>> filterHymnsByCodes(
  List<String> titleCodes,
  DataLoader dataLoader,
) async {
  return await HymnsLibrary.getHymns(titleCodes, dataLoader);
}

/// Displays hymns to console for debugging purposes.
void displayHymns(Map<String, Hymns> hymns) {
  for (var hymn in hymns.values) {
    print('Title: ${hymn.title}');
    if (hymn.author != null) {
      print('Author: ${hymn.author}');
    }
    print('Content: ${hymn.content}');
    print('---');
  }
}

// --- HYMN SELECTION LOGIC ---

/// Generic private function to extract hymn codes and map them to [HymnEntry].
/// Centralizes liturgical time handling and the "ordinary" fallback logic.
List<HymnEntry> _getHymnsForOffice(
  String liturgicalTime,
  Map<String, List<String>> sourceList,
) {
  final key = _middleOfDayHymnSeason(liturgicalTime);

  // Retrieve the list based on the key, fallback to 'ordinary', or return an empty list.
  // We use List.from to ensure we are working with a growable List<String>.
  final List<String> codes = List<String>.from(
    sourceList[key] ?? sourceList['ordinary'] ?? [],
  );

  return codes.map((e) => HymnEntry(code: e)).toList();
}

/// Returns the hymn season key specific to middle-of-day offices.
/// Advent and Christmas typically share the same hymn cycle as Ordinary time for these hours.
String _middleOfDayHymnSeason(String liturgicalTime) {
  switch (liturgicalTime) {
    case 'lent':
      return 'lent';
    case 'easter':
      return 'easter';
    default:
      return 'ordinary';
  }
}

// --- PUBLIC API ---

/// Returns the list of hymns for the Tierce office (Mid-morning).
List<HymnEntry> getTierceHymns(String liturgicalTime) {
  return _getHymnsForOffice(liturgicalTime, tierceHymnList);
}

/// Returns the list of hymns for the Sexte office (Midday).
List<HymnEntry> getSexteHymns(String liturgicalTime) {
  return _getHymnsForOffice(liturgicalTime, sexteHymnList);
}

/// Returns the list of hymns for the None office (Mid-afternoon).
List<HymnEntry> getNoneHymns(String liturgicalTime) {
  return _getHymnsForOffice(liturgicalTime, noneHymnList);
}

/// Generic season-based hymn retriever, kept for backward compatibility.
List<HymnEntry> getHymnsForSeason(String seasonKey) {
  final List<String> codes = List<String>.from(hymnList[seasonKey] ?? []);
  return codes.map((e) => HymnEntry(code: e)).toList();
}
