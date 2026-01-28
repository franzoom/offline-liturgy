import '../../classes/vespers_class.dart';
import '../../classes/office_elements_class.dart';
import './ferial_vespers_resolution.dart';
import './vespers_extract.dart';
import '../../tools/hierarchical_common_loader.dart';
import '../../tools/constants.dart';

/// Resolves vespers prayer for a given celebration context.
/// requires only Oration for the Memories: adding only the Oration of the saint,
/// or adding the chosen Common.
/// Returns a Vespers instance for the celebration.
Future<Vespers> vespersResolution(CelebrationContext celebrationContext) async {
  Vespers vespersOffice = Vespers();
  Vespers properVespers = Vespers();

  // firstable catches the ferial data if exists (if not feast or solemnity)
  if (celebrationContext.ferialCode?.trim().isNotEmpty ?? false) {
    vespersOffice = await ferialVespersResolution(celebrationContext);
  }

  // Load proper celebration data if not ferial
  if (celebrationContext.celebrationCode != celebrationContext.ferialCode) {
    // Try special directory first, then sanctoral
    properVespers = await vespersExtract(
        '$specialFilePath/${celebrationContext.celebrationCode}.yaml',
        celebrationContext.dataLoader);

    if (properVespers.isEmpty) {
      // File not found in special, try sanctoral
      properVespers = await vespersExtract(
          '$sanctoralFilePath/${celebrationContext.celebrationCode}.yaml',
          celebrationContext.dataLoader);
    }
  }

  // For optional celebrations (precedence > 6), apply layers in correct order
  if (celebrationContext.precedence != null &&
      celebrationContext.precedence! > 6) {
    // Layer 1: Ferial (already in vespersOffice)
    // Layer 2: Common if provided (selective overlay - only fills gaps)
    if (celebrationContext.common?.trim().isNotEmpty ?? false) {
      Vespers commonVespers = await loadVespersHierarchicalCommon(celebrationContext);
      vespersOffice.overlayWithCommon(commonVespers);
    }
    // Layer 3: Proper (always applied, has priority over everything)
    vespersOffice.overlayWith(properVespers);
  } else {
    // Mandatory celebrations (precedence <= 6): standard full overlay
    if (celebrationContext.common?.trim().isNotEmpty ?? false) {
      Vespers commonVespers = await loadVespersHierarchicalCommon(celebrationContext);
      vespersOffice.overlayWith(commonVespers);
    }
    vespersOffice.overlayWith(properVespers);
  }

  return vespersOffice;
}
