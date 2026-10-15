import 'package:yaml/yaml.dart';
import '../classes/office_elements_class.dart';
import '../tools/data_loader.dart';

// --- HYMN LIST CACHE ---

/// Season → hymn codes, for the hours that pick their hymns by season.
typedef _HymnLists = ({
  Map<String, List<String>> seasons,
  Map<String, List<String>> tierce,
  Map<String, List<String>> sexte,
  Map<String, List<String>> none,
});

/// hymns/000_list.yaml, loaded once and shared by concurrent callers. A
/// failed load is not kept, so that the next call retries.
Future<_HymnLists>? _hymnLists;

Map<String, List<String>> _toStringListMap(dynamic yamlMap) {
  final result = <String, List<String>>{};
  for (final entry in (yamlMap as Map).entries) {
    result[entry.key as String] =
        (entry.value as YamlList).map((e) => e as String).toList();
  }
  return result;
}

Future<_HymnLists> _loadHymnLists(DataLoader dataLoader) =>
    _hymnLists ??= () async {
      try {
        final content = await dataLoader.loadYaml('hymns/000_list.yaml');
        if (content.isEmpty) {
          throw Exception(
              'Asset not found: hymns/000_list.yaml — run flutter pub get');
        }
        final parsed = loadYaml(content);
        if (parsed is! Map) {
          throw Exception('Invalid YAML structure in hymns/000_list.yaml');
        }
        return (
          seasons: _toStringListMap(parsed['hymn_list']),
          tierce: _toStringListMap(parsed['tierce_hymn_list']),
          sexte: _toStringListMap(parsed['sexte_hymn_list']),
          none: _toStringListMap(parsed['none_hymn_list']),
        );
      } catch (_) {
        _hymnLists = null;
        rethrow;
      }
    }();

// --- HYMN SELECTION LOGIC ---

List<HymnEntry> _getHymnsForOffice(
  String liturgicalTime,
  Map<String, List<String>> sourceList,
) {
  final key = _middleOfDayHymnSeason(liturgicalTime);
  final List<String> codes = List<String>.from(
    sourceList[key] ?? sourceList['ordinary'] ?? [],
  );
  return codes.map((e) => HymnEntry(code: e)).toList();
}

// 'easter' on the right is the hymn library's own season key (000_list.yaml),
// a different vocabulary from the liturgicalTime values matched on the left
// — 'easter' never occurs as a liturgicalTime value (see
// french_liturgy_labels.dart), so it's not one of the input cases.
String _middleOfDayHymnSeason(String liturgicalTime) =>
    switch (liturgicalTime) {
      'lent' || 'holyweek' => 'lent',
      'paschaloctave' || 'paschaltime' => 'easter',
      _ => 'ordinary',
    };

// --- PUBLIC API ---

/// Returns the list of hymns for the Tierce office (Mid-morning).
Future<List<HymnEntry>> getTierceHymns(
    String liturgicalTime, DataLoader dataLoader) async {
  final lists = await _loadHymnLists(dataLoader);
  return _getHymnsForOffice(liturgicalTime, lists.tierce);
}

/// Returns the list of hymns for the Sexte office (Midday).
Future<List<HymnEntry>> getSexteHymns(
    String liturgicalTime, DataLoader dataLoader) async {
  final lists = await _loadHymnLists(dataLoader);
  return _getHymnsForOffice(liturgicalTime, lists.sexte);
}

/// Returns the list of hymns for the None office (Mid-afternoon).
Future<List<HymnEntry>> getNoneHymns(
    String liturgicalTime, DataLoader dataLoader) async {
  final lists = await _loadHymnLists(dataLoader);
  return _getHymnsForOffice(liturgicalTime, lists.none);
}

/// Generic season-based hymn retriever.
Future<List<HymnEntry>> getHymnsForSeason(
    String seasonKey, DataLoader dataLoader) async {
  final lists = await _loadHymnLists(dataLoader);
  final List<String> codes = List<String>.from(lists.seasons[seasonKey] ?? []);
  return codes.map((e) => HymnEntry(code: e)).toList();
}
