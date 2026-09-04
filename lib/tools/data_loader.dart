import 'dart:io';

// --- DATA LOADER INTERFACE ---

/// Abstract interface to be implemented by the host project (Dart or Flutter)
abstract class DataLoader {
  Future<String> load(String relativePath);
  Future<String> loadJson(String relativePath) => load(relativePath);
  Future<String> loadYaml(String relativePath) => load(relativePath);

  /// Returns the filenames (basename only, e.g. "france.yaml") found under
  /// [prefix] in the asset tree. Default returns an empty list.
  Future<List<String>> listFiles(String prefix) async => const [];
}

/// Default implementation for CLI/Server tools
class FileSystemDataLoader implements DataLoader {
  final String assetsPrefix;
  final Map<String, Future<String>> _cache = {};
  FileSystemDataLoader({this.assetsPrefix = './assets/'});

  @override
  Future<List<String>> listFiles(String prefix) async {
    final dir = Directory('$assetsPrefix$prefix');
    final names = <String>[];
    await for (final entity in dir.list()) {
      if (entity is File) names.add(entity.uri.pathSegments.last);
    }
    return names;
  }

  @override
  Future<String> load(String path) {
    return _cache[path] ??= _readFile(path);
  }

  Future<String> _readFile(String path) async {
    final file = File('$assetsPrefix$path');
    return (await file.exists()) ? await file.readAsString() : '';
  }

  @override
  Future<String> loadJson(String path) => load(path);
  @override
  Future<String> loadYaml(String path) => load(path);
}
