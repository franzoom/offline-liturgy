import 'package:yaml/yaml.dart';
import '../classes/office_elements_class.dart';
import '../tools/data_loader.dart';

// --- HYMN LIST CACHE ---

Map<String, List<String>>? _hymnList;
Map<String, List<String>>? _tierceHymnList;
Map<String, List<String>>? _sexteHymnList;
Map<String, List<String>>? _noneHymnList;

Map<String, List<String>> _toStringListMap(dynamic yamlMap) {
  final result = <String, List<String>>{};
  for (final entry in (yamlMap as Map).entries) {
    result[entry.key as String] =
        (entry.value as YamlList).map((e) => e as String).toList();
  }
  return result;
}

Future<void> _ensureHymnListLoaded(DataLoader dataLoader) async {
  if (_hymnList != null) return;
  final content = await dataLoader.loadYaml('hymns/000_list.yaml');
  if (content.isEmpty) {
    throw Exception(
        'Asset not found: hymns/000_list.yaml — run flutter pub get');
  }
  final parsed = loadYaml(content);
  if (parsed == null || parsed is! Map) {
    throw Exception('Invalid YAML structure in hymnes/000_list.yaml');
  }
  _hymnList = _toStringListMap(parsed['hymn_list']);
  _tierceHymnList = _toStringListMap(parsed['tierce_hymn_list']);
  _sexteHymnList = _toStringListMap(parsed['sexte_hymn_list']);
  _noneHymnList = _toStringListMap(parsed['none_hymn_list']);
}

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
  await _ensureHymnListLoaded(dataLoader);
  return _getHymnsForOffice(liturgicalTime, _tierceHymnList!);
}

/// Returns the list of hymns for the Sexte office (Midday).
Future<List<HymnEntry>> getSexteHymns(
    String liturgicalTime, DataLoader dataLoader) async {
  await _ensureHymnListLoaded(dataLoader);
  return _getHymnsForOffice(liturgicalTime, _sexteHymnList!);
}

/// Returns the list of hymns for the None office (Mid-afternoon).
Future<List<HymnEntry>> getNoneHymns(
    String liturgicalTime, DataLoader dataLoader) async {
  await _ensureHymnListLoaded(dataLoader);
  return _getHymnsForOffice(liturgicalTime, _noneHymnList!);
}

/// Generic season-based hymn retriever.
Future<List<HymnEntry>> getHymnsForSeason(
    String seasonKey, DataLoader dataLoader) async {
  await _ensureHymnListLoaded(dataLoader);
  final List<String> codes = List<String>.from(_hymnList![seasonKey] ?? []);
  return codes.map((e) => HymnEntry(code: e)).toList();
}
