import '../classes/compline_class.dart';
import '../assets/libraries/psalms_library.dart';
import '../assets/libraries/hymns_library.dart';
import '../tools/hymns_management.dart';
import '../classes/hymns_class.dart';

/// Complines text display (temporary)
void complineDisplay(Compline compline) {
  if (compline.complineCommentary != null) {
    print('Commentary: ${compline.complineCommentary ?? "No commentary"}');
  }
  if (compline.celebrationType != null &&
      compline.celebrationType != 'normal') {
    print('Celebration Type: ${compline.celebrationType}');
  }
  print('------ HYMNS ------');
  Map<String, Hymns> selectedHymns =
      filterHymnsByCodes(compline.complineHymns!, hymnsLibraryContent);
  displayHymns(selectedHymns);
  print('Psalm 1 Antiphon 1: ${compline.complinePsalm1Antiphon}');
  print('Psalm 1 Antiphon 2: ${compline.complinePsalm1Antiphon2}');
  print('Psalm 1 title: ${psalms[compline.complinePsalm1]!.getTitle}');
  print('Psalm 1 subtitle: ${psalms[compline.complinePsalm1]!.getSubtitle}');
  print(
      'Psalm 1 commentary: ${psalms[compline.complinePsalm1]!.getCommentary}');
  print(
      'Psalm 1 biblical reference: ${psalms[compline.complinePsalm1]!.getBiblicalReference}');
  print('Psalm 1 content: ${psalms[compline.complinePsalm1]!.getContent}');

  if (compline.complinePsalm2 != "") {
    print('Psalm 2 Antiphon 1: ${compline.complinePsalm2Antiphon}');
    print('Psalm 2 Antiphon 2: ${compline.complinePsalm2Antiphon2}');
    print('Psalm 2 title: ${psalms[compline.complinePsalm1]!.getTitle}');
    print('Psalm 2 subtitle: ${psalms[compline.complinePsalm1]!.getSubtitle}');
    print(
        'Psalm 2 commentary: ${psalms[compline.complinePsalm1]!.getCommentary}');
    print(
        'Psalm 2 biblical reference: ${psalms[compline.complinePsalm1]!.getBiblicalReference}');
    print('Psalm 2 content: ${psalms[compline.complinePsalm1]!.getContent}');
  }
  print('Reading Reference: ${compline.complineReadingRef}');
  print('Reading: ${compline.complineReading}');
  print('Responsory: ${compline.complineResponsory}');
  print('Evangelic Antiphon: ${compline.complineEvangelicAntiphon}');
  print('Oration: ${compline.complineOration}');
  print('------ MARIAN HYMNS ------');
  selectedHymns =
      filterHymnsByCodes(compline.marialHymnRef!, hymnsLibraryContent);
  displayHymns(selectedHymns);
}
