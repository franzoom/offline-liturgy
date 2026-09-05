// Balaie tous les offices (Laudes, Vêpres, Lectures, Complies, Sexte/Tierce/None,
// Messe) de chaque jour d'une année liturgique pour un lieu donné, et vérifie
// que chaque champ nécessaire au rendu est bien présent et non vide.
//
// Affiche en direct, pour chaque jour et chaque office : OK (vert) si le
// contenu est complet, ou le détail de ce qui manque (rouge). Un résumé
// groupé par office est imprimé à la fin, puis le test échoue s'il reste au
// moins une anomalie.
//
// Ce fichier ne modifie rien : c'est un audit de couverture des données, pas
// un test unitaire de logique.

import 'package:test/test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';

const String _location = 'lyon';
const int _year = 2026;

const String _green = '\x1B[32m';
const String _red = '\x1B[31m';
const String _gray = '\x1B[90m';
const String _reset = '\x1B[0m';

/// One (date, office, celebration) anomaly, kept for the final summary.
class _Anomaly {
  final String office;
  final DateTime date;
  final String celebration;
  final String issue;
  _Anomaly(this.office, this.date, this.celebration, this.issue);

  @override
  String toString() =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
      '[$office] $celebration : $issue';
}

void main() {
  late LiturgyData data;
  late Calendar calendar;
  late DataLoader dataLoader;
  final anomalies = <_Anomaly>[];
  int checkedCount = 0;

  setUpAll(() async {
    dataLoader = FileSystemDataLoader();
    data = await LiturgyData.load();
    calendar = getCalendar(Calendar(), DateTime(_year, 1, 1), _location, data);
  });

  /// Prints one result line and records the anomaly if [issues] is non-empty.
  void report(String office, DateTime date, String celebration,
      List<String> issues) {
    checkedCount++;
    if (issues.isEmpty) {
      print('  $_green$office — OK$_reset  ($celebration)');
    } else {
      for (final issue in issues) {
        anomalies.add(_Anomaly(office, date, celebration, issue));
      }
      print('  $_red$office — MANQUE : ${issues.join(' | ')}$_reset  ($celebration)');
    }
  }

  test('Balayage complet des offices — $_location $_year', () async {
    for (var date = DateTime(_year, 1, 1);
        date.year == _year;
        date = date.shift(1)) {
      final dayContent = calendar.getDayContent(date);
      print('\n=== ${date.year}-${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')} — '
          '${dayContent?.defaultCelebrationTitle ?? '?'} ===');

      // --- Morning (Laudes) ---
      final morningCandidates = await morningDetection(calendar, date, dataLoader);
      for (final entry in morningCandidates.entries) {
        final morning = await morningExport(entry.value);
        report('Morning', date, _label(entry.key, entry.value.isCelebrable),
            _checkMorning(morning));
      }

      // --- Vespers (I & II) ---
      final vespersCandidates = await vespersDetection(calendar, date, dataLoader);
      for (final entry in vespersCandidates.entries) {
        final isVespers2 = entry.value.celebrationType != 'vespers1';
        // Second Vespers of Saturday doesn't exist as its own office — it IS
        // the following Sunday's First Vespers. Any content found there in
        // the ferial data is incidental, so skip the check entirely rather
        // than flag it as a hole.
        if (isVespers2 && date.weekday == DateTime.saturday) {
          checkedCount++;
          print('  $_gray Vespers2 — n/a (Vêpres II du samedi n\'existe pas)'
              '$_reset  (${entry.key})');
          continue;
        }
        final vespers = await vespersExport(entry.value);
        final officeLabel = isVespers2 ? 'Vespers2' : 'Vespers1';
        report(officeLabel, date, _label(entry.key, entry.value.isCelebrable),
            _checkVespers(vespers));
      }

      // --- Readings (Office des lectures) ---
      final readingsCandidates = await readingsDetection(calendar, date, dataLoader);
      for (final entry in readingsCandidates.entries) {
        final readings = await readingsExport(entry.value);
        report('Readings', date, _label(entry.key, entry.value.isCelebrable),
            _checkReadings(readings, entry.value));
      }

      // --- Compline ---
      final complineCandidates = await complineDetection(calendar, date, dataLoader);
      for (final entry in complineCandidates.entries) {
        final compline = await complineExport(entry.value);
        report('Compline', date, _label(entry.key, entry.value.isCelebrable),
            _checkCompline(compline));
      }

      // --- Middle of Day (Tierce/Sexte/None) ---
      final middleCandidates =
          await middleOfDayDetection(calendar, date, dataLoader);
      for (final entry in middleCandidates.entries) {
        final middle = await middleOfDayExport(entry.value);
        report('MiddleOfDay', date, _label(entry.key, entry.value.isCelebrable),
            _checkMiddleOfDay(middle));
      }

      // --- Mass ---
      final massCandidates = await massDetection(calendar, date, dataLoader);
      for (final entry in massCandidates.entries) {
        final mass = await massExport(entry.value);
        report('Mass', date, _label(entry.key, entry.value.isCelebrable),
            _checkMass(mass));

        // Trou de cycle lectionnaire : une lecture peut être renseignée pour
        // B et C mais oubliée pour A (ou pour l'année I mais pas II). Un seul
        // passage sur l'année 2026 n'exerce qu'un seul cycle par jour ; on
        // rejoue donc massExport en ne changeant que l'année de référence du
        // cycle (le calendrier et la date restent identiques) pour couvrir
        // les cycles non exercés par la vraie date. Silencieux si tout va
        // bien, pour ne pas noyer la sortie.
        final isSunday = entry.value.date.isSunday;
        final realCycle = isSunday
            ? liturgicalYear(entry.value.liturgicalYear ?? _year)
            : weekdayLectionaryYear(entry.value.liturgicalYear ?? _year);
        final candidateRefYears = isSunday ? [2026, 2027, 2028] : [2026, 2027];
        for (final refYear in candidateRefYears) {
          final cycleKey = isSunday
              ? liturgicalYear(refYear)
              : weekdayLectionaryYear(refYear);
          if (cycleKey == realCycle) continue; // déjà couvert ci-dessus
          final variantContext = entry.value.copyWith(liturgicalYear: refYear);
          final variantMass = await massExport(variantContext);
          final issues = _checkReadingParts(variantMass.readingParts,
              'lectures (cycle $cycleKey)');
          if (issues.isNotEmpty) {
            final label =
                '${_label(entry.key, entry.value.isCelebrable)} — cycle $cycleKey';
            for (final issue in issues) {
              anomalies.add(_Anomaly('Mass', date, label, issue));
            }
            print('  $_red Mass — MANQUE (cycle $cycleKey) : '
                '${issues.join(' | ')}$_reset  ($label)');
          }
        }
      }
    }

    // --- Résumé final ---
    print('\n\n===================== RÉSUMÉ =====================');
    print('$checkedCount office(s) vérifié(s) pour $_location $_year.');
    if (anomalies.isEmpty) {
      print('${_green}Aucune anomalie détectée.$_reset');
    } else {
      final byOffice = <String, List<_Anomaly>>{};
      for (final a in anomalies) {
        byOffice.putIfAbsent(a.office, () => []).add(a);
      }
      for (final office in byOffice.keys) {
        print('\n$_red-- $office : ${byOffice[office]!.length} anomalie(s) --$_reset');
        for (final a in byOffice[office]!) {
          print('  $a');
        }
      }
      print('\n${_red}TOTAL : ${anomalies.length} anomalie(s).$_reset');
    }

    expect(anomalies, isEmpty,
        reason: '${anomalies.length} anomalie(s) — voir le résumé ci-dessus');
  }, timeout: const Timeout(Duration(hours: 1)));
}

