import '../classes/calendar_class.dart'; // Calendar class
import '../classes/compline_class.dart';
import '../tools/date_tools.dart';

Map<String, ComplineDefinition> complineDetection(
    Calendar calendar, DateTime date) {
  /// Detects which Compline to use for a given day.
  /// Returns a Map "day or feast name" : ComplineDefinition
  Map<String, ComplineDefinition> complineOfGivenDay = {};

  DayContent? todayContent = calendar.getDayContent(date);
  String todayName = dayName[date.weekday];
  String liturgicalTime = todayContent!.liturgicalTime;
  String celebrationTitle = todayContent.defaultCelebrationTitle.toLowerCase();
  int liturgicalGrade = todayContent.liturgicalGrade;

  if (celebrationTitle == 'commemoration_of_all_the_faithful_departed') {
    ComplineDefinition complineDefinition = ComplineDefinition(
        dayOfWeek: todayName,
        liturgicalTime: 'OrdinaryTime',
        celebrationType: 'normal',
        priority: 13);
    return complineOfGivenDay = {celebrationTitle: complineDefinition};
  }

  switch (celebrationTitle) {
    case 'holy_thursday' || 'holy_friday' || 'holy_saturday':
      ComplineDefinition complineDefinition = ComplineDefinition(
          dayOfWeek: 'sunday',
          liturgicalTime: 'LentTime',
          celebrationType: celebrationTitle,
          priority: 1);
      return complineOfGivenDay = {celebrationTitle: complineDefinition};
    case 'ashes':
      ComplineDefinition complineDefinition = ComplineDefinition(
          dayOfWeek: 'wednesday',
          liturgicalTime: 'OrdinaryTime',
          celebrationType: 'normal',
          priority: 13);
      return complineOfGivenDay = {celebrationTitle: complineDefinition};
  }
  if (celebrationTitle.toLowerCase().contains('sunday')) {
    // If displayed as a Sunday, check if there's also a solemnity
    bool hasSolemnity = false;
    for (var entry in todayContent.priority.entries) {
      if (entry.key <= 4) {
        // Add the Solemnity Compline option
        ComplineDefinition solemnityComplineDefinition = ComplineDefinition(
            dayOfWeek: todayName,
            liturgicalTime: liturgicalTime,
            celebrationType: 'Solemnity',
            priority: entry.key);
        complineOfGivenDay[entry.value[0]] = solemnityComplineDefinition;
        hasSolemnity = true;
        break;
      }
    }
    // Always add the Sunday Compline option
    ComplineDefinition sundayComplineDefinition = ComplineDefinition(
        dayOfWeek: todayName,
        liturgicalTime: liturgicalTime,
        celebrationType: hasSolemnity ? 'Sunday' : 'normal',
        priority: 5);
    complineOfGivenDay[celebrationTitle] = sundayComplineDefinition;
    return complineOfGivenDay;
  }
  // Add other cases: Complines of the day and solemnity in the week
  if (liturgicalGrade <= 4) {
    // Firstly: major solemnities (in the root of the day Calendar)
    ComplineDefinition complineDefinition = ComplineDefinition(
        dayOfWeek: 'sunday',
        liturgicalTime: liturgicalTime,
        celebrationType: 'Solemnity',
        priority: liturgicalGrade);
    return complineOfGivenDay = {celebrationTitle: complineDefinition};
  }
  // Then the added solemnities (in a sub directory of the Calendar)
  for (var entry in todayContent.priority.entries) {
    if (entry.key <= 4) {
      ComplineDefinition complineDefinition = ComplineDefinition(
          dayOfWeek: 'sunday',
          liturgicalTime: liturgicalTime,
          celebrationType: 'Solemnity',
          priority: entry.key);
      return complineOfGivenDay = {entry.value[0]: complineDefinition};
    }
  }
  // Concluding with the simple Compline of the day
  ComplineDefinition complineDefinition = ComplineDefinition(
      dayOfWeek: todayName,
      liturgicalTime: liturgicalTime,
      celebrationType: 'normal',
      priority: liturgicalGrade);
  return complineOfGivenDay = {todayName: complineDefinition};
}
