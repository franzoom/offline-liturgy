import 'dart:io';
import 'dart:async';

// Office classes imports
import '../classes/middle_of_day_class.dart';
import '../classes/morning_class.dart';
import '../classes/readings_class.dart';
import '../classes/vespers_class.dart';
import '../classes/office_elements_class.dart';
import '../tools/constants.dart';
import '../offices/middle_of_day/middle_of_day_extract.dart';
import '../offices/morning/morning_extract.dart';
import '../offices/readings/readings_extract.dart';
import '../offices/vespers/vespers_extract.dart';

// --- DATA LOADER INTERFACE ---

/// Abstract interface to be implemented by the host project (Dart or Flutter)
abstract class DataLoader {
  Future<String> load(String relativePath);
  Future<String> loadJson(String relativePath) => load(relativePath);
  Future<String> loadYaml(String relativePath) => load(relativePath);
}

/// Default implementation for CLI/Server tools
class FileSystemDataLoader implements DataLoader {
  final String assetsPrefix;
  FileSystemDataLoader({this.assetsPrefix = './assets/'});

  @override
  Future<String> load(String path) async {
    final file = File('$assetsPrefix$path');
    return (await file.exists()) ? await file.readAsString() : '';
  }

  @override
  Future<String> loadJson(String path) => load(path);
  @override
  Future<String> loadYaml(String path) => load(path);
}

// --- HIERARCHICAL LOGIC ---

/// Builds the file hierarchy (e.g., 'pastors_bishops_lent')
List<String> _buildCommonHierarchy(String commonName, String? liturgicalTime) {
  final cleanName = commonName.trim().toLowerCase();
  final parts = cleanName.split('_');
  final isPrivileged =
      liturgicalTime != null && privilegedTimes.contains(liturgicalTime);
  final addTimeSuffix = isPrivileged && !cleanName.contains('_$liturgicalTime');

  final List<String> commons = [];
  for (int i = 0; i < parts.length; i++) {
    final level = parts.sublist(0, i + 1).join('_');
    commons.add(level);
    if (addTimeSuffix) commons.add('${level}_$liturgicalTime');
  }
  return commons;
}

/// Generic helper to load and overlay files in parallel
Future<T> _loadHierarchical<T>({
  required CelebrationContext context,
  required T Function() createEmpty,
  required Future<T> Function(String, DataLoader) extractor,
  required void Function(T, T) overlayFn,
}) async {
  if (context.selectedCommon == null) return createEmpty();

  final hierarchy =
      _buildCommonHierarchy(context.selectedCommon!, context.liturgicalTime);
  final result = createEmpty();

  // Parallel fetch, then sequential overlay
  final tasks = hierarchy.map(
      (lvl) => extractor('$commonsFilePath/$lvl.yaml', context.dataLoader));
  final allData = await Future.wait(tasks);

  for (final data in allData) {
    overlayFn(result, data);
  }
  return result;
}

// --- PUBLIC API ---

Future<Morning> loadMorningHierarchicalCommon(CelebrationContext context) =>
    _loadHierarchical<Morning>(
        context: context,
        createEmpty: () => Morning(),
        extractor: morningExtract,
        overlayFn: (b, o) => b.overlayWith(o));

Future<Readings> loadReadingsHierarchicalCommon(CelebrationContext context) =>
    _loadHierarchical<Readings>(
        context: context,
        createEmpty: () => Readings(),
        extractor: readingsExtract,
        overlayFn: (b, o) => b.overlayWith(o));

Future<Vespers> loadVespersHierarchicalCommon(CelebrationContext context) =>
    _loadHierarchical<Vespers>(
        context: context,
        createEmpty: () => Vespers(),
        extractor: vespersExtract,
        overlayFn: (b, o) => b.overlayWith(o));

Future<MiddleOfDay> loadMiddleOfDayHierarchicalCommon(
        CelebrationContext context) =>
    _loadHierarchical<MiddleOfDay>(
        context: context,
        createEmpty: () => MiddleOfDay(),
        extractor: middleOfDayExtract,
        overlayFn: (b, o) => b.overlayWith(o));
