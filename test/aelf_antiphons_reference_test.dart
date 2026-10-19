// Compare, for every day of the given years (France calendar), the
// psalms/canticles and their antiphons computed by this package against
// AELF's own published office (fixtures in test/fixtures/, one per year,
// rebuilt by test/tools/fetch_aelf_antiphons_reference.dart — no network
// access here): Office of Readings, Lauds, Tierce, Sext, None, Vespers and
// Compline.
//
// Psalms are compared by number and part (see [_aelfPsalmKey]), canticles by
// book and chapter, as AELF only gives that much of their reference.
//
// Text is compared on its words only, after stripping HTML, punctuation and
// case: AELF and our own YAML sources format the same antiphon slightly
// differently (curly vs straight apostrophes, <p>/<br/> markup, a missing
// comma, '!' vs '.') without that being a real content discrepancy.

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';

const List<int> _years = [2024, 2025, 2026];
const String _location = 'france';
const String _aelfZone = 'france';

/// Divergences where AELF is wrong: our text was checked against the printed
/// breviary by the maintainer. Keyed '$date|$office|$field', as in
/// [_Mismatch.key], with the breviary's text: a divergence is only ignored
/// when ours is exactly that text (see [_isKnownAelfError]), so that a known
/// AELF error can't hide a bug of ours on the same field. They're still
/// listed in the summary, but don't fail the test; an entry that no longer
/// diverges is reported so it can be removed.
final Map<String, String> _knownAelfErrors = {
  // "maison de prière" chez AELF, "maison de la prière" au bréviaire
  // (Dédicace des églises, dernier dimanche d'octobre).
  for (final date in ['2024-10-27', '2025-10-26', '2026-10-25'])
    '$date|Laudes|antienne_1':
        "Ma maison, dit le Seigneur, est la maison de la prière.",
  // "du ciel et d'auprès de Dieu" chez AELF au Latran (mais sans "et" à la
  // Dédicace des églises), "du ciel d'auprès de Dieu" au bréviaire.
  for (final date in ['2024-11-09', '2025-11-09', '2026-11-09'])
    '$date|Lectures|antienne_3':
        "Cité sainte, notre Mère, tu descends du ciel d'auprès de Dieu.",
  // AELF garde l'antienne du psautier pour le Ps 75 ; le bréviaire met
  // l'antienne de l'Heure sur les trois psaumes.
  for (final antiphon in ['antienne_2', 'antienne_3'])
    '2026-12-06|None|$antiphon': "De toi, Bethléem, sortira le berger d'Israël.",
  // Faute de frappe AELF : "Isarël".
  for (final antiphon in ['antienne_1', 'antienne_2', 'antienne_3'])
    '2026-12-20|Sexte|$antiphon':
        "De toi, Bethléem, sortira le berger d'Israël.",
  // Semaine avant Noël : AELF intervertit l'antienne 3 des Laudes du
  // vendredi ("Ciel, répands ta rosée") et l'antienne 2 de celles du samedi
  // ("Je regarde vers mon Dieu").
  for (final date in ['2024-12-20', '2025-12-19', '2026-12-18'])
    '$date|Laudes|antienne_3': 'Ciel, répands ta rosée, nuée, fais pleuvoir '
        'le Juste ; terre, enfante un Sauveur !',
  for (final date in ['2024-12-21', '2025-12-20', '2026-12-19'])
    '$date|Laudes|antienne_2': "Je regarde vers mon Dieu, j'attends mon Sauveur !",
  // Semaine avant Noël, milieu du jour : les antiennes de la semaine en cours
  // (III ou IV) ; AELF met presque toujours "L'Ange dit à Marie", sans
  // régularité.
  for (final (date, antiphon) in [
    ('2024-12-17', _rappelleToi),
    ('2024-12-18', _monSecours),
    ('2024-12-19', _jEspere),
    ('2024-12-20', _envoieLAgneau),
    ('2024-12-21', _viergeBenie),
    ('2024-12-23', _lesProphetes),
    ('2024-12-24', _lAngeDitAMarie),
    ('2025-12-17', _monSecours),
    ('2025-12-18', _jEspere),
    ('2025-12-19', _envoieLAgneau),
    ('2025-12-20', _viergeBenie),
    ('2025-12-24', _viergeBenie),
    ('2026-12-17', _jEspere),
    ('2026-12-18', _envoieLAgneau),
    ('2026-12-19', _viergeBenie),
    ('2026-12-21', _lesProphetes),
    ('2026-12-22', _lAngeDitAMarie),
    ('2026-12-23', _viergeBenie),
  ])
    for (final hour in ['Tierce', 'Sexte', 'None'])
      for (final n in [1, 2, 3]) '$date|$hour|antienne_$n': antiphon,
  // Complies de la veille d'une solennité : le bréviaire garde les antiennes
  // des solennités ; AELF prend celles du samedi du temps en cours.
  for (final date in [
    '2024-03-18', '2024-05-25', '2024-06-01', '2024-06-06', '2024-06-23',
    '2024-08-14', '2024-10-31', '2024-11-23', '2025-03-18', '2025-03-24',
    '2025-06-14', '2025-06-21', '2025-06-23', '2025-06-26', '2025-08-14',
    '2025-10-31', '2025-11-22', '2026-03-18', '2026-03-24', '2026-05-30',
    '2026-06-06', '2026-06-11', '2026-06-23', '2026-08-14', '2026-10-31',
    '2026-11-21', '2026-12-07',
  ])
    '$date|Complies|antienne_1': 'Dans la paix, je reposerai.',
  '2026-12-07|Complies|antienne_2': 'Au long des nuits, bénissez le Seigneur !',
  // Christ-Roi (solennité du T.O.) : "Dieu puissant" au Ps 90 ; AELF met en
  // 2025 "Le Seigneur te couvre de ses ailes".
  '2025-11-23|Complies|antienne_1': 'Dieu puissant, mon rempart et ma foi !',
  // 31 décembre 2025 : AELF prend les Complies de la veille d'une solennité
  // (Sainte Marie, Mère de Dieu) au lieu de celles de l'octave de Noël.
  '2025-12-31|Complies|antienne_1':
      'Nos yeux ont vu le salut : qui peut nous ravir notre joie ?',
  '2025-12-31|Complies|antienne_2':
      "Sur le pays de l'ombre, une lumière s'est levée.",
  '2025-12-31|Complies|antienne_symeon (Nunc dimittis)':
      "J'ai vu de mes yeux le Sauveur : lumière des peuples.",
  // Annonciation (transférée au 8 avril 2024) et Ascension 2025, en temps
  // pascal : AELF ne prend pas l'antienne pascale de Syméon.
  for (final date in ['2024-04-08', '2025-05-29'])
    '$date|Complies|antienne_symeon (Nunc dimittis)':
        'Le Seigneur est ressuscité, alléluia, il nous remplit de sa lumière. '
            'Alléluia.',
  // Complies du vendredi : "Dans ma nuit" au bréviaire ; AELF met deux fois
  // "Dans la nuit", sans la seconde antienne.
  for (final date in ['2024-05-31', '2026-05-29'])
    '$date|Complies|antienne_1': 'Dans ma nuit, je crie vers toi, Seigneur. '
        "Que ma prière parvienne jusqu'à toi.",
  // "il comble de bien les affamés" chez AELF, "de biens" au bréviaire.
  '2025-10-30|Vêpres|antienne_magnificat':
      'Exaltez le Seigneur : il comble de biens les affamés.',
  // Transfiguration 2025, Vêpres : le cantique de 1 Tm 3, sans antienne au
  // bréviaire ; AELF met le cantique d'Ap 19 avec une antienne.
  '2025-08-06|Vêpres|psaume_3': 'NT_7 (1tm 3)',
  '2025-08-06|Vêpres|antienne_3': '',
  // Veille de l'Épiphanie (solennité) : AELF prend en 2026 l'antienne du
  // samedi du temps de Noël ("Sur le pays de l'ombre").
  '2026-01-03|Complies|antienne_2': 'Au long des nuits, bénissez le Seigneur !',
  // Fautes de frappe AELF à l'antienne de Syméon : "vous veillerons",
  // "allélulia".
  for (final date in [
    '2024-12-18', '2024-12-23', '2025-01-02', '2025-12-22', '2026-12-21',
  ])
    '$date|Complies|antienne_symeon (Nunc dimittis)':
        'Sauve-nous, Seigneur, quand nous veillons ; garde-nous quand nous '
            'dormons : nous veillerons avec le Christ et nous reposerons en '
            'paix.',
  '2026-05-14|Complies|antienne_symeon (Nunc dimittis)':
      'Le Seigneur est ressuscité, alléluia, il nous remplit de sa lumière. '
          'Alléluia.',
  // "nous recevrons" chez AELF, "nous recevons" au bréviaire.
  '2026-12-25|Laudes|antienne_zacharie (Benedictus)':
      "Voici que les oracles s'accomplissent : la lumière du Très-Haut a "
          "surgi dans le monde ; la vie nous est donnée ; nous recevons en "
          "héritage la joie du Père, alléluia.",
};

