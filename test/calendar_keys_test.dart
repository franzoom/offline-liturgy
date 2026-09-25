// Location data consistency for celebration codes.
//
// A location's `move:` entry names the feast to move by its base name
// (prefix-agnostic). A misspelled name used to leave the feast at its
// original date and add an empty, unqualified entry at the new one;
// moveItemToDate now ignores such entries with a warning, so they would
// otherwise go unnoticed. These tests keep the data honest.

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';

const int _year = 2026;

String _baseName(String code) => code.substring(code.lastIndexOf('/') + 1);

void main() {
  late LiturgyData data;
  late Set<String> knownBaseNames;

  setUpAll(() async {
    data = await LiturgyData.load();
    final index = jsonDecode(
            await File('assets/calendar_data/index.json').readAsString())
        as Map<String, dynamic>;
    knownBaseNames = index.keys.map(_baseName).toSet();
  });

  test('Chaque entrée move: désigne une fête existante (index.json)', () {
    final unknown = <String>[];
    for (final location in data.locationData.values) {
      for (final feast in location.moveFeasts) {
        if (!knownBaseNames.contains(feast.key)) {
          unknown.add('${location.id}: ${feast.key}');
        }
      }
    }
    expect(unknown..sort(), isEmpty,
        reason: 'entrées move: qui ne correspondent à aucune fête');
  });

  test('Aucun code de célébration sans préfixe — tous les lieux, $_year',
      () {
    final unqualified = <String>{};
    for (final location in data.locationData.keys.toList()..sort()) {
      final calendar =
          getCalendar(Calendar(), DateTime(_year, 1, 1), location, data);
      for (final entry in calendar.calendarData.entries) {
        for (final code in entry.value.feastList.values.expand((l) => l)) {
          if (!code.contains('/')) {
            final iso = entry.key.toIso8601String().substring(0, 10);
            unqualified.add('$location $iso $code');
          }
        }
      }
    }
    expect(unqualified, isEmpty, reason: 'codes sans préfixe');
  });
}
