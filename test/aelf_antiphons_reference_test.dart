// Compare, for every Sunday/Solemnity/Feast of a given year (France
// calendar), the psalm/canticle antiphons computed by this package against
// AELF's own published texts (fixture in test/fixtures/, rebuilt by
// test/tools/fetch_aelf_antiphons_reference.dart — no network access here).
//
// Text is compared on its words only, after stripping HTML, punctuation and
// case: AELF and our own YAML sources format the same antiphon slightly
// differently (curly vs straight apostrophes, <p>/<br/> markup, a missing
// comma, '!' vs '.') without that being a real content discrepancy.

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';

const int _year = 2026;
const String _location = 'france';
const String _aelfZone = 'france';

/// Divergences where AELF is wrong: our text was checked against the printed
/// breviary by the maintainer. Keyed '$date|$office|$field', as in
/// [_Mismatch.key]. They're still listed in the summary, but don't fail the
/// test; an entry that no longer diverges is reported so it can be removed.
const Set<String> _knownAelfErrors = {
  // "maison de prière" chez AELF, "maison de la prière" au bréviaire.
  '2026-10-25|Laudes|antienne_1',
  // AELF garde l'antienne du psautier pour le Ps 75 ; le bréviaire met
  // l'antienne de l'Heure sur les trois psaumes.
  '2026-12-06|None|antienne_2',
  '2026-12-06|None|antienne_3',
  // Faute de frappe AELF : "Isarël".
  '2026-12-20|Sexte|antienne_1',
  '2026-12-20|Sexte|antienne_2',
  '2026-12-20|Sexte|antienne_3',
  // "nous recevrons" chez AELF, "nous recevons" au bréviaire.
  '2026-12-25|Laudes|antienne_zacharie (Benedictus)',
};

class _Mismatch {
  final String date;
  final String office;
  final String celebration;
  final String field;
  final String ours;
  final String aelf;
  _Mismatch(this.date, this.office, this.celebration, this.field, this.ours,
      this.aelf);

  String get key => '$date|$office|$field';

  @override
  String toString() => '$date [$office] $celebration — $field\n'
      '    nous  : "$ours"\n'
      '    AELF  : "$aelf"';
}

