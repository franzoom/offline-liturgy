import '../classes/morning_class.dart';
import '../classes/readings_class.dart';
import '../classes/office_elements_class.dart';
import '../tools/constants.dart';
import '../offices/morning/morning_extract.dart';
import '../offices/readings/readings_extract.dart';

/// Loads a common with hierarchical inheritance.
/// For example: 'saints-female_religious_paschal' will load and merge:
/// 1. saints-female.json (base)
/// 2. saints-female_religious.json (overlays on base)
/// 3. saints-female_religious_paschal.json (overlays on previous)
///
/// Each more specific level overrides data from more general levels.
Future<Morning> loadMorningHierarchicalCommon(
    CelebrationContext context) async {
  if (context.common == null) return Morning();

  // Split the common name by underscores
  List<String> parts = context.common!.split('_');

  // Build the hierarchy of file names to load
  List<String> hierarchy = [];
  for (int i = 0; i < parts.length; i++) {
    // Build cumulative name: X, X_Y, X_Y_Z
    String cumulativeName = parts.sublist(0, i + 1).join('_');
    hierarchy.add(cumulativeName);
  }

  // Start with empty Morning
  Morning result = Morning();

  // Load each level in order (from most general to most specific)
  for (String level in hierarchy) {
    String filePath = '$commonsFilePath/$level.yaml';
    Morning levelMorning = await morningExtract(filePath, context.dataLoader);

    // Overlay this level's data onto the result
    // More specific data will override general data
    result.overlayWith(levelMorning);
  }

  return result;
}

/// Loads a common with hierarchical inheritance for Readings.
/// For example: 'saints-female_religious_paschal' will load and merge:
/// 1. saints-female.yaml (base)
/// 2. saints-female_religious.yaml (overlays on base)
/// 3. saints-female_religious_paschal.yaml (overlays on previous)
///
/// Each more specific level overrides data from more general levels.
Future<Readings> loadReadingsHierarchicalCommon(
    CelebrationContext context) async {
  if (context.common == null) return Readings();

  // Split the common name by underscores
  List<String> parts = context.common!.split('_');

  // Build the hierarchy of file names to load
  List<String> hierarchy = [];
  for (int i = 0; i < parts.length; i++) {
    // Build cumulative name: X, X_Y, X_Y_Z
    String cumulativeName = parts.sublist(0, i + 1).join('_');
    hierarchy.add(cumulativeName);
  }

  // Start with empty Readings
  Readings result = Readings();

  // Load each level in order (from most general to most specific)
  for (String level in hierarchy) {
    String filePath = '$commonsFilePath/$level.yaml';
    Readings levelReadings = await readingsExtract(filePath, context.dataLoader);

    // Overlay this level's data onto the result
    // More specific data will override general data
    result.overlayWith(levelReadings);
  }

  return result;
}
