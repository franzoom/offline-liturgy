import '../../classes/calendar_class.dart';
import '../../classes/vespers_class.dart';
import '../../tools/data_loader.dart';
import '../office_detection.dart';

/// Precedence threshold for First Vespers eligibility
/// Celebrations with precedence <= this value can have First Vespers
/// This includes: Solemnities (1-4), Feasts of the Lord (5)
const int _firstVespersPrecedenceThreshold = 5;

/// Returns a map of possible Vespers Offices, sorted by precedence (lowest first)
/// Key: celebration title from YAML (or resolved ferial name)
/// Value: VespersDefinition with all celebration data
///
/// This wrapper handles the special case of First Vespers (I Vespers):
/// - Detects celebrations for today (II Vespers)
/// - Detects celebrations for tomorrow
/// - If tomorrow has a high-precedence celebration (Solemnity, Feast of the Lord),
///   its First Vespers are added as options for today evening
Future<Map<String, VespersDefinition>> vespersDetection(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
) async {
  // 1. Detect celebrations for today (these will be II Vespers)
  final todayCelebrations = await detectCelebrations(calendar, date, dataLoader);

  // 2. Detect celebrations for tomorrow (potential I Vespers)
  final tomorrow = date.add(const Duration(days: 1));
  final tomorrowCelebrations =
      await detectCelebrations(calendar, tomorrow, dataLoader);

  // 3. Filter tomorrow's celebrations that qualify for First Vespers
  final firstVespersCandidates = tomorrowCelebrations
      .where((c) => c.precedence <= _firstVespersPrecedenceThreshold)
      .toList();

  // 4. Build the result map
  final Map<String, VespersDefinition> possibleVespers = {};

  // Check if there's a high priority celebration today or tomorrow (for isCelebrable logic)
  final bool hasHighPriorityToday =
      todayCelebrations.any((c) => c.precedence >= 1 && c.precedence <= 6);
  final bool hasHighPriorityTomorrow =
      firstVespersCandidates.any((c) => c.precedence >= 1 && c.precedence <= 6);

  // Add today's celebrations (II Vespers)
  for (final c in todayCelebrations) {
    // If tomorrow has First Vespers with higher precedence, today's II Vespers
    // may not be celebrable
    bool isCelebrable = c.isCelebrable;
    if (hasHighPriorityTomorrow) {
      final highestTomorrowPrecedence = firstVespersCandidates
          .map((fc) => fc.precedence)
          .reduce((a, b) => a < b ? a : b);
      if (c.precedence > highestTomorrowPrecedence) {
        isCelebrable = false;
      }
    }

    possibleVespers[c.mapKey] = VespersDefinition(
      vespersDescription: c.celebrationName,
      celebrationCode: c.celebrationCode,
      ferialCode: c.ferialCode,
      commonList: c.commonList,
      liturgicalTime: c.liturgicalTime,
      breviaryWeek: c.breviaryWeek?.toString(),
      precedence: c.precedence,
      liturgicalColor: c.liturgicalColor,
      isCelebrable: isCelebrable,
      celebrationDescription: c.celebrationDescription,
      isFirstVespers: false, // II Vespers
    );
  }

  // Add tomorrow's high-precedence celebrations (I Vespers)
  for (final c in firstVespersCandidates) {
    // Create a distinct key for First Vespers
    final firstVespersKey = 'I Vêpres: ${c.mapKey}';

    // First Vespers are celebrable if they have high precedence
    // and no higher-precedence II Vespers today
    bool isCelebrable = true;
    if (hasHighPriorityToday) {
      final highestTodayPrecedence = todayCelebrations
          .map((tc) => tc.precedence)
          .reduce((a, b) => a < b ? a : b);
      if (c.precedence > highestTodayPrecedence) {
        isCelebrable = false;
      }
    }

    possibleVespers[firstVespersKey] = VespersDefinition(
      vespersDescription: 'Premières Vêpres: ${c.celebrationName}',
      celebrationCode: c.celebrationCode,
      ferialCode: c.ferialCode,
      commonList: c.commonList,
      liturgicalTime: c.liturgicalTime,
      breviaryWeek: c.breviaryWeek?.toString(),
      precedence: c.precedence,
      liturgicalColor: c.liturgicalColor,
      isCelebrable: isCelebrable,
      celebrationDescription: c.celebrationDescription,
      isFirstVespers: true, // I Vespers
    );
  }

  // Sort by precedence (convert map to sorted entries, then back to map)
  final sortedEntries = possibleVespers.entries.toList()
    ..sort((a, b) => a.value.precedence.compareTo(b.value.precedence));

  final sortedVespers = Map.fromEntries(sortedEntries);

  print(
      '+-+-+-+-+-+-+-+-+-+ VESPERS DETECTION V2 - Possible Vespers Offices: $sortedVespers');
  return sortedVespers;
}