void main() {
  late LiturgyData data;
  late Calendar calendar;
  late DataLoader dataLoader;
  late Map<String, dynamic> fixture;
  final mismatches = <_Mismatch>[];
  int comparedCount = 0;

  setUpAll(() async {
    dataLoader = FileSystemDataLoader();
    data = await LiturgyData.load();
    calendar = getCalendar(Calendar(), DateTime(_year, 1, 1), _location, data);
    final file = File(
        'test/fixtures/aelf_antiphons_reference_${_year}_$_aelfZone.json');
    fixture = jsonDecode(await file.readAsString());
  });

  test('Antiennes des psaumes/cantiques — $_location $_year vs AELF',
      () async {
    final dates = fixture.keys.toList()..sort();
    for (final iso in dates) {
      final date = DateTime.parse(iso);
      final aelf = fixture[iso] as Map<String, dynamic>;
      final category = aelf['category'] as String;

      // --- Laudes ---
      final morningCandidates = await morningDetection(calendar, date, dataLoader);
      final morningWinner = _pickWinner(morningCandidates);
      if (morningWinner != null) {
        final morning = await morningExport(morningWinner);
        final label = _label(morningWinner);
        _comparePsalmody(morning.psalmody, aelf['laudes'], iso, 'Laudes',
            label, mismatches, () => comparedCount++,
            sharedAntiphonAcrossHour: false);
        _compareEvangelicAntiphon(morning.evangelicAntiphon,
            aelf['laudes']?['antienne_zacharie'], iso, 'Laudes', label,
            'antienne_zacharie (Benedictus)', mismatches, () => comparedCount++);
      }

      // --- Vêpres (celle qui est réellement priée ce soir-là) ---
      final vespersCandidates = await vespersDetection(calendar, date, dataLoader);
      final vespersWinner = _pickWinner(vespersCandidates);
      if (vespersWinner != null) {
        final vespers = await vespersExport(vespersWinner);
        final label = _label(vespersWinner);
        _comparePsalmody(vespers.psalmody, aelf['vepres'], iso, 'Vêpres',
            label, mismatches, () => comparedCount++,
            sharedAntiphonAcrossHour: false);
        _compareEvangelicAntiphon(vespers.evangelicAntiphon,
            aelf['vepres']?['antienne_magnificat'], iso, 'Vêpres', label,
            'antienne_magnificat', mismatches, () => comparedCount++);
      }

      // --- Tierce / Sexte / None ---
      final middleCandidates =
          await middleOfDayDetection(calendar, date, dataLoader);
      final middleWinner = _pickWinner(middleCandidates);
      if (middleWinner != null) {
        final middle = await middleOfDayExport(middleWinner);
        final label = _label(middleWinner);
        _comparePsalmody(middle.psalmodyTierce, aelf['tierce'], iso, 'Tierce',
            label, mismatches, () => comparedCount++,
            sharedAntiphonAcrossHour: true);
        _comparePsalmody(middle.psalmodySexte, aelf['sexte'], iso, 'Sexte',
            label, mismatches, () => comparedCount++,
            sharedAntiphonAcrossHour: true);
        _comparePsalmody(middle.psalmodyNone, aelf['none'], iso, 'None',
            label, mismatches, () => comparedCount++,
            sharedAntiphonAcrossHour: true);
      }

      print('$iso [$category] vérifié.');
    }

    print('\n\n===================== RÉSUMÉ =====================');
    print('$comparedCount antienne(s) comparée(s) pour $_location $_year '
        'vs AELF ($_aelfZone).');
    final known =
        mismatches.where((m) => _knownAelfErrors.contains(m.key)).toList();
    final unexpected =
        mismatches.where((m) => !_knownAelfErrors.contains(m.key)).toList();
    final foundKeys = mismatches.map((m) => m.key).toSet();
    final staleKnown =
        _knownAelfErrors.where((k) => !foundKeys.contains(k)).toList();

    if (known.isNotEmpty) {
      print('\n${known.length} erreur(s) AELF connue(s), ignorée(s) '
          '(voir _knownAelfErrors).');
    }
    for (final k in staleKnown) {
      print('\nÀ retirer de _knownAelfErrors (plus de divergence) : $k');
    }
    if (unexpected.isEmpty) {
      print('Aucune divergence inattendue détectée.');
    } else {
      for (final m in unexpected) {
        print('\n$m');
      }
      print('\nTOTAL : ${unexpected.length} divergence(s).');
    }

    expect(unexpected, isEmpty,
        reason:
            '${unexpected.length} divergence(s) — voir le résumé ci-dessus');
  }, timeout: const Timeout(Duration(minutes: 5)));
}

/// The single celebrable candidate for the day (there should be exactly one
/// among the offices we query, since we only look at Sundays/Solemnities/
/// Feasts, which always have an unambiguous winner).
CelebrationContext? _pickWinner(Map<String, CelebrationContext> candidates) {
  for (final c in candidates.values) {
    if (c.isCelebrable) return c;
  }
  return null;
}

String _label(CelebrationContext c) => c.celebrationTitle ?? c.celebrationCode;

/// Psalm/canticle codes known to have no antiphon of their own by design
/// (same list as test/office_content_coverage_test.dart) — comparing them
/// against AELF's silence would be a false positive, not a real gap.
final Set<String> _ignoredMissingAntiphonCodes = {
  'PSALM_135_1',
  'PSALM_135_2',
  'PSALM_135_3',
  'PSALM_45',
  'PSALM_8',
  'OT_40',
  'OT_41',
};

bool _isIgnoredMissingAntiphonCode(String? psalm) {
  if (psalm == null) return false;
  return psalm.startsWith('NT_') || _ignoredMissingAntiphonCodes.contains(psalm);
}

