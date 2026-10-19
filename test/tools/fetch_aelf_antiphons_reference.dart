// Maintenance script (not a test): rebuilds the AELF reference fixtures used
// by test/aelf_antiphons_reference_test.dart, one per year.
//
// For every day of each year (France calendar), it calls the AELF API (Office
// des lectures, Laudes, Tierce, Sexte, None, Vêpres, Complies — zone=france)
// and saves the psalm/canticle antiphons and references to a JSON fixture, so
// the actual comparison test can run offline and reproducibly.
//
// Usage: dart run test/tools/fetch_aelf_antiphons_reference.dart [year...]
// (2024, 2025 and 2026 when no year is given)

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:offline_liturgy/offline_liturgy.dart';

const List<int> defaultYears = [2024, 2025, 2026];
const String location = 'france';
const String aelfZone = 'france';
const int maxConcurrentRequests = 8;
const int maxAttempts = 3;
const List<String> offices = [
  'lectures',
  'laudes',
  'tierce',
  'sexte',
  'none',
  'vepres',
  'complies',
];

String fixturePath(int year) =>
    'test/fixtures/aelf_antiphons_reference_${year}_$aelfZone.json';

void main(List<String> args) async {
  final years = args.isEmpty ? defaultYears : args.map(int.parse).toList();
  final data = await LiturgyData.load();
  final loader = FileSystemDataLoader();
  final client = HttpClient();
  final semaphore = _Semaphore(maxConcurrentRequests);
  try {
    for (final year in years) {
      await _fetchYear(year, data, loader, client, semaphore);
    }
  } finally {
    client.close();
  }
}

Future<void> _fetchYear(int year, LiturgyData data, DataLoader loader,
    HttpClient client, _Semaphore semaphore) async {
  final calendar = getCalendar(Calendar(), DateTime(year, 1, 1), location, data);

  final categories = <DateTime, String>{};
  for (var date = DateTime(year, 1, 1);
      date.year == year;
      date = date.shift(1)) {
    categories[date] =
        _category(date, await morningDetection(calendar, date, loader));
  }

  print('${categories.length} dates à interroger sur AELF pour '
      '$year ($aelfZone)...');

  final result = <String, dynamic>{};
  final failures = <String>[];
  int done = 0;

  Future<void> fetchDate(DateTime date, String category) async {
    final iso = date.toIso8601String().substring(0, 10);
    final officeData = <String, dynamic>{};
    Map<String, dynamic>? informations;
    await Future.wait(offices.map((office) async {
      await semaphore.acquire();
      try {
        final raw = await _getJson(client, office, iso);
        if (raw == null) {
          failures.add('$office $iso');
          return;
        }
        informations ??= raw['informations'] as Map<String, dynamic>?;
        officeData[office] = _extractReference(raw[office]);
      } finally {
        semaphore.release();
      }
    }));
    // Fixed office order (not the requests' completion order), so that a
    // rebuilt fixture only differs where AELF's content does.
    result[iso] = {
      'category': category,
      // What AELF celebrates that day ("de la férie", a memorial's name...),
      // to tell a different choice of celebration from a content error.
      'aelf': [
        informations?['jour_liturgique_nom'],
        informations?['fete'],
      ].whereType<String>().where((s) => s.isNotEmpty).join(' — '),
      for (final office in offices) office: officeData[office],
    };
    done++;
    if (done % 50 == 0) print('  $done/${categories.length}...');
  }

  await Future.wait(categories.entries.map((e) => fetchDate(e.key, e.value)));

  if (failures.isNotEmpty) {
    print('${failures.length} requête(s) en échec pour $year, fixture non '
        'écrite : ${failures.join(', ')}');
    exitCode = 1;
    return;
  }

  final sortedResult = Map.fromEntries(
      result.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));

  final file = File(fixturePath(year));
  await file.create(recursive: true);
  await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(sortedResult));
  print('Écrit : ${file.path} (${sortedResult.length} dates).');
}

/// The day's rank, as the package sees it — only shown by the test.
String _category(DateTime date, Map<String, CelebrationContext> candidates) {
  CelebrationContext? winner;
  for (final c in candidates.values) {
    if (!c.isCelebrable) continue;
    if (winner == null || (c.precedence ?? 13) < (winner.precedence ?? 13)) {
      winner = c;
    }
  }
  final prec = winner?.precedence ?? 13;
  if (date.weekday == DateTime.sunday) return 'Dimanche';
  if (prec <= 4) return 'Solennite';
  if (prec <= 8) return 'Fete';
  if (prec <= 11) return 'Memoire';
  return 'Ferie';
}

/// The office's JSON, retried [maxAttempts] times; null if it still fails.
/// An office AELF doesn't have that day (HTTP 404: the Office of Readings of
/// Easter Sunday, replaced by the Vigil) is an empty map, not a failure.
Future<Map<String, dynamic>?> _getJson(
    HttpClient client, String office, String isoDate) async {
  final uri = Uri.parse('https://api.aelf.org/v1/$office/$isoDate/$aelfZone');
  for (int attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        return jsonDecode(body) as Map<String, dynamic>;
      }
      if (response.statusCode == HttpStatus.notFound) {
        await response.drain();
        return {};
      }
      print('  ! HTTP ${response.statusCode} pour $uri');
      await response.drain();
    } catch (e) {
      print('  ! Erreur pour $uri : $e');
    }
    await Future.delayed(Duration(seconds: attempt));
  }
  return null;
}

/// Keeps only the antiphons and the psalm references (AELF's `reference`,
/// e.g. "75 - I" or "CANTIQUE (Col 1)") — nothing else in the office content
/// is used by the comparison test.
Map<String, dynamic> _extractReference(Map<String, dynamic>? office) {
  if (office == null) return {};
  final result = <String, dynamic>{};
  for (final key in [
    'antienne_1',
    'antienne_2',
    'antienne_3',
    'antienne_zacharie',
    'antienne_magnificat',
    'antienne_symeon',
  ]) {
    if (office[key] != null) result[key] = office[key];
  }
  // An absent psalm is an empty list (Compline's psaume_2), not a map.
  for (final key in ['psaume_1', 'psaume_2', 'psaume_3']) {
    final psalm = office[key];
    if (psalm is Map && psalm['reference'] != null) {
      result[key] = psalm['reference'];
    }
  }
  return result;
}

/// Small counting semaphore to bound concurrent HTTP requests.
class _Semaphore {
  final int max;
  int _current = 0;
  final List<void Function()> _waiters = [];
  _Semaphore(this.max);

  Future<void> acquire() {
    if (_current < max) {
      _current++;
      return Future.value();
    }
    final completer = Completer<void>();
    _waiters.add(() {
      _current++;
      completer.complete();
    });
    return completer.future;
  }

  void release() {
    _current--;
    if (_waiters.isNotEmpty) {
      final next = _waiters.removeAt(0);
      next();
    }
  }
}
