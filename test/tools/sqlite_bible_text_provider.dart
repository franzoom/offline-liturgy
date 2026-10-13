import 'dart:io';

import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:sqlite3/sqlite3.dart';

/// Bible database of the aelf-flutter app, next to this package.
/// Override with the BIBLE_DB environment variable.
String get bibleDbPath =>
    Platform.environment['BIBLE_DB'] ?? '../aelf-flutter/assets/bible.db';

/// [BibleTextProvider] reading the aelf-flutter Bible database (table
/// `verses`: book, chapter, verse, text), for tests and CLI tools.
/// Verses are returned in row order, which keeps lettered sub-verses
/// ('1a', '1b'...) right after their verse. Rows without a verse number
/// (speaker labels of the Song of Songs, 'Alléluia' headings...) are kept
/// with an empty label: they are read when they fall inside a range.
class SqliteBibleTextProvider implements BibleTextProvider {
  final Database _db;
  final Map<String, List<BibleVerse>?> _cache = {};

  SqliteBibleTextProvider(String path)
      : _db = sqlite3.open(path, mode: OpenMode.readOnly);

  @override
  Future<List<BibleVerse>?> chapter(String book, String chapter) async {
    return _cache.putIfAbsent('$book $chapter', () {
      final rows = _db.select(
          'SELECT verse, text FROM verses WHERE book = ? AND chapter = ? '
          'ORDER BY rowid',
          [book, chapter]);
      if (rows.isEmpty) return null;
      return [
        for (final r in rows)
          BibleVerse((r['verse'] as String?) ?? '', (r['text'] as String?) ?? ''),
      ];
    });
  }

  void close() => _db.close();
}
