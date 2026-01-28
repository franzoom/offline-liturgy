import '../../classes/readings_class.dart';
import '../../classes/office_elements_class.dart';
import './ferial_readings_resolution.dart';
import './readings_extract.dart';
import '../../tools/hierarchical_common_loader.dart';
import '../../tools/constants.dart';

/// Resolves readings prayer for a given celebration context.
/// requires onlyOration for the Memories: adding only the Oration of the saint,
/// or adding the chosen Common.
/// Returns a Readings instance for the celebration.
Future<Readings> readingsResolution(CelebrationContext context) async {
  Readings readingsOffice = Readings();
  Readings properReadings = Readings();

  // firstable catches the ferial data if exists (if not feast or solemnity)
  if (context.ferialCode?.trim().isNotEmpty ?? false) {
    readingsOffice = await ferialReadingsResolution(context);
  }

  // Load proper celebration data if not ferial
  if (context.celebrationCode != context.ferialCode) {
    // Try special directory first, then sanctoral
    properReadings = await readingsExtract(
        '$specialFilePath/${context.celebrationCode}.yaml', context.dataLoader);

    if (properReadings.isEmpty) {
      // File not found in special, try sanctoral
      properReadings = await readingsExtract(
          '$sanctoralFilePath/${context.celebrationCode}.yaml', context.dataLoader);
    }
  }

  // For optional celebrations (precedence > 6), apply layers in correct order
  if ((context.precedence ?? 0) > 6) {
    // Layer 1: Ferial (already in readingsOffice)
    // Layer 2: Common if provided (selective overlay - only fills gaps)
    if (context.common?.trim().isNotEmpty ?? false) {
      Readings commonReadings = await loadReadingsHierarchicalCommon(context);
      readingsOffice.overlayWithCommon(commonReadings);
    }
    // Layer 3: Proper (always applied, has priority over everything)
    readingsOffice.overlayWith(properReadings);
  } else {
    // Mandatory celebrations (precedence <= 6): standard full overlay
    if (context.common?.trim().isNotEmpty ?? false) {
      Readings commonReadings = await loadReadingsHierarchicalCommon(context);
      readingsOffice.overlayWith(commonReadings);
    }
    readingsOffice.overlayWith(properReadings);
  }

  // Set Te Deum flag if provided
  if (context.teDeum != null) {
    readingsOffice.tedeum = context.teDeum;
  }

  return readingsOffice;
}