// Middle of Day antiphons of the 3rd and 4th weeks of Advent.
const _rappelleToi =
    "Rappelle-toi, Seigneur : n'oublie pas sans fin la vie de tes pauvres.";
const _monSecours = 'Mon secours, mon libérateur, Seigneur, ne tarde pas.';
const _jEspere = "J'espère en ta parole : ne déçois pas mon attente.";
const _envoieLAgneau = "Seigneur, envoie l'Agneau, le souverain de la terre, "
    'vers la montagne de Sion.';
const _viergeBenie =
    'Vierge bénie entre toutes les femmes, Jésus, ton Enfant, est béni !';
const _lesProphetes =
    "Les prophètes l'ont dit : le Sauveur naîtra de la Vierge Marie.";
const _lAngeDitAMarie =
    "L'Ange dit à Marie : je te salue, comblée de grâce ! Le Seigneur est "
    'avec toi !';

/// More known AELF errors, too many to list here, in the same form: grouped
/// by reason in test/fixtures/aelf_known_errors.json, loaded by [main].
final Map<String, String> _knownAelfErrorsFromFile = {};

/// [_knownAelfErrors] and [_knownAelfErrorsFromFile] together.
String? _expectedText(String key) =>
    _knownAelfErrors[key] ?? _knownAelfErrorsFromFile[key];

