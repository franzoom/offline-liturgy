// The psalm tone scores (assets/svg/psalm-tones/NAME.svg) carry the MIDI of
// their psalmody, base64-encoded in a final <metadata id="midi"> element
// (produced by build.py in the Psaumes repository). These tests check that
// every embedded MIDI is readable and plays one note at a time — the guarantee
// that no chord is ever played —, and that the MIDI reaches the office through
// svgData.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/tools/constants.dart';
import 'package:offline_liturgy/tools/resolve_office_content.dart';
import 'package:test/test.dart';

final _midiMetadata =
    RegExp(r'<metadata id="midi">([A-Za-z0-9+/=]+)</metadata></svg>\s*$');

/// Notes of a standard MIDI file as (start, end) ticks, in start order.
List<(int, int)> _midiNotes(Uint8List data) {
  expect(ascii.decode(data.sublist(0, 4)), 'MThd');
  final trackCount = (data[10] << 8) | data[11];
  var pos = 8 + ByteData.sublistView(data, 4, 8).getUint32(0);
  final notes = <(int, int)>[];

  int readVarLen() {
    var value = 0;
    while (true) {
      final byte = data[pos++];
      value = (value << 7) | (byte & 0x7F);
      if (byte < 0x80) return value;
    }
  }

  for (var t = 0; t < trackCount; t++) {
    expect(ascii.decode(data.sublist(pos, pos + 4)), 'MTrk');
    final end =
        pos + 8 + ByteData.sublistView(data, pos + 4, pos + 8).getUint32(0);
    pos += 8;
    var tick = 0;
    var status = 0;
    final started = <int, int>{};
    while (pos < end) {
      tick += readVarLen();
      // Meta and sysex events: skip their data (read the length first, as
      // readVarLen moves pos).
      if (data[pos] == 0xFF || data[pos] == 0xF0 || data[pos] == 0xF7) {
        pos += data[pos] == 0xFF ? 2 : 1;
        final length = readVarLen();
        pos += length;
        continue;
      }
      if (data[pos] & 0x80 != 0) status = data[pos++];
      final command = status & 0xF0;
      if (command == 0xC0 || command == 0xD0) {
        pos += 1;
        continue;
      }
      final key = data[pos];
      final velocity = data[pos + 1];
      pos += 2;
      final note = ((status & 0x0F) << 8) | key;
      if (command == 0x90 && velocity > 0) {
        started[note] = tick;
      } else if ((command == 0x80 || command == 0x90) &&
          started.containsKey(note)) {
        notes.add((started.remove(note)!, tick));
      }
    }
    pos = end;
  }
  return notes..sort((a, b) => a.$1.compareTo(b.$1));
}

/// Whether no note starts before the previous one ends.
bool _isMonophonic(List<(int, int)> notes) {
  for (var i = 1; i < notes.length; i++) {
    if (notes[i].$1 < notes[i - 1].$2) return false;
  }
  return true;
}

/// A one-track MIDI file playing [notes], given as (key, start, end) ticks.
Uint8List _midiFile(List<(int, int, int)> notes) {
  final events = [
    for (final (key, start, _) in notes) (start, 0x90, key, 90),
    for (final (key, _, end) in notes) (end, 0x80, key, 0),
  ]..sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
  final track = <int>[];
  var tick = 0;
  for (final (time, command, key, velocity) in events) {
    track.addAll([time - tick, command, key, velocity]); // deltas < 128
    tick = time;
  }
  track.addAll([0, 0xFF, 0x2F, 0]);
  return Uint8List.fromList([
    ...ascii.encode('MThd'), 0, 0, 0, 6, 0, 0, 0, 1, 0, 96, //
    ...ascii.encode('MTrk'), 0, 0, 0, track.length, ...track,
  ]);
}

void main() {
  final scores = Directory('assets/svg')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.svg'))
      .toList();

  test('scores are found', () => expect(scores, isNotEmpty));

  test('the check tells a melody from a chord', () {
    expect(_isMonophonic(_midiNotes(_midiFile([(60, 0, 96), (62, 96, 120)]))),
        isTrue);
    expect(
        _isMonophonic(
            _midiNotes(_midiFile([(60, 0, 96), (64, 0, 96), (67, 0, 96)]))),
        isFalse);
  });

  test('every embedded MIDI is valid and plays one note at a time', () {
    var withMidi = 0;
    for (final file in scores) {
      final svg = file.readAsStringSync();
      if (!svg.contains('<metadata id="midi">')) continue;
      final match = _midiMetadata.firstMatch(svg);
      expect(match, isNotNull,
          reason: '${file.path}: the MIDI must be the last element');
      final notes = _midiNotes(base64.decode(match!.group(1)!));
      expect(notes, isNotEmpty, reason: '${file.path}: MIDI without notes');
      expect(_isMonophonic(notes), isTrue,
          reason: '${file.path}: simultaneous notes');
      withMidi++;
    }
    expect(withMidi, greaterThan(0));
  });

  test('the scores are the psalm tones, all with their MIDI', () {
    for (final file in scores) {
      final name = file.uri.pathSegments.last;
      expect(file.parent.path, endsWith(psalmTonesFilePath),
          reason: '$name is not a psalm tone score');
      expect(file.readAsStringSync(), contains('<metadata id="midi">'),
          reason: '$name has no MIDI');
    }
  });

  test('the evangelic canticles have their score', () {
    for (final code in ['NT_1', 'NT_2']) {
      expect(File('assets/$psalmTonesFilePath/$code.svg').existsSync(), isTrue,
          reason: code);
    }
  });

  test('the MIDI reaches the psalmody through svgData', () async {
    final entry = PsalmEntry(psalm: 'PSALM_109');
    await resolveOfficeContent(
      psalmody: [entry],
      dataLoader: FileSystemDataLoader(),
      psalmTones: true,
    );
    expect(entry.svgData, hasLength(1));
    expect(_midiMetadata.hasMatch(entry.svgData!.single), isTrue);
  });

  test('no score is loaded without psalmTones', () async {
    final entry = PsalmEntry(psalm: 'PSALM_109');
    await resolveOfficeContent(
      psalmody: [entry],
      dataLoader: FileSystemDataLoader(),
    );
    expect(entry.svgData, isNull);
  });
}
