import '../classes/compline_class.dart';
import '../assets/libraries/psalms_library.dart';
import '../tools/hymns_management.dart';
import '../tools/data_loader.dart';
import '../classes/hymns_class.dart';

/// Complines text display (temporary)
/// Now supports async loading of psalms and hymns from JSON
Future<void> complineDisplay(Compline compline, DataLoader dataLoader) async {
  if (compline.commentary != null) {
    print('Commentary: ${compline.commentary ?? "No commentary"}');
  }
  if (compline.celebrationType != null &&
      compline.celebrationType != 'normal') {
    print('Celebration Type: ${compline.celebrationType}');
  }

  print('------ HYMNS ------');
  if (compline.hymns != null) {
    Map<String, Hymns> selectedHymns =
        await filterHymnsByCodes(compline.hymns!, dataLoader);
    displayHymns(selectedHymns);
  }

  print('------ PSALMODY ------');
  if (compline.psalmody != null) {
    // Load all required psalms at once
    final psalmCodes = compline.psalmody!.map((e) => e.psalm).toList();
    final psalmsMap = await PsalmsLibrary.getPsalms(psalmCodes, dataLoader);

    for (var psalmEntry in compline.psalmody!) {
      // psalmEntry is now a PsalmEntry object
      String psalmCode = psalmEntry.psalm;
      List<String>? antiphons = psalmEntry.antiphon;

      if (antiphons != null && antiphons.isNotEmpty) {
        print('Psalm Antiphon 1: ${antiphons[0]}');
        if (antiphons.length > 1 && antiphons[1].isNotEmpty) {
          print('Psalm Antiphon 2: ${antiphons[1]}');
        }
      }

      final psalm = psalmsMap[psalmCode];
      if (psalm != null) {
        print('Psalm title: ${psalm.getTitle}');
        print('Psalm subtitle: ${psalm.getSubtitle}');
        print('Psalm commentary: ${psalm.getCommentary}');
        print('Psalm biblical reference: ${psalm.getBiblicalReference}');
        print('Psalm content: ${psalm.getContent}');
      } else {
        print('Psalm $psalmCode not found in library');
      }
      print(''); // Empty line between psalms
    }
  }

  print('------ READING ------');
  if (compline.reading != null) {
    // reading is now a Reading object
    print('Reading Reference: ${compline.reading!.biblicalReference ?? ""}');
    print('Reading: ${compline.reading!.content ?? ""}');
  }

  print('Responsory: ${compline.responsory ?? ""}');

  print('------ EVANGELIC ANTIPHON ------');
  if (compline.evangelicAntiphon != null) {
    // evangelicAntiphon is now an EvangelicAntiphon object
    // Display common antiphon or year-specific variants
    if (compline.evangelicAntiphon!.common != null) {
      print('Evangelic Antiphon: ${compline.evangelicAntiphon!.common}');
    }
    if (compline.evangelicAntiphon!.yearA != null) {
      print(
          'Evangelic Antiphon (Year A): ${compline.evangelicAntiphon!.yearA}');
    }
    if (compline.evangelicAntiphon!.yearB != null) {
      print(
          'Evangelic Antiphon (Year B): ${compline.evangelicAntiphon!.yearB}');
    }
    if (compline.evangelicAntiphon!.yearC != null) {
      print(
          'Evangelic Antiphon (Year C): ${compline.evangelicAntiphon!.yearC}');
    }
  }

  print('Oration: ${compline.oration ?? ""}');

  print('------ MARIAN HYMNS ------');
  if (compline.marialHymnRef != null) {
    Map<String, Hymns> selectedHymns =
        await filterHymnsByCodes(compline.marialHymnRef!, dataLoader);
    displayHymns(selectedHymns);
  }
}
