import '../../classes/calendar_class.dart';
import '../../classes/compline_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/date_tools.dart';
import '../office_detection.dart';

/// Determines the celebration type for Compline based on precedence and code
String _detectCelebrationType(int precedence, String celebrationCode) {
  // Check for special Holy Week days
  if (holyWeekCodes.contains(celebrationCode.toLowerCase())) {
    return celebrationCode.toLowerCase();
  }

  // Solemnities have precedence <= 4
  if (precedence <= 4) {
    return 'solemnity';
  }

  return 'normal';
}

/// Determines the day of week to use for Compline psalms
/// (For solemnities, sunday psalms will be used)
String _detectDayOfWeek(DateTime date, String celebrationType) {
  // first handle the solemnities
  final specialDay = switch (celebrationType) {
    'solemnity' => 'sunday',
    'solemnityeve' => 'saturday',
    _ => null,
  };
  if (specialDay != null) return specialDay;

  // otherwise look at the day name
  return dayNames[date.weekday] ?? 'monday';
}

/// Returns a map of possible Compline Offices, sorted by precedence (lowest first)
/// Key: celebration description
/// Value: ComplineDefinition with all celebration data
///
/// This wrapper handles Compline-specific logic:
/// - Determines dayOfWeek for psalm selection
/// - Determines celebrationType (normal, solemnity, etc.)
/// - Handles Eve Complines (like First Vespers) for tomorrow's solemnities/Sundays
Future<Map<String, ComplineDefinition>> complineDetection(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
) async {
  final Map<String, ComplineDefinition> possibleComplines = {};

  // Get day content for liturgical time
  final dayContent = calendar.getDayContent(date);
  if (dayContent == null) {
    return possibleComplines;
  }

  final String liturgicalTime = dayContent.liturgicalTime;
  final String todayName = dayNames[date.weekday] ?? 'monday';

  // Special case for octaves - simplified Complines
  if (liturgicalTime == 'christmasoctave' ||
      liturgicalTime == 'paschaloctave') {
    possibleComplines['Complies du samedi'] = ComplineDefinition(
      complineDescription: 'Complies du samedi',
      celebrationCode: dayContent.defaultCelebrationTitle,
      ferialCode: dayContent.defaultCelebrationTitle,
      liturgicalTime: liturgicalTime,
      precedence: 8,
      liturgicalColor: dayContent.liturgicalColor,
      isCelebrable: true,
      dayOfWeek: 'saturday',
      celebrationType: 'solemnityeve',
    );
    possibleComplines['Complies du dimanche'] = ComplineDefinition(
      complineDescription: 'Complies du dimanche',
      celebrationCode: dayContent.defaultCelebrationTitle,
      ferialCode: dayContent.defaultCelebrationTitle,
      liturgicalTime: liturgicalTime,
      precedence: 8,
      liturgicalColor: dayContent.liturgicalColor,
      isCelebrable: true,
      dayOfWeek: 'sunday',
      celebrationType: 'solemnity',
    );
    return possibleComplines;
  }

  // 1. Detect celebrations for today
  final todayCelebrations =
      await detectCelebrations(calendar, date, dataLoader);

  // 2. Detect celebrations for tomorrow (for eve Complines)
  final tomorrow = date.shift(1);
  final tomorrowCelebrations =
      await detectCelebrations(calendar, tomorrow, dataLoader);

  // 3. Process today's celebrations
  for (final c in todayCelebrations) {
    final int precedence = c.precedence ?? 13;
    final celebrationType =
        _detectCelebrationType(precedence, c.celebrationCode);
    final dayOfWeek = _detectDayOfWeek(date, celebrationType);

    // Build description
    final description = switch (celebrationType) {
      _ when ferialDayCheck(c.celebrationCode) =>
        'Complies du $todayName du ${_liturgicalTimeLabel(liturgicalTime)}',
      'solemnity' => 'Complies de ${c.celebrationGlobalName}',
      _ => 'Complies du $todayName',
    };

    possibleComplines[description] = ComplineDefinition(
      complineDescription: description,
      celebrationCode: c.celebrationCode,
      ferialCode: c.ferialCode ?? '',
      liturgicalTime: liturgicalTime,
      precedence: precedence,
      liturgicalColor: c.liturgicalColor ?? 'green',
      isCelebrable: c.isCelebrable,
      dayOfWeek: dayOfWeek,
      celebrationType: celebrationType,
      isEveCompline: false,
    );
  }

  // 4. Process tomorrow's celebrations for eve Complines
  // Only solemnities (precedence <= 4) and Sundays get eve Complines
  for (final c in tomorrowCelebrations) {
    final int precedence = c.precedence ?? 13;
    final bool needsEveCompline =
        precedence <= 4 || tomorrow.weekday == DateTime.sunday;

    if (needsEveCompline) {
      final String eveDescription =
          'Complies de la veille de ${c.celebrationGlobalName}';
      final String eveCelebrationType =
          precedence <= 4 ? 'solemnityeve' : 'normal';

      // Check if today already has a solemnity - if so, eve Compline is not celebrable
      final bool todayHasSolemnity =
          todayCelebrations.any((tc) => (tc.precedence ?? 13) <= 4);
      final bool isCelebrable = !todayHasSolemnity || precedence <= 4;

      possibleComplines[eveDescription] = ComplineDefinition(
        complineDescription: eveDescription,
        celebrationCode: c.celebrationCode,
        ferialCode: c.ferialCode ?? '',
        liturgicalTime: liturgicalTime,
        precedence: precedence,
        liturgicalColor: c.liturgicalColor ?? 'green',
        isCelebrable: isCelebrable,
        dayOfWeek: 'saturday', // Eve Complines always use Saturday psalms
        celebrationType: eveCelebrationType,
        isEveCompline: true,
      );
    }
  }

  // Sort by precedence
  final sortedEntries = possibleComplines.entries.toList()
    ..sort((a, b) => a.value.precedence.compareTo(b.value.precedence));

  print(
      '+-+-+-+-+-+-+-+-+-+ COMPLINE DETECTION V2 - Possible Complines: ${Map.fromEntries(sortedEntries)}');
  return Map.fromEntries(sortedEntries);
}

/// Helper to get French label for liturgical time
String _liturgicalTimeLabel(String liturgicalTime) {
  switch (liturgicalTime.toLowerCase()) {
    case 'advent':
      return 'temps de l\'Avent';
    case 'christmas':
    case 'christmasoctave':
      return 'temps de Noël';
    case 'lent':
      return 'temps du Carême';
    case 'paschal':
    case 'paschaloctave':
      return 'temps Pascal';
    case 'ot':
      return 'temps Ordinaire';
    default:
      return liturgicalTime;
  }
}