/// Whether [m] is a known AELF error with exactly the breviary's text on our
/// side (any of ours, for an evangelic antiphon: see [_compareEvangelicAntiphon]).
bool _isKnownAelfError(_Mismatch m) {
  final expected = _expectedText(m.key);
  return expected != null &&
      m.ours.split(' | ').map(_normalize).contains(_normalize(expected));
}

class _Mismatch {
  final String date;
  final String office;
  final String celebration;
  final String aelfCelebration;
  final String field;
  final String ours;
  final String aelf;
  _Mismatch(this.date, this.office, this.celebration, this.aelfCelebration,
      this.field, this.ours, this.aelf);

  String get key => '$date|$office|$field';

  @override
  String toString() => '$date [$office] $celebration — $field\n'
      '    nous  : "$ours"\n'
      '    AELF  : "$aelf"   ($aelfCelebration)';
}

/// What was compared for one year (or one Compline option), and how it went.
class _Report {
  final mismatches = <_Mismatch>[];
  int antiphons = 0;
  int psalms = 0;

  void absorb(_Report other) {
    mismatches.addAll(other.mismatches);
    antiphons += other.antiphons;
    psalms += other.psalms;
  }
}

void main() {
  late LiturgyData data;
  final dataLoader = FileSystemDataLoader();

  setUpAll(() async {
    data = await LiturgyData.load();
    final groups = jsonDecode(
            await File('test/fixtures/aelf_known_errors.json').readAsString())
        as Map<String, dynamic>;
    for (final group in groups.values) {
      _knownAelfErrorsFromFile
          .addAll(((group as Map)['errors'] as Map).cast<String, String>());
    }
  });

  for (final year in _years) {
    test('Psaumes/cantiques et antiennes — $_location $year vs AELF',
        () async {
      final calendar =
          getCalendar(Calendar(), DateTime(year, 1, 1), _location, data);
      final file = File(
          'test/fixtures/aelf_antiphons_reference_${year}_$_aelfZone.json');
      final fixture =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final report = _Report();
      for (final iso in fixture.keys.toList()..sort()) {
        await _compareDay(calendar, dataLoader, iso,
            fixture[iso] as Map<String, dynamic>, report);
      }
      _printSummary(year, report);
      final unexpected = report.mismatches
          .where((m) => !_isKnownAelfError(m))
          .toList();
      expect(unexpected, isEmpty,
          reason:
              '${unexpected.length} divergence(s) — voir le résumé ci-dessus');
    }, timeout: const Timeout(Duration(minutes: 10)));
  }
}

