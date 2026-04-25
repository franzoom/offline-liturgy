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

  if (celebrationContext.selectedCommon?.trim().isNotEmpty ?? false) {
    celebrationOverlay =
        await loadMiddleOfDayHierarchicalCommon(celebrationContext);
  }

  if (celebrationContext.celebrationCode != celebrationContext.ferialCode) {
    final results = await Future.wait([
      middleOfDayExtract(
          '$specialFilePath/${celebrationContext.celebrationCode}.yaml',
          celebrationContext.dataLoader),
      middleOfDayExtract(
          '$sanctoralFilePath/${celebrationContext.celebrationCode}.yaml',
          celebrationContext.dataLoader),
    ]);
    final MiddleOfDay proper =
        results.firstWhere((r) => !r.isEmpty, orElse: MiddleOfDay.new);

    celebrationOverlay.overlayWith(proper);
  }

  // 3. FINAL MERGING
  if (celebrationContext.precedence != null &&
      celebrationContext.precedence! <= 6) {
    middleOfDayOffice.overlayWith(celebrationOverlay);
  } else {
    middleOfDayOffice.overlayWithCommon(celebrationOverlay);
  }

  // 3b. PER-HOUR PSALMODY
  if (celebrationContext.precedence != null &&
      celebrationContext.precedence! <= 4) {
    _buildPerHourPsalmody(
      middleOfDayOffice,
      isFerialTheCelebration:
          celebrationContext.celebrationCode == celebrationContext.ferialCode,
      isPaschalOctave:
          (celebrationContext.liturgicalTime ?? '') == 'paschaloctave',
      isSunday: celebrationContext.date.weekday == DateTime.sunday,
    );
  }

  // 3c. PER-HOUR ANTIPHONS for non-solemnity cases
  if (middleOfDayOffice.psalmody != null) {
    final basePsalms = middleOfDayOffice.psalmody!;
    final tierceAntiphon = middleOfDayOffice.tierce?.antiphon;
    final sexteAntiphon = middleOfDayOffice.sexte?.antiphon;
    final noneAntiphon = middleOfDayOffice.none?.antiphon;

    if (tierceAntiphon != null && middleOfDayOffice.psalmodyTierce == null) {
      middleOfDayOffice.psalmodyTierce =
          _withAntiphon(basePsalms, tierceAntiphon);
    }
    if (sexteAntiphon != null && middleOfDayOffice.psalmodySexte == null) {
      middleOfDayOffice.psalmodySexte =
          _withAntiphon(basePsalms, sexteAntiphon);
    }
    if (noneAntiphon != null && middleOfDayOffice.psalmodyNone == null) {
      middleOfDayOffice.psalmodyNone = _withAntiphon(basePsalms, noneAntiphon);
    }
  }

  // 4. PROPAGATE ANTIPHON: repeat first antiphon to all psalms if others lack one
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

  // 5. APPEND SEASON ANTIPHON
  final bool isSolemnity = celebrationContext.precedence != null &&
      celebrationContext.precedence! <= 4;
  final bool isLentOrHolyWeek =
      (celebrationContext.liturgicalTime ?? '') == 'lent' ||
          (celebrationContext.liturgicalTime ?? '') == 'holyweek';
  final seasonAntiphon = (isSolemnity && isLentOrHolyWeek)
      ? null
      : _getSeasonAntiphon(celebrationContext);

  if (seasonAntiphon != null) {
    List<PsalmEntry> appendSeason(List<PsalmEntry> psalms) => psalms
        .map((e) => PsalmEntry(
              psalm: e.psalm,
              antiphon: [...?e.antiphon, seasonAntiphon],
              psalmData: e.psalmData,
            ))
        .toList();

    if (middleOfDayOffice.psalmody != null) {
      middleOfDayOffice.psalmody = appendSeason(middleOfDayOffice.psalmody!);
    }
    if (middleOfDayOffice.psalmodyTierce != null) {
      middleOfDayOffice.psalmodyTierce =
          appendSeason(middleOfDayOffice.psalmodyTierce!);
    }
    if (middleOfDayOffice.psalmodySexte != null) {
      middleOfDayOffice.psalmodySexte =
          appendSeason(middleOfDayOffice.psalmodySexte!);
    }
    if (middleOfDayOffice.psalmodyNone != null) {
      middleOfDayOffice.psalmodyNone =
          appendSeason(middleOfDayOffice.psalmodyNone!);
    }
  }

  // 6. HYDRATION
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

  // 7. PASCHAL ALLÉLUIA
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

// --- HELPERS ---

/// Builds per-hour psalmody lists on [office] for solemnities (step 3b).
void _buildPerHourPsalmody(
  MiddleOfDay office, {
  required bool isFerialTheCelebration,
  required bool isPaschalOctave,
  required bool isSunday,
}) {
  final tierceAntiphon = office.tierce?.antiphon;
  final sexteAntiphon = office.sexte?.antiphon;
  final noneAntiphon = office.none?.antiphon;

  if (isFerialTheCelebration || (isPaschalOctave && !isSunday)) {
    final basePsalms = office.psalmody ?? [];
    if (basePsalms.isEmpty) return;
    office.psalmodyTierce = _withAntiphon(basePsalms, tierceAntiphon);
    office.psalmodySexte = _withAntiphon(basePsalms, sexteAntiphon);
    office.psalmodyNone = _withAntiphon(basePsalms, noneAntiphon);
  } else if (isSunday) {
    final existingAntiphons =
        office.psalmody?.map((e) => e.antiphon).toList() ?? [];
    office.psalmody = List.generate(
      sunday1PsalmsForMiddleOfDay.length,
      (i) => PsalmEntry(
        psalm: sunday1PsalmsForMiddleOfDay[i],
        antiphon: i < existingAntiphons.length ? existingAntiphons[i] : null,
      ),
    );
  } else {
    office.psalmodyTierce =
        _fromGradual(gradualPsalms['tierce']!, tierceAntiphon);
    office.psalmodySexte = _fromGradual(gradualPsalms['sexte']!, sexteAntiphon);
    office.psalmodyNone = _fromGradual(gradualPsalms['none']!, noneAntiphon);
  }
}

/// Applies [antiphon] to all entries. Falls back to the entry's own antiphon if null.
List<PsalmEntry> _withAntiphon(List<PsalmEntry> psalms, String? antiphon) =>
    psalms
        .map((e) => PsalmEntry(
              psalm: e.psalm,
              antiphon: antiphon != null ? [antiphon] : e.antiphon,
            ))
        .toList();

/// Builds PsalmEntry list from gradual psalm data, overriding antiphon if provided.
List<PsalmEntry> _fromGradual(List<List<String>> gradual, String? antiphon) =>
    gradual
        .map((e) => PsalmEntry(
              psalm: e[0],
              antiphon: antiphon != null ? [antiphon] : [e[1]],
            ))
        .toList();

/// Returns the season antiphon for the middle of day office, or null for ordinary time.
String? _getSeasonAntiphon(CelebrationContext context) {
  final lt = context.liturgicalTime ?? '';
  final ferialCode = context.ferialCode ?? '';

  return switch (lt) {
    'advent' => middleOfDayAntiphons['advent'],
    'christmas' when ferialCode.startsWith('christmas_2_') =>
      middleOfDayAntiphons['after_epiphany'],
    'christmas' => middleOfDayAntiphons['christmas'],
    'lent' => middleOfDayAntiphons['lent'],
    'holyweek' => middleOfDayAntiphons['passion'],
    'paschaloctave' || 'paschaltime' => middleOfDayAntiphons['paschal'],
    _ => null,
  };
}
