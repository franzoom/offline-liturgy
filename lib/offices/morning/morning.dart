import '../../classes/morning_class.dart';
import '../../tools/data_loader.dart';
import './ferial_morning_resolution.dart';
import './morning_extract.dart';
import '../../tools/hierarchical_common_loader.dart';
import '../../tools/file_paths.dart';

/// Resolves morning prayer for a given celebrationCode.
/// requires onlyOration for the Memories: adding only the Oration of the saint,
/// or adding the chosen Common.
/// Returns a Map with celebration name as key and Morning instance as value
/// (the argument "date" is used for advent calculation)
Future<Morning> morningResolution(String celebrationCode, String? ferialCode,
    String? common, DateTime date, String? breviaryWeek, DataLoader dataLoader,
    {int? precedence}) async {
  Morning morningOffice = Morning();
  Morning properMorning = Morning();

  // firstable catches the ferial data if exists (if not feast or solemnity)
  if (ferialCode != null && ferialCode.trim().isNotEmpty) {
    morningOffice = await ferialMorningResolution(
        ferialCode, date, breviaryWeek, dataLoader);
  }

  // Load proper celebration data if not ferial
  if (celebrationCode != ferialCode) {
    // Try special directory first, then sanctoral
    properMorning = await morningExtract(
        '$specialFilePath/$celebrationCode.json', dataLoader);

    if (properMorning.isEmpty()) {
      // File not found in special, try sanctoral
      properMorning = await morningExtract(
          '$sanctoralFilePath/$celebrationCode.json', dataLoader);
    }
  }

  // For optional celebrations (precedence > 6), apply layers in correct order
  if (precedence != null && precedence > 6) {
    // Layer 1: Ferial (already in morningOffice)
    // Layer 2: Common if provided (selective overlay - only fills gaps)
    if (common != null && common.trim().isNotEmpty) {
      Morning commonMorning = await loadHierarchicalCommon(common, dataLoader);
      morningOffice.overlayWithCommon(commonMorning);
    }
    // Layer 3: Proper (always applied, has priority over everything)
    morningOffice.overlayWith(properMorning);
  } else {
    // Obligatory celebrations (precedence <= 6): standard full overlay
    if (common != null && common.trim().isNotEmpty) {
      Morning commonMorning = await loadHierarchicalCommon(common, dataLoader);
      morningOffice.overlayWith(commonMorning);
    }
    morningOffice.overlayWith(properMorning);
  }

  return morningOffice;
}
