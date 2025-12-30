import '../classes/morning_class.dart';
import 'data_loader.dart';
import 'file_paths.dart';
import '../offices/morning/morning_extract.dart';

/// Loads a common with hierarchical inheritance.
/// For example: 'saints-female_religious_paschal' will load and merge:
/// 1. saints-female.json (base)
/// 2. saints-female_religious.json (overlays on base)
/// 3. saints-female_religious_paschal.json (overlays on previous)
///
/// Each more specific level overrides data from more general levels.
Future<Morning> loadHierarchicalCommon(
    String commonName, DataLoader dataLoader) async {
  // Split the common name by underscores
  List<String> parts = commonName.split('_');

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
    Morning levelMorning = await morningExtract(filePath, dataLoader);

    // Overlay this level's data onto the result
    // More specific data will override general data
    result.overlayWith(levelMorning);
  }

  return result;
}
