import '../classes/morning_class.dart';
import '../classes/readings_class.dart';
import '../classes/office_elements_class.dart';
import '../tools/constants.dart';
import '../offices/morning/morning_extract.dart';
import '../offices/readings/readings_extract.dart';

/// Builds the hierarchy of common file names from a common name.
/// For example: 'saints-female_religious_paschal' returns:
/// ['saints-female', 'saints-female_religious', 'saints-female_religious_paschal']
/// If liturgicalTime is a privileged time and not already at the end of commonName,
/// appends '_$liturgicalTime' to commonName. (for exemple adds "_lent" to "virgins"
/// if liturgical time is Lent)
List<String> _buildCommonHierarchy(String commonName, String? liturgicalTime) {
  String effectiveCommonName = commonName;
  if (liturgicalTime != null &&
      privilegedTimes.contains(liturgicalTime) &&
      !commonName.endsWith('_$liturgicalTime')) {
    effectiveCommonName = '${commonName}_$liturgicalTime';
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
  if (context.common == null) return Morning();

  Morning result = Morning();
  for (String level
      in _buildCommonHierarchy(context.common!, context.liturgicalTime)) {
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
  if (context.common == null) return Readings();

  Readings result = Readings();
  for (String level
      in _buildCommonHierarchy(context.common!, context.liturgicalTime)) {
    Readings levelData = await readingsExtract(
        '$commonsFilePath/$level.yaml', context.dataLoader);
    result.overlayWith(levelData);
  }
  return result;
}
