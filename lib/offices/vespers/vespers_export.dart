import '../../classes/vespers_class.dart';
import '../../classes/office_elements_class.dart';
import './ferial_vespers_resolution.dart';
import './vespers_extract.dart';
import '../../tools/hierarchical_common_loader.dart';
import '../compose_hour_prayer.dart';
import '../../tools/resolve_office_content.dart';
import '../../tools/date_tools.dart';
import '../../tools/paschal_antiphon.dart';
import '../../assets/usual_texts.dart';

/// Resolves the Vespers (Evening Prayer) by orchestrating different sources:
/// 1. Ferial base
/// 2. Common (if applicable)
/// 3. Proper (Sanctoral or Special)
Future<Vespers> vespersExport(CelebrationContext celebrationContext) async {
  // STEPS 1-4: Ferial base, Common and proper layers
  final vespersOffice = await composeHourPrayer<Vespers>(
    celebrationContext,
    empty: Vespers.new,
    ferial: () => ferialVespersResolution(celebrationContext),
    proper: (path) => vespersExtract(path, celebrationContext.dataLoader,
        section: celebrationContext.vespersSection),
    common: () => loadVespersHierarchicalCommon(celebrationContext),
  );

  // Append Lucernaire hymn, except during Lent and Holy Week, unless a layer
  // (e.g. the ferial day) already lists it
  final lt = celebrationContext.liturgicalTime ?? '';
  final bool hasLucernaire =
      vespersOffice.hymn?.any((h) => h.code == 'joie-et-lumiere') ?? false;
  if (lt != 'lent' && lt != 'holyweek' && !hasLucernaire) {
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
      celebrationContext.effectiveLiturgicalYear);

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
