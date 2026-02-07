import '../../classes/compline_class.dart';

/// Complines text display (temporary)
/// Uses pre-hydrated psalmData and hymnData from resolveOfficeContent
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
    for (var hymnEntry in compline.hymns!) {
      final hymn = hymnEntry.hymnData;
      if (hymn != null) {
        print('Title: ${hymn.title}');
        if (hymn.author != null) {
          print('Author: ${hymn.author}');
        }
        print('Content: ${hymn.content}');
        print('---');
      } else {
        print('Hymn ${hymnEntry.code} not found in library');
      }
    }
  }

  print('------ PSALMODY ------');
  if (compline.psalmody != null) {
    for (var psalmEntry in compline.psalmody!) {
      if (psalmEntry.psalm == null) continue;

      List<String>? antiphons = psalmEntry.antiphon;

      if (antiphons != null && antiphons.isNotEmpty) {
        print('Psalm Antiphon 1: ${antiphons[0]}');
        if (antiphons.length > 1 && antiphons[1].isNotEmpty) {
          print('Psalm Antiphon 2: ${antiphons[1]}');
        }
      }

      final psalm = psalmEntry.psalmData;
      if (psalm != null) {
        print('Psalm title: ${psalm.title}');
        print('Psalm subtitle: ${psalm.subtitle}');
        print('Psalm commentary: ${psalm.commentary}');
        print('Psalm biblical reference: ${psalm.biblicalReference}');
        print('Psalm content: ${psalm.content}');
      } else {
        print('Psalm ${psalmEntry.psalm} not found in library');
      }
      print(''); // Empty line between psalms
    }
  }

  print('------ READING ------');
  if (compline.reading != null) {
    print('Reading Reference: ${compline.reading!.biblicalReference ?? ""}');
    print('Reading: ${compline.reading!.content ?? ""}');
  }

  print('Responsory: ${compline.responsory ?? ""}');

  print('------ EVANGELIC ANTIPHON ------');
  if (compline.evangelicAntiphon != null) {
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
    for (var hymnEntry in compline.marialHymnRef!) {
      final hymn = hymnEntry.hymnData;
      if (hymn != null) {
        print('Title: ${hymn.title}');
        if (hymn.author != null) {
          print('Author: ${hymn.author}');
        }
        print('Content: ${hymn.content}');
        print('---');
      } else {
        print('Hymn ${hymnEntry.code} not found in library');
      }
    }
  }
}
