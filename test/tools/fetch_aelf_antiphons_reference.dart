// Maintenance script (not a test): rebuilds the AELF reference fixture used
// by test/aelf_antiphons_reference_test.dart.
//
// For every Sunday, Solemnity and Feast of [year] in the France calendar, it
// calls the AELF API (Laudes, Tierce, Sexte, None, Vêpres — zone=france) and
// saves the psalm/canticle antiphons to a JSON fixture, so the actual
// comparison test can run offline and reproducibly.
//
// Usage: dart run test/tools/fetch_aelf_antiphons_reference.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:offline_liturgy/offline_liturgy.dart';

const int year = 2026;
const String location = 'france';
const String aelfZone = 'france';
const int maxConcurrentRequests = 8;

final Uri _fixturePath = Uri.file(
    'test/fixtures/aelf_antiphons_reference_${year}_$aelfZone.json');

void main() async {
  final data = await LiturgyData.load();
  final loader = FileSystemDataLoader();
  final calendar = getCalendar(Calendar(), DateTime(year, 1, 1), location, data);

  final qualifyingDates = <DateTime, String>{};
  for (var date = DateTime(year, 1, 1);
      date.year == year;
      date = date.shift(1)) {
    final morningCandidates = await morningDetection(calendar, date, loader);
    CelebrationContext? winner;
    for (final c in morningCandidates.values) {
      if (!c.isCelebrable) continue;
      if (winner == null || (c.precedence ?? 13) < (winner.precedence ?? 13)) {
        winner = c;
      }
    }
    if (winner == null) continue;
    final prec = winner.precedence ?? 13;
    final isSunday = date.weekday == DateTime.sunday;
    String? category;
    if (isSunday) {
      category = 'Dimanche';
    } else if (prec <= 4) {
      category = 'Solennite';
    } else if (prec == 5) {
      category = 'Fete';
    }
    if (category != null) qualifyingDates[date] = category;
  }

  print('${qualifyingDates.length} dates à interroger sur AELF pour '
      '$year ($aelfZone)...');

  final client = HttpClient();
  final semaphore = _Semaphore(maxConcurrentRequests);
  final result = <String, dynamic>{};
  int done = 0;

  Future<void> fetchDate(DateTime date, String category) async {
    final iso = date.toIso8601String().substring(0, 10);
    final offices = ['laudes', 'tierce', 'sexte', 'none', 'vepres'];
    final officeData = <String, dynamic>{};
    await Future.wait(offices.map((office) async {
      await semaphore.acquire();
      try {
        final raw = await _getJson(client, office, iso);
        officeData[office] = _extractAntiphons(raw?[office]);
      } finally {
        semaphore.release();
      }
    }));
    result[iso] = {'category': category, ...officeData};
    done++;
    if (done % 10 == 0) print('  $done/${qualifyingDates.length}...');
  }

  await Future.wait(
      qualifyingDates.entries.map((e) => fetchDate(e.key, e.value)));
  client.close();

  final sortedResult = Map.fromEntries(
      result.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));

  final file = File(_fixturePath.toFilePath());
  await file.create(recursive: true);
  await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(sortedResult));
  print('Écrit : ${file.path} (${sortedResult.length} dates).');
}

Future<Map<String, dynamic>?> _getJson(
    HttpClient client, String office, String isoDate) async {
  final uri = Uri.parse('https://api.aelf.org/v1/$office/$isoDate/$aelfZone');
  try {
    final request = await client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode != 200) {
      print('  ! HTTP ${response.statusCode} pour $uri');
      await response.drain();
      return null;
    }
    final body = await response.transform(utf8.decoder).join();
    return jsonDecode(body) as Map<String, dynamic>;
  } catch (e) {
    print('  ! Erreur pour $uri : $e');
    return null;
  }
}

/// Keeps only the antiphon-related fields — nothing else in the office
/// content is used by the comparison test.
Map<String, dynamic> _extractAntiphons(Map<String, dynamic>? office) {
  if (office == null) return {};
  final result = <String, dynamic>{};
  for (final key in ['antienne_1', 'antienne_2', 'antienne_3',
      'antienne_zacharie', 'antienne_magnificat']) {
    if (office[key] != null) result[key] = office[key];
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
