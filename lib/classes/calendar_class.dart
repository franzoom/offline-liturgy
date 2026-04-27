import '../tools/date_tools.dart';
import '../tools/constants.dart';

class DayContent {
  final int liturgicalYear;
  final String liturgicalTime;
  final String defaultCelebrationTitle;
  final int precedence;
  final String liturgicalColor;
  final int? breviaryWeek;
  final Map<int, List<String>>
      feastList; // Map is mutable internally, but reference is final

  DayContent({
    required this.liturgicalYear,
    required this.liturgicalTime,
    required this.defaultCelebrationTitle,
    required this.precedence,
    required this.liturgicalColor,
    required this.breviaryWeek,
    required this.feastList,
  });
}

class Calendar {
  final Map<DateTime, DayContent> calendarData = {};
  Calendar(); // default constructor

  void addDayContent(DateTime date, DayContent content) {
    calendarData[date] = content;
  }

  DayContent? getDayContent(DateTime date) {
    return calendarData[date];
  }

  void addItemToDay(DateTime date, int precedence, String newFeastName) {
    final dayContent = calendarData[date];
    if (dayContent == null) return;

    // Search for existing item
    int? existingPrecedence;
    int existingIndex = 0;
    String? existingFeastName;

    outer:
    for (var entry in dayContent.feastList.entries) {
      final list = entry.value;
      for (int i = 0; i < list.length; i++) {
        if (newFeastName.contains(list[i])) {
          existingPrecedence = entry.key;
          existingIndex = i;
          existingFeastName = list[i];
          break outer;
        }
      }
    }

    // No existing match found - simply add
    if (existingFeastName == null) {
      (dayContent.feastList[precedence] ??= []).add(newFeastName);
      return;
    }

    // Exact match at same precedence - nothing to do
    if (existingPrecedence == precedence && existingFeastName == newFeastName) {
      return;
    }

    // Same precedence but enriched name - replace in place
    // e.g. "saint_casimir" -> "lyon_saint_casimir"
    if (existingPrecedence == precedence) {
      dayContent.feastList[precedence]![existingIndex] = newFeastName;
      return;
    }

    // Different precedence - remove from old, add to new
    final oldList = dayContent.feastList[existingPrecedence]!;
    oldList.removeAt(existingIndex);
    if (oldList.isEmpty) {
      dayContent.feastList.remove(existingPrecedence);
    }

    (dayContent.feastList[precedence] ??= []).add(newFeastName);
  }

  void addFeastsToCalendar(Map<String, FeastDates> feastList,
      int liturgicalYear, Map<String, DateTime> liturgicalMainFeasts) {
    final beginOfLiturgicalYear = liturgicalMainFeasts['ADVENT']!;
    final endOfLiturgicalYear =
        liturgicalMainFeasts['CHRIST_KING']!.add(const Duration(days: 6));
    final previousYear = liturgicalYear - 1;

    for (final entry in feastList.entries) {
      final feastName = entry.key;
      final feastData = entry.value;

      // Try current liturgical year first
      var feastDate = DateTime(liturgicalYear, feastData.month, feastData.day);

      // If after end of liturgical year, use previous calendar year
      if (feastDate.isAfter(endOfLiturgicalYear)) {
        feastDate = DateTime(previousYear, feastData.month, feastData.day);
      }

      // Check if within liturgical year bounds (inclusive on start)
      if (!feastDate.isBefore(beginOfLiturgicalYear) &&
          feastDate.isBefore(endOfLiturgicalYear)) {
        addItemToDay(feastDate, feastData.precedence, feastName);
      }
    }
  }

  /// Adds a date related to another one: for example
  /// Notre-Dame de Fourvière on the Saturday after the 2nd Sunday of Easter
  /// The shift parameter specifies the number of days to offset from the requested date.
  void addItemRelatedToFeast(
      DateTime date, int shift, int precedence, String feastName) {
    addItemToDay(date.shift(shift), precedence, feastName);
  }

  /// Removes a specific celebration from a given date.
  /// If the precedence list becomes empty after removal, it is removed.
  void removeCelebrationFromDay(DateTime date, String feastName) {
    final content = calendarData[date];
    if (content == null) return;

    // Find and remove the item, exit early once found
    for (final entry in content.feastList.entries) {
      final list = entry.value;
      if (list.remove(feastName)) {
        if (list.isEmpty) {
          content.feastList.remove(entry.key);
        }
        return; // Item found and removed, done
      }
    }
  }

