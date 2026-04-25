import '../../classes/vespers_class.dart';
import '../../classes/office_elements_class.dart';
import './ferial_vespers_resolution.dart';
import './vespers_extract.dart';
import '../../tools/hierarchical_common_loader.dart';
import '../../tools/constants.dart';
import '../../tools/resolve_office_content.dart';
import '../../tools/date_tools.dart';
import '../../tools/paschal_antiphon.dart';
import '../../assets/usual_texts.dart';

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
  final bool isMemory = (celebrationContext.precedence ?? 13) > 7;
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

  // Prepend Lucernaire hymn, except during Lent and Holy Week
  final lt = celebrationContext.liturgicalTime ?? '';
  if (lt != 'lent' && lt != 'holyweek') {

    vespersOffice.hymn = [
      HymnEntry(code: 'joie-et-lumiere'),
      ...?vespersOffice.hymn,
    ];
  }

  // Hydrate psalm and hymn content
  await resolveOfficeContent(
    psalmody: vespersOffice.psalmody,
    invitatory: vespersOffice.invitatory,
    hymns: vespersOffice.hymn,
    dataLoader: celebrationContext.dataLoader,
  );

  // Filter evangelicAntiphon: keep only default + current year
  vespersOffice.evangelicAntiphon = filterEvangelicAntiphon(
      vespersOffice.evangelicAntiphon, celebrationContext.date.year);

  // Apply paschal alléluia to antiphons
  applyPaschalToPsalmody(vespersOffice.psalmody, lt);
  vespersOffice.evangelicAntiphon =
      applyPaschalToAntiphonMap(vespersOffice.evangelicAntiphon, lt);

  // Assign the evangelic canticle (Magnificat)
  vespersOffice.evangelicCanticle = magnificat;

  return vespersOffice;
}

/// Helper to try loading the proper file from multiple directories (Special then Sanctoral)
Future<Vespers> _loadProperVespers(CelebrationContext context) async {
  final String section =
      context.celebrationType == 'vespers1' ? 'firstVespers' : 'vespers';

  final results = await Future.wait([
    vespersExtract('$specialFilePath/${context.celebrationCode}.yaml',
        context.dataLoader, section: section),
    vespersExtract('$sanctoralFilePath/${context.celebrationCode}.yaml',
        context.dataLoader, section: section),
  ]);

  return results.firstWhere((v) => !v.isEmpty, orElse: Vespers.new);
}
