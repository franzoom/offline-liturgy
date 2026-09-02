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
///  - a Feast/Solemnity (precedence <= 5) is celebrated: its own proper
///    Mass — readingParts included — always applies wholesale (STEP 4);
///    there is no "day's readings" alternative for a Solemnity.
///  - a memorial/commemoration (precedence > 5) is celebrated: its own
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

  // STEP 1: Load ferial data as the base layer
  if (context.ferialCode?.trim().isNotEmpty ?? false) {
    massesOffice = await ferialMassResolution(context);
  }

  // Snapshot: the ferial day's own readingPart types for this massName —
  // the canonical set of "what a complete Mass needs" (STEP 5b), captured
  // before any proper/common overlay can change what's selected.
  final List<String> requiredPartTypes = (massesOffice.masses ?? [])
          .firstWhere(
            (m) => m.name == context.massName,
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
  final bool hasCommon = context.selectedCommon?.trim().isNotEmpty ?? false;
  Masses commonMasses = Masses();
  if (hasCommon) {
    commonMasses = await loadMassHierarchicalCommon(context);
    if (prec <= 5) {
      massesOffice.overlayWith(commonMasses);
    } else {
      massesOffice.overlayPrayerFields(commonMasses);
    }
  }

  // STEP 4: Apply proper data.
  //  - Feasts/Solemnities (precedence <= 5): the proper Mass replaces
  //    everything wholesale, readingParts included (unchanged — there is no
  //    "day's readings" concept for a Solemnity).
  //  - Memorials/commemorations (precedence > 5): only the proper's prayer
  //    texts apply, layered after the Common above so the saint's own
  //    texts always win over the Common's generic ones when present.
  //    readingParts stay governed separately — see STEP 5b.
  if (prec <= 5) {
    massesOffice.overlayWith(properMasses);
  } else {
    massesOffice.overlayPrayerFields(properMasses);
  }

  // STEP 5: Select the Mass matching this context's massName
  final masses = massesOffice.masses ?? [];
  final Mass selected = masses.isEmpty
      ? Mass()
      : masses.firstWhere(
          (m) => m.name == context.massName,
          orElse: () => masses.first,
        );

  // STEP 5b: For a memorial/commemoration (precedence > 5) that asked for
  // "the feast's own readings" (useProperReadingsForMemorial): the proper's
  // readingParts apply wholesale where it has any (everything else —
  // collect, antiphons, prefaces... — stays exactly as resolved above);
  // whichever readingPart types are still missing against the day's own
  // set (requiredPartTypes) — because the proper had none at all, or only
  // some — are then filled in, type by type, from the selected Common.
  // Feasts/Solemnities are untouched here: STEP 4 already forced their
  // readingParts unconditionally.
  if (prec > 5 && context.useProperReadingsForMemorial) {
    final properMassList = properMasses.masses ?? [];
    final Mass? properSelected = properMassList.isEmpty
        ? null
        : properMassList.firstWhere(
            (m) => m.name == context.massName,
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

  // STEP 6: Filter readingParts to the applicable lectionary cycle —
  // Sunday/major feasts use the A/B/C cycle, weekdays the I/II cycle.
  // Entries without a cycle tag (e.g. the weekday Gospel) are always kept.
  final int? year = context.liturgicalYear;
  if (year != null) {
    final String cycleKey = context.date.isSunday
        ? liturgicalYear(year)
        : weekdayLectionaryYear(year);
    _filterMassByCycle(selected, cycleKey);
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

/// Keeps only the partContents entries relevant to [cycleKey] in each
/// readingPart of [mass], mutating it in place. Entries with no cycle tag
/// are universal and always kept.
void _filterMassByCycle(Mass mass, String cycleKey) {
  if (mass.readingParts == null) return;
  for (final part in mass.readingParts!) {
    part.partContents.removeWhere((content) {
      final cycle = switch (content) {
        MassReading r => r.cycle,
        MassPsalm p => p.cycle,
        MassGospel g => g.cycle,
      };
      return cycle != null && !cycle.contains(cycleKey);
    });
  }
}
