import '../classes/morning_class.dart';
import '../classes/readings_class.dart';
import '../classes/vespers_class.dart';
import '../classes/office_elements_class.dart';
import '../tools/constants.dart';
import '../offices/morning/morning_extract.dart';
import '../offices/readings/readings_extract.dart';
import '../offices/vespers/vespers_extract.dart';

/// Builds the hierarchy of common file names from a common name.
/// For example: 'saints-female_religious' with paschal returns:
/// ['saints-female', 'saints-female_paschal', 'saints-female_paschal_religious']
/// If liturgicalTime is a privileged time and not already present in commonName,
/// inserts '_$liturgicalTime' after the first element.
List<String> _buildCommonHierarchy(String commonName, String? liturgicalTime) {
  commonName = commonName.trim().toLowerCase();
  String effectiveCommonName = commonName;

  // Check if commonName already contains a liturgical time
  bool hasLiturgicalTime = liturgicalTime != null &&
      privilegedTimes.any((time) => commonName.contains('_$time'));

  if (liturgicalTime != null &&
      privilegedTimes.contains(liturgicalTime) &&
      !hasLiturgicalTime) {
    List<String> parts = commonName.split('_');
    if (parts.length > 1) {
      // Insert liturgical time after first element
      parts.insert(1, liturgicalTime);
      effectiveCommonName = parts.join('_');
    } else {
      effectiveCommonName = '${commonName}_$liturgicalTime';
    }
  }

  List<String> parts = effectiveCommonName.split('_');
  List<String> commonsToTry = [
    for (int i = 0; i < parts.length; i++) parts.sublist(0, i + 1).join('_')
  ];
  return commonsToTry;
}

/// Loads a common with hierarchical inheritance.
/// Each more specific level overrides data from more general levels.
Future<Morning> loadMorningHierarchicalCommon(
    CelebrationContext context) async {
  final common = context.selectedCommon;
  if (common == null) return Morning();
  Morning result = Morning();
  for (String level
      in _buildCommonHierarchy(common, context.liturgicalTime)) {
    Morning levelData = await morningExtract(
        '$commonsFilePath/$level.yaml', context.dataLoader);
    result.overlayWith(levelData);
  }
  return result;
}

/// Loads a common with hierarchical inheritance for Readings.
/// Each more specific level overrides data from more general levels.
Future<Readings> loadReadingsHierarchicalCommon(
    CelebrationContext context) async {
  final common = context.selectedCommon;
  if (common == null) return Readings();
  Readings result = Readings();
  for (String level
      in _buildCommonHierarchy(common, context.liturgicalTime)) {
    Readings levelData = await readingsExtract(
        '$commonsFilePath/$level.yaml', context.dataLoader);
    result.overlayWith(levelData);
  }
  return result;
}

/// Loads a common with hierarchical inheritance for Vespers.
/// Each more specific level overrides data from more general levels.
Future<Vespers> loadVespersHierarchicalCommon(
    CelebrationContext context) async {
  final common = context.selectedCommon;
  if (common == null) return Vespers();
  Vespers result = Vespers();
  for (String level
      in _buildCommonHierarchy(common, context.liturgicalTime)) {
    Vespers levelData = await vespersExtract(
        '$commonsFilePath/$level.yaml', context.dataLoader);
    result.overlayWith(levelData);
  }
  return result;
}
