import 'dart:developer';

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
import '../../tools/constants.dart';
import '../../tools/date_tools.dart';
import '../../tools/bible_text_provider.dart';

/// Resolves the Office of Readings by orchestrating different sources.
Future<Readings> readingsExport(CelebrationContext context) async {
  Readings readingsOffice = Readings();

  final String lt = context.liturgicalTime ?? '';
  final int prec = context.precedence ?? 13;
  final bool isMemory = context.isMemorial;
  // Memorials and feasts keep the season's hymns selectable after their own;
  // solemnities replace them.
  final bool keepBaseHymns = context.keepsSeasonHymns;

  // STEP 1: Load Ferial data as the base layer
  if (context.hasFerialBase) {
    readingsOffice = await ferialReadingsResolution(context);
  }

  // STEP 2: Load Proper celebration data
  Readings properReadings = Readings();
  if (context.hasProper) {
    properReadings = await readingsExtractFor(context,
        await celebrationFilePath(context.celebrationCode, context.dataLoader));
  }

  // STEP 3: Handle Commons and Overlays
  final bool hasCommon = context.hasSelectedCommon;

  if (hasCommon) {
    Readings commonReadings = await loadReadingsHierarchicalCommon(context);
    if (isMemory) {
      readingsOffice.overlayWithCommon(commonReadings);
    } else {
      readingsOffice.overlayWith(commonReadings, keepBaseHymns: keepBaseHymns);
    }
  }

  // STEP 4: Apply Proper data
  readingsOffice.overlayWith(properReadings, keepBaseHymns: keepBaseHymns);

  // Readings stored by reference only take their text from the Bible
  readingsOffice.biblicalReading = await hydrateBiblicalReadings(
      readingsOffice.biblicalReading, context.bibleTextProvider);

  // A two-year cycle reading whose text cannot be found (no provider, or a
  // reference it cannot resolve) gives way to the annual cycle, whose
  // readings always carry their text.
  if (context.twoYearReadingCycle &&
      (readingsOffice.biblicalReading?.any((r) => r.content == null) ??
          false)) {
    log('Two-year cycle reading without text, annual cycle used instead',
        name: 'ReadingsExport', level: 900);
    return readingsExport(context.copyWith(twoYearReadingCycle: false));
  }

  // STEP 5: Te Deum (GILH 68) — on Sundays outside Lent, during the Easter
  // and Christmas octaves, and on solemnities and feasts. Not a precedence
  // threshold: Ash Wednesday and the Sundays of Lent rank 2 yet have none,
  // while Dec 29-31 rank 9 yet do. The Commemoration of All the Faithful
  // Departed keeps its high rank (so that its Mass prevails even over a
  // Sunday) but has no Te Deum.
  final bool isAllSouls = context.celebrationCode ==
      'roman/commemoration_of_all_the_faithful_departed';
  final bool isOctaveDay =
      lt == 'nativity' || lt == 'christmasoctave' || lt == 'paschaloctave';
  final bool isSundayOutsideLent =
      context.date.isSunday && lt != 'lent' && lt != 'holyweek';
  final bool isSolemnityOrFeast =
      prec <= 8 && !ferialDayCheck(context.celebrationCode);
  final bool hasTeDeum =
      !isAllSouls && (isOctaveDay || isSundayOutsideLent || isSolemnityOrFeast);
  readingsOffice.teDeum = hasTeDeum ? teDeum : null;

  // Holy Week: assign Passion hymns if no proper hymn is defined
  if (readingsOffice.hymn == null &&
      holyWeekCodes.contains(context.celebrationCode)) {
    readingsOffice.hymn =
        await getHymnsForSeason("passion", context.dataLoader);
  }

  // Hydrate psalm and hymn content
  await resolveOfficeContent(
    psalmody: readingsOffice.psalmody,
    hymns: readingsOffice.hymn,
    dataLoader: context.dataLoader,
    showImprecatoryVerses: context.showImprecatoryVerses,
  );

  // Apply paschal alléluia to psalm antiphons
  applyPaschalToPsalmody(readingsOffice.psalmody, lt);

  return readingsOffice;
}