/// Marks a celebration label as superseded by a higher-precedence option
/// today (e.g. Second Vespers of a Saturday when tomorrow's Sunday First
/// Vespers wins) — such options are commonly thin or empty in the source
/// data by design (nobody actually prays them), so anomalies found there are
/// annotated rather than silently dropped, for the reader to judge.
String _label(String celebration, bool isCelebrable) =>
    isCelebrable ? celebration : '$celebration [non célébrable]';

// --- Helpers de vérification par type de contenu ---

/// Psalm/canticle codes known to have no antiphon of their own by design —
/// confirmed by the maintainer, not a content gap. NT_x canticles and this
/// handful of psalms are excluded from the "antienne absente" check.
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

List<String> _checkPsalmody(List<PsalmEntry>? psalmody, String label) {
  if (psalmody == null || psalmody.isEmpty) return ['$label absente'];
  final issues = <String>[];
  for (final e in psalmody) {
    if (e.psalm == null || e.psalm!.isEmpty) {
      issues.add('$label : entrée sans code psaume');
    } else if (e.psalmData == null) {
      issues.add('$label : ${e.psalm} non résolu');
    } else if (e.psalmData!.content.trim().isEmpty) {
      issues.add('$label : ${e.psalm} résolu mais vide');
    }
    if (!_isIgnoredMissingAntiphonCode(e.psalm) &&
        (e.antiphon == null ||
            e.antiphon!.isEmpty ||
            e.antiphon!.every((a) => a.trim().isEmpty))) {
      issues.add('$label : antienne absente pour ${e.psalm ?? "?"}');
    }
  }
  return issues;
}

