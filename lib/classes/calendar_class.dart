import 'dart:developer';

import '../tools/date_tools.dart';
import '../tools/constants.dart';

class LocationOrigin {
  final String name;
  final String locative;
  const LocationOrigin({required this.name, required this.locative});
}

class DayContent {
  final int liturgicalYear;
  final String liturgicalTime;
  final String defaultCelebrationTitle;
  final int precedence;
  final String liturgicalColor;
  final int? breviaryWeek;
  final Map<int, List<String>> feastList;
  // feast key → location that added it (null = Roman calendar)
  final Map<String, LocationOrigin> feastOrigins;

  DayContent({
    required this.liturgicalYear,
    required this.liturgicalTime,
    required this.defaultCelebrationTitle,
    required this.precedence,
    required this.liturgicalColor,
    required this.breviaryWeek,
    Map<int, List<String>>? feastList,
    Map<String, LocationOrigin>? feastOrigins,
  })  : feastList = feastList ?? {},
        feastOrigins = feastOrigins ?? {};
}

class Calendar {
  final Map<DateTime, DayContent> calendarData = {};
  Calendar(); // default constructor

  void addDayContent(DateTime date, DayContent content) {
    calendarData[date] = content;
  }

  /// The day of [date], whatever its time of day or UTC/local mode (days
  /// are stored at local midnight).
  DayContent? getDayContent(DateTime date) {
    return calendarData[DateTime(date.year, date.month, date.day)];
  }

  // Returns the filename part of a key: 'france/joan_of_arc' → 'joan_of_arc'
  String _baseName(String key) {
    final slash = key.lastIndexOf('/');
    return slash == -1 ? key : key.substring(slash + 1);
  }

  /// Finds the feast of [day] whose key has the base name [baseName]
  /// (prefix-agnostic): its precedence bucket, index and stored key.
  ({int precedence, int index, String key})? _findByBaseName(
      DayContent day, String baseName) {
    for (final entry in day.feastList.entries) {
      final index = entry.value.indexWhere((k) => _baseName(k) == baseName);
      if (index >= 0) {
        return (precedence: entry.key, index: index, key: entry.value[index]);
      }
    }
    return null;
  }

  /// Removes the feast found by [_findByBaseName] from [day].
  void _removeFeast(
      DayContent day, ({int precedence, int index, String key}) found) {
    final list = day.feastList[found.precedence]!;
    list.removeAt(found.index);
    if (list.isEmpty) day.feastList.remove(found.precedence);
  }

  /// Adds or updates a feast entry.
  ///
  /// Deduplicates by base name (strips prefix). When [knownCodes] is provided
  /// and the new qualified key is absent from it (no corresponding YAML file),
  /// the existing key is preserved and only the precedence is updated.
  /// An empty [knownCodes] means "unknown" (no index loaded), like null: the
  /// new key is then taken — rather than every local key being treated as
  /// having no file and silently losing to the Roman one.
  ///
  /// Returns the key actually stored in the calendar.
  String addItemToDay(DateTime date, int precedence, String newFeastName,
      {Set<String>? knownCodes}) {
    final dayContent = calendarData[date];
    if (dayContent == null) return newFeastName;

    // Search for an existing entry with the same base name
    final existing = _findByBaseName(dayContent, _baseName(newFeastName));

    // No existing match — simply add
    if (existing == null) {
      (dayContent.feastList[precedence] ??= []).add(newFeastName);
      return newFeastName;
    }
    final existingFeastName = existing.key;

    // If newFeastName has no own YAML file, preserve the existing qualified key
    final effectiveKey = (knownCodes != null &&
            knownCodes.isNotEmpty &&
            !knownCodes.contains(newFeastName))
        ? existingFeastName
        : newFeastName;

    // Same precedence — replace in place (nothing to do for the same key)
    if (existing.precedence == precedence) {
      dayContent.feastList[precedence]![existing.index] = effectiveKey;
      return effectiveKey;
    }

    // Different precedence — remove from old bucket, add to new
    _removeFeast(dayContent, existing);
    (dayContent.feastList[precedence] ??= []).add(effectiveKey);
    return effectiveKey;
  }

  /// Adds a date related to another one: for example
  /// Notre-Dame de Fourvière on the Saturday after the 2nd Sunday of Easter
  /// The shift parameter specifies the number of days to offset from the requested date.
  String addItemRelatedToFeast(DateTime date, int shift, int precedence,
      String feastName, {Set<String>? knownCodes}) {
    return addItemToDay(date.shift(shift), precedence, feastName,
        knownCodes: knownCodes);
  }