/// Compares every office of the day [iso] with AELF's ([aelf]).
Future<void> _compareDay(Calendar calendar, DataLoader dataLoader, String iso,
    Map<String, dynamic> aelf, _Report report) async {
  final date = DateTime.parse(iso);
  final aelfCelebration = aelf['aelf'] as String? ?? '';

  // --- Office des lectures ---
  final readingsWinner =
      _pickWinner(await readingsDetection(calendar, date, dataLoader));
  if (readingsWinner != null) {
    final readings = await readingsExport(readingsWinner);
    _compareHour(report, readings.psalmody, aelf['lectures'], iso,
        'Lectures', _label(readingsWinner), aelfCelebration);
  }

  // --- Laudes ---
  final morningWinner =
      _pickWinner(await morningDetection(calendar, date, dataLoader));
  if (morningWinner != null) {
    final morning = await morningExport(morningWinner);
    final label = _label(morningWinner);
    _compareHour(report, morning.psalmody, aelf['laudes'], iso, 'Laudes',
        label, aelfCelebration);
    _compareEvangelicAntiphon(
        morning.evangelicAntiphon,
        aelf['laudes']?['antienne_zacharie'],
        iso,
        'Laudes',
        label,
        aelfCelebration,
        'antienne_zacharie (Benedictus)',
        report);
  }

  // --- Tierce / Sexte / None ---
  final middleWinner =
      _pickWinner(await middleOfDayDetection(calendar, date, dataLoader));
  if (middleWinner != null) {
    final middle = await middleOfDayExport(middleWinner);
    final label = _label(middleWinner);
    _compareHour(report, middle.psalmodyTierce, aelf['tierce'], iso, 'Tierce',
        label, aelfCelebration,
        sharedAntiphonAcrossHour: true);
    _compareHour(report, middle.psalmodySexte, aelf['sexte'], iso, 'Sexte',
        label, aelfCelebration,
        sharedAntiphonAcrossHour: true);
    _compareHour(report, middle.psalmodyNone, aelf['none'], iso, 'None',
        label, aelfCelebration,
        sharedAntiphonAcrossHour: true);
  }

  // --- Vêpres (celle qui est réellement priée ce soir-là) ---
  final vespersWinner =
      _pickWinner(await vespersDetection(calendar, date, dataLoader));
  if (vespersWinner != null) {
    final vespers = await vespersExport(vespersWinner);
    final label = _label(vespersWinner);
    _compareHour(report, vespers.psalmody, aelf['vepres'], iso, 'Vêpres',
        label, aelfCelebration);
    _compareEvangelicAntiphon(
        vespers.evangelicAntiphon,
        aelf['vepres']?['antienne_magnificat'],
        iso,
        'Vêpres',
        label,
        aelfCelebration,
        'antienne_magnificat',
        report);
  }

  // --- Complies ---
  // Several Compline may be offered the same evening (an octave's Saturday
  // and Sunday ones, a solemnity's eve...): AELF's must match one of them.
  // Otherwise, the option with the fewest divergences is reported.
  _Report? best;
  for (final option
      in (await complineDetection(calendar, date, dataLoader)).values) {
    final compline = await complineExport(option);
    final optionReport = _Report();
    _compareHour(optionReport, compline.psalmody, aelf['complies'], iso,
        'Complies', option.complineDescription, aelfCelebration);
    _compareEvangelicAntiphon(
        compline.evangelicAntiphon,
        aelf['complies']?['antienne_symeon'],
        iso,
        'Complies',
        option.complineDescription,
        aelfCelebration,
        'antienne_symeon (Nunc dimittis)',
        optionReport);
    if (best == null ||
        optionReport.mismatches.length < best.mismatches.length) {
      best = optionReport;
    }
    if (best.mismatches.isEmpty) break;
  }
  if (best != null) report.absorb(best);
}