List<String> _checkHymns(List<HymnEntry>? hymns, String label) {
  if (hymns == null || hymns.isEmpty) return ['$label absent'];
  final issues = <String>[];
  for (final h in hymns) {
    if (h.hymnData == null) {
      issues.add('$label : ${h.code} non résolu');
    } else if (h.hymnData!.content.trim().isEmpty) {
      issues.add('$label : ${h.code} résolu mais vide');
    }
  }
  return issues;
}

List<String> _checkReading(Reading? reading, String label) {
  if (reading == null) return ['$label absente'];
  if ((reading.content ?? '').trim().isEmpty) {
    return ['$label vide (${reading.biblicalReference ?? "?"})'];
  }
  return [];
}

List<String> _checkIntercession(Intercession? intercession, String label) {
  if (intercession == null) return ['$label absentes'];
  if ((intercession.content ?? '').trim().isEmpty) return ['$label vides'];
  return [];
}

List<String> _checkStringList(List<String>? list, String label) {
  if (list == null || list.isEmpty) return ['$label absente'];
  if (list.every((s) => s.trim().isEmpty)) return ['$label vide'];
  return [];
}

List<String> _checkEvangelicAntiphon(
    Map<String, List<String>>? antiphon, String label) {
  if (antiphon == null || antiphon.isEmpty) return ['$label absente'];
  final hasContent =
      antiphon.values.any((l) => l.any((s) => s.trim().isNotEmpty));
  if (!hasContent) return ['$label vide'];
  return [];
}

List<String> _checkCanticle(Psalm? canticle, String label) {
  if (canticle == null) return ['$label absent'];
  if (canticle.content.trim().isEmpty) return ['$label vide'];
  return [];
}

List<String> _checkInvitatory(Invitatory? invitatory) {
  if (invitatory == null) return ['invitatoire absent'];
  final issues = <String>[];
  if (invitatory.psalms == null || invitatory.psalms!.isEmpty) {
    issues.add('psaumes de l\'invitatoire absents');
  }
  if (invitatory.antiphon == null ||
      invitatory.antiphon!.isEmpty ||
      invitatory.antiphon!.every((a) => a.trim().isEmpty)) {
    issues.add('antienne de l\'invitatoire absente');
  }
  return issues;
}

List<String> _checkMorning(Morning m) => [
      ..._checkPsalmody(m.psalmody, 'psalmodie'),
      ..._checkHymns(m.hymn, 'hymne'),
      ..._checkInvitatory(m.invitatory),
      ..._checkReading(m.reading, 'lecture brève'),
      if ((m.responsory ?? '').trim().isEmpty) 'répons absent',
      ..._checkEvangelicAntiphon(m.evangelicAntiphon, 'antienne du Benedictus'),
      ..._checkCanticle(m.evangelicCanticle, 'Benedictus'),
      ..._checkIntercession(m.intercession, 'intercessions'),
      ..._checkStringList(m.oration, 'oraison'),
    ];

List<String> _checkVespers(Vespers v) => [
      ..._checkPsalmody(v.psalmody, 'psalmodie'),
      ..._checkHymns(v.hymn, 'hymne'),
      ..._checkReading(v.reading, 'lecture brève'),
      if ((v.responsory ?? '').trim().isEmpty) 'répons absent',
      ..._checkEvangelicAntiphon(v.evangelicAntiphon, 'antienne du Magnificat'),
      ..._checkCanticle(v.evangelicCanticle, 'Magnificat'),
      ..._checkIntercession(v.intercession, 'intercessions'),
      ..._checkStringList(v.oration, 'oraison'),
    ];

