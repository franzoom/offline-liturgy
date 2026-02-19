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
import 'package:offline_liturgy/tools/data_loader.dart';

/// Builds the hierarchy of common file names from a common name.
/// For each cumulative level, also checks the liturgical time variant.
/// For example: 'pastors_bishops' with lent returns:
/// ['pastors', 'pastors_lent', 'pastors_bishops', 'pastors_bishops_lent']
List<String> _buildCommonHierarchy(String commonName, String? liturgicalTime) {
  final cleanName = commonName.trim().toLowerCase();
  final parts = cleanName.split('_');

  final isPrivileged =
      liturgicalTime != null && privilegedTimes.contains(liturgicalTime);
  final alreadyHasTime = isPrivileged && cleanName.contains('_$liturgicalTime');
  final addTimeSuffix = isPrivileged && !alreadyHasTime;

  final List<String> commonsToTry = [];
  for (int i = 0; i < parts.length; i++) {
    final level = parts.sublist(0, i + 1).join('_');
    commonsToTry.add(level);
    if (addTimeSuffix) {
      commonsToTry.add('${level}_$liturgicalTime');
    }
  }
  return commonsToTry;
}

/// Generic internal loader.
/// It explicitly types the extractor to ensure DataLoader is recognized.
Future<T> _loadHierarchical<T>({
  required CelebrationContext context,
  required T Function() createEmpty,
  required Future<T> Function(String, DataLoader) extractor,
  required void Function(T base, T overlay) overlayFn,
}) async {
  final common = context.selectedCommon;
  if (common == null) return createEmpty();

  final hierarchy = _buildCommonHierarchy(common, context.liturgicalTime);
  final result = createEmpty();

  // Load all files in parallel
  final List<Future<T>> tasks = hierarchy.map((level) {
    final path = '$commonsFilePath/$level.yaml';
    return extractor(path, context.dataLoader);
  }).toList();

  final List<T> allData = await Future.wait(tasks);

  // Apply overlays in order
  for (final data in allData) {
    overlayFn(result, data);
  }

  return result;
}

// --- PUBLIC API ---

Future<Morning> loadMorningHierarchicalCommon(CelebrationContext context) {
  return _loadHierarchical<Morning>(
    context: context,
    createEmpty: () => Morning(),
    extractor: (path, loader) => morningExtract(path, loader),
    overlayFn: (base, overlay) => base.overlayWith(overlay),
  );
}

Future<Readings> loadReadingsHierarchicalCommon(CelebrationContext context) {
  return _loadHierarchical<Readings>(
    context: context,
    createEmpty: () => Readings(),
    extractor: (path, loader) => readingsExtract(path, loader),
    overlayFn: (base, overlay) => base.overlayWith(overlay),
  );
}

Future<Vespers> loadVespersHierarchicalCommon(CelebrationContext context) {
  return _loadHierarchical<Vespers>(
    context: context,
    createEmpty: () => Vespers(),
    extractor: (path, loader) => vespersExtract(path, loader),
    overlayFn: (base, overlay) => base.overlayWith(overlay),
  );
}

Future<MiddleOfDay> loadMiddleOfDayHierarchicalCommon(
    CelebrationContext context) {
  return _loadHierarchical<MiddleOfDay>(
    context: context,
    createEmpty: () => MiddleOfDay(),
    extractor: (path, loader) => middleOfDayExtract(path, loader),
    overlayFn: (base, overlay) => base.overlayWith(overlay),
  );
}