  /// Moves an item by applying a day offset from its current position.
  /// The offset can be positive (forward in time) or negative (backward in time).
  /// If the item exists at multiple dates, only the first occurrence found will be moved.
  void moveItemByDays(String feastName, int shift) {
    if (shift == 0) return;

    // Search for the item - keep track of index to avoid second lookup
    DateTime? itemDate;
    int? itemPrecedence;
    int? itemIndex;

    outer:
    for (final entry in calendarData.entries) {
      for (final feastEntry in entry.value.feastList.entries) {
        final list = feastEntry.value;
        for (int i = 0; i < list.length; i++) {
          if (list[i] == feastName) {
            itemDate = entry.key;
            itemPrecedence = feastEntry.key;
            itemIndex = i;
            break outer;
          }
        }
      }
    }

    if (itemDate == null || itemPrecedence == null || itemIndex == null) {
      return;
    }

    // Remove from old date directly (no second search)
    final oldContent = calendarData[itemDate]!;
    final oldList = oldContent.feastList[itemPrecedence]!;
    oldList.removeAt(itemIndex);
    if (oldList.isEmpty) {
      oldContent.feastList.remove(itemPrecedence);
    }

    // Add to new date
    final newDate = itemDate.shift(shift);
    addItemToDay(newDate, itemPrecedence, feastName);
  }

  /// Removes a feast by name from all dates in the calendar.
  void removeFeastFromCalendar(String feastName) {
    for (final dayContent in calendarData.values) {
      for (final entry in dayContent.feastList.entries.toList()) {
        if (entry.value.remove(feastName)) {
          if (entry.value.isEmpty) dayContent.feastList.remove(entry.key);
          return;
        }
      }
    }
  }

  /// Moves a feast to an absolute date. If the feast already exists in the
  /// calendar at a different date, it is removed from the old location first.
  /// If it does not exist yet, it is simply added at [newDate].
  void moveItemToDate(String feastName, DateTime newDate, int precedence) {
    DateTime? oldDate;
    int? oldPrecedence;
    int? oldIndex;

    outer:
    for (final entry in calendarData.entries) {
      for (final feastEntry in entry.value.feastList.entries) {
        final list = feastEntry.value;
        for (int i = 0; i < list.length; i++) {
          if (list[i] == feastName) {
            oldDate = entry.key;
            oldPrecedence = feastEntry.key;
            oldIndex = i;
            break outer;
          }
        }
      }
    }

    if (oldDate != null && oldDate != newDate) {
      final oldContent = calendarData[oldDate]!;
      final oldList = oldContent.feastList[oldPrecedence!]!;
      oldList.removeAt(oldIndex!);
      if (oldList.isEmpty) oldContent.feastList.remove(oldPrecedence);
    }

    addItemToDay(newDate, precedence, feastName);
  }

  /// Like [moveItemToDate] but only searches for an existing entry within
  /// [beginYear, endYear). This prevents a location feast added during the
  /// first liturgical-year pass from being erroneously removed when
  /// [getCalendar] processes the second year.
  void moveItemToDateInRange(
    String feastName,
    DateTime newDate,
    int precedence,
    DateTime beginYear,
    DateTime endYear,
  ) {
    DateTime? oldDate;
    int? oldPrecedence;
    int? oldIndex;

    outer:
    for (final entry in calendarData.entries) {
      final date = entry.key;
      if (date.isBefore(beginYear) || !date.isBefore(endYear)) continue;
      for (final feastEntry in entry.value.feastList.entries) {
        final list = feastEntry.value;
        for (int i = 0; i < list.length; i++) {
          if (list[i] == feastName) {
            oldDate = date;
            oldPrecedence = feastEntry.key;
            oldIndex = i;
            break outer;
          }
        }
      }
    }

    if (oldDate != null && oldDate != newDate) {
      final oldContent = calendarData[oldDate]!;
      final oldList = oldContent.feastList[oldPrecedence!]!;
      oldList.removeAt(oldIndex!);
      if (oldList.isEmpty) oldContent.feastList.remove(oldPrecedence);
    }

    addItemToDay(newDate, precedence, feastName);
  }

  /// Downgrades obligatory memorials (precedence 10/11) to optional (12)
  /// during privileged liturgical times where memorials are not celebrated.
  void downgradeMemorialsDuringPrivilegedTimes() {
    for (final dayContent in calendarData.values) {
      if (!privilegedTimes.contains(dayContent.liturgicalTime)) continue;

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

/// class used to transmit informations to calendar events recording
class FeastDates {
  final int month;
  final int day;
  final int precedence;

  const FeastDates(
      {required this.month, required this.day, required this.precedence});
}

/// Short alias for FeastDates to allow for a readable const Map.
class F extends FeastDates {
  const F(int m, int d, int p) : super(month: m, day: d, precedence: p);
}
