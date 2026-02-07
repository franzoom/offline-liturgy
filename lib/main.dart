import 'dart:io';
import 'offline_liturgy.dart';
import 'tools/data_loader.dart';
import 'classes/office_elements_class.dart';

Future<void> main() async {
  Calendar calendar = Calendar(); // Calendar creation
  DateTime date = DateTime(2025, 12, 8);
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

  // Taking the first celebration in the list
  final MapEntry<String, CelebrationContext>? firstEntry =
      possibleMornings.isNotEmpty ? possibleMornings.entries.first : null;

  if (firstEntry == null) {
    print('No morning office found for this date');
    return;
  }

  // Use the CelebrationContext directly
  final celebrationContext = firstEntry.value;

  final Morning firstMorningOffice =
      await morningResolution(celebrationContext);
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
