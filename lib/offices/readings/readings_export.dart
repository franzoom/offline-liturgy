import '../../classes/readings_class.dart';
import '../../classes/office_elements_class.dart';
import '../../assets/usual_texts.dart';
import './ferial_readings_resolution.dart';
import './readings_extract.dart';
import '../../tools/hierarchical_common_loader.dart';
import '../../tools/celebration_index.dart';
import '../../tools/resolve_office_content.dart';
import '../../tools/paschal_antiphon.dart';
import '../../tools/hymns_management.dart';

/// Resolves the Office of Readings by orchestrating different sources.
Future<Readings> readingsExport(CelebrationContext context) async {
  Readings readingsOffice = Readings();

  final String lt = context.liturgicalTime ?? '';
  final int prec = context.precedence ?? 13;
  final bool isMemory = prec > 7;

  // STEP 1: Load Ferial data as the base layer
  if (context.ferialCode?.trim().isNotEmpty ?? false) {
    readingsOffice = await ferialReadingsResolution(context);
  }

  // STEP 2: Load Proper celebration data
  Readings properReadings = Readings();
  if (context.celebrationCode != context.ferialCode) {
    properReadings = await _loadProperReadings(context);
  }

  // STEP 3: Handle Commons and Overlays
  final bool hasCommon = context.selectedCommon?.trim().isNotEmpty ?? false;

  if (hasCommon) {
    Readings commonReadings = await loadReadingsHierarchicalCommon(context);
    if (isMemory) {
      readingsOffice.overlayWithCommon(commonReadings);
    } else {
      readingsOffice.overlayWith(commonReadings);
    }
  }

  // STEP 4: Apply Proper data
  readingsOffice.overlayWith(properReadings);

  // STEP 5: Te Deum — only for Feasts and Solemnities (precedence ≤ 7), never in Holy Week
  final bool hasTeDeum = prec <= 7 && lt != 'holyweek' &&
      context.celebrationCode != 'commemoration_of_all_the_faithful_departed';
  readingsOffice.tedeum = hasTeDeum;
  if (hasTeDeum) {
    readingsOffice.tedeumContent = teDeum;
  }

  // Holy Week: assign Passion hymns if no proper hymn is defined
  const holyWeekCodes = {'holy_thursday', 'holy_friday', 'holy_saturday'};
  if (readingsOffice.hymn == null &&
      holyWeekCodes.contains(context.celebrationCode)) {
    readingsOffice.hymn = await getHymnsForSeason("passion", context.dataLoader);
  }

  // Hydrate psalm and hymn content
  await resolveOfficeContent(
    psalmody: readingsOffice.psalmody,
    hymns: readingsOffice.hymn,
    dataLoader: context.dataLoader,
  );

  // Apply paschal alléluia to psalm antiphons
  applyPaschalToPsalmody(readingsOffice.psalmody, lt);

  return readingsOffice;
}

/// Loads proper readings by trying special_days and sanctoral paths in parallel.
Future<Readings> _loadProperReadings(CelebrationContext context) async {
  final filePath = await dirPathForCode(context.celebrationCode, context.dataLoader);
  return readingsExtract('$filePath/${context.celebrationCode}.yaml', context.dataLoader);
}
