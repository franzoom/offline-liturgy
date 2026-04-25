import '../classes/office_elements_class.dart';
import '../classes/psalms_class.dart';
import '../assets/libraries/psalms_library.dart';
import '../assets/libraries/hymns_library.dart';
import 'data_loader.dart';

/// Resolves psalm and hymn codes into full content instances.
/// Works for any office type — just pass the relevant fields.
/// Psalmody, Invitatory, and Hymns are all hydrated in-place.
Future<void> resolveOfficeContent({
  List<PsalmEntry>? psalmody,
  Invitatory? invitatory,
  List<HymnEntry>? hymns,
  required DataLoader dataLoader,
}) async {
  final List<Future<void>> tasks = [];

  // 1. Psalmody
  if (psalmody != null) {
    tasks.addAll(
      psalmody.where((e) => e.psalm != null && e.psalmData == null).map(
            (e) => PsalmsLibrary.getPsalm(e.psalm!, dataLoader)
                .then((result) => e.psalmData = result),
          ),
    );
  }

  // 2. Invitatory
  final invPsalms = invitatory?.psalms;
  if (invPsalms != null && invitatory!.psalmsData == null) {
    tasks.add(
      Future.wait(invPsalms.map((code) => PsalmsLibrary.getPsalm(code, dataLoader)))
          .then((results) =>
              invitatory.psalmsData = results.whereType<Psalm>().toList()),
    );
  }

  // 3. Hymns
  if (hymns != null) {
    tasks.addAll(
      hymns.where((e) => e.hymnData == null).map(
            (e) => HymnsLibrary.getHymn(e.code, dataLoader)
                .then((result) => e.hymnData = result),
          ),
    );
  }

  await Future.wait(tasks);
}
