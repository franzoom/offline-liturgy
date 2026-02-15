import 'dart:math';
import '../../classes/calendar_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/date_tools.dart';
import '../office_detection.dart';

/// Precedence threshold for First Vespers eligibility
/// Celebrations with precedence <= 5 can have First Vespers
/// (this includes: Solemnities (1-4), Feasts of the Lord (5) )
/// Note: All Sundays also have First Vespers, handled separately
const int _firstVespersPrecedenceThreshold = 5;
const int _defaultPrecedence = 13;

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
      await detectCelebrations(calendar, date, dataLoader);

  // 2. Detect celebrations for tomorrow (potential I Vespers)
  final tomorrow = date.shift(1);
  final tomorrowCelebrations =
      await detectCelebrations(calendar, tomorrow, dataLoader);

  // 3. Filter tomorrow's celebrations that qualify for First Vespers
  // All Sundays have First Vespers, plus high-precedence celebrations
  final firstVespersCandidates = tomorrowCelebrations
      .where((c) =>
          tomorrow.isSunday ||
          (c.precedence ?? _defaultPrecedence) <=
              _firstVespersPrecedenceThreshold)
      .toList();

  // 4. Build the result map
  final Map<String, CelebrationContext> possibleVespers = {};

  // --- Safety: Pre-calculate highest priorities to avoid reduce() on empty lists ---

  // Calculate the highest priority (lowest numerical value) for today
  final int highestTodayPrecedence = todayCelebrations.isEmpty
      ? _defaultPrecedence
      : todayCelebrations
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

  // Add today's celebrations (II Vespers)
  for (final c in todayCelebrations) {
    // If tomorrow has First Vespers with higher precedence (lower number),
    // today's II Vespers may not be celebrable
    bool isCelebrable = c.isCelebrable;
    if (hasHighPriorityTomorrow &&
        (c.precedence ?? _defaultPrecedence) > highestTomorrowPrecedence) {
      isCelebrable = false;
    }

    possibleVespers[c.celebrationTitle ?? c.celebrationCode] = c.copyWith(
      celebrationType: 'vespers2', // II Vespers
      isCelebrable: isCelebrable,
      officeDescription: c.celebrationGlobalName,
    );
  }

  // Add tomorrow's high-precedence celebrations (I Vespers)
  for (final c in firstVespersCandidates) {
    // Create a distinct key for First Vespers
    final firstVespersKey =
        'I Vêpres: ${c.celebrationTitle ?? c.celebrationCode}';

    // First Vespers are celebrable if:
    // - tomorrow is Sunday (all Sundays always have celebrable First Vespers)
    // - or they have higher precedence than today's celebrations
    bool isCelebrable = true;
    if (!tomorrow.isSunday && hasHighPriorityToday) {
      if ((c.precedence ?? _defaultPrecedence) > highestTodayPrecedence) {
        isCelebrable = false;
      }
    }

    possibleVespers[firstVespersKey] = c.copyWith(
      celebrationType: 'vespers1', // I Vespers
      date: tomorrow, // First Vespers belong to tomorrow's celebration
      isCelebrable: isCelebrable,
      officeDescription: 'Premières Vêpres: ${c.celebrationGlobalName}',
    );
  }

  // 5. Sort: Sunday First Vespers come first, then by precedence (lowest value first)
  final sortedEntries = possibleVespers.entries.toList()
    ..sort((a, b) {
      final aIsSundayFirstVespers =
          a.value.celebrationType == 'vespers1' && tomorrow.isSunday;
      final bIsSundayFirstVespers =
          b.value.celebrationType == 'vespers1' && tomorrow.isSunday;

      if (aIsSundayFirstVespers != bIsSundayFirstVespers) {
        return aIsSundayFirstVespers ? -1 : 1;
      }
      return (a.value.precedence ?? _defaultPrecedence)
          .compareTo(b.value.precedence ?? _defaultPrecedence);
    });

  final sortedVespers = Map.fromEntries(sortedEntries);

  return sortedVespers;
}
