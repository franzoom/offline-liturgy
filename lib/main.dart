import 'offline_liturgy.dart';
import 'tools/data_loader.dart';

Future<void> main() async {
  Calendar calendar = Calendar(); // Calendar creation
  DateTime date = DateTime(2025, 12, 8);
  String location = 'lyon';
  calendar = getCalendar(calendar, date, location); // Calendar initialisation

  // Create a DataLoader for pure Dart usage
  final dataLoader = FileSystemDataLoader();

  // Launch Morning prayer generation for the requested day:

  final possibleMornings = await morningDetection(calendar, date, dataLoader);

  final ferialMornings =
      await ferialMorningResolution(calendar, date, dataLoader);
//  String hymnName = ferialMornings[0]!.hymn[0];

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
}
