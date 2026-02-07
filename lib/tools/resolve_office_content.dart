import '../classes/office_elements_class.dart';
import '../assets/libraries/psalms_library.dart';
import '../assets/libraries/hymns_library.dart';
import 'data_loader.dart';

/// Resolves psalm and hymn codes into full content instances.
/// Works for any office type — just pass the relevant fields.
/// Psalmody, Invitatory and Hymns are all hydrated in-place.
Future<void> resolveOfficeContent({
  List<PsalmEntry>? psalmody,
  Invitatory? invitatory,
  List<HymnEntry>? hymns,
  required DataLoader dataLoader,
}) async {
  // Hydrate psalmody in-place
  if (psalmody != null) {
    for (var entry in psalmody) {
      if (entry.psalm != null && entry.psalmData == null) {
        entry.psalmData =
            await PsalmsLibrary.getPsalm(entry.psalm!, dataLoader);
      }
    }
  }

  // Hydrate invitatory psalms in-place
  if (invitatory?.psalms != null) {
    invitatory!.psalmsData = [];
    for (var code in invitatory.psalms!) {
      final psalm = await PsalmsLibrary.getPsalm(code, dataLoader);
      if (psalm != null) invitatory.psalmsData!.add(psalm);
    }
  }

  // Hydrate hymns in-place
  if (hymns != null) {
    for (var entry in hymns) {
      entry.hymnData ??=
          await HymnsLibrary.getHymn(entry.code, dataLoader);
    }
  }
}
