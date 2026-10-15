import '../../classes/morning_class.dart';
import '../../classes/office_elements_class.dart';
import './ferial_morning_resolution.dart';
import './morning_extract.dart';
import '../../tools/hierarchical_common_loader.dart';
import '../compose_office.dart';
import '../../tools/resolve_office_content.dart';
import '../../tools/date_tools.dart';
import '../../tools/paschal_antiphon.dart';
import '../../assets/usual_texts.dart';

/// Resolves the Morning Prayer (Lauds).
/// Priority logic: Proper > Common > Ferial base.
Future<Morning> morningExport(CelebrationContext celebrationContext) async {
  // 1-4. Ferial base, Common and proper layers
  final (office: morningOffice, proper: _) = await composeOffice<Morning>(
    celebrationContext,
    empty: Morning.new,
    ferial: () => ferialMorningResolution(celebrationContext),
    proper: (path) => morningExtract(path, celebrationContext.dataLoader),
    common: () => loadMorningHierarchicalCommon(celebrationContext),
    overlay: (base, layer) => base.overlayWith(layer,
        keepBaseHymns: celebrationContext.keepsSeasonHymns),
    overlayCommon: (base, common) => base.overlayWithCommon(common),
    // The day's year-cycle antiphons (Sundays of Ordinary Time) belong to
    // that day's own office only, never to a celebration replacing it
    beforeOverlays: (base) => base.evangelicAntiphon =
        withoutYearCycleAntiphons(base.evangelicAntiphon),
  );

  final liturgicalTime = celebrationContext.liturgicalTime ?? '';

  // 5. Invitatory: exclude psalms already used in the final, merged Lauds
  // psalmody (must run after merging — a Memorial's invitatory may come from
  // the Common while the day keeps the ferial psalmody, or vice versa).
  final invitatoryPsalms = morningOffice.invitatory?.psalms;
  if (invitatoryPsalms != null) {
    final usedPsalms = morningOffice.psalmody
            ?.where((entry) => entry.psalm != null)
            .map((entry) => entry.psalm!)
            .toSet() ??
        {};
    morningOffice.invitatory = Invitatory(
      antiphon: morningOffice.invitatory!.antiphon,
      psalms: invitatoryPsalms
          .where((psalm) => !usedPsalms.contains(psalm))
          .toList(),
    );
  }

  // 6. HYDRATION: Resolve full texts (canticle SVG starts in parallel)
  final Future<String>? canticleSvgFuture = celebrationContext.svgSource != null
      ? celebrationContext.dataLoader
          .load('svg/${celebrationContext.svgSource}/NT_2.svg')
      : null;
  await resolveOfficeContent(
    psalmody: morningOffice.psalmody,
    invitatory: morningOffice.invitatory,
    hymns: morningOffice.hymn,
    dataLoader: celebrationContext.dataLoader,
    showImprecatoryVerses: celebrationContext.showImprecatoryVerses,
    svgSource: celebrationContext.svgSource,
  );

  // 7. Filter evangelicAntiphon: keep only default + current year. The
  // liturgical year, not the civil one: from the 1st Sunday of Advent to
  // Dec 31 they differ (Advent 2025 is year A, not C).
  morningOffice.evangelicAntiphon = filterEvangelicAntiphon(
      morningOffice.evangelicAntiphon,
      celebrationContext.effectiveLiturgicalYear);

  // 8. Apply paschal alléluia to antiphons
  applyPaschalToList(morningOffice.invitatory?.antiphon, liturgicalTime);
  applyPaschalToPsalmody(morningOffice.psalmody, liturgicalTime);
  morningOffice.evangelicAntiphon = applyPaschalToAntiphonMap(
      morningOffice.evangelicAntiphon, liturgicalTime);

  // 9. Assign the evangelic canticle (Benedictus)
  morningOffice.evangelicCanticle = benedictus;

  // 10. Apply canticle SVG (was loading in parallel since step 6)
  if (canticleSvgFuture != null) {
    final svgContent = await canticleSvgFuture;
    if (svgContent.isNotEmpty) morningOffice.canticleSvgData = [svgContent];
  }

  return morningOffice;
}
