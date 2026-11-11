// Maintenance script (not a test): rebuilds the AELF reference fixture used
// by test/aelf_sunday_masses_reference_test.dart.
//
// For every Sunday of the given years, it calls the AELF Mass API
// (zone=france) and saves, for each Mass of the day, the type and biblical
// reference of its readings, so the comparison test can run offline and
// reproducibly. The API only gives the readings, not the prayers.
//
// Usage: dart run test/tools/fetch_aelf_sunday_masses_reference.dart [year...]
// (2024, 2025 and 2026 when no year is given)

import 'dart:convert';
import 'dart:io';

const List<int> defaultYears = [2024, 2025, 2026];
const String aelfZone = 'france';
const String fixturePath =
    'test/fixtures/aelf_sunday_masses_reference_$aelfZone.json';
const int maxAttempts = 3;

void main(List<String> args) async {
  final years = args.isEmpty ? defaultYears : args.map(int.parse).toList();
  final client = HttpClient();
  final result = <String, dynamic>{};
  final failures = <String>[];
  try {
    for (final year in years) {
      var date = DateTime(year, 1, 1);
      while (date.weekday != DateTime.sunday) {
        date = date.add(const Duration(days: 1));
      }
      for (; date.year == year; date = date.add(const Duration(days: 7))) {
        final iso = date.toIso8601String().substring(0, 10);
        final raw = await _getJson(client, iso);
        if (raw == null) {
          failures.add(iso);
          continue;
        }
        final info = raw['informations'] as Map<String, dynamic>? ?? {};
        result[iso] = {
          'aelf': [info['jour_liturgique_nom'], info['fete']]
              .whereType<String>()
              .where((s) => s.isNotEmpty)
              .join(' — '),
          'annee': info['annee'],
          'messes': [
            for (final mass in (raw['messes'] as List? ?? []))
              {
                'nom': mass['nom'],
                'lectures': [
                  for (final reading in (mass['lectures'] as List? ?? []))
                    {'type': reading['type'], 'ref': reading['ref']},
                ],
              },
          ],
        };
      }
      print('$year : ${result.keys.where((k) => k.startsWith('$year')).length}'
          ' dimanches');
    }
  } finally {
    client.close();
  }

  if (failures.isNotEmpty) {
    print('${failures.length} requête(s) en échec, fixture non écrite : '
        '${failures.join(', ')}');
    exitCode = 1;
    return;
  }

  final file = File(fixturePath);
  await file.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(result));
  print('Écrit : ${file.path} (${result.length} dimanches).');
}

Future<Map<String, dynamic>?> _getJson(HttpClient client, String iso) async {
  final uri = Uri.parse('https://api.aelf.org/v1/messes/$iso/$aelfZone');
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode == 200) {
        return jsonDecode(body) as Map<String, dynamic>;
      }
    } catch (_) {
      // retried below
    }
    await Future.delayed(Duration(seconds: attempt));
  }
  return null;
}
