import './classes/hymns_class.dart';

Map<String, Hymns> filterHymnsByCodes(
  List<String> titleCodes,
  Map<String, Hymns> complineHymns,
) {
  return {
    for (var code in titleCodes)
      if (complineHymns.containsKey(code)) code: complineHymns[code]!
  };
}

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
