import '../../classes/morning_class.dart';
import '../../classes/office_elements_class.dart';
import './ferial_morning_resolution.dart';
import './morning_extract.dart';
import '../../tools/hierarchical_common_loader.dart';
import '../../tools/constants.dart';
import '../../tools/resolve_office_content.dart';
import '../../tools/date_tools.dart';
import '../../tools/paschal_antiphon.dart';

/// Resolves the Morning Prayer (Lauds).
/// Priority logic: Proper > Common > Ferial base.
Future<Morning> morningExport(CelebrationContext celebrationContext) async {
  Morning morningOffice = Morning();

  // 1. BASE LAYER: Load Ferial content
  if (celebrationContext.ferialCode?.trim().isNotEmpty ?? false) {
    morningOffice = await ferialMorningResolution(celebrationContext);
  }

  // 2. CELEBRATION LAYER (Buffer): Proper + Common
  Morning celebrationOverlay = Morning();

  // Load Common first
  if (celebrationContext.selectedCommon?.trim().isNotEmpty ?? false) {
    celebrationOverlay =
        await loadMorningHierarchicalCommon(celebrationContext);
  }

  // Load Proper and overwrite the Common content in the buffer
  if (celebrationContext.celebrationCode != celebrationContext.ferialCode) {
    Morning proper = await morningExtract(
        '$specialFilePath/${celebrationContext.celebrationCode}.yaml',
        celebrationContext.dataLoader);

    if (proper.isEmpty) {
      proper = await morningExtract(
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
    morningOffice.overlayWith(celebrationOverlay);
  } else {
    // Memorials (> 6):
    // evangelicAntiphon overlay for Memorials
    if (celebrationOverlay.evangelicAntiphon != null) {
      morningOffice.evangelicAntiphon = celebrationOverlay.evangelicAntiphon;
    }

    // For oration (which is a List<String>), isNotEmpty is valid.
    // But to be consistent with your overlayWithCommon, we can just call it directly.
    morningOffice.overlayWithCommon(celebrationOverlay);
  }

  // 4. Prepend Gloria hymn at the first position
  morningOffice.hymn = [
    HymnEntry(code: 'gloire-a-dieu-paix-aux-hommes'),
    ...?morningOffice.hymn,
  ];

  // 5. HYDRATION: Resolve full texts
  await resolveOfficeContent(
    psalmody: morningOffice.psalmody,
    invitatory: morningOffice.invitatory,
    hymns: morningOffice.hymn,
    dataLoader: celebrationContext.dataLoader,
    imprecatory: celebrationContext.showImprecatoryVerses,
  );

  // 6. Filter evangelicAntiphon: keep only default + current year
  final antiphonMap = morningOffice.evangelicAntiphon;
  if (antiphonMap != null) {
    final year = liturgicalYear(celebrationContext.date.year);
    morningOffice.evangelicAntiphon = {
      if (antiphonMap.containsKey('antiphon'))
        'antiphon': antiphonMap['antiphon']!,
      if (antiphonMap.containsKey(year)) year: antiphonMap[year]!,
    };
  }

  // 7. Apply paschal alléluia to antiphons
  final lt = celebrationContext.liturgicalTime ?? '';

  final invitatoryAntiphon = morningOffice.invitatory?.antiphon;
  if (invitatoryAntiphon != null) {
    for (int i = 0; i < invitatoryAntiphon.length; i++) {
      invitatoryAntiphon[i] = paschalAntiphon(invitatoryAntiphon[i], lt);
    }
  }

  if (morningOffice.psalmody != null) {
    for (final entry in morningOffice.psalmody!) {
      final antiphon = entry.antiphon;
      if (antiphon != null) {
        for (int i = 0; i < antiphon.length; i++) {
          antiphon[i] = paschalAntiphon(antiphon[i], lt);
        }
      }
    }
  }

  if (morningOffice.evangelicAntiphon != null) {
    morningOffice.evangelicAntiphon = morningOffice.evangelicAntiphon!
        .map((k, v) => MapEntry(k, paschalAntiphon(v, lt)));
  }

  return morningOffice;
}
