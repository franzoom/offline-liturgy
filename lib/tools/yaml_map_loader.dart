import 'dart:developer';

import 'package:yaml/yaml.dart';
import 'data_loader.dart';

/// Number of parsed files kept: enough for a whole day (detection, then
/// every office reading the same ferial, proper and common files) without
/// keeping the whole asset tree in memory.
const _maxParsedFiles = 256;

/// Parsed files by path, most recently used last. Keyed by path only, like
/// the other caches of the package: some consumers (e.g. Flutter) create a
/// fresh DataLoader per call for the same asset source.
final Map<String, Future<Map<String, dynamic>?>> _parsed = {};

/// Loads the YAML file at [relativePath] as a map, or null if the file is
/// missing, empty, invalid or not a map (an invalid file is logged).
///
/// Each file is parsed once and shared, also between concurrent callers:
/// the returned maps and lists are unmodifiable — build new objects from
/// them, never change them in place.
Future<Map<String, dynamic>?> loadYamlMap(
    String relativePath, DataLoader dataLoader) {
  final cached = _parsed.remove(relativePath);
  if (cached != null) return _parsed[relativePath] = cached;

  final future = _parse(relativePath, dataLoader);
  _parsed[relativePath] = future;
  if (_parsed.length > _maxParsedFiles) _parsed.remove(_parsed.keys.first);
  return future;
}

Future<Map<String, dynamic>?> _parse(
    String relativePath, DataLoader dataLoader) async {
  try {
    final content = await dataLoader.loadYaml(relativePath);
    if (content.isEmpty) return null;
    final data = _frozen(loadYaml(content));
    return data is Map<String, dynamic> ? data : null;
  } catch (e) {
    // Not kept: a read error may be transient, unlike a missing file
    _parsed.remove(relativePath);
    log('Cannot parse $relativePath',
        name: 'YamlMapLoader', level: 1000, error: e);
    return null;
  }
}

/// Converts YAML maps and lists into unmodifiable Dart ones, with string
/// keys, recursively.
dynamic _frozen(dynamic value) => switch (value) {
      YamlMap map => Map<String, dynamic>.unmodifiable({
          for (final e in map.entries) e.key.toString(): _frozen(e.value),
        }),
      YamlList list => List<dynamic>.unmodifiable(list.map(_frozen)),
      _ => value,
    };
