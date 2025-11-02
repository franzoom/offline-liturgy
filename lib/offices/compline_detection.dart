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

  switch (celebrationTitle) {
    case 'holy_thursday':
    case 'holy_friday':
    case 'holy_saturday':
      ComplineDefinition complineDefinition = ComplineDefinition(
          dayOfWeek: 'sunday',
          liturgicalTime: 'lenttime',
          celebrationType: celebrationTitle,
          priority: 1);
      return {celebrationTitle: complineDefinition};
    case 'ashes':
      ComplineDefinition complineDefinition = ComplineDefinition(
          dayOfWeek: 'wednesday',
          liturgicalTime: 'ordinarytime',
          celebrationType: 'normal',
          priority: 13);
      return {celebrationTitle: complineDefinition};
  }

  // Major solemnities (in the root of the day Calendar)
  if (liturgicalGrade <= 4) {
    ComplineDefinition complineDefinition = ComplineDefinition(
        dayOfWeek: 'sunday',
        liturgicalTime: liturgicalTime,
        celebrationType: 'solemnity',
        priority: liturgicalGrade);
    return {celebrationTitle: complineDefinition};
  }

  // Then look for the solemnities found in a sub directory of the Calendar
  for (var entry in todayContent.priority.entries) {
    if (entry.key <= 4) {
      ComplineDefinition complineDefinition = ComplineDefinition(
          dayOfWeek: 'sunday',
          liturgicalTime: liturgicalTime,
          celebrationType: 'solemnity',
          priority: entry.key);
      complineOfGivenDay[entry.value[0]] = complineDefinition;
    }
  }
  // Add the Sunday Compline option
  if (todayName == 'sunday') {
    ComplineDefinition sundayComplineDefinition = ComplineDefinition(
        dayOfWeek: todayName,
        liturgicalTime: liturgicalTime,
        celebrationType: 'sunday',
        priority: 5);
    complineOfGivenDay[celebrationTitle] = sundayComplineDefinition;
  }
  // chek if there are solemnities or if it's sunday (non empty)
  if (complineOfGivenDay.isNotEmpty) {
    return complineOfGivenDay;
  }

  //otherwise:

  if (celebrationTitle == 'commemoration_of_all_the_faithful_departed') {
    ComplineDefinition complineDefinition = ComplineDefinition(
        dayOfWeek: todayName,
        liturgicalTime: 'ordinarytime',
        celebrationType: 'normal',
        priority: 13);
    return {celebrationTitle: complineDefinition};
  }

// concluding with the simple Complines of the day
  ComplineDefinition complineDefinition = ComplineDefinition(
      dayOfWeek: todayName,
      liturgicalTime: liturgicalTime,
      celebrationType: 'normal',
      priority: liturgicalGrade);
  return {todayName: complineDefinition};
}
