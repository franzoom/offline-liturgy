import '../../classes/morning_class.dart';
import '../../classes/office_elements_class.dart';
import './ferial_morning_resolution.dart';
import './morning_extract.dart';
import '../../tools/hierarchical_common_loader.dart';
import '../../tools/constants.dart';

/// Resolves morning prayer for a given celebration context.
/// requires only Oration for the Memories: adding only the Oration of the saint,
/// or adding the chosen Common.
/// Returns a Morning instance for the celebration.
Future<Morning> morningResolution(CelebrationContext celebrationContext) async {
  Morning morningOffice = Morning();
  Morning properMorning = Morning();

  // firstable catches the ferial data if exists (if not feast or solemnity)
  if (celebrationContext.ferialCode?.trim().isNotEmpty ?? false) {
    morningOffice = await ferialMorningResolution(celebrationContext);
  }

  // Load proper celebration data if not ferial
  if (celebrationContext.celebrationCode != celebrationContext.ferialCode) {
    // Try special directory first, then sanctoral
    properMorning = await morningExtract(
        '$specialFilePath/${celebrationContext.celebrationCode}.yaml',
        celebrationContext.dataLoader);

    if (properMorning.isEmpty) {
      // File not found in special, try sanctoral
      properMorning = await morningExtract(
          '$sanctoralFilePath/${celebrationContext.celebrationCode}.yaml',
          celebrationContext.dataLoader);
    }
  }

  // For optional celebrations (precedence > 6), apply layers in correct order
  if (celebrationContext.precedence != null &&
      celebrationContext.precedence! > 6) {
    // Layer 1: Ferial (already in morningOffice)
    // Layer 2: Common if provided (selective overlay - only fills gaps)
    if (celebrationContext.common?.trim().isNotEmpty ?? false) {
      Morning commonMorning =
          await loadMorningHierarchicalCommon(celebrationContext);
      morningOffice.overlayWithCommon(commonMorning);
    }
    // Layer 3: Proper (always applied, has priority over everything)
    morningOffice.overlayWith(properMorning);
  } else {
    // Mandatory celebrations (precedence <= 6): standard full overlay
    if (celebrationContext.common?.trim().isNotEmpty ?? false) {
      Morning commonMorning =
          await loadMorningHierarchicalCommon(celebrationContext);
      morningOffice.overlayWith(commonMorning);
    }
    morningOffice.overlayWith(properMorning);
  }

  return morningOffice;
}
