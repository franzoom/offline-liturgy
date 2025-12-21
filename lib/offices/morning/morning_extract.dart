import 'dart:convert';
import '../../classes/morning_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/data_loader.dart';

/// Extracts Morning data from a JSON file
/// Reads the file via DataLoader, parses only the 'morning' section
Future<Morning> morningExtract(
    String relativePath, DataLoader dataLoader) async {
  print('=== morningExtract DEBUG == Loading file: $relativePath');

  String fileContent = await dataLoader.loadJson(relativePath);

  // If file doesn't exist or is empty, return empty Morning
  if (fileContent.isEmpty) {
    print('ERROR: File is empty or does not exist');
    return Morning();
  }
  var jsonData = jsonDecode(fileContent);

  // Extract oration from root level if present
  List<String> oration = List<String>.from(jsonData['oration'] ?? []);

  // Create Morning from JSON (from 'morning' section if exists, otherwise empty)
  Morning morning;
  if (jsonData['morning'] != null) {
    morning = Morning.fromJson(jsonData['morning'] as Map<String, dynamic>);
  } else {
    // No 'morning' section, create empty Morning
    morning = Morning();
  }

  // Extract invitatory if present
  if (jsonData['invitatory'] != null) {
    Invitatory invitatory =
        Invitatory.fromJson(jsonData['invitatory'] as Map<String, dynamic>);

    // If invitatory doesn't have psalms, use default list
    List<String> invitatoryPsalms =
        invitatory.psalms ?? ["PSALM_94", "PSALM_66", "PSALM_99", "PSALM_23"];

    // Remove invitatory psalms that are already in morning psalmody
    if (morning.psalmody != null) {
      final psalmsInPsalmody =
          morning.psalmody!.map((entry) => entry.psalm).toSet();
      invitatoryPsalms = invitatoryPsalms
          .where((psalm) => !psalmsInPsalmody.contains(psalm))
          .toList();
    }

    // Assign invitatory with filtered psalms
    morning.invitatory =
        Invitatory(antiphon: invitatory.antiphon, psalms: invitatoryPsalms);
  }

  // If oration is not in morning section, check in main section of the json
  morning.oration ??= oration;

  print('=== morningExtract SUCCESS ===');
  return morning;

  // If no "morning" section exists, return empty Morning
}
