import '../../classes/morning_class.dart';
import '../../classes/office_elements_class.dart';
import './ferial_morning_resolution.dart';
import './morning_extract.dart';
import '../../tools/hierarchical_common_loader.dart';
import '../../tools/constants.dart';
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
    final results = await Future.wait([
      morningExtract('$specialFilePath/${celebrationContext.celebrationCode}.yaml',
          celebrationContext.dataLoader),
      morningExtract('$sanctoralFilePath/${celebrationContext.celebrationCode}.yaml',
          celebrationContext.dataLoader),
    ]);
    final Morning proper =
        results.firstWhere((r) => !r.isEmpty, orElse: Morning.new);

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
    morningOffice.hymn = getHymnsForSeason("passion");
  }

  // 5. Prepend Gloria hymn, except during Lent and Holy Week
  final lt = celebrationContext.liturgicalTime ?? '';
  if (lt != 'lent' && lt != 'holyweek') {
    morningOffice.hymn = [
      HymnEntry(code: 'gloire-a-dieu-paix-aux-hommes'),
      ...?morningOffice.hymn,
    ];
  }

  // 6. HYDRATION: Resolve full texts
  await resolveOfficeContent(
    psalmody: morningOffice.psalmody,
    invitatory: morningOffice.invitatory,
    hymns: morningOffice.hymn,
    dataLoader: celebrationContext.dataLoader,
  );

  // 8. Filter evangelicAntiphon: keep only default + current year
  final antiphonMap = morningOffice.evangelicAntiphon;
  if (antiphonMap != null) {
    final year = liturgicalYear(celebrationContext.date.year);
    morningOffice.evangelicAntiphon = {
      if (antiphonMap.containsKey('antiphon'))
        'antiphon': antiphonMap['antiphon']!,
      if (antiphonMap.containsKey(year)) year: antiphonMap[year]!,
    };
  }

  // 9. Apply paschal alléluia to antiphons

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

  // 8. Assign the evangelic canticle (Benedictus)
  morningOffice.evangelicCanticle = benedictus;

  return morningOffice;
}
