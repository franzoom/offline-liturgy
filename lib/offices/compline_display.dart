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
  Map<String, Hymns> selectedHymns =
      filterHymnsByCodes(compline.hymns!, hymnsLibraryContent);
  displayHymns(selectedHymns);

  print('------ PSALMODY ------');
  if (compline.psalmody != null) {
    for (var psalmItem in compline.psalmody!) {
      String psalmCode = psalmItem['psalm'];
      List<String> antiphons = List<String>.from(psalmItem['antiphon']);

      print('Psalm Antiphon 1: ${antiphons[0]}');
      if (antiphons.length > 1 && antiphons[1].isNotEmpty) {
        print('Psalm Antiphon 2: ${antiphons[1]}');
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
    print('Reading Reference: ${compline.reading!['ref']}');
    print('Reading: ${compline.reading!['content']}');
  }

  print('Responsory: ${compline.responsory}');
  print('Evangelic Antiphon: ${compline.evangelicAntiphon}');
  print('Oration: ${compline.oration}');
  print('------ MARIAN HYMNS ------');
  selectedHymns =
      filterHymnsByCodes(compline.marialHymnRef!, hymnsLibraryContent);
  displayHymns(selectedHymns);
}
