import 'dart:math';
import '../../classes/calendar_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/date_tools.dart';
import '../../tools/constants.dart';
import '../office_detection.dart';
import '../../assets/libraries/french_liturgy_labels.dart';

/// Precedence threshold for First Vespers eligibility
/// Celebrations with precedence <= 5 can have First Vespers
/// (this includes: Solemnities (1-4), Feasts of the Lord (5) )
/// Note: All Sundays also have First Vespers, handled separately
const int _firstVespersPrecedenceThreshold = 5;
const int _defaultPrecedence = 13;

/// Solemnities and the days ranking above them (Triduum, privileged
/// Sundays, Holy Week, Easter Octave...) — see isSolemnityLevel below.
const int _solemnityLevelPrecedence = 4;

/// Returns a map of possible Vespers Offices, sorted by precedence (lowest value first)
/// Key: celebration title from YAML (or resolved ferial name)
/// Value: CelebrationContext with all celebration data
///   - celebrationType='vespers1' for First Vespers (I Vespers)
///   - celebrationType='vespers2' for Second Vespers (II Vespers)
///
/// This wrapper handles the special case of First Vespers (I Vespers):
/// - Detects celebrations for today (II Vespers)
/// - Detects celebrations for tomorrow
/// - If tomorrow has a high-precedence celebration (Solemnity, Feast of the Lord),
///   its First Vespers are added as options for today evening
Future<Map<String, CelebrationContext>> vespersDetection(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
) async {
  // 1. Detect celebrations for today (these will be II Vespers)
  final todayCelebrations =
      await detectOfficeCelebrations(calendar, date, dataLoader);

  // --- Special case: Holy Week Triduum only has its own Vespers, no other option ---
  bool isHolyWeekCell(CelebrationContext c) =>
      holyWeekCodes.contains(c.celebrationCode);

  if (todayCelebrations.any(isHolyWeekCell)) {
    final c = todayCelebrations.firstWhere(isHolyWeekCell);
    final Map<String, CelebrationContext> result = {};
    result[c.celebrationTitle ?? c.celebrationCode] = c.copyWith(
      celebrationType: 'vespers2',
      isCelebrable: true,
      officeDescription: c.celebrationGlobalName,
    );
    return result;
  }

  // 2. Detect celebrations for tomorrow (potential I Vespers)
  final tomorrow = date.shift(1);
  final tomorrowCelebrations =
      await detectOfficeCelebrations(calendar, tomorrow, dataLoader);

  // 3. Filter tomorrow's celebrations that qualify for First Vespers
  // All Sundays have First Vespers, plus high-precedence celebrations
  // Ferial days (even high-precedence ones like Ash Wednesday) never have First Vespers
  // When today is Sunday, tomorrow's solemnities (prec. <= 3) always qualify —
  // but this must still exclude ferial days, or Palm Sunday (a Sunday) hands
  // Monday/Tuesday/Wednesday of Holy Week (precedence 2, ferial-coded
  // lent_6_1/2/3) a bogus First Vespers, when Palm Sunday's own Second
  // Vespers is what actually covers that evening.
  //
  // A Feast (prec. 4-5, not a true solemnity) must NOT be granted First
  // Vespers when today is already a Sunday — only a solemnity (prec. <= 3)
  // may override a Sunday's own Second Vespers. Confirmed against AELF: the
  // Presentation of the Lord (prec. 5) on a Monday does not get its First
  // Vespers on the preceding Sunday evening; that Sunday keeps its own
  // Second Vespers.
  //
  // Exception: during the Easter Octave (Easter Sunday through Easter Saturday),
  // no First Vespers of the next day are celebrated — all octave days are equal.
  final bool isEasterOctave = todayCelebrations.any((c) {
    final code =
        c.ferialCode?.isNotEmpty == true ? c.ferialCode! : c.celebrationCode;
    return RegExp(r'^easter_1_[0-6]$').hasMatch(code);
  });

  // First Vespers of these feasts are only celebrated when they fall on a
  // Sunday (Holy Family: on its usual Sunday, First Vespers is its own; when
  // Christmas is itself a Sunday and Holy Family is fixed to Dec 30 instead,
  // there is no First Vespers of Holy Family — the ferial Vespers of that
  // Christmas Octave day is celebrated normally).
  // 'roman/exaltation_of_the_holy_cross_week' only ever appears on a weekday
  // (the calendar picks 'roman/exaltation_of_the_holy_cross_sunday' when the
  // feast itself falls on a Sunday), so listing it here means it never gets
  // First Vespers — the Sunday variant is left out on purpose: by
  // construction it only appears when tomorrow.isSunday is already true, so
  // the default (First Vespers allowed) is correct for it.
  const sundayOnlyFirstVespersCodes = {
    'roman/transfiguration_of_the_lord_week',
    'roman/exaltation_of_the_holy_cross_week',
    'roman/holy_family_week',
    'roman/presentation_of_the_lord_week',
    'roman/baptism_of_the_lord_week',
    // A single code whatever the weekday: First Vespers only on a Sunday.
    'roman/dedication_of_the_lateran_basilica',
  };

  // A Solemnity of the Lord's First Vespers always wins over a Sunday's
  // Second Vespers, even when both share the same raw precedence (2) — e.g.
  // the Nativity (Dec 25) vs. the 4th Sunday of Advent when Dec 24 falls on
  // a Sunday. Of the precedence-2 Solemnities of the Lord, only the
  // Nativity's eve can actually land on a precedence-2 Sunday (Ascension's
  // eve is always a Wednesday, Pentecost's eve a Saturday, Mary Mother of
  // God's eve is within the Christmas Octave at precedence 6/9) — so this
  // set only needs the one entry for now.
  const sundayTieBreakingFirstVespersCodes = {'roman/nativity'};

  // The Commemoration of All the Faithful Departed (Table item 3, alongside
  // solemnities) never has a First Vespers of its own — the Office of the
  // Dead used that day has no Vespers I, unlike a true solemnity.
  const neverFirstVespersCodes = {
    'roman/commemoration_of_all_the_faithful_departed',
  };
  bool isFirstVespersAllowed(CelebrationContext c) {
    if (neverFirstVespersCodes.contains(c.celebrationCode)) return false;
    if (sundayOnlyFirstVespersCodes.contains(c.celebrationCode)) {
      return tomorrow.isSunday;
    }
    return true;
  }

  final firstVespersCandidates = isEasterOctave
      ? <CelebrationContext>[]
      : tomorrowCelebrations
          .where((c) =>
              isFirstVespersAllowed(c) &&
              ((tomorrow.isSunday &&
                      (c.precedence ?? _defaultPrecedence) <= 6) ||
                  (!ferialDayCheck(c.celebrationCode) &&
                      !date.isSunday &&
                      (c.precedence ?? _defaultPrecedence) <=
                          _firstVespersPrecedenceThreshold) ||
                  (date.isSunday &&
                      !ferialDayCheck(c.celebrationCode) &&
                      (c.precedence ?? _defaultPrecedence) <= 3)))
          .toList();

  // 4. Build the result map
  final Map<String, CelebrationContext> possibleVespers = {};

  // The Marian memory is only celebrated at Morning and Readings, not Vespers
  final vespersEligible = todayCelebrations
      .where((c) => c.celebrationCode != 'roman/virgin-mary-memory')
      .toList();

  // --- Safety: Pre-calculate highest priorities to avoid reduce() on empty lists ---

  // Calculate the highest priority (lowest numerical value) for today
  final int highestTodayPrecedence = vespersEligible.isEmpty
      ? _defaultPrecedence
      : vespersEligible
          .map((c) => c.precedence ?? _defaultPrecedence)
          .reduce(min);

  // Calculate the highest priority (lowest numerical value) for tomorrow
  final int highestTomorrowPrecedence = firstVespersCandidates.isEmpty
      ? _defaultPrecedence
      : firstVespersCandidates
          .map((c) => c.precedence ?? _defaultPrecedence)
          .reduce(min);

  // Boolean flags for high priority (Solemnities/Feasts)
  final bool hasHighPriorityToday = highestTodayPrecedence <= 6;
  final bool hasHighPriorityTomorrow = highestTomorrowPrecedence <= 6;

  // Does tomorrow's winning First Vespers candidate belong to the
  // tie-breaking set above? If so, a Sunday's Second Vespers today must
  // give way even at equal precedence (see comment above the set).
  final bool tomorrowWinsTies = date.isSunday &&
      firstVespersCandidates.any((c) =>
          sundayTieBreakingFirstVespersCodes.contains(c.celebrationCode) &&
          (c.precedence ?? _defaultPrecedence) == highestTomorrowPrecedence);

  // Two solemnity-level celebrations (precedence <= 4) competing for the
  // same evening are a doubtful case: practice isn't uniform (AELF kept
  // the Second Vespers of the Immaculate Conception over the 2nd Sunday of
  // Advent in 2018, but gave the Annunciation's way to the 5th Sunday of
  // Lent in 2023). Both stay celebrable, and the sort below puts first the
  // likelier one: the higher rank per the Table of Liturgical Days, Second
  // Vespers on a tie. The Nativity tie-break above still applies.
  bool isSolemnityConflict(int precedence, int otherPrecedence) =>
      precedence <= _solemnityLevelPrecedence &&
      otherPrecedence <= _solemnityLevelPrecedence;

  // Add today's celebrations
  for (final c in vespersEligible) {
    // If tomorrow has First Vespers with higher precedence (lower number),
    // today's Vespers may not be celebrable
    bool isCelebrable = c.isCelebrable;
    final int precedence = c.precedence ?? _defaultPrecedence;
    final bool solemnityConflict = !tomorrowWinsTies &&
        isSolemnityConflict(precedence, highestTomorrowPrecedence);
    if (hasHighPriorityTomorrow &&
        !solemnityConflict &&
        (precedence > highestTomorrowPrecedence ||
            (tomorrowWinsTies && precedence == highestTomorrowPrecedence))) {
      isCelebrable = false;
    }

    final bool showSecondVespersLabel = date.isSunday ||
        (c.precedence ?? _defaultPrecedence) <=
            _firstVespersPrecedenceThreshold;
    possibleVespers.putIfAbsent(
        c.celebrationTitle ?? c.celebrationCode,
        () => c.copyWith(
              celebrationType: 'vespers2', // II Vespers
              isCelebrable: isCelebrable,
              officeDescription: showSecondVespersLabel
                  ? '${c.celebrationGlobalName}  (${celebrationTypeLabels['secondVespers']})'
                  : c.celebrationGlobalName,
            ));
  }

  // Add tomorrow's high-precedence celebrations (I Vespers)
  for (final c in firstVespersCandidates) {
    // Create a distinct key for First Vespers
    final firstVespersKey =
        'I Vespers: ${c.celebrationTitle ?? c.celebrationCode}';

    // First Vespers are celebrable unless today's celebration outranks
    // them (GILH 61) — Sundays included: a Solemnity or a Feast of the
    // Lord on Saturday keeps its Second Vespers over an Ordinary Time
    // Sunday's First Vespers. Exceptions: a solemnity conflict keeps both
    // celebrable (see isSolemnityConflict above), and a Solemnity
    // (prec. <= 3) tomorrow always is when today is a Sunday.
    final int precedence = c.precedence ?? _defaultPrecedence;
    bool isCelebrable = true;
    if (hasHighPriorityToday &&
        precedence > highestTodayPrecedence &&
        !isSolemnityConflict(precedence, highestTodayPrecedence)) {
      isCelebrable = false;
    }
    if (date.isSunday && precedence <= 3) {
      isCelebrable = true;
    }

    possibleVespers[firstVespersKey] = c.copyWith(
      celebrationType: 'vespers1', // I Vespers
      date: tomorrow, // First Vespers belong to tomorrow's celebration
      isCelebrable: isCelebrable,
      officeDescription:
          '${c.celebrationGlobalName} (${celebrationTypeLabels['firstVespers']})',
    );
  }

  // 5. Sort: celebrable options first, then by rank (Table of Liturgical
  // Days), Second Vespers before First Vespers on a tie.
  double rankOf(CelebrationContext c) => effectivePrecedence(
      c.precedence ?? _defaultPrecedence, c.celebrationCode);

  int compareVespers(CelebrationContext a, CelebrationContext b) {
    if (a.isCelebrable != b.isCelebrable) return a.isCelebrable ? -1 : 1;
    final byRank = rankOf(a).compareTo(rankOf(b));
    if (byRank != 0) return byRank;
    if (a.celebrationType != b.celebrationType) {
      return a.celebrationType == 'vespers2' ? -1 : 1;
    }
    return 0;
  }

  final sortedEntries = possibleVespers.entries.toList()
    ..sort((a, b) => compareVespers(a.value, b.value));

  return Map.fromEntries(sortedEntries);
}
