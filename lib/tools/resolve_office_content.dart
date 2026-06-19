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
  bool showImprecatoryVerses = true,
  String? svgSource,
}) async {
  // 1. Psalmody
  final List<Future<void>> psalmTasks = [];
  if (psalmody != null) {
    psalmTasks.addAll(
      psalmody.where((e) => e.psalm != null && e.psalmData == null).map(
            (e) => PsalmsLibrary.getPsalm(e.psalm!, dataLoader)
                .then((result) => e.psalmData = result),
          ),
    );
    if (svgSource != null) {
      psalmTasks.addAll(
        psalmody.where((e) => e.psalm != null && e.svgData == null).map(
              (e) => dataLoader
                  .load('svg/$svgSource/${e.psalm!}.svg')
                  .then((content) {
                if (content.isNotEmpty) e.svgData = [content];
              }),
            ),
      );
    }
  }

  // 2. Invitatory
  final invPsalms = invitatory?.psalms;
  if (invPsalms != null && invitatory!.psalmsData == null) {
    psalmTasks.add(
      Future.wait(
              invPsalms.map((code) => PsalmsLibrary.getPsalm(code, dataLoader)))
          .then((results) =>
              invitatory.psalmsData = results.whereType<Psalm>().toList()),
    );
  }

  await Future.wait(psalmTasks);

  // Once psalms and invitatory are loaded, strip verses marked as imprecatory
  // so they are never exposed to the caller.
  if (!showImprecatoryVerses) {
    psalmody?.forEach((psalmEntry) {
      psalmEntry.psalmData = psalmEntry.psalmData?.withoutImprecatoryVerses();
    });
    if (invitatory?.psalmsData != null) {
      invitatory!.psalmsData = invitatory.psalmsData!
          .map((p) => p.withoutImprecatoryVerses())
          .toList();
    }
  }

  // 3. Hymns
  if (hymns != null) {
    await Future.wait(
      hymns.where((hymnEntry) => hymnEntry.hymnData == null).map(
            (hymnEntry) => HymnsLibrary.getHymn(hymnEntry.code, dataLoader)
                .then((result) => hymnEntry.hymnData = result),
          ),
    );
  }
}
