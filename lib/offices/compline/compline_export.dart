import '../../classes/compline_class.dart';
import '../../classes/office_elements_class.dart';
import '../../assets/compline/compline_default.dart';
import '../../assets/compline/compline_paschal_time.dart';
import '../../assets/compline/compline_lent_time.dart';
import '../../assets/compline/compline_solemnity_lent_time.dart';
import '../../assets/compline/compline_solemnity_paschal_time.dart';
import '../../assets/compline/compline_solemnity_ordinary_time.dart';
import '../../assets/compline/compline_solemnity_advent_christmas.dart';
import '../../assets/compline/compline_advent_time.dart';
import '../../assets/compline/compline_christmas_time.dart';
import '../../tools/resolve_office_content.dart';
import '../../tools/paschal_antiphon.dart';
import '../../assets/usual_texts.dart';

/// Hydrates a SINGLE chosen ComplineDefinition into a full Compline object with text.
/// This is called AFTER the user has picked a specific Compline option.
Future<Compline> complineExport(
  ComplineDefinition choice, {
  bool showImprecatoryVerses = false,
}) async {
  final dataLoader = choice.dataLoader;
  if (dataLoader == null) {
    throw Exception("ComplineDefinition is missing a DataLoader");
  }

  // 1. Get the static text structure based on the user's choice
  final compline = getComplineText(choice);

  if (compline == null) {
    throw Exception("Could not resolve text for the chosen Compline");
  }

  // 2. Hydrate dynamic content (psalms, hymns) from data source
  await resolveOfficeContent(
    psalmody: compline.psalmody,
    hymns: compline.hymns,
    dataLoader: dataLoader,
  );

  // 3. Hydrate Marian hymns
  if (compline.marialHymnRef != null) {
    await resolveOfficeContent(
      hymns: compline.marialHymnRef,
      dataLoader: dataLoader,
    );
  }

  // 4. Assign the evangelic canticle (Nunc Dimittis)
  compline.evangelicCanticle = nuncDimittis;

  // 5. Apply paschal alléluia to evangelic antiphon
  final lt = choice.liturgicalTime;
  final ea = compline.evangelicAntiphon;
  if (ea != null) {
    compline.evangelicAntiphon = EvangelicAntiphon(
      common: ea.common != null ? paschalAntiphon(ea.common!, lt) : null,
      yearA: ea.yearA != null ? paschalAntiphon(ea.yearA!, lt) : null,
      yearB: ea.yearB != null ? paschalAntiphon(ea.yearB!, lt) : null,
      yearC: ea.yearC != null ? paschalAntiphon(ea.yearC!, lt) : null,
    );
  }

  return compline;
}

// --- TEXT RESOLUTION LOGIC ---

/// Maps a ComplineDefinition to the correct asset files.
/// This logic is central to linking your detection to your text files.
Compline? getComplineText(ComplineDefinition def) {
  final String day = def.dayOfCompline; // 'sunday', 'monday', etc.
  final String time = def.liturgicalTime.toLowerCase();

  // Base default structure for fallback
  final Compline base = defaultCompline[day] ?? defaultCompline['monday']!;

  // Resolve the specific structure based on the celebration category
  final Compline? correction = switch (def.celebrationType.toLowerCase()) {
    // Triduum Special Cases
    'holy_thursday' => lentTimeCompline['holy_thursday'],
    'holy_friday' => lentTimeCompline['holy_friday'],
    'holy_saturday' => lentTimeCompline['holy_saturday'],

    // Solemnities and their Eves
    'solemnity' || 'solemnityeve' => switch (time) {
        'paschaloctave' || 'paschaltime' => solemnityComplinePaschalTime[day],
        'lent' => solemnityComplineLentTime[day],
        'advent' ||
        'christmas' ||
        'christmasoctave' =>
          solemnityComplineAdventChristmas[day],
        _ => solemnityComplineOrdinaryTime[day],
      },

    // Normal Days (Ferial) and Sundays
    _ => switch (time) {
        'paschaloctave' || 'paschaltime' => paschalTimeCompline[day],
        'lent' => lentTimeCompline[day],
        'advent' => adventTimeCompline[day],
        'christmas' || 'christmasoctave' => christmasTimeCompline[day],
        _ => base,
      },
  };

  if (correction == null) return base;

  // Merge the base structure with the specific liturgical corrections
  // and ensure the celebrationType is preserved in the final object
  return base.mergeWith(correction).copyWith(
        celebrationType: def.celebrationType,
      );
}
