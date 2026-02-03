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

  final Map<String, MorningDefinition> possibleMornings =
      await morningDetection(calendar, date, dataLoader);

//for tries: taking the first celebration in the list
  final MapEntry<String, MorningDefinition>? firstEntry =
      possibleMornings.isNotEmpty ? possibleMornings.entries.first : null;
//retrieving the celebrationCode...
  final String celebrationCode = firstEntry!.value.celebrationCode;
  final String ferialCode = firstEntry!.value.ferialCode;
  final List<String>? commonList = firstEntry!.value.commonList;
  final String? liturgicalTime = firstEntry!.value.liturgicalTime;
  final String? breviaryWeek = firstEntry!.value.breviaryWeek;
//... and the first common proposed (if exists)...

  final String common =
      (commonList != null && commonList.isNotEmpty) ? commonList.first : '';

// ... in order to run the office Resolution
  final celebrationContext = CelebrationContext(
    celebrationCode: celebrationCode,
    ferialCode: ferialCode,
    common: common,
    date: date,
    liturgicalTime: liturgicalTime,
    breviaryWeek: breviaryWeek,
    dataLoader: dataLoader,
  );
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
      complineTextCompilation(possibleComplines);

  complineTextCompiled.forEach((key, compline) {
    print('$key');
    print('=========================');
    complineDisplay(compline, dataLoader);
    print('=========================');
  });
  */
}
