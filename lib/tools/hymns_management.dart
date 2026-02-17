import '../classes/hymns_class.dart';
import '../classes/office_elements_class.dart';
import '../assets/libraries/hymns_library.dart';
import '../assets/libraries/hymn_list.dart';
import '../tools/data_loader.dart';

/// Filters hymns by their codes from the hymns library
Future<Map<String, Hymns>> filterHymnsByCodes(
  List<String> titleCodes,
  DataLoader dataLoader,
) async {
  return await HymnsLibrary.getHymns(titleCodes, dataLoader);
}

/// Displays hymns to console (for debugging)
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

List<HymnEntry> getHymnsForSeason(String seasonKey) {
  // On récupère la liste de Strings depuis ton fichier hymn_list.dart
  final List<String> codes = List<String>.from(hymnList[seasonKey] ?? []);

  // On mappe vers la classe HymnEntry
  return codes.map((e) => HymnEntry(code: e)).toList();
}

/// Returns the hymn season key for middle of day offices.
/// Ordinary time, advent and christmas all use "ordinary".
/// Lent uses "lent", Easter uses "easter".
String _middleOfDayHymnSeason(String liturgicalTime) {
  if (liturgicalTime == 'lent') return 'lent';
  if (liturgicalTime == 'easter') return 'easter';
  return 'ordinary';
}

List<HymnEntry> getTierceHymns(String liturgicalTime) {
  final key = _middleOfDayHymnSeason(liturgicalTime);
  final List<String> codes =
      List<String>.from(tierceHymnList[key] ?? tierceHymnList['ordinary'] ?? []);
  return codes.map((e) => HymnEntry(code: e)).toList();
}

List<HymnEntry> getSexteHymns(String liturgicalTime) {
  final key = _middleOfDayHymnSeason(liturgicalTime);
  final List<String> codes =
      List<String>.from(sexteHymnList[key] ?? sexteHymnList['ordinary'] ?? []);
  return codes.map((e) => HymnEntry(code: e)).toList();
}

List<HymnEntry> getNoneHymns(String liturgicalTime) {
  final key = _middleOfDayHymnSeason(liturgicalTime);
  final List<String> codes =
      List<String>.from(noneHymnList[key] ?? noneHymnList['ordinary'] ?? []);
  return codes.map((e) => HymnEntry(code: e)).toList();
}
