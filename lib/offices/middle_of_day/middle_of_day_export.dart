import '../../classes/middle_of_day_class.dart';
import '../../classes/office_elements_class.dart';
import './ferial_middle_of_day_resolution.dart';
import './middle_of_day_extract.dart';
import '../../tools/hierarchical_common_loader.dart';
import '../../tools/constants.dart';
import '../../tools/resolve_office_content.dart';

/// Resolves the Middle of Day Prayer (Tierce, Sexte, None).
/// Priority logic: Proper > Common > Ferial base.
Future<MiddleOfDay> middleOfDayExport(
    CelebrationContext celebrationContext) async {
  MiddleOfDay middleOfDayOffice = MiddleOfDay();

  // 1. BASE LAYER: Load Ferial content
  if (celebrationContext.ferialCode?.trim().isNotEmpty ?? false) {
    middleOfDayOffice =
        await ferialMiddleOfDayResolution(celebrationContext);
  }

  // 2. CELEBRATION LAYER (Buffer): Proper + Common
  MiddleOfDay celebrationOverlay = MiddleOfDay();

  // Load Common first
  if (celebrationContext.selectedCommon?.trim().isNotEmpty ?? false) {
    celebrationOverlay =
        await loadMiddleOfDayHierarchicalCommon(celebrationContext);
  }

  // Load Proper and overwrite the Common content in the buffer
  if (celebrationContext.celebrationCode != celebrationContext.ferialCode) {
    MiddleOfDay proper = await middleOfDayExtract(
        '$specialFilePath/${celebrationContext.celebrationCode}.yaml',
        celebrationContext.dataLoader);

    if (proper.isEmpty) {
      proper = await middleOfDayExtract(
          '$sanctoralFilePath/${celebrationContext.celebrationCode}.yaml',
          celebrationContext.dataLoader);
    }

    // Proper overwrites Common inside the buffer
    celebrationOverlay.overlayWith(proper);
  }

  // 3. FINAL MERGING
  if (celebrationContext.precedence != null &&
      celebrationContext.precedence! <= 6) {
    // Solemnities and Feasts: Full replacement
    middleOfDayOffice.overlayWith(celebrationOverlay);
  } else {
    // Memorials (> 6): Selective overlay
    middleOfDayOffice.overlayWithCommon(celebrationOverlay);
  }

  // 4. HYDRATION: Resolve full texts
  await resolveOfficeContent(
    psalmody: middleOfDayOffice.psalmody,
    dataLoader: celebrationContext.dataLoader,
  );

  return middleOfDayOffice;
}
