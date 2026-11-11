// Compare, for every Sunday of 2024–2026 (France calendar), the Mass
// readings computed by this package against AELF's own published Masses
// (fixture test/fixtures/aelf_sunday_masses_reference_france.json, rebuilt by
// test/tools/fetch_aelf_sunday_masses_reference.dart — no network access
// here). AELF's Mass API only gives the readings, so only their biblical
// references are compared, not the prayers.
//
// Each AELF Mass of the day is matched with the Mass of ours sharing the most
// readings. A reading is identified by its book and first chapter (psalms by
// their number): a reading of AELF's missing from ours fails the test, as it
// means a different text. Readings only ours have (alternatives AELF doesn't
// list, e.g. the Dedication's three second readings) and differences in the
// verses only (often a matter of notation) are listed in the summary without
// failing it.

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';

const String _location = 'france';
const String _fixture =
    'test/fixtures/aelf_sunday_masses_reference_france.json';

/// A reading reference, at the two levels compared.
class _Ref {
  final String chapter; // book + first chapter: '2s7', 'ps88', 'lc1'
  final String full; // the whole reference, spaces and dashes normalized
  final String raw;
  _Ref(this.chapter, this.full, this.raw);
}

// The psalm number only: AELF writes Ps 19 (Hebrew) "18B (19)" or "18 (19)"
final _psalmStart = RegExp(r'^(?:ps\.?\s*)?(\d+)', caseSensitive: false);
final _bookChapter =
    RegExp(r'^(\d?\s*[a-zà-ÿ]+)\.?\s*(\d+)', caseSensitive: false);

/// Book names AELF sometimes spells out
const _bookAliases = {
  'jean': 'jn',
  'matthieu': 'mt',
  'marc': 'mc',
  'luc': 'lc'
};

_Ref? _parse(String? raw, {required bool psalm}) {
  if (raw == null) return null;
  var s = raw
      .replaceAll(RegExp(r'[  \s]+'), ' ')
      .replaceAll(RegExp(r'[–—]'), '-')
      .trim();
  if (s.isEmpty) return null;
  s = s.replaceFirst(RegExp(r'^cf\.?\s*', caseSensitive: false), '');
  final full = s.toLowerCase().replaceAll(' ', '').replaceFirst('ps', '');
  if (psalm) {
    final m = _psalmStart.firstMatch(s);
    if (m != null) return _Ref('ps${m.group(1)}', full, raw);
  }
  final m = _bookChapter.firstMatch(s);
  if (m == null) return _Ref(full, full, raw);
  final book = _bookAliases[m.group(1)!.toLowerCase().replaceAll(' ', '')] ??
      m.group(1)!.toLowerCase().replaceAll(' ', '');
  return _Ref('$book${m.group(2)}', full, raw);
}

/// The references of an entry: its own, and its short form's if any
List<String?> _refsOf(MassReadingContent c) => switch (c) {
      MassReading r => [r.biblicalRef, r.shortReadingRef],
      MassPsalm p => [p.biblicalRef],
      MassGospel g => [g.biblicalRef, g.shortBiblicalRef],
    };

List<_Ref> _ourRefs(Mass mass) => [
      for (final part in mass.readingParts ?? <MassReadingPart>[])
        for (final c in part.partContents)
          for (final raw in _refsOf(c))
            if (_parse(raw, psalm: part.partType == 'PSALM') case final ref?)
              ref,
    ];

List<_Ref> _aelfRefs(Map<String, dynamic> mass) => [
      for (final l in (mass['lectures'] as List))
        if (_parse(l['ref'] as String?,
                psalm: l['type'] == 'psaume' || l['type'] == 'cantique')
            case final ref?)
          ref,
    ];

