import '../tools/date_tools.dart';

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

    // Search for existing item - keep track of index to avoid second lookup
    int? existingPrecedence;
    int? existingIndex;
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
      dayContent.feastList.putIfAbsent(precedence, () => []);
      dayContent.feastList[precedence]!.add(newFeastName);
      return;
    }

    // Exact match at same precedence - nothing to do
    if (existingPrecedence == precedence && existingFeastName == newFeastName) {
      return;
    }

    // Same precedence but enriched name - replace in place
    // e.g. "saint_casimir" -> "lyon_saint_casimir"
    if (existingPrecedence == precedence) {
      dayContent.feastList[precedence]![existingIndex!] = newFeastName;
      return;
    }

    // Different precedence - remove from old, add to new
    final oldList = dayContent.feastList[existingPrecedence]!;
    oldList.removeAt(existingIndex!);
    if (oldList.isEmpty) {
      dayContent.feastList.remove(existingPrecedence);
    }

    dayContent.feastList.putIfAbsent(precedence, () => []);
    dayContent.feastList[precedence]!.add(newFeastName);
  }

/* LEGACY FUNCTION TO ADD NEW FEAST
  void addItemToDay(DateTime date, int precedence, String feastName) {
    final dayContent = calendarData[date];
    if (dayContent == null) return;

    // Search for existing item and remove it in a single pass
    int? existingPrecedence;
    for (var entry in dayContent.feastList.entries.toList()) {
      if (entry.value.remove(feastName)) {
        existingPrecedence = entry.key;
        // Remove the precedence key if list is now empty
        if (entry.value.isEmpty) {
          dayContent.feastList.remove(entry.key);
        }
        break;
      }
    }

    // If the item is already at the correct precedence, don't re-add it
    if (existingPrecedence == precedence) {
      // Re-add it since we removed it above
      dayContent.feastList.putIfAbsent(precedence, () => []);
      dayContent.feastList[precedence]!.add(feastName);
      return;
    }

    // Add the item to the new precedence
    dayContent.feastList.putIfAbsent(precedence, () => []);
    if (!dayContent.feastList[precedence]!.contains(feastName)) {
      dayContent.feastList[precedence]!.add(feastName);
    }
  }
*/
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
      DateTime date, int shift, int precedence, String item) {
    addItemToDay(dayShift(date, shift), precedence, item);
  }

  /// Removes a specific celebration from a given date.
  /// If the precedence list becomes empty after removal, it is removed.
  void removeCelebrationFromDay(DateTime date, String title) {
    final content = calendarData[date];
    if (content == null) return;

    // Find and remove the item, exit early once found
    for (final entry in content.feastList.entries) {
      final list = entry.value;
      if (list.remove(title)) {
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
  void moveItemByDays(String itemTitle, int shift) {
    if (shift == 0) {
      print("0-day offset: no move performed for '$itemTitle'");
      return;
    }

    // Search for the item - keep track of index to avoid second lookup
    DateTime? itemDate;
    int? itemPrecedence;
    int? itemIndex;

    outer:
    for (final entry in calendarData.entries) {
      for (final feastEntry in entry.value.feastList.entries) {
        final list = feastEntry.value;
        for (int i = 0; i < list.length; i++) {
          if (list[i] == itemTitle) {
            itemDate = entry.key;
            itemPrecedence = feastEntry.key;
            itemIndex = i;
            break outer;
          }
        }
      }
    }

    if (itemDate == null || itemPrecedence == null || itemIndex == null) {
      print("Item '$itemTitle' was not found in the calendar");
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
    final newDate = dayShift(itemDate, shift);
    addItemToDay(newDate, itemPrecedence, itemTitle);

    final direction = shift > 0 ? "moved forward" : "moved backward";
    print("Item '$itemTitle' $direction by ${shift.abs()} day(s): "
        "from ${_formatDateForLog(itemDate)} to ${_formatDateForLog(newDate)} "
        "(precedence $itemPrecedence)");
  }

  List<MapEntry<int, String>> getSortedItemsForDay(DateTime date) {
    final dayContent = calendarData[date];
    if (dayContent == null) return [];

    // Collect feastCelebrations and track min precedence in single pass
    final List<MapEntry<int, String>> feastCelebrations = [];
    int? minHighPrecedence; // smallest precedence between 1-6
    bool hasPrecedenceBelow10 = false;

    void trackPrecedence(int precedence) {
      if (precedence >= 1 && precedence <= 6) {
        minHighPrecedence =
            (minHighPrecedence == null || precedence < minHighPrecedence!)
                ? precedence
                : minHighPrecedence;
      }
      if (precedence <= 9) hasPrecedenceBelow10 = true;
    }

    // Add elements from feastList
    for (final entry in dayContent.feastList.entries) {
      final precedence = entry.key;
      trackPrecedence(precedence);
      for (final title in entry.value) {
        feastCelebrations.add(MapEntry(precedence, title));
      }
    }

    // Add default celebration
    trackPrecedence(dayContent.precedence);
    feastCelebrations.add(
        MapEntry(dayContent.precedence, dayContent.defaultCelebrationTitle));

    // Filter based on precedence rules
    if (minHighPrecedence != null) {
      // Keep only items with the highest priority (1-6)
      feastCelebrations.removeWhere((item) => item.key != minHighPrecedence);
    } else if (hasPrecedenceBelow10) {
      // Remove items with precedence > 9
      feastCelebrations.removeWhere((item) => item.key > 9);
    }

    // Adjust precedences 10/11 to 12 during Lent (memorials become optional)
    if (dayContent.liturgicalTime == "LentFeriale") {
      for (int i = 0; i < feastCelebrations.length; i++) {
        final key = feastCelebrations[i].key;
        if (key == 10 || key == 11) {
          feastCelebrations[i] = MapEntry(12, feastCelebrations[i].value);
        }
      }
    }

    feastCelebrations.sort((a, b) => a.key.compareTo(b.key));
    return feastCelebrations;
  }

  /// Utility method to format a date in logs
  String _formatDateForLog(DateTime date) {
    return '${_pad(date.day)}/${_pad(date.month)}/${date.year}';
  }

  /// Utility method to pad numbers with leading zeros
  String _pad(int number) => number.toString().padLeft(2, '0');
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

  FeastDates(
      {required this.month, required this.day, required this.precedence});
}
