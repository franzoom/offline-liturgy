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
/// (ferial base -> proper overlay -> common overlay -> proper overlay again),
/// then selects the Mass matching context.massName and filters its
/// readingParts down to the applicable lectionary cycle for the date. See
/// STEP 5b for how a memorial/commemoration may opt into its own proper
/// readingParts via context.useProperReadingsForMemorial.
Future<Mass> massExport(CelebrationContext context) async {
  Masses massesOffice = Masses();

  final int prec = context.precedence ?? 13;
  final bool isMemory = prec > 8;

  // STEP 1: Load ferial data as the base layer
  if (context.ferialCode?.trim().isNotEmpty ?? false) {
    massesOffice = await ferialMassResolution(context);
  }

  // STEP 2: Load proper celebration data — needed when it will be applied
  // wholesale (Feasts/Solemnities, STEP 4) or when a memorial/commemoration
  // asks for its own readingParts as an alternative to the day's (STEP 5b).
  Masses properMasses = Masses();
  final bool needsProperMasses = context.celebrationCode != context.ferialCode &&
      (prec <= 5 || context.useProperReadingsForMemorial);
  if (needsProperMasses) {
    properMasses = await _loadProperMasses(context);
  }

  // STEP 3: Handle commons
  final bool hasCommon = context.selectedCommon?.trim().isNotEmpty ?? false;
  if (hasCommon) {
    Masses commonMasses = await loadMassHierarchicalCommon(context);
    if (isMemory) {
      massesOffice.overlayWithCommon(commonMasses);
    } else {
      massesOffice.overlayWith(commonMasses);
    }
  }

  // STEP 4: Apply proper data — only for Feasts and Solemnities (precedence
  // <= 5). Memorials, commemorations and ferial days keep the ferial Mass
  // texts (the celebration's proper collect may still reach them via the
  // Common overlay in STEP 3); see STEP 5b for their readingParts.
  if (prec <= 5) {
    massesOffice.overlayWith(properMasses);
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
  // its own proper readingParts (useProperReadingsForMemorial) and actually
  // has some, swap them in — everything else (collect, antiphons,
  // prefaces...) stays exactly as resolved above. Feasts/Solemnities are
  // untouched here: STEP 4 already forced their readingParts unconditionally.
  if (prec > 5 && context.useProperReadingsForMemorial) {
    final properMassList = properMasses.masses ?? [];
    final Mass? properSelected = properMassList.isEmpty
        ? null
        : properMassList.firstWhere(
            (m) => m.name == context.massName,
            orElse: () => properMassList.first,
          );
    if (properSelected?.readingParts?.isNotEmpty ?? false) {
      selected.readingParts = properSelected!.readingParts;
    }
  }

  // STEP 6: Filter readingParts to the applicable lectionary cycle —
  // Sunday/major feasts use the A/B/C cycle, weekdays the I/II cycle.
  // Entries without a cycle tag (e.g. the weekday Gospel) are always kept.
  final int? year = context.liturgicalYear;
  if (year != null) {
    final String cycleKey =
        context.date.isSunday ? liturgicalYear(year) : weekdayLectionaryYear(year);
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
