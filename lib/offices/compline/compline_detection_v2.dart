import '../../classes/calendar_class.dart';
import '../../classes/compline_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/date_tools.dart';
import '../office_detection.dart';

/// Day names mapping for Compline (English weekday names)
const Map<int, String> _dayNames = {
  1: 'monday',
  2: 'tuesday',
  3: 'wednesday',
  4: 'thursday',
  5: 'friday',
  6: 'saturday',
  7: 'sunday',
};

/// Special celebration codes for Holy Week
const Set<String> _holyWeekCodes = {
  'holy_thursday',
  'holy_friday',
  'holy_saturday',
};

/// Determines the celebration type for Compline based on precedence and code
String _determineCelebrationType(int precedence, String celebrationCode) {
  // Check for special Holy Week days
  if (_holyWeekCodes.contains(celebrationCode.toLowerCase())) {
    return celebrationCode.toLowerCase();
  }

  // Solemnities have precedence <= 4
  if (precedence <= 4) {
    return 'solemnity';
  }

  return 'normal';
}

/// Determines the day of week to use for Compline psalms
/// For solemnities, use 'sunday' psalms; otherwise use actual day
String _determineDayOfWeek(
    DateTime date, String celebrationType, int precedence) {
  if (celebrationType == 'solemnity' || celebrationType == 'solemnityeve') {
    return celebrationType == 'solemnityeve' ? 'saturday' : 'sunday';
  }

  // For Sundays, always return 'sunday'
  if (date.weekday == DateTime.sunday) {
    return 'sunday';
  }

  return _dayNames[date.weekday] ?? 'monday';
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
  final String todayName = _dayNames[date.weekday] ?? 'monday';

  // Special case for octaves - simplified Complines
  if (liturgicalTime == 'christmasoctave' || liturgicalTime == 'paschaloctave') {
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
  final todayCelebrations = await detectCelebrations(calendar, date, dataLoader);

  // 2. Detect celebrations for tomorrow (for eve Complines)
  final tomorrow = date.add(const Duration(days: 1));
  final tomorrowCelebrations =
      await detectCelebrations(calendar, tomorrow, dataLoader);

  // 3. Process today's celebrations
  for (final c in todayCelebrations) {
    final celebrationType =
        _determineCelebrationType(c.precedence, c.celebrationCode);
    final dayOfWeek = _determineDayOfWeek(date, celebrationType, c.precedence);

    // Build description
    String description;
    if (ferialDayCheck(c.celebrationCode)) {
      description = 'Complies du $todayName du ${_liturgicalTimeLabel(liturgicalTime)}';
    } else if (celebrationType == 'solemnity') {
      description = 'Complies de ${c.celebrationName}';
    } else {
      description = 'Complies du $todayName';
    }

    possibleComplines[description] = ComplineDefinition(
      complineDescription: description,
      celebrationCode: c.celebrationCode,
      ferialCode: c.ferialCode,
      commonList: c.commonList,
      liturgicalTime: liturgicalTime,
      breviaryWeek: c.breviaryWeek?.toString(),
      precedence: c.precedence,
      liturgicalColor: c.liturgicalColor,
      isCelebrable: c.isCelebrable,
      celebrationDescription: c.celebrationDescription,
      dayOfWeek: dayOfWeek,
      celebrationType: celebrationType,
      isEveCompline: false,
    );
  }

  // 4. Process tomorrow's celebrations for eve Complines
  // Only solemnities (precedence <= 4) and Sundays get eve Complines
  for (final c in tomorrowCelebrations) {
    final bool needsEveCompline =
        c.precedence <= 4 || tomorrow.weekday == DateTime.sunday;

    if (needsEveCompline) {
      final String eveDescription = 'Complies de la veille de ${c.celebrationName}';
      final String eveCelebrationType =
          c.precedence <= 4 ? 'solemnityeve' : 'normal';

      // Check if today already has a solemnity - if so, eve Compline is not celebrable
      final bool todayHasSolemnity =
          todayCelebrations.any((tc) => tc.precedence <= 4);
      final bool isCelebrable = !todayHasSolemnity || c.precedence <= 4;

      possibleComplines[eveDescription] = ComplineDefinition(
        complineDescription: eveDescription,
        celebrationCode: c.celebrationCode,
        ferialCode: c.ferialCode,
        commonList: c.commonList,
        liturgicalTime: liturgicalTime,
        breviaryWeek: c.breviaryWeek?.toString(),
        precedence: c.precedence,
        liturgicalColor: c.liturgicalColor,
        isCelebrable: isCelebrable,
        celebrationDescription: c.celebrationDescription,
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