void _printSummary(int year, _Report report) {
  print('\n\n===================== RÉSUMÉ $year =====================');
  print('${report.psalms} psaume(s)/cantique(s) et ${report.antiphons} '
      'antienne(s) comparé(e)s pour $_location $year vs AELF ($_aelfZone).');
  final known = report.mismatches.where(_isKnownAelfError).toList();
  final unexpected =
      report.mismatches.where((m) => !_isKnownAelfError(m)).toList();
  final foundKeys = report.mismatches.map((m) => m.key).toSet();
  final staleKnown = [..._knownAelfErrors.keys, ..._knownAelfErrorsFromFile.keys]
      .where((k) => k.startsWith('$year-') && !foundKeys.contains(k))
      .toList();

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
      final expected = _expectedText(m.key);
      if (expected != null) {
        print('    bréviaire : "$expected" (erreur AELF connue, mais notre '
            'texte en diffère)');
      }
    }
    print('\nTOTAL $year : ${unexpected.length} divergence(s).');
  }
}

/// Compares an hour's psalms/canticles and their antiphons with AELF's.
void _compareHour(
  _Report report,
  List<PsalmEntry>? psalmody,
  Map<String, dynamic>? aelfOffice,
  String date,
  String office,
  String celebration,
  String aelfCelebration, {
  bool sharedAntiphonAcrossHour = false,
}) {
  _comparePsalmody(psalmody, aelfOffice, date, office, celebration,
      aelfCelebration, report,
      sharedAntiphonAcrossHour: sharedAntiphonAcrossHour);
  _comparePsalmReferences(
      psalmody, aelfOffice, date, office, celebration, aelfCelebration, report);
}

/// The day's celebrable candidate: the first one, as the detections sort
/// them by precedence (a ferial day before its optional memorials, as AELF
/// does).
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
  String aelfCelebration,
  _Report report, {
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
    report.antiphons++;
    // Several antiphons for a psalm are choices: AELF may show any of them.
    final oursChoices = oursRaw?.map(_normalize) ?? const <String>[];
    if (!_sameWords(oursText, aelfText) &&
        !_isLegitimateSecondAntiphon(oursText, aelfText) &&
        !oursChoices.any((choice) => _sameWords(choice, aelfText))) {
      report.mismatches.add(_Mismatch(date, office, celebration,
          aelfCelebration, aelfKey, oursText, aelfText));
    }
  }
}

/// Compares, position by position, the psalm or canticle we say with the one
/// AELF names in its `reference` ("75 - I", "118-17", "CANTIQUE (Col 1)").
void _comparePsalmReferences(
  List<PsalmEntry>? ours,
  Map<String, dynamic>? aelfOffice,
  String date,
  String office,
  String celebration,
  String aelfCelebration,
  _Report report,
) {
  if (aelfOffice == null) return;
  // Psalm 54 said in two parts (Wednesday II) is PSALM_54_1_2 + PSALM_54_3 in
  // our data, which keeps the numbering of its three-part division (Friday
  // IV); AELF numbers those two parts "54 - I" and "54 - II".
  final psalm54InTwoParts =
      ours?.any((e) => e.psalm == 'PSALM_54_1_2') ?? false;
  for (int i = 0; i < 3; i++) {
    final aelfKey = 'psaume_${i + 1}';
    final aelfRef = aelfOffice[aelfKey] as String?;
    final entry = (ours != null && i < ours.length) ? ours[i] : null;
    if (aelfRef == null && entry == null) continue;
    report.psalms++;
    final oursKey = entry == null
        ? null
        : psalm54InTwoParts && entry.psalm == 'PSALM_54_3'
            ? '54-2'
            : _ourPsalmKey(entry);
    if (aelfRef == null || oursKey != _aelfPsalmKey(aelfRef)) {
      report.mismatches.add(_Mismatch(date, office, celebration,
          aelfCelebration, aelfKey, '${entry?.psalm ?? '—'} ($oursKey)',
          aelfRef ?? '—'));
    }
  }
}

