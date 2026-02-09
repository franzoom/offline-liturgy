import 'dart:io';
import 'offline_liturgy.dart';

Future<void> main() async {
  Calendar calendar = Calendar(); // Calendar creation
  DateTime date = DateTime(2026, 2, 11);
  String location = 'lyon';
  calendar = getCalendar(calendar, date, location); // Calendar initialisation

  String calendarDisplay = calendar.formattedDisplay;
  File('calendar_output.txt').writeAsStringSync(calendarDisplay);
  print('Calendrier ecrit dans calendar_output.txt');

  // Create a DataLoader for pure Dart usage
  final dataLoader = FileSystemDataLoader();

  // Launch Morning prayer generation for the requested day:
  final Map<String, CelebrationContext> possibleMornings =
      await morningDetection(calendar, date, dataLoader);

  // Debug: detail possibleMornings content
  print('===== possibleMornings (${possibleMornings.length} entries) =====');
  possibleMornings.forEach((key, ctx) {
    print('--- [$key] ---');
    print('  celebrationType:        ${ctx.celebrationType}');
    print('  celebrationCode:        ${ctx.celebrationCode}');
    print('  celebrationTitle:       ${ctx.celebrationTitle}');
    print('  celebrationGlobalName:  ${ctx.celebrationGlobalName}');
    print('  ferialCode:             ${ctx.ferialCode}');
    print('  commonList:             ${ctx.commonList}');
    print('  date:                   ${ctx.date}');
    print('  liturgicalTime:         ${ctx.liturgicalTime}');
    print('  breviaryWeek:           ${ctx.breviaryWeek}');
    print('  precedence:             ${ctx.precedence}');
    print('  teDeum:                 ${ctx.teDeum}');
    print('  isCelebrable:           ${ctx.isCelebrable}');
    print('  officeDescription:      ${ctx.officeDescription}');
    print('  liturgicalColor:        ${ctx.liturgicalColor}');
    print('  celebrationDescription: ${ctx.celebrationDescription}');
  });
  print('===== fin possibleMornings =====');

  // Taking the first celebration in the list
  final MapEntry<String, CelebrationContext>? firstEntry =
      possibleMornings.isNotEmpty ? possibleMornings.entries.first : null;

  if (firstEntry == null) {
    print('No morning office found for this date');
    return;
  }

  // Use the CelebrationContext directly
  final celebrationContext = firstEntry.value;

  final Morning firstMorningOffice = await morningExport(celebrationContext);
  print(firstMorningOffice);

////////////////////
/*
  // Launch Compline generation for the requested day:
  Map<String, ComplineDefinition> possibleComplines =
      await complineDefinitionResolution(calendar, date, dataLoader);

  // Display these Complines:
  Map<String, Compline> complineTextCompiled =
      await complineTextCompilation(possibleComplines, dataLoader);

  complineTextCompiled.forEach((key, compline) {
    print('$key');
    print('=========================');
    complineDisplay(compline);
    print('=========================');
  });
  */
}
