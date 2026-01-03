import '../../classes/readings_class.dart';
import '../../tools/data_loader.dart';
import './ferial_readings_resolution.dart';
import './readings_extract.dart';
import '../../tools/hierarchical_common_loader.dart';
import '../../tools/file_paths.dart';

/// Resolves readings prayer for a given celebrationCode.
/// requires onlyOration for the Memories: adding only the Oration of the saint,
/// or adding the chosen Common.
/// Returns a Map with celebration name as key and Readings instance as value
/// (the argument "date" is used for advent calculation)
Future<Readings> readingsResolution(String celebrationCode, String? ferialCode,
    String? common, DateTime date, String? breviaryWeek, DataLoader dataLoader,
    {int? precedence, bool? teDeum}) async {
  Readings readingsOffice = Readings();
  Readings properReadings = Readings();

  // firstable catches the ferial data if exists (if not feast or solemnity)
  if (ferialCode != null && ferialCode.trim().isNotEmpty) {
    readingsOffice = await ferialReadingsResolution(
        ferialCode, date, breviaryWeek, dataLoader);
  }

  // Load proper celebration data if not ferial
  if (celebrationCode != ferialCode) {
    // Try special directory first, then sanctoral
    properReadings = await readingsExtract(
        '$specialFilePath/$celebrationCode.yaml', dataLoader);

    if (properReadings.isEmpty()) {
      // File not found in special, try sanctoral
      properReadings = await readingsExtract(
          '$sanctoralFilePath/$celebrationCode.yaml', dataLoader);
    }
  }

  // For optional celebrations (precedence > 6), apply layers in correct order
  if (precedence != null && precedence > 6) {
    // Layer 1: Ferial (already in readingsOffice)
    // Layer 2: Common if provided (selective overlay - only fills gaps)
    if (common != null && common.trim().isNotEmpty) {
      Readings commonReadings =
          await loadReadingsHierarchicalCommon(common, dataLoader);
      readingsOffice.overlayWithCommon(commonReadings);
    }
    // Layer 3: Proper (always applied, has priority over everything)
    readingsOffice.overlayWith(properReadings);
  } else {
    // Mandatory celebrations (precedence <= 6): standard full overlay
    if (common != null && common.trim().isNotEmpty) {
      Readings commonReadings =
          await loadReadingsHierarchicalCommon(common, dataLoader);
      readingsOffice.overlayWith(commonReadings);
    }
    readingsOffice.overlayWith(properReadings);
  }

  // Set Te Deum flag if provided
  if (teDeum != null) {
    readingsOffice.tedeum = teDeum;
  }

  return readingsOffice;
}