  /// Records the originating location for a feast at [date].
  void setFeastOrigin(
      DateTime date, String feastKey, String name, String locative) {
    calendarData[date]?.feastOrigins[feastKey] =
        LocationOrigin(name: name, locative: locative);
  }

  /// Moves a feast to an absolute date, searching by base name (prefix-agnostic).
  /// If the feast exists in the calendar, it is removed from its current date
  /// and re-added at [newDate] with the qualified key preserved.
  /// If it does not exist, nothing is added — an unprefixed [feastName]
  /// would resolve to no file, and the feast would end up both at its
  /// original date and as an empty entry at [newDate] — and a warning is
  /// logged so that a misspelled `move:` entry stays visible.
  ///
  /// Returns the qualified key as found in the calendar (e.g.
  /// `roman/peter_canisius_priest`), or null if no matching entry was found.
  String? moveItemToDate(String feastName, DateTime newDate, int precedence) {
    final base = _baseName(feastName);
    for (final MapEntry(key: oldDate, value: day) in calendarData.entries) {
      final found = _findByBaseName(day, base);
      if (found == null) continue;
      if (oldDate != newDate) _removeFeast(day, found);
      addItemToDay(newDate, precedence, found.key);
      return found.key;
    }

    log('move: no feast named "$feastName" in the calendar, ignored',
        name: 'Calendar', level: 900);
    return null;
  }

  /// Downgrades obligatory memorials (precedence 10/11) to optional (12)
  /// during privileged liturgical times where memorials are not celebrated.
  /// In Advent this only applies from December 17 to 24: before Dec 17,
  /// Advent weekdays rank 13 and obligatory memorials stay obligatory.
  void downgradeMemorialsDuringPrivilegedTimes() {
    for (final MapEntry(key: date, value: dayContent) in calendarData.entries) {
      if (!privilegedTimes.contains(dayContent.liturgicalTime)) continue;
      if (dayContent.liturgicalTime == 'advent' &&
          !(date.month == 12 && date.day >= 17)) {
        continue;
      }

      // Check for precedences 10 and 11 and move them to 12
      for (final precedence in [10, 11]) {
        final feasts = dayContent.feastList[precedence];
        if (feasts == null || feasts.isEmpty) continue;

        (dayContent.feastList[12] ??= []).addAll(feasts);

        // Remove from original precedence
        dayContent.feastList.remove(precedence);
      }
    }
  }
}

// Calendar display method
// Extension for the Calendar class
extension CalendarDisplay on Calendar {
  String get formattedDisplay {
    final buffer = StringBuffer();
    buffer.writeln('📆 *Liturgical Calendar*');
    buffer.writeln('══════════════════════════════════════');
    if (calendarData.isEmpty) {
      buffer.writeln('No days recorded in the calendar.');
      return buffer.toString();
    }

    final sortedDates = calendarData.keys.toList()..sort();
    for (final date in sortedDates) {
      final content = calendarData[date]!;
      buffer.writeln('📅 ${_formatDate(date)}');
      buffer.writeln('──────────────────────────────');
      buffer.writeln('🗓️ Liturgical year   : ${content.liturgicalYear}');
      buffer.writeln('⛪ Liturgical season : ${content.liturgicalTime}');
      buffer
          .writeln('🎉 Celebration       : ${content.defaultCelebrationTitle}');
      buffer.writeln('⭐ Default precedence: ${content.precedence}');
      buffer.writeln('🎨 Liturgical color  : ${content.liturgicalColor}');
      buffer.writeln(
          '📖 Breviary week     : ${content.breviaryWeek ?? "Not specified"}');
      buffer.writeln('📌 Other celebrations:');
      if (content.feastList.isEmpty) {
        buffer.writeln('  (No additional celebrations)');
      } else {
        final sortedPriorities = content.feastList.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        for (final entry in sortedPriorities) {
          buffer.writeln(
              '  🔹 Precedence ${entry.key} : ${entry.value.join(", ")}');
        }
      }
      buffer.writeln('────────────────────────────── ');
    }
    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    return '${_pad(date.day)}/${_pad(date.month)}/${date.year}';
  }

  String _pad(int number) => number.toString().padLeft(2, '0');
}
