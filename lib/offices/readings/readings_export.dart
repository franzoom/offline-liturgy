import '../../classes/readings_class.dart';
import '../../classes/office_elements_class.dart';
import '../../assets/usual_texts.dart';
import './ferial_readings_resolution.dart';
import './readings_extract.dart';
import '../../tools/hierarchical_common_loader.dart';
import '../../tools/constants.dart';
import '../../tools/resolve_office_content.dart';
import '../../tools/paschal_antiphon.dart';

/// Resolves the Office of Readings by orchestrating different sources.
Future<Readings> readingsExport(CelebrationContext context) async {
  Readings readingsOffice = Readings();

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
  final bool isMemory = (context.precedence ?? 13) > 6;
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
  // Note: overlayWith will update readingsOffice.tedeum if defined in YAML
  readingsOffice.overlayWith(properReadings);

  // STEP 5: Finalize Te Deum flag and hydrate content
  // Rule: No Te Deum on Sundays of Lent (non-feast/solemnity), even if YAML sets it.
  // Feasts and solemnities (precedence <= 5) always have Te Deum, even in Lent.
  final bool isLentenSundayNonFeast =
      context.date.weekday == DateTime.sunday &&
      (context.liturgicalTime ?? '').toLowerCase().contains('lent') &&
      (context.precedence ?? 13) >= 6;

  readingsOffice.tedeum = isLentenSundayNonFeast
      ? false
      : (context.teDeum == true) || (readingsOffice.tedeum == true);
  if (readingsOffice.tedeum == true) {
    readingsOffice.tedeumContent = teDeum;
  }

  // Hydrate psalm and hymn content
  await resolveOfficeContent(
    psalmody: readingsOffice.psalmody,
    hymns: readingsOffice.hymn,
    dataLoader: context.dataLoader,
    imprecatory: context.showImprecatoryVerses,
  );

  // Apply paschal alléluia to psalm antiphons
  final lt = context.liturgicalTime ?? '';

  if (readingsOffice.psalmody != null) {
    for (final entry in readingsOffice.psalmody!) {
      final antiphon = entry.antiphon;
      if (antiphon != null) {
        for (int i = 0; i < antiphon.length; i++) {
          antiphon[i] = paschalAntiphon(antiphon[i], lt);
        }
      }
    }
  }

  return readingsOffice;
}

/// Helper to try loading the proper file from multiple directories
Future<Readings> _loadProperReadings(CelebrationContext context) async {
  final List<String> searchPaths = [
    '$specialFilePath/${context.celebrationCode}.yaml',
    '$sanctoralFilePath/${context.celebrationCode}.yaml',
  ];

  for (String path in searchPaths) {
    final readings = await readingsExtract(path, context.dataLoader);
    if (!readings.isEmpty) return readings;
  }
  return Readings();
}
