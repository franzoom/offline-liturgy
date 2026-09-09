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
///    Mass — readingParts included — always applies wholesale (STEP 4);
///    there is no "day's readings" alternative for a Solemnity.
///  - a memorial/commemoration (precedence > 9) is celebrated: its own
///    proper prayer texts (collect, antiphons...) always apply (STEP 4),
///    applied after the Common (STEP 3) so the saint's own texts win over
///    the Common's generic ones whenever present — there is no "no prayer
///    texts" state once the memorial is selected. readingParts stay the
///    day's by default; if the reader opts into "the feast's own readings"
///    (context.useProperReadingsForMemorial), the proper's readingParts
///    apply wholesale where it has any, and whichever readingPart types
///    are still missing (partial proper, or none at all) are filled in,
///    type by type, from the selected Common — see STEP 5b.
Future<Mass> massExport(CelebrationContext context) async {
  Masses massesOffice = Masses();

  final int prec = context.precedence ?? 13;

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

  // STEP 1: Load ferial data as the base layer
  if (context.ferialCode?.trim().isNotEmpty ?? false) {
    massesOffice = await ferialMassResolution(context);
  }

  // Snapshot: the ferial day's own readingPart types for this massName —
  // the canonical set of "what a complete Mass needs" (STEP 5b), captured
  // before any proper/common overlay can change what's selected.
  final List<String> requiredPartTypes = (massesOffice.masses ?? [])
          .firstWhere(
            (m) => m.massType == context.massName,
            orElse: () => Mass(),
          )
          .readingParts
          ?.map((p) => p.partType)
          .toList() ??
      [];

  // STEP 2: Load the celebration's own proper Mass file whenever
  // celebrating the saint — needed for its prayer texts (any precedence,
  // STEP 4) and/or its own readingParts (Feasts/Solemnities always;
  // memorials only if the reader opts in, STEP 5b).
  Masses properMasses = Masses();
  if (context.celebrationCode != context.ferialCode) {
    properMasses = await _loadProperMasses(context);
  }

  // STEP 3: Handle commons — same precedence boundary as STEP 4 below, so
  // a memorial's Common never leaks its readingParts in unconditionally
  // (only STEP 5b's explicit opt-in may add readings from the Common).
  // Exception: the Christmas Octave (see isChristmasOctave above) always
  // takes the full-overlay branch regardless of precedence.
  final bool hasCommon = context.selectedCommon?.trim().isNotEmpty ?? false;
  Masses commonMasses = Masses();
  if (hasCommon) {
    commonMasses = await loadMassHierarchicalCommon(context);
    if (prec <= 9 || isChristmasOctave) {
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
  //    readingParts stay governed separately — see STEP 5b.
  //  - Christmas Octave (see isChristmasOctave above): always the full
  //    overlay branch too, for the same reason as STEP 3.
  if (prec <= 9 || isChristmasOctave) {
    massesOffice.overlayWith(properMasses);
  } else {
    massesOffice.overlayPrayerFields(properMasses);
  }

  // STEP 5: Select the Mass matching this context's massName
  final masses = massesOffice.masses ?? [];
  final Mass selected = masses.isEmpty
      ? Mass()
      : masses.firstWhere(
          (m) => m.massType == context.massName,
          orElse: () => masses.first,
        );

  // STEP 5b: For a memorial/commemoration (precedence > 9) that asked for
  // "the feast's own readings" (useProperReadingsForMemorial): the proper's
  // readingParts apply wholesale where it has any (everything else —
  // collect, antiphons, prefaces... — stays exactly as resolved above);
  // whichever readingPart types are still missing against the day's own
  // set (requiredPartTypes) — because the proper had none at all, or only
  // some — are then filled in, type by type, from the selected Common.
  // Feasts/Solemnities are untouched here: STEP 4 already forced their
  // readingParts unconditionally.
  if (prec > 9 && context.useProperReadingsForMemorial) {
    final properMassList = properMasses.masses ?? [];
    final Mass? properSelected = properMassList.isEmpty
        ? null
        : properMassList.firstWhere(
            (m) => m.massType == context.massName,
            orElse: () => properMassList.first,
          );
    selected.readingParts = (properSelected?.readingParts?.isNotEmpty ?? false)
        ? properSelected!.readingParts
        : null; // clear the day's readingParts so the Common gap-fill
    // below has room — the day's own readings must not silently
    // count as "already present" once the feast's own are requested.

    if (hasCommon) {
      final commonMassList = commonMasses.masses ?? [];
      final commonIndex =
          commonMassList.indexWhere((m) => m.massType == selected.massType);
      if (commonIndex >= 0) {
        selected.fillMissingReadingPartsFromCommon(
            commonMassList[commonIndex], requiredPartTypes);
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
        ? [liturgicalYear(year)]
        : [weekdayLectionaryYear(year), liturgicalYear(year)];
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

/// Loads proper Mass data by resolving the correct directory for the
/// celebration's code (sanctoral vs ferial), mirroring
/// readingsExport._loadProperReadings.
Future<Masses> _loadProperMasses(CelebrationContext context) async {
  final filePath =
      await dirPathForCode(context.celebrationCode, context.dataLoader);
  return massExtract(
      '$filePath/${context.celebrationCode}.yaml', context.dataLoader);
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
