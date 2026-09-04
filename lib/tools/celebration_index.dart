import 'dart:convert';
import 'data_loader.dart';
import 'constants.dart';

Future<Map<String, String>>? _indexFuture;

Future<Map<String, String>> _buildIndex(DataLoader dataLoader) async {
  final raw = await dataLoader.loadJson('calendar_data/index.json');
  final map = <String, String>{};
  if (raw.isEmpty) return map;
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  for (final e in decoded.entries) {
    final dir = (e.value as Map<String, dynamic>)['dir'] as String?;
    if (dir != null) map[e.key] = dir;
  }
  return map;
}

/// Returns the shared index (code → directory name), content-addressed —
/// not by which DataLoader instance fetched it, since a fresh loader is
/// created per call in some consumers (e.g. Flutter) despite always
/// resolving the same underlying asset source.
/// Loads once on first call; all callers share the same Future.
Future<Map<String, String>> celebrationDirIndex(DataLoader dataLoader) {
  return _indexFuture ??= _buildIndex(dataLoader);
}

/// Returns the asset path prefix for a celebration code, e.g. 'calendar_data/sanctoral'.
Future<String> dirPathForCode(String code, DataLoader dataLoader) async {
  final index = await celebrationDirIndex(dataLoader);
  return switch (index[code]) {
    'sanctoral' => sanctoralFilePath,
    _           => ferialFilePath,
  };
}
