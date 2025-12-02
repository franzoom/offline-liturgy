import '../classes/hymns_class.dart';
import '../assets/libraries/hymns_library.dart';
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