/// AELF's reference as a key: a psalm by its number, division letter and
/// part ("75 - I" → "75-1", "118-17", "113b", "9 B - I" → "9b-1", "14." →
/// "14"), a canticle by
/// the book and chapter in its parentheses ("CANTIQUE d'Anne (1 S 2)" →
/// "1s 2").
String _aelfPsalmKey(String reference) {
  final canticle = RegExp(r'\(([^)]*)\)').firstMatch(reference);
  if (canticle != null) return _bookChapterKey(canticle.group(1)!);
  final psalm = RegExp(r'^(\d+)\s*([AaBb]?)\s*(?:-\s*([IVX]+|\d+))?')
      .firstMatch(reference.trim());
  if (psalm == null) return reference;
  final part = psalm.group(3);
  return '${psalm.group(1)}${psalm.group(2)!.toLowerCase()}'
      '${part == null ? '' : '-${int.tryParse(part) ?? _romanToInt(part)}'}';
}

/// Our psalm as the same key: from its code ("PSALM_75_1" → "75-1",
/// "PSALM_113B" → "113b"; what follows the part is a variant of the same
/// psalm, e.g. PSALM_135_1B → "135-1"), or for a canticle (OT_n, NT_n) from
/// its biblical reference ("1S 2,1-10" → "1s 2").
String _ourPsalmKey(PsalmEntry entry) {
  final code = entry.psalm ?? '';
  final psalm = RegExp(r'^PSALM_(\d+)([AB]?)(?:_(\d+))?').firstMatch(code);
  if (psalm != null) {
    final part = psalm.group(3);
    return '${psalm.group(1)}${psalm.group(2)!.toLowerCase()}'
        '${part == null ? '' : '-$part'}';
  }
  return _bookChapterKey(entry.psalmData?.biblicalReference ?? code);
}

/// "1 S 2", "1S 2,1-10", "Ap 4-5" → "1s 2", "1s 2", "ap 4": spaces inside
/// the book's abbreviation differ between AELF and our data, and so do a few
/// abbreviations themselves ([_bookAliases]).
String _bookChapterKey(String reference) {
  final match = RegExp(r'^\s*(\d?\s*\p{L}+)\s*(\d+)', unicode: true)
      .firstMatch(reference);
  if (match == null) return reference;
  final book = match.group(1)!.replaceAll(' ', '').toLowerCase();
  return '${_bookAliases[book] ?? book} ${match.group(2)}';
}

/// Our abbreviation of a book → AELF's.
const _bookAliases = {'1chr': '1ch'};

int _romanToInt(String roman) {
  const values = {'I': 1, 'V': 5, 'X': 10};
  var total = 0;
  for (int i = 0; i < roman.length; i++) {
    final value = values[roman[i]]!;
    final next = i + 1 < roman.length ? values[roman[i + 1]]! : 0;
    total += value < next ? -value : value;
  }
  return total;
}

void _compareEvangelicAntiphon(
  Map<String, List<String>>? ours,
  dynamic aelfRaw,
  String date,
  String office,
  String celebration,
  String aelfCelebration,
  String fieldLabel,
  _Report report,
) {
  final aelfText = _normalize(aelfRaw is String ? aelfRaw : null);
  // Every antiphon we offer (year A/B/C, then the common one; a memorial's
  // weekday and Common ones) is selectable, so AELF's may match any of them.
  // A memorial's choices are introduced by their origin in italics
  // ("%(antienne de la férie :)%"), which AELF doesn't show.
  final oursTexts = [
    for (final list in ours?.values ?? const <List<String>>[])
      for (final antiphon in list)
        _normalize(antiphon.replaceFirst(RegExp(r'^%\([^)]*\)%\s*'), '')),
  ];
  // Nothing to check ours against (no such office in the fixture).
  if (aelfText.isEmpty) return;
  report.antiphons++;
  if (!oursTexts.any((t) => _sameWords(t, aelfText))) {
    report.mismatches.add(_Mismatch(date, office, celebration,
        aelfCelebration, fieldLabel, oursTexts.join(' | '), aelfText));
  }
}

