import '../../classes/morning_class.dart';
import '../../classes/office_elements_class.dart';
import './ferial_morning_resolution.dart';
import './morning_extract.dart';
import '../../tools/hierarchical_common_loader.dart';
import '../../tools/celebration_index.dart';
import '../../tools/resolve_office_content.dart';
import '../../tools/date_tools.dart';
import '../../tools/paschal_antiphon.dart';
import '../../tools/hymns_management.dart';
import '../../assets/usual_texts.dart';

/// Resolves the Morning Prayer (Lauds).
/// Priority logic: Proper > Common > Ferial base.
Future<Morning> morningExport(CelebrationContext celebrationContext) async {
  Morning morningOffice = Morning();

  // 1. BASE LAYER: Load Ferial content
  if (celebrationContext.ferialCode?.trim().isNotEmpty ?? false) {
    morningOffice = await ferialMorningResolution(celebrationContext);
  }

  // 2. Load Proper celebration data
  Morning properMorning = Morning();
  if (celebrationContext.celebrationCode != celebrationContext.ferialCode) {
    final filePath = await dirPathForCode(
        celebrationContext.celebrationCode, celebrationContext.dataLoader);
    properMorning = await morningExtract(
        '$filePath/${celebrationContext.celebrationCode}.yaml',
        celebrationContext.dataLoader);
  }

  // 3. Handle Commons and Overlays based on precedence
  final bool isMemory = (celebrationContext.precedence ?? 13) > 9;
  if (celebrationContext.selectedCommon?.trim().isNotEmpty ?? false) {
    final Morning commonMorning =
        await loadMorningHierarchicalCommon(celebrationContext);
    if (isMemory) {
      // Memorials: selective overlay (excludes psalmody/celebration)
      morningOffice.overlayWithCommon(commonMorning);
    } else {
      // Solemnities/Feasts: full overlay
      morningOffice.overlayWith(commonMorning);
    }
  }

  // 4. Apply Proper data (highest priority, always full — a Memorial's own
  // proper psalmody/celebration data must win when present)
  morningOffice.overlayWith(properMorning);

  // 5. Holy Week: assign Passion hymns if no proper hymn is defined
  const holyWeekCodes = {'holy_thursday', 'holy_friday', 'holy_saturday'};
  if (morningOffice.hymn == null &&
      holyWeekCodes.contains(celebrationContext.celebrationCode)) {
    morningOffice.hymn =
        await getHymnsForSeason("passion", celebrationContext.dataLoader);
  }

  final liturgicalTime = celebrationContext.liturgicalTime ?? '';

  // 6. Invitatory: exclude psalms already used in the final, merged Lauds
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
      psalms:
          invitatoryPsalms.where((psalm) => !usedPsalms.contains(psalm)).toList(),
    );
  }

  // 7. HYDRATION: Resolve full texts (canticle SVG starts in parallel)
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

  // When a solemnity overrides an OT Sunday, the Sunday's year-cycle antiphons don't apply
  if (celebrationContext.date.isSunday &&
      celebrationContext.liturgicalTime == 'ot' &&
      (celebrationContext.precedence ?? 13) <= 3 &&
      celebrationContext.celebrationCode !=
          (celebrationContext.ferialCode ?? '')) {
    final map = morningOffice.evangelicAntiphon;
    morningOffice.evangelicAntiphon =
        (map != null && map.containsKey('antiphon'))
            ? {'antiphon': map['antiphon']!}
            : null;
  }

  // 8. Filter evangelicAntiphon: keep only default + current year
  morningOffice.evangelicAntiphon = filterEvangelicAntiphon(
      morningOffice.evangelicAntiphon, celebrationContext.date.year);

  // 9. Apply paschal alléluia to antiphons
  final invitatoryAntiphon = morningOffice.invitatory?.antiphon;
  if (invitatoryAntiphon != null) {
    for (int i = 0; i < invitatoryAntiphon.length; i++) {
      invitatoryAntiphon[i] =
          paschalAntiphon(invitatoryAntiphon[i], liturgicalTime);
    }
  }
  applyPaschalToPsalmody(morningOffice.psalmody, liturgicalTime);
  morningOffice.evangelicAntiphon = applyPaschalToAntiphonMap(
      morningOffice.evangelicAntiphon, liturgicalTime);

  // 10. Assign the evangelic canticle (Benedictus)
  morningOffice.evangelicCanticle = benedictus;

  // 11. Apply canticle SVG (was loading in parallel since step 7)
  if (canticleSvgFuture != null) {
    final svgContent = await canticleSvgFuture;
    if (svgContent.isNotEmpty) morningOffice.canticleSvgData = [svgContent];
  }

  return morningOffice;
}
