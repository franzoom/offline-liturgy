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
/// readingParts down to the applicable lectionary cycle for the date.
Future<Mass> massExport(CelebrationContext context) async {
  Masses massesOffice = Masses();

  final int prec = context.precedence ?? 13;
  final bool isMemory = prec > 7;

  // STEP 1: Load ferial data as the base layer
  if (context.ferialCode?.trim().isNotEmpty ?? false) {
    massesOffice = await ferialMassResolution(context);
  }

  // STEP 2: Load proper celebration data
  Masses properMasses = Masses();
  if (context.celebrationCode != context.ferialCode) {
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

  // STEP 4: Apply proper data
  massesOffice.overlayWith(properMasses);

  // STEP 5: Select the Mass matching this context's massName
  final masses = massesOffice.masses ?? [];
  final Mass selected = masses.isEmpty
      ? Mass()
      : masses.firstWhere(
          (m) => m.name == context.massName,
          orElse: () => masses.first,
        );

  // STEP 6: Filter readingParts to the applicable lectionary cycle —
  // Sunday/major feasts use the A/B/C cycle, weekdays the I/II cycle.
  // Entries without a cycle tag (e.g. the weekday Gospel) are always kept.
  final int? year = context.liturgicalYear;
  if (year != null) {
    final String cycleKey =
        context.date.isSunday ? liturgicalYear(year) : weekdayLectionaryYear(year);
    _filterMassByCycle(selected, cycleKey);
  }

  // STEP 7: Resolve the proper sequence's and solemn blessing's codes (if
  // any) into their content, exactly like a hymn.
  await resolveOfficeContent(
    hymns: selected.sequence,
    blessings: selected.solemnBlessingList,
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