void main() {
  late LiturgyData data;
  final loader = FileSystemDataLoader();
  setUpAll(() async => data = await LiturgyData.load());

  test('Lectures des messes du dimanche — $_location vs AELF', () async {
    final reference =
        jsonDecode(File(_fixture).readAsStringSync()) as Map<String, dynamic>;
    final calendars = <int, Calendar>{};
    final errors = <String>[];
    final verseNotes = <String>[];
    final extraNotes = <String>[];
    int compared = 0;

    for (final entry in reference.entries) {
      final date = DateTime.parse(entry.key);
      final aelf = entry.value as Map<String, dynamic>;
      // A calendar holds two liturgical years: one per civil year is enough
      final calendar = calendars[date.year] ??=
          getCalendar(Calendar(), DateTime(date.year, 1, 1), _location, data);

      final detected = await massDetection(calendar, date, loader);
      if (detected.isEmpty) {
        errors.add('${entry.key} : aucune messe calculée (AELF : '
            '${aelf['aelf']})');
        continue;
      }
      // The day's principal celebration, and all of its Masses
      final principal = detected.values.first.celebrationCode;
      final ours = <String, List<_Ref>>{
        for (final e in detected.entries)
          if (e.value.celebrationCode == principal)
            e.key: _ourRefs(await massExport(e.value)),
      };

      for (final aelfMass in (aelf['messes'] as List)) {
        final aelfRefs = _aelfRefs(aelfMass as Map<String, dynamic>);
        if (aelfRefs.isEmpty) continue;
        compared++;
        final aelfChapters = aelfRefs.map((r) => r.chapter).toSet();
        // Our Mass with the most readings in common
        final best = ours.entries.reduce((a, b) {
          int score(List<_Ref> refs) => refs
              .map((r) => r.chapter)
              .toSet()
              .intersection(aelfChapters)
              .length;
          return score(b.value) > score(a.value) ? b : a;
        });
        final ourChapters = best.value.map((r) => r.chapter).toSet();
        final missing = aelfRefs.where((r) => !ourChapters.contains(r.chapter));
        final extra =
            best.value.where((r) => !aelfChapters.contains(r.chapter));
        final label = '${entry.key} (${aelf['annee']}) ${aelf['aelf']} '
            '[${aelfMass['nom']}] ↔ ${best.key}';
        if (missing.isEmpty && extra.isNotEmpty) {
          extraNotes.add('$label\n'
              '      appli seulement : ${extra.map((r) => r.raw).join(' | ')}');
          continue;
        }
        if (missing.isNotEmpty) {
          errors.add('$label\n'
              '      AELF seulement : ${missing.map((r) => r.raw).join(' | ')}\n'
              '      appli seulement : ${extra.map((r) => r.raw).join(' | ')}');
          continue;
        }
        final ourFull = best.value.map((r) => r.full).toSet();
        final aelfFull = aelfRefs.map((r) => r.full).toSet();
        final aelfOnly = aelfRefs.where((r) => !ourFull.contains(r.full));
        final oursOnly = best.value.where((r) => !aelfFull.contains(r.full));
        if (aelfOnly.isNotEmpty || oursOnly.isNotEmpty) {
          verseNotes.add('$label\n'
              '      AELF : ${aelfOnly.map((r) => r.raw).join(' | ')}\n'
              '      appli : ${oursOnly.map((r) => r.raw).join(' | ')}');
        }
      }
    }

    print('\n===== Messes du dimanche : ${reference.length} dimanches, '
        '$compared messe(s) AELF comparée(s) =====');
    if (verseNotes.isNotEmpty) {
      print('\n${verseNotes.length} différence(s) de versets seulement '
          '(même livre et chapitre, non bloquantes) :');
      for (final n in verseNotes) {
        print('  $n');
      }
    }
    if (extraNotes.isNotEmpty) {
      print('\n${extraNotes.length} messe(s) où l\'appli propose des lectures '
          'au choix qu\'AELF ne liste pas (non bloquant) :');
      for (final n in extraNotes) {
        print('  $n');
      }
    }
    if (errors.isNotEmpty) {
      print('\n${errors.length} messe(s) avec des lectures différentes :');
      for (final e in errors) {
        print('  $e');
      }
    } else {
      print('\nAucune lecture différente.');
    }
    expect(errors, isEmpty, reason: '${errors.length} messe(s) divergente(s)');
  });
}