List<String> _checkReadings(Readings r, CelebrationContext context) {
  final prec = context.precedence ?? 13;
  final lt = context.liturgicalTime ?? '';
  final expectsTeDeum = prec <= 8 &&
      lt != 'holyweek' &&
      context.celebrationCode != 'commemoration_of_all_the_faithful_departed';

  final biblicalIssues = (r.biblicalReading == null || r.biblicalReading!.isEmpty)
      ? ['lecture biblique absente']
      : [
          for (final b in r.biblicalReading!)
            if ((b.content ?? '').trim().isEmpty)
              'lecture biblique vide (${b.ref ?? "?"})'
        ];
  final patristicIssues =
      (r.patristicReading == null || r.patristicReading!.isEmpty)
          ? ['lecture patristique absente']
          : [
              for (final p in r.patristicReading!)
                if ((p.content ?? '').trim().isEmpty)
                  'lecture patristique vide (${p.title ?? "?"})'
            ];

  return [
    ..._checkPsalmody(r.psalmody, 'psalmodie'),
    ..._checkHymns(r.hymn, 'hymne'),
    ...biblicalIssues,
    ...patristicIssues,
    if (expectsTeDeum && r.teDeum == null) 'Te Deum absent',
    ..._checkStringList(r.oration, 'oraison'),
  ];
}

List<String> _checkCompline(Compline c) => [
      ..._checkPsalmody(c.psalmody, 'psalmodie'),
      ..._checkHymns(c.hymns, 'hymne'),
      ..._checkReading(c.reading, 'lecture brève'),
      if ((c.responsory ?? '').trim().isEmpty) 'répons absent',
      ..._checkEvangelicAntiphon(c.evangelicAntiphon, 'antienne du Nunc Dimittis'),
      ..._checkCanticle(c.evangelicCanticle, 'Nunc Dimittis'),
    ];

List<String> _checkMiddleOfDay(MiddleOfDay m) => [
      ..._checkPsalmody(m.psalmodyTierce, 'psalmodie de Tierce'),
      ..._checkPsalmody(m.psalmodySexte, 'psalmodie de Sexte'),
      ..._checkPsalmody(m.psalmodyNone, 'psalmodie de None'),
      ..._checkHymns(m.hymnTierce, 'hymne de Tierce'),
      ..._checkHymns(m.hymnSexte, 'hymne de Sexte'),
      ..._checkHymns(m.hymnNone, 'hymne de None'),
    ];

List<String> _checkMassAntiphons(List<MassAntiphon>? list, String label) {
  if (list == null || list.isEmpty) return ['$label absente'];
  final issues = <String>[];
  for (final a in list) {
    if ((a.content ?? '').trim().isEmpty) {
      issues.add('$label vide (${a.biblicalReference ?? "?"})');
    }
  }
  return issues;
}

String? _contentTextOf(MassReadingContent c) => switch (c) {
      MassReading r => r.content,
      MassPsalm p => p.content,
      MassGospel g => g.content,
    };

List<String> _checkReadingParts(List<MassReadingPart>? parts, String label) {
  if (parts == null || parts.isEmpty) return ['$label absentes'];
  final issues = <String>[];
  for (final part in parts) {
    if (part.partContents.isEmpty) {
      issues.add('$label : section ${part.partType} vide (trou de cycle ?)');
      continue;
    }
    for (final content in part.partContents) {
      if ((_contentTextOf(content) ?? '').trim().isEmpty) {
        issues.add('$label : section ${part.partType} — contenu vide');
      }
    }
  }
  return issues;
}

List<String> _checkMass(Mass m) => [
      ..._checkMassAntiphons(m.entranceAntiphon, 'antienne d\'entrée'),
      ..._checkStringList(m.collect, 'collecte'),
      ..._checkReadingParts(m.readingParts, 'lectures'),
      ..._checkStringList(m.offeringPrayer, 'prière sur les offrandes'),
      ..._checkMassAntiphons(m.communionAntiphon, 'antienne de communion'),
      ..._checkStringList(m.prayerAfterCommunion, 'prière après la communion'),
    ];
