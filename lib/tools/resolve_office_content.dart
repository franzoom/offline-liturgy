import '../classes/office_elements_class.dart';
import '../classes/psalms_class.dart';
import '../assets/libraries/psalms_library.dart';
import '../assets/libraries/hymns_library.dart';
import 'data_loader.dart';

/// Returns the SVG lookup key for a psalm code, stripping the part suffix
/// from multi-part psalms (e.g. PSALM_134_1 → PSALM_134) while leaving
/// OT_N and NT_N keys unchanged.
String _svgKey(String psalmCode) =>
    psalmCode.replaceFirstMapped(RegExp(r'^(PSALM_\d+)_\d+$'), (m) => m.group(1)!);

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
                  .load('svg/$svgSource/${_svgKey(e.psalm!)}.svg')
                  .then((content) {
                if (content.isNotEmpty) e.svgData = [content];
              }),
            ),
      );
    }
  }

  // 2. Invitatory
  final invPsalms = invitatory?.psalms;
  if (invPsalms != null) {
    final inv = invitatory!;
    if (inv.psalmsData == null) {
      psalmTasks.add(
        Future.wait(invPsalms.map((code) => PsalmsLibrary.getPsalm(code, dataLoader)))
            .then((results) => inv.psalmsData = results.whereType<Psalm>().toList()),
      );
    }
    if (svgSource != null && inv.psalmsSvgData == null) {
      psalmTasks.add(
        Future.wait(invPsalms.map((code) => dataLoader.load('svg/$svgSource/${_svgKey(code)}.svg')))
            .then((results) {
          inv.psalmsSvgData = results
              .map((content) => content.isNotEmpty ? <String>[content] : null)
              .toList();
        }),
      );
    }
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
