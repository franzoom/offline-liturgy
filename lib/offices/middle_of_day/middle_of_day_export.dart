import '../../assets/libraries/middle_of_day_antiphons.dart';
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

  // 4. PREPEND LITURGICAL TIME ANTIPHON to each psalm's antiphon list
  final seasonAntiphon = _getSeasonAntiphon(celebrationContext);
  if (seasonAntiphon != null && middleOfDayOffice.psalmody != null) {
    middleOfDayOffice.psalmody = middleOfDayOffice.psalmody!.map((entry) {
      return PsalmEntry(
        psalm: entry.psalm,
        antiphon: [seasonAntiphon, ...?entry.antiphon],
        psalmData: entry.psalmData,
      );
    }).toList();
  }

  // 5. HYDRATION: Resolve full texts (psalmody + hymns for each hour)
  await resolveOfficeContent(
    psalmody: middleOfDayOffice.psalmody,
    hymns: [
      ...?middleOfDayOffice.hymnTierce,
      ...?middleOfDayOffice.hymnSexte,
      ...?middleOfDayOffice.hymnNone,
    ],
    dataLoader: celebrationContext.dataLoader,
  );

  return middleOfDayOffice;
}

/// Returns the season antiphon for the middle of day office, or null
/// if the liturgical time has no specific antiphon (ordinary time).
String? _getSeasonAntiphon(CelebrationContext context) {
  final lt = context.liturgicalTime ?? '';
  final ferialCode = context.ferialCode ?? '';

  if (lt == 'advent') return middleOfDayAntiphons['advent'];
  if (lt == 'christmas') {
    // After Epiphany: ferialCode like christmas_2_x
    if (ferialCode.startsWith('christmas_2_')) {
      return middleOfDayAntiphons['after_epiphany'];
    }
    return middleOfDayAntiphons['christmas'];
  }
  if (lt == 'lent') return middleOfDayAntiphons['lent'];
  if (lt == 'holyweek') return middleOfDayAntiphons['passion'];
  if (lt == 'easter') return middleOfDayAntiphons['easter'];

  // Ordinary time: no season antiphon
  return null;
}
