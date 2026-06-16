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

  // 2. CELEBRATION LAYER (Buffer): Proper + Common
  Morning celebrationOverlay = Morning();

  // Load Common first
  if (celebrationContext.selectedCommon?.trim().isNotEmpty ?? false) {
    celebrationOverlay =
        await loadMorningHierarchicalCommon(celebrationContext);
  }

  // Load Proper and overwrite the Common content in the buffer
  if (celebrationContext.celebrationCode != celebrationContext.ferialCode) {
    final filePath = await dirPathForCode(
        celebrationContext.celebrationCode, celebrationContext.dataLoader);
    final Morning proper = await morningExtract(
        '$filePath/${celebrationContext.celebrationCode}.yaml',
        celebrationContext.dataLoader);

    // Proper overwrites Common inside the buffer
    celebrationOverlay.overlayWith(proper);
  }

  // 3. FINAL MERGING
  if (celebrationContext.precedence != null &&
      celebrationContext.precedence! <= 7) {
    // Solemnities and Feasts: Full replacement
    morningOffice.overlayWith(celebrationOverlay);
  } else {
    // Memorials (> 6):
    // evangelicAntiphon overlay for Memorials
    if (celebrationOverlay.evangelicAntiphon != null) {
      morningOffice.evangelicAntiphon = celebrationOverlay.evangelicAntiphon;
    }

    morningOffice.overlayWithCommon(celebrationOverlay);
  }

  // 4. Holy Week: assign Passion hymns if no proper hymn is defined
  const holyWeekCodes = {'holy_thursday', 'holy_friday', 'holy_saturday'};
  if (morningOffice.hymn == null &&
      holyWeekCodes.contains(celebrationContext.celebrationCode)) {
    morningOffice.hymn =
        await getHymnsForSeason("passion", celebrationContext.dataLoader);
  }

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
      psalms:
          invitatoryPsalms.where((psalm) => !usedPsalms.contains(psalm)).toList(),
    );
  }

  // 6. HYDRATION: Resolve full texts
  await resolveOfficeContent(
    psalmody: morningOffice.psalmody,
    invitatory: morningOffice.invitatory,
    hymns: morningOffice.hymn,
    dataLoader: celebrationContext.dataLoader,
    showImprecatoryVerses: celebrationContext.showImprecatoryVerses,
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

  // 7. Filter evangelicAntiphon: keep only default + current year
  morningOffice.evangelicAntiphon = filterEvangelicAntiphon(
      morningOffice.evangelicAntiphon, celebrationContext.date.year);

  // 8. Apply paschal alléluia to antiphons
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

  // 9. Assign the evangelic canticle (Benedictus)
  morningOffice.evangelicCanticle = benedictus;

  return morningOffice;
}
