import 'offline_liturgy.dart';
import 'tools/data_loader.dart';

Future<void> main() async {
  Calendar calendar = Calendar(); // Calendar creation
  DateTime date = DateTime(2025, 12, 21);
  String location = 'lyon';
  calendar = getCalendar(calendar, date, location); // Calendar initialisation

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
  final String? breviaryWeek = firstEntry!.value.breviaryWeek;
//... and the first common proposed (if exists)...

  final String common =
      (commonList != null && commonList.isNotEmpty) ? commonList.first : '';

// ... in order to run the office Resolution
  final Morning firstMorningOffice = await morningResolution(
      celebrationCode, ferialCode, common, date, breviaryWeek, dataLoader);
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
