import 'dart:io';

/// Abstract interface for loading data files (JSON, YAML, etc.)
/// Keeps the offline_liturgy package independent from Flutter
abstract class DataLoader {
  /// Loads a JSON file from a relative path
  ///
  /// [relativePath]: relative path from the assets/ folder
  /// Example: 'calendar_data/special_days/immaculate_conception.json'
  ///
  /// Returns the file content as a String, or an empty String if the file doesn't exist
  Future<String> loadJson(String relativePath);

  /// Loads a YAML file from a relative path
  ///
  /// [relativePath]: relative path from the assets/ folder
  /// Example: 'hymns/debout-le-seigneur-vient.yaml'
  ///
  /// Returns the file content as a String, or an empty String if the file doesn't exist
  Future<String> loadYaml(String relativePath);
}

/// DataLoader for pure Dart usage (without Flutter)
/// Reads files from the local file system
///
/// Usage:
/// ```dart
/// final dataLoader = FileSystemDataLoader();
/// final complines = await complineDefinitionResolution(calendar, date, dataLoader);
/// ```
class FileSystemDataLoader implements DataLoader {
  /// Assets path prefix (default: './assets/')
  final String assetsPrefix;

  FileSystemDataLoader({this.assetsPrefix = './assets/'});

  @override
  Future<String> loadJson(String relativePath) async {
    try {
      print('*********** DATALOADER: trying to load $relativePath');
      final file = File('$assetsPrefix$relativePath');

      // Check if file exists
      if (!file.existsSync()) {
        return '';
      }

      // Read file content
      return await file.readAsString();
    } catch (e) {
      // In case of error (permissions, encoding, etc.), return empty string
      return '';
    }
  }

  @override
  Future<String> loadYaml(String relativePath) async {
    try {
      print('*********** DATALOADER: trying to load YAML $relativePath');
      final file = File('$assetsPrefix$relativePath');

      // Check if file exists
      if (!file.existsSync()) {
        return '';
      }

      // Read file content
      return await file.readAsString();
    } catch (e) {
      // In case of error (permissions, encoding, etc.), return empty string
      return '';
    }
  }
}
