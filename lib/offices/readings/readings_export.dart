import 'dart:developer';

import '../../classes/readings_class.dart';
import '../../classes/office_elements_class.dart';
import '../../assets/usual_texts.dart';
import './ferial_readings_resolution.dart';
import './readings_extract.dart';
import '../../tools/hierarchical_common_loader.dart';
import '../compose_office.dart';
import '../../tools/resolve_office_content.dart';
import '../../tools/paschal_antiphon.dart';
import '../../tools/date_tools.dart';
import '../../tools/bible_text_provider.dart';

/// Resolves the Office of Readings by orchestrating different sources.
Future<Readings> readingsExport(CelebrationContext context) async {
  final String lt = context.liturgicalTime ?? '';
  final int prec = context.precedence ?? 13;

  // STEPS 1-4: Ferial base, Common and proper layers
  final (office: readingsOffice, proper: _) = await composeOffice<Readings>(
    context,
    empty: Readings.new,
    ferial: () => ferialReadingsResolution(context),
    proper: (path) => readingsExtractFor(context, path),
    common: () => loadReadingsHierarchicalCommon(context),
    overlay: (base, layer) =>
        base.overlayWith(layer, keepBaseHymns: context.keepsSeasonHymns),
    overlayCommon: (base, common) => base.overlayWithCommon(common),
  );

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
