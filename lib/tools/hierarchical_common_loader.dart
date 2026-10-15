import '../classes/mass_class.dart';
import '../classes/middle_of_day_class.dart';
import '../classes/morning_class.dart';
import '../classes/readings_class.dart';
import '../classes/vespers_class.dart';
import '../classes/office_elements_class.dart';
import '../tools/constants.dart';
import '../offices/masses/mass_extract.dart';
import '../offices/middle_of_day/middle_of_day_extract.dart';
import '../offices/morning/morning_extract.dart';
import '../offices/readings/readings_extract.dart';
import '../offices/vespers/vespers_extract.dart';
import 'package:offline_liturgy/tools/data_loader.dart';
import '../offices/compose_office.dart';

/// Maps a liturgicalTime value to the suffix used by the seasonal common
/// files (e.g. 'martyrs_paschal.yaml'). The file suffixes are a different
/// vocabulary from liturgicalTime: several values share one suffix
/// ('paschaltime' and 'paschaloctave' both use '_paschal'). Ordinary Time
/// has no seasonal variant.
const Map<String, String> _commonSeasonSuffix = {
  'advent': 'advent',
  'nativity': 'christmas',
  'christmasoctave': 'christmas',
  'christmas': 'christmas',
  'lent': 'lent',
  'holyweek': 'lent',
  'paschaloctave': 'paschal',
  'paschaltime': 'paschal',
};

/// Builds the hierarchy of common file names from a common name.
/// For each cumulative level, also checks the liturgical time variant.
/// For example: 'pastors_bishops' with lent returns:
/// ['pastors', 'pastors_lent', 'pastors_bishops', 'pastors_bishops_lent']
List<String> _buildCommonHierarchy(String commonName, String? liturgicalTime) {
  final cleanName = commonName.trim().toLowerCase();
  final parts = cleanName.split('_');

  final suffix = _commonSeasonSuffix[liturgicalTime];
  final addTimeSuffix = suffix != null && !cleanName.contains('_$suffix');

  final List<String> commonsToTry = [];
  for (int i = 0; i < parts.length; i++) {
    final level = parts.sublist(0, i + 1).join('_');
    commonsToTry.add(level);
    if (addTimeSuffix) {
      commonsToTry.add('${level}_$suffix');
    }
  }
  return commonsToTry;
}

/// Loads every level of the selected common in parallel and overlays them,
/// the most general first; empty when no common is selected.
Future<T> _loadHierarchical<T>({
  required CelebrationContext context,
  required T Function() createEmpty,
  required Future<T> Function(String, DataLoader) extractor,
  required void Function(T base, T overlay) overlayFn,
}) async {
  final common = context.selectedCommon;
  if (common == null) return createEmpty();

  return composeLayers(
    [
      for (final level in _buildCommonHierarchy(common, context.liturgicalTime))
        '$commonsFilePath/$level.yaml',
    ],
    (path) => extractor(path, context.dataLoader),
    overlayFn,
  );
}

// --- PUBLIC API ---

Future<Morning> loadMorningHierarchicalCommon(CelebrationContext context) {
  return _loadHierarchical<Morning>(
    context: context,
    createEmpty: () => Morning(),
    extractor: morningExtract,
    overlayFn: (base, overlay) => base.overlayWith(overlay),
  );
}

Future<Readings> loadReadingsHierarchicalCommon(CelebrationContext context) {
  return _loadHierarchical<Readings>(
    context: context,
    createEmpty: () => Readings(),
    extractor: readingsExtract,
    overlayFn: (base, overlay) => base.overlayWith(overlay),
  );
}

Future<Vespers> loadVespersHierarchicalCommon(CelebrationContext context) {
  final String section = context.vespersSection;
  return _loadHierarchical<Vespers>(
    context: context,
    createEmpty: () => Vespers(),
    extractor: (path, loader) => vespersExtract(path, loader, section: section),
    overlayFn: (base, overlay) => base.overlayWith(overlay),
  );
}

Future<MiddleOfDay> loadMiddleOfDayHierarchicalCommon(
    CelebrationContext context) {
  return _loadHierarchical<MiddleOfDay>(
    context: context,
    createEmpty: () => MiddleOfDay(),
    extractor: middleOfDayExtract,
    overlayFn: (base, overlay) => base.overlayWith(overlay),
  );
}

Future<Masses> loadMassHierarchicalCommon(CelebrationContext context) {
  return _loadHierarchical<Masses>(
    context: context,
    createEmpty: () => Masses(),
    extractor: massExtract,
    overlayFn: (base, overlay) => base.overlayWith(overlay),
  );
}
