import '../../classes/vespers_class.dart';
import '../../classes/office_elements_class.dart';
import './ferial_vespers_resolution.dart';
import './vespers_extract.dart';
import '../../tools/hierarchical_common_loader.dart';
import '../../tools/celebration_index.dart';
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
    // The day's year-cycle antiphons (Sundays of Ordinary Time) belong to
    // that day's own office only — never to a celebration replacing it,
    // whatever its rank (First Vespers included). Stripped from the ferial
    // layer before any overlay, so that a celebration's own A/B/C
    // antiphons would be kept.
    vespersOffice.evangelicAntiphon =
        withoutYearCycleAntiphons(vespersOffice.evangelicAntiphon);
    properVespers = await _loadProperVespers(celebrationContext);
  }

  // STEP 3: Handle Commons and Overlays based on precedence
  final bool isMemory = (celebrationContext.precedence ?? 13) > 9;
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

  // Append Lucernaire hymn, except during Lent and Holy Week
  final lt = celebrationContext.liturgicalTime ?? '';
  if (lt != 'lent' && lt != 'holyweek') {
    vespersOffice.hymn = [
      ...?vespersOffice.hymn,
      HymnEntry(code: 'joie-et-lumiere'),
    ];
  }

  // Hydrate psalm and hymn content (canticle SVG starts in parallel)
  final Future<String>? canticleSvgFuture = celebrationContext.svgSource != null
      ? celebrationContext.dataLoader
          .load('svg/${celebrationContext.svgSource}/NT_1.svg')
      : null;
  await resolveOfficeContent(
    psalmody: vespersOffice.psalmody,
    invitatory: vespersOffice.invitatory,
    hymns: vespersOffice.hymn,
    dataLoader: celebrationContext.dataLoader,
    showImprecatoryVerses: celebrationContext.showImprecatoryVerses,
    svgSource: celebrationContext.svgSource,
  );

  // Filter evangelicAntiphon: keep only default + current year. The
  // liturgical year, not the civil one: from the 1st Sunday of Advent to
  // Dec 31 they differ. For First Vespers, the context is tomorrow's, so
  // the eve of the 1st Sunday of Advent already takes the new year.
  vespersOffice.evangelicAntiphon = filterEvangelicAntiphon(
      vespersOffice.evangelicAntiphon,
      celebrationContext.liturgicalYear ?? celebrationContext.date.year);

  // Apply paschal alléluia to antiphons
  applyPaschalToPsalmody(vespersOffice.psalmody, lt);
  vespersOffice.evangelicAntiphon =
      applyPaschalToAntiphonMap(vespersOffice.evangelicAntiphon, lt);

  // Assign the evangelic canticle (Magnificat)
  vespersOffice.evangelicCanticle = magnificat;

  // Apply canticle SVG (was loading in parallel with psalmody hydration)
  if (canticleSvgFuture != null) {
    final svgContent = await canticleSvgFuture;
    if (svgContent.isNotEmpty) vespersOffice.canticleSvgData = [svgContent];
  }

  return vespersOffice;
}

/// Helper to try loading the proper file from multiple directories (Special then Sanctoral)
Future<Vespers> _loadProperVespers(CelebrationContext context) async {
  final String section =
      context.celebrationType == 'vespers1' ? 'firstVespers' : 'vespers';

  final filePath = await dirPathForCode(context.celebrationCode, context.dataLoader);
  return vespersExtract('$filePath/${context.celebrationCode}.yaml',
      context.dataLoader, section: section);
}