/// Strips HTML markup and normalizes quotes/whitespace so that stylistic
/// differences between AELF's HTML and our plain-text YAML don't register
/// as false positives.
String _normalize(String? text) {
  if (text == null) return '';
  var t = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
  _htmlEntities.forEach((entity, char) => t = t.replaceAll(entity, char));
  t = t.replaceAll('’', "'").replaceAll('‘', "'");
  t = t.replaceAll(' ', ' ');
  t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
  return t;
}

/// The HTML entities found in some of AELF's texts.
const _htmlEntities = {
  '&nbsp;': ' ',
  '&eacute;': 'é',
  '&egrave;': 'è',
  '&rsquo;': '’',
};

/// Reduces a normalized text to its words only — lowercase, no punctuation,
/// no soft hyphens — so that punctuation and case differences between AELF
/// and our YAML (a missing comma, '!' vs '.', a capital after a colon) are
/// not reported as mismatches. Only a difference in the words themselves is.
///
/// The word "alléluia" is left out too, whatever its spelling: AELF shows
/// an optional "(alléluia)" outside Lent where we follow the season, and
/// its own text has typos of it ("allléluia", "allélluia").
String _wordsKey(String text, {bool keepCase = false}) {
  final t = text
      .replaceAll('­', '')
      .replaceAll('œ', 'oe')
      .replaceAll('Œ', 'Oe')
      .replaceAll(RegExp(r'\b[RV]/'), ' '); // responsory markers (R/, V/)
  return (keepCase ? t : t.toLowerCase())
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .split(' ')
      .where((w) => w.isNotEmpty && !_alleluiaWord.hasMatch(w.toLowerCase()))
      .join(' ');
}

final RegExp _alleluiaWord = RegExp(r'^al+él+u+ia$');


/// An AELF text with no words left (only "alléluia", a refrain marker or
/// stray punctuation) has nothing to check ours against.
bool _sameWords(String ours, String aelf) {
  final aelfWords = _wordsKey(aelf);
  return aelfWords.isEmpty ||
      _isRefrainMention(ours) ||
      _isRefrainMention(aelf) ||
      _wordsKey(ours) == aelfWords ||
      _sameButCapitalAccents(ours, aelf);
}

/// "R/ du psaume": the psalm's refrain is said as its antiphon, whichever
/// text the other side writes for it (the refrain itself, or nothing).
bool _isRefrainMention(String text) =>
    RegExp(r'^R/ du psaume\.?$').hasMatch(text.trim());

/// Same words, except that one side's capital lacks the accent of the
/// other's letter ("Ecoutez" / "Écoutez", "À toi" / "à toi"): AELF isn't
/// precise about accented capitals.
bool _sameButCapitalAccents(String ours, String aelf) {
  List<String> words(String t) => _wordsKey(t, keepCase: true).split(' ');
  final a = words(ours), b = words(aelf);
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    final x = a[i], y = b[i];
    if (x.toLowerCase() == y.toLowerCase()) continue;
    final capital = _isUpper(x[0]) || _isUpper(y[0]);
    if (!capital ||
        _unaccented(x[0].toLowerCase()) != _unaccented(y[0].toLowerCase()) ||
        x.substring(1).toLowerCase() != y.substring(1).toLowerCase()) {
      return false;
    }
  }
  return true;
}

bool _isUpper(String c) => c != c.toLowerCase();

String _unaccented(String c) => _accents[c] ?? c;

const _accents = {
  'à': 'a', 'â': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'î': 'i',
  'ï': 'i', 'ô': 'o', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c',
};

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