void _comparePsalmody(
  List<PsalmEntry>? ours,
  Map<String, dynamic>? aelfOffice,
  String date,
  String office,
  String celebration,
  List<_Mismatch> mismatches,
  void Function() tick, {
  required bool sharedAntiphonAcrossHour,
}) {
  if (aelfOffice == null) return;
  // Tierce/Sexte/None: AELF leaves antienne_2/antienne_3 blank whenever it's
  // the same antiphon as the antienne that precedes it — not necessarily
  // antienne_1: e.g. a psalm split into two halves (PSALM_75_1/PSALM_75_2)
  // legitimately shares its antiphon with the previous entry only, while
  // antienne_1 itself is for an unrelated psalm. Carry forward the last
  // non-blank antienne seen so far, cascading, rather than always falling
  // back to antienne_1. Laudes/Vêpres don't follow that convention: each of
  // the 3 psalms/canticles has its own antiphon, or legitimately none at all
  // (see _ignoredMissingAntiphonCodes).
  String lastNonEmptyAelf = '';
  for (int i = 0; i < 3; i++) {
    final aelfKey = 'antienne_${i + 1}';
    final aelfRaw = aelfOffice[aelfKey] as String?;
    var aelfText = _normalize(aelfRaw);
    final oursPsalmCode = (ours != null && i < ours.length) ? ours[i].psalm : null;
    if (sharedAntiphonAcrossHour && aelfText.isEmpty && lastNonEmptyAelf.isNotEmpty) {
      aelfText = lastNonEmptyAelf;
    } else if (aelfText.isNotEmpty) {
      lastNonEmptyAelf = aelfText;
    }
    if (!sharedAntiphonAcrossHour &&
        aelfText.isEmpty &&
        _isIgnoredMissingAntiphonCode(oursPsalmCode)) {
      continue; // ce psaume/cantique n'a légitimement pas d'antienne
    }
    final oursRaw = (ours != null && i < ours.length) ? ours[i].antiphon : null;
    final oursText = _normalize(oursRaw?.join(' '));
    if (aelfText.isEmpty && oursText.isEmpty) {
      continue; // ni l'un ni l'autre n'en a — rien à comparer ici
    }
    tick();
    if (!_sameWords(oursText, aelfText) &&
        !_isLegitimateSecondAntiphon(oursText, aelfText)) {
      mismatches.add(_Mismatch(date, office, celebration, aelfKey, oursText,
          aelfText));
    }
  }
}

void _compareEvangelicAntiphon(
  Map<String, List<String>>? ours,
  dynamic aelfRaw,
  String date,
  String office,
  String celebration,
  String fieldLabel,
  List<_Mismatch> mismatches,
  void Function() tick,
) {
  final aelfText = _normalize(aelfRaw is String ? aelfRaw : null);
  final nonEmptyLines =
      ours?.values.where((l) => l.isNotEmpty).toList() ?? [];
  final oursJoined = nonEmptyLines.isEmpty ? null : nonEmptyLines.first.join(' ');
  final oursText = _normalize(oursJoined);
  if (aelfText.isEmpty && oursText.isEmpty) return;
  tick();
  if (!_sameWords(oursText, aelfText)) {
    mismatches.add(
        _Mismatch(date, office, celebration, fieldLabel, oursText, aelfText));
  }
}

/// Strips HTML markup and normalizes quotes/whitespace so that stylistic
/// differences between AELF's HTML and our plain-text YAML don't register
/// as false positives.
String _normalize(String? text) {
  if (text == null) return '';
  var t = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
  t = t.replaceAll('’', "'").replaceAll('‘', "'");
  t = t.replaceAll(' ', ' ');
  t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
  return t;
}

/// Reduces a normalized text to its words only — lowercase, no punctuation,
/// no soft hyphens — so that punctuation and case differences between AELF
/// and our YAML (a missing comma, '!' vs '.', a capital after a colon) are
/// not reported as mismatches. Only a difference in the words themselves is.
///
/// The word "alléluia" is left out too, whatever its spelling: AELF shows
/// an optional "(alléluia)" outside Lent where we follow the season, and
/// its own text has typos of it ("allléluia", "allélluia").
String _wordsKey(String text) => text
    .replaceAll('­', '')
    .replaceAll(RegExp(r'\b[RV]/'), ' ') // responsory markers (R/, V/)
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .split(' ')
    .where((w) => w.isNotEmpty && !_alleluiaWord.hasMatch(w))
    .join(' ');

final RegExp _alleluiaWord = RegExp(r'^al+él+u+ia$');

/// An AELF text with no words left (only "alléluia", a refrain marker or
/// stray punctuation) has nothing to check ours against.
bool _sameWords(String ours, String aelf) {
  final aelfWords = _wordsKey(aelf);
  return aelfWords.isEmpty || _wordsKey(ours) == aelfWords;
}

/// AELF's own site only ever shows one antiphon per psalm, even where the
/// printed breviary gives two (confirmed by the maintainer) — so when our
/// antiphon is AELF's text plus something more after it, that extra part is
/// a legitimate second antiphon AELF simply doesn't display, not a content
/// bug. Compared on words only (see [_wordsKey]), since the continuation
/// point in [ours] doesn't necessarily carry the same punctuation mark.
bool _isLegitimateSecondAntiphon(String ours, String aelf) {
  final aelfWords = _wordsKey(aelf);
  if (aelfWords.isEmpty) return false;
  final oursWords = _wordsKey(ours);
  return oursWords.startsWith('$aelfWords ') &&
      oursWords.length > aelfWords.length;
}
