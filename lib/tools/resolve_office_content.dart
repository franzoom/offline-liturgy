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
  // We use a list of futures to perform all data fetching in parallel,
  // which is significantly faster than waiting for each item sequentially.
  final List<Future<void>> tasks = [];

  // 1. Hydrate Psalmody
  if (psalmody != null) {
    tasks.addAll(
      psalmody
          .where((entry) => entry.psalm != null && entry.psalmData == null)
          .map((entry) async {
        entry.psalmData =
            await PsalmsLibrary.getPsalm(entry.psalm!, dataLoader);
      }),
    );
  }

  // 2. Hydrate Invitatory psalms
  if (invitatory?.psalms != null) {
    tasks.add(() async {
      // Fetch all invitatory psalms simultaneously
      final results = await Future.wait(
        invitatory!.psalms!
            .map((code) => PsalmsLibrary.getPsalm(code, dataLoader)),
      );
      // Filter out potential nulls and assign the list to the model
      invitatory.psalmsData = results.whereType<Psalm>().toList();
    }());
  }

  // 3. Hydrate Hymns
  if (hymns != null) {
    tasks.addAll(
      hymns.where((entry) => entry.hymnData == null).map((entry) async {
        entry.hymnData = await HymnsLibrary.getHymn(entry.code, dataLoader);
      }),
    );
  }

  // Execute all hydration tasks concurrently
  await Future.wait(tasks);
}
