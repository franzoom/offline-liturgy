import '../../classes/mass_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/celebration_index.dart';
import '../../tools/date_tools.dart';
import '../../tools/hierarchical_common_loader.dart';
import '../../tools/resolve_office_content.dart';
import './ferial_mass_resolution.dart';
import './mass_extract.dart';

/// Resolves the full Mass content for one specific (celebration, massName)
/// pair, as detected by [massDetection]. Mirrors the readingsExport pipeline
/// (ferial base -> common overlay -> proper overlay), then selects the Mass
/// matching context.massName and filters its readingParts down to the
/// applicable lectionary cycle for the date.
///
/// Three cases:
///  - the ferial day is celebrated: celebrationCode == ferialCode, nothing
///    proper/common ever loads.
///  - a Feast/Solemnity (precedence <= 9) is celebrated: its own proper
///    Mass applies (STEP 4), its readings completed from the Common up to
///    a complete Liturgy of the Word (STEP 5b); there is no "day's
///    readings" alternative for a Feast.
///  - a memorial/commemoration (precedence > 9) is celebrated: its own
///    proper prayer texts (collect, antiphons...) always apply (STEP 4),
///    applied after the Common (STEP 3) so the saint's own texts win over
///    the Common's generic ones whenever present — there is no "no prayer
///    texts" state once the memorial is selected. Its readings come from
///    context.massReadingSource: the day's by default, or its proper ones,
///    completed from the day or from the Common — see STEP 5b.
Future<Mass> massExport(CelebrationContext context) async {
  Masses massesOffice = Masses();

  // Dec 26-28 (Christmas Octave, proper-only days): these have no separate
  // ferial day underneath — their own file (in ferial_days/) is the day's
  // only Mass, but ferialCode is left empty for them (see date_tools.dart's
  // ferialDayCheck), so STEP 1 below never runs and massesOffice stays
  // empty. Their precedence (6/7, see main_calendar_fill.dart) is > 5, so
  // without this, STEP 3/4 would take the memorial-only overlayPrayerFields
  // path, which requires an existing Mass to enrich and silently does
  // nothing on an empty base — losing the whole Mass. Force the
  // full-overlay path for exactly these dates. Dec 29-31 are a normal
  // ferial day again (ferialDayCheck) and don't need this: forcing them too
  // would let a competing saint's own readingParts override the day's,
  // which is wrong for a plain memorial.
  final bool isChristmasOctave =
      context.liturgicalTime == 'christmasoctave' && context.date.day <= 28;

  // STEP 1: Load ferial data as the base layer — but the Mass of the
  // Dedication or of the Dead is its Common's alone: the day's prayers
  // would be another Mass's
  if (context.hasFerialBase && context.votiveOffice == null) {
    massesOffice = await ferialMassResolution(context);
  }

  // Snapshot: the day's own readingParts for this massName — what a
  // complete Mass needs and where a memorial's missing readings come from
  // (STEP 5b), captured before any proper/common overlay replaces them.
  final List<MassReadingPart>? dayParts =
      massesOffice.ofType(context.massName)?.readingParts;

  // STEP 2: Load the celebration's own proper Mass file whenever
  // celebrating the saint — needed for its prayer texts (any precedence,
  // STEP 4) and/or its own readingParts (Feasts/Solemnities always;
  // memorials only if the reader opts in, STEP 5b).
  Masses properMasses = Masses();
  if (context.hasProperFile) {
    properMasses = await massExtract(
        await celebrationFilePath(context.properCode, context.dataLoader),
        context.dataLoader);
  }

  // STEP 3: Handle commons — same precedence boundary as STEP 4 below, so
  // a memorial's Common never leaks its readingParts in unconditionally
  // (only STEP 5b's MassReadingSource.all may add readings from it).
  // Exception: the Christmas Octave (see isChristmasOctave above) always
  // takes the full-overlay branch regardless of precedence.
  // Feasts and Solemnities (precedence <= 9), and the Christmas Octave,
  // take the full overlay; memorials only the prayer texts (STEP 4).
  final bool fullOverlay = !context.isMemorial || isChristmasOctave;
  final bool hasCommon = context.hasSelectedCommon;
  Masses commonMasses = Masses();
  if (hasCommon) {
    commonMasses = await loadMassHierarchicalCommon(context);
    if (fullOverlay) {
      massesOffice.overlayWith(commonMasses);
    } else {
      massesOffice.overlayPrayerFields(commonMasses);
    }
  }

  // STEP 4: Apply proper data.
  //  - Feasts/Solemnities (precedence <= 9): the proper Mass replaces
  //    everything wholesale, readingParts included (unchanged — there is no
  //    "day's readings" concept for a Solemnity). This threshold matches
  //    isMemory in morning/vespers/readings/middle-of-day export — Feasts
  //    of the Lord sit at precedence 5, Feasts of the Virgin/saints at 7
  //    (e.g. the Nativity of the BVM), obligatory memorials start at 10.
  //  - Memorials/commemorations (precedence > 9): only the proper's prayer
  //    texts apply, layered after the Common above so the saint's own
  //    texts always win over the Common's generic ones when present.
  //    readingParts are governed by STEP 5b.
  //  - Christmas Octave (see isChristmasOctave above): always the full
  //    overlay branch too, for the same reason as STEP 3.
  if (fullOverlay) {
    massesOffice.overlayWith(properMasses);
  } else {
    massesOffice.overlayPrayerFields(properMasses);
  }

  // STEP 5: Select the Mass matching this context's massName
  final Mass selected = massesOffice.ofType(context.massName) ??
      massesOffice.masses?.firstOrNull ??
      Mass();

  // STEP 5b: the Liturgy of the Word of a celebrated saint, measured
  // against a complete one (referenceReadingPartTypes: the day's readings,
  // two for a solemnity) and completed type by type (completeReadingParts):
  //  - a Feast/Solemnity: its proper readings, those it lacks from the
  //    Common — whatever STEP 3/4's wholesale overlays left;
  //  - a memorial: the day's readings (STEP 1, untouched since), unless the
  //    reader chose its own (massReadingSource): the proper's, those it
  //    lacks from the day (proper) or from the Common (all).
  // The Christmas Octave's proper-only days keep STEP 4's.
  if (context.hasProper && !isChristmasOctave) {
    final Mass? properSelected = properMasses.ofType(context.massName) ??
        properMasses.masses?.firstOrNull;
    final ownParts = properSelected?.readingParts;
    final commonParts =
        hasCommon ? commonMasses.ofType(selected.massType)?.readingParts : null;
    List<String> typesOf(List<MassReadingPart>? parts) =>
        parts?.map((p) => p.partType).toList() ?? const [];
    final reference = referenceReadingPartTypes(
        context.precedence, typesOf(dayParts), typesOf(ownParts));

    if (!context.isMemorial) {
      if ((ownParts?.isNotEmpty ?? false) ||
          (commonParts?.isNotEmpty ?? false)) {
        selected.readingParts =
            completeReadingParts(ownParts, commonParts, reference);
      }
    } else {
      switch (context.massReadingSource) {
        case MassReadingSource.day:
          break;
        case MassReadingSource.proper:
          selected.readingParts =
              completeReadingParts(ownParts, dayParts, reference);
        case MassReadingSource.all:
          selected.readingParts =
              completeReadingParts(ownParts, commonParts, reference);
      }
    }
  }

  // STEP 6: Filter readingParts to the applicable lectionary cycle(s) —
  // Sunday/major feasts use the A/B/C cycle, weekdays the I/II cycle. A
  // weekday checks both: a handful of Lenten weekdays (e.g. the 5th Monday
  // of Lent) key their Gospel choice off the Sunday A/B/C letter instead of
  // the weekday cycle, to avoid repeating the adjacent Sunday's Gospel — the
  // two value sets never overlap, so checking both is always safe.
  // Entries without a cycle tag (e.g. the weekday Gospel) are always kept.
  final int? year = context.liturgicalYear;
  if (year != null) {
    final List<String> cycleKeys = context.date.isSunday
        ? [sundayCycle(year)]
        : [weekdayLectionaryYear(year), sundayCycle(year)];
    _filterMassByCycle(selected, cycleKeys);
  }

  // STEP 7: Resolve the proper sequence's, solemn blessing's, eucharistic
  // prayer insert's and prefaces' codes (if any) into their content, exactly
  // like a hymn.
  await resolveOfficeContent(
    hymns: selected.sequence,
    blessings: selected.solemnBlessingList,
    eucharisticPrayerCommunicantes: selected.eucharisticPrayerCommunicantes,
    prefaces: selected.prefaceList,
    dataLoader: context.dataLoader,
  );

  return selected;
}

/// Keeps only the partContents entries relevant to one of [cycleKeys] in
/// each readingPart of [mass], mutating it in place. Entries with no cycle
/// tag are universal and always kept.
void _filterMassByCycle(Mass mass, List<String> cycleKeys) {
  if (mass.readingParts == null) return;
  for (final part in mass.readingParts!) {
    part.partContents.removeWhere((content) {
      final cycle = switch (content) {
        MassReading r => r.cycle,
        MassPsalm p => p.cycle,
        MassGospel g => g.cycle,
      };
      return cycle != null && !cycle.any(cycleKeys.contains);
    });
  }
}
