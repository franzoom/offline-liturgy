import '../classes/compline_class.dart';
import '../assets/libraries/psalms_library.dart';
import '../assets/libraries/hymns_library.dart';
import '../tools/hymns_management.dart';
import '../classes/hymns_class.dart';

/// Complines text display (temporary)
void complineDisplay(Compline compline) {
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
        filterHymnsByCodes(compline.hymns!, hymnsLibraryContent);
    displayHymns(selectedHymns);
  }

  print('------ PSALMODY ------');
  if (compline.psalmody != null) {
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

      print('Psalm title: ${psalms[psalmCode]!.getTitle}');
      print('Psalm subtitle: ${psalms[psalmCode]!.getSubtitle}');
      print('Psalm commentary: ${psalms[psalmCode]!.getCommentary}');
      print(
          'Psalm biblical reference: ${psalms[psalmCode]!.getBiblicalReference}');
      print('Psalm content: ${psalms[psalmCode]!.getContent}');
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
        filterHymnsByCodes(compline.marialHymnRef!, hymnsLibraryContent);
    displayHymns(selectedHymns);
  }
}
