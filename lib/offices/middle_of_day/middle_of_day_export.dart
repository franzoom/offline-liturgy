import '../../assets/libraries/middle_of_day_antiphons.dart';
import '../../assets/libraries/gradual_psalms.dart';
import '../../classes/middle_of_day_class.dart';
import '../../classes/office_elements_class.dart';
import './ferial_middle_of_day_resolution.dart';
import './middle_of_day_extract.dart';
import '../../tools/hierarchical_common_loader.dart';
import '../../tools/constants.dart';
import '../../tools/resolve_office_content.dart';
import '../../tools/paschal_antiphon.dart';

/// Resolves the Middle of Day Prayer (Tierce, Sexte, None).
/// Priority logic: Proper > Common > Ferial base.
Future<MiddleOfDay> middleOfDayExport(
    CelebrationContext celebrationContext) async {
  MiddleOfDay middleOfDayOffice = MiddleOfDay();

  // 1. BASE LAYER: Load Ferial content
  if (celebrationContext.ferialCode?.trim().isNotEmpty ?? false) {
    middleOfDayOffice = await ferialMiddleOfDayResolution(celebrationContext);
  }

  // 2. CELEBRATION LAYER (Buffer): Proper + Common
  MiddleOfDay celebrationOverlay = MiddleOfDay();

  // Load Common first
  if (celebrationContext.selectedCommon?.trim().isNotEmpty ?? false) {
    celebrationOverlay =
        await loadMiddleOfDayHierarchicalCommon(celebrationContext);
  }

  // Load Proper and overwrite the Common content in the buffer
  if (celebrationContext.celebrationCode != celebrationContext.ferialCode) {
    MiddleOfDay proper = await middleOfDayExtract(
        '$specialFilePath/${celebrationContext.celebrationCode}.yaml',
        celebrationContext.dataLoader);

    if (proper.isEmpty) {
      proper = await middleOfDayExtract(
          '$sanctoralFilePath/${celebrationContext.celebrationCode}.yaml',
          celebrationContext.dataLoader);
    }

    // Proper overwrites Common inside the buffer
    celebrationOverlay.overlayWith(proper);
  }

  // 3. FINAL MERGING
  if (celebrationContext.precedence != null &&
      celebrationContext.precedence! <= 6) {
    // Solemnities and Feasts: Full replacement
    middleOfDayOffice.overlayWith(celebrationOverlay);
  } else {
    // Memorials (> 6): Selective overlay
    middleOfDayOffice.overlayWithCommon(celebrationOverlay);
  }

  // 3b. GRADUAL PSALMS: For solemnities (precedence <= 4), override psalmody
  if (celebrationContext.precedence != null &&
      celebrationContext.precedence! <= 4) {
    final isSunday = celebrationContext.date.weekday == DateTime.sunday;

    if (isSunday) {
      // Sunday solemnity: use sunday1PsalmsForMiddleOfDay for all three hours,
      // keeping the antiphons already defined in the merged psalmody.
      final existingAntiphons =
          middleOfDayOffice.psalmody?.map((e) => e.antiphon).toList() ?? [];
      middleOfDayOffice.psalmody = List.generate(
        sunday1PsalmsForMiddleOfDay.length,
        (i) => PsalmEntry(
          psalm: sunday1PsalmsForMiddleOfDay[i],
          antiphon: i < existingAntiphons.length ? existingAntiphons[i] : null,
        ),
      );
    } else {
      // Weekday solemnity: use gradual psalms (different per hour).
      // Each entry in gradualPsalms is [psalmCode, antiphon].
      middleOfDayOffice.psalmodyTierce = gradualPsalms['tierce']!
          .map((e) => PsalmEntry(psalm: e[0], antiphon: [e[1]]))
          .toList();
      middleOfDayOffice.psalmodySexte = gradualPsalms['sexte']!
          .map((e) => PsalmEntry(psalm: e[0], antiphon: [e[1]]))
          .toList();
      middleOfDayOffice.psalmodyNone = gradualPsalms['none']!
          .map((e) => PsalmEntry(psalm: e[0], antiphon: [e[1]]))
          .toList();
    }
  }

  // 4. PROPAGATE ANTIPHON: If only the first psalm has an antiphon,
  //    repeat it for the other psalms (before adding season antiphon).
  if (middleOfDayOffice.psalmody != null &&
      middleOfDayOffice.psalmody!.length > 1) {
    final firstAntiphon = middleOfDayOffice.psalmody!.first.antiphon;
    final othersHaveAntiphon = middleOfDayOffice.psalmody!
        .skip(1)
        .any((entry) => entry.antiphon != null && entry.antiphon!.isNotEmpty);

    if (firstAntiphon != null &&
        firstAntiphon.isNotEmpty &&
        !othersHaveAntiphon) {
      middleOfDayOffice.psalmody = middleOfDayOffice.psalmody!.map((entry) {
        if (entry.antiphon == null || entry.antiphon!.isEmpty) {
          return PsalmEntry(
            psalm: entry.psalm,
            antiphon: List.from(firstAntiphon),
            psalmData: entry.psalmData,
          );
        }
        return entry;
      }).toList();
    }
  }

  // 5. PREPEND LITURGICAL TIME ANTIPHON to each psalm's antiphon list
  final seasonAntiphon = _getSeasonAntiphon(celebrationContext);
  if (seasonAntiphon != null) {
    List<PsalmEntry> prependSeason(List<PsalmEntry> psalms) {
      return psalms.map((entry) {
        return PsalmEntry(
          psalm: entry.psalm,
          antiphon: [seasonAntiphon, ...?entry.antiphon],
          psalmData: entry.psalmData,
        );
      }).toList();
    }

    if (middleOfDayOffice.psalmody != null) {
      middleOfDayOffice.psalmody = prependSeason(middleOfDayOffice.psalmody!);
    }
    if (middleOfDayOffice.psalmodyTierce != null) {
      middleOfDayOffice.psalmodyTierce =
          prependSeason(middleOfDayOffice.psalmodyTierce!);
    }
    if (middleOfDayOffice.psalmodySexte != null) {
      middleOfDayOffice.psalmodySexte =
          prependSeason(middleOfDayOffice.psalmodySexte!);
    }
    if (middleOfDayOffice.psalmodyNone != null) {
      middleOfDayOffice.psalmodyNone =
          prependSeason(middleOfDayOffice.psalmodyNone!);
    }
  }

  // 6. HYDRATION: Resolve full texts (psalmody + hymns for each hour)
  await resolveOfficeContent(
    psalmody: [
      ...?middleOfDayOffice.psalmody,
      ...?middleOfDayOffice.psalmodyTierce,
      ...?middleOfDayOffice.psalmodySexte,
      ...?middleOfDayOffice.psalmodyNone,
    ],
    hymns: [
      ...?middleOfDayOffice.hymnTierce,
      ...?middleOfDayOffice.hymnSexte,
      ...?middleOfDayOffice.hymnNone,
    ],
    dataLoader: celebrationContext.dataLoader,
  );

  // 7. Apply paschal alléluia to psalm antiphons and responsories
  final lt = celebrationContext.liturgicalTime ?? '';

  void applyPaschalToList(List<PsalmEntry>? psalms) {
    if (psalms == null) return;
    for (final entry in psalms) {
      final antiphon = entry.antiphon;
      if (antiphon != null) {
        for (int i = 0; i < antiphon.length; i++) {
          antiphon[i] = paschalAntiphon(antiphon[i], lt);
        }
      }
    }
  }

  applyPaschalToList(middleOfDayOffice.psalmody);
  applyPaschalToList(middleOfDayOffice.psalmodyTierce);
  applyPaschalToList(middleOfDayOffice.psalmodySexte);
  applyPaschalToList(middleOfDayOffice.psalmodyNone);

  for (final hour in [
    middleOfDayOffice.tierce,
    middleOfDayOffice.sexte,
    middleOfDayOffice.none,
  ]) {
    if (hour?.responsory != null) {
      hour!.responsory = paschalAntiphon(hour.responsory!, lt);
    }
  }

  return middleOfDayOffice;
}

/// Returns the season antiphon for the middle of day office, or null
/// if the liturgical time has no specific antiphon (ordinary time).
String? _getSeasonAntiphon(CelebrationContext context) {
  final lt = context.liturgicalTime ?? '';
  final ferialCode = context.ferialCode ?? '';

  if (lt == 'advent') return middleOfDayAntiphons['advent'];
  if (lt == 'christmas') {
    // After Epiphany: ferialCode like christmas_2_x
    if (ferialCode.startsWith('christmas_2_')) {
      return middleOfDayAntiphons['after_epiphany'];
    }
    return middleOfDayAntiphons['christmas'];
  }
  if (lt == 'lent') return middleOfDayAntiphons['lent'];
  if (lt == 'holyweek') return middleOfDayAntiphons['passion'];
  if (lt == 'easter') return middleOfDayAntiphons['easter'];

  // Ordinary time: no season antiphon
  return null;
}
