import '../../classes/vespers_class.dart';
import '../../classes/office_elements_class.dart';
import './ferial_vespers_resolution.dart';
import './vespers_extract.dart';
import '../../tools/hierarchical_common_loader.dart';
import '../../tools/constants.dart';
import '../../tools/resolve_office_content.dart';
import '../../tools/date_tools.dart';

/// Resolves the Vespers (Evening Prayer) by orchestrating different sources:
/// 1. Ferial base
/// 2. Common (if applicable)
/// 3. Proper (Sanctoral or Special)
Future<Vespers> vespersExport(CelebrationContext celebrationContext) async {
  Vespers vespersOffice = Vespers();

  // STEP 1: Load Ferial data as the base layer
  if (celebrationContext.ferialCode?.trim().isNotEmpty ?? false) {
    vespersOffice = await ferialVespersResolution(celebrationContext);
  }

  // STEP 2: Load Proper celebration data (Sanctoral or Special files)
  Vespers properVespers = Vespers();
  if (celebrationContext.celebrationCode != celebrationContext.ferialCode) {
    properVespers = await _loadProperVespers(celebrationContext);
  }

  // STEP 3: Handle Commons and Overlays based on precedence
  final bool isMemory = (celebrationContext.precedence ?? 13) > 6;
  final bool hasCommon =
      celebrationContext.selectedCommon?.trim().isNotEmpty ?? false;

  if (hasCommon) {
    Vespers commonVespers =
        await loadVespersHierarchicalCommon(celebrationContext);

    if (isMemory) {
      // For Memories: Selective overlay (includes Hymn and Invitatory if provided)
      vespersOffice.overlayWithCommon(commonVespers);
    } else {
      // For Solemnities/Feasts: Standard full overlay
      vespersOffice.overlayWith(commonVespers);
    }
  }

  // STEP 4: Apply Proper data (Highest priority)
  vespersOffice.overlayWith(properVespers);

  // Prepend Lucernaire hymn at the first position
  vespersOffice.hymn = [
    HymnEntry(code: 'joie-et-lumiere'),
    ...?vespersOffice.hymn,
  ];

  // Hydrate psalm and hymn content
  await resolveOfficeContent(
    psalmody: vespersOffice.psalmody,
    invitatory: vespersOffice.invitatory,
    hymns: vespersOffice.hymn,
    dataLoader: celebrationContext.dataLoader,
  );

  // Filter evangelicAntiphon: keep only default + current year
  final antiphonMap = vespersOffice.evangelicAntiphon;
  if (antiphonMap != null) {
    final year = liturgicalYear(celebrationContext.date.year);
    vespersOffice.evangelicAntiphon = {
      if (antiphonMap.containsKey('antiphon'))
        'antiphon': antiphonMap['antiphon']!,
      if (antiphonMap.containsKey(year)) year: antiphonMap[year]!,
    };
  }

  return vespersOffice;
}

/// Helper to try loading the proper file from multiple directories (Special then Sanctoral)
Future<Vespers> _loadProperVespers(CelebrationContext context) async {
  final List<String> searchPaths = [
    '$specialFilePath/${context.celebrationCode}.yaml',
    '$sanctoralFilePath/${context.celebrationCode}.yaml',
  ];

  for (String path in searchPaths) {
    final vespers = await vespersExtract(path, context.dataLoader);
    if (!vespers.isEmpty) return vespers;
  }

  return Vespers();
}
