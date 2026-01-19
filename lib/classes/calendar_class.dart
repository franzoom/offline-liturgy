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

class FeastItem {
  final int precedence;
  final String celebrationTitle;
  final String? color;
  final bool celebrable;

  const FeastItem({
    required this.precedence,
    required this.celebrationTitle,
    this.color,
    required this.celebrable,
  });

  @override
  String toString() =>
      'FeastItem(precedence=$precedence, celebrable=$celebrable, title="$celebrationTitle")';
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
    addItemToDay(dayShift(date, shift), precedence, feastName);
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
    final newDate = dayShift(itemDate, shift);
    addItemToDay(newDate, itemPrecedence, feastName);
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

        // Add to precedence 12
        dayContent.feastList.putIfAbsent(12, () => []);
        dayContent.feastList[12]!.addAll(feasts);

        // Remove from original precedence
        dayContent.feastList.remove(precedence);
      }
    }
  }

///////////
  ///
  /// Returns a Record containing the day's global info and the sorted list of feasts.
  /// The return type is nullable (?) because the date might not exist in the calendar.
  ({
    String liturgicalTime,
    String color,
    int? breviaryWeek,
    List<FeastItem> celebrationList,
  })? getSortedItemsForDay2(DateTime date) {
    final dayContent = calendarData[date];
    if (dayContent == null) return null;

    // --- 1. Calculate "Celebrable" logic (minHigh) ---
    // We determine the highest priority (lowest precedence value) present on this day.
    int? minHigh;

    // Check if the default celebration is high priority (1-6)
    if (dayContent.precedence >= 1 && dayContent.precedence <= 6) {
      minHigh = dayContent.precedence;
    }

    // Check if any added feast is high priority (1-6)
    for (final precedence in dayContent.feastList.keys) {
      if (precedence >= 1 && precedence <= 6) {
        if (minHigh == null || precedence < minHigh) {
          minHigh = precedence;
        }
      }
    }

    final bool hasHighPriorityFeast = minHigh != null;

    // Use an internal record for sorting before converting to FeastItem
    final tempItems = <({
      int precedence,
      String celebrationTitle,
      bool fromFeastList,
      bool celebrable
    })>[];

    // --- 2. Build the temporary list ---

    // A. Add items from feastList
    for (final entry in dayContent.feastList.entries) {
      final precedence = entry.key;
      // Safety check: ensure the list is not empty
      if (entry.value.isNotEmpty) {
        tempItems.add((
          precedence: precedence,
          celebrationTitle: entry.value.first,
          fromFeastList: true,
          // If a high-priority feast exists (1-6), only items in that range are celebrable
          celebrable: hasHighPriorityFeast
              ? (precedence >= 1 && precedence <= 6)
              : true,
        ));
      }
    }

    // B. Add the default celebration item
    final defaultPrecedence = dayContent.precedence;
    tempItems.add((
      precedence: defaultPrecedence,
      celebrationTitle: dayContent.defaultCelebrationTitle,
      fromFeastList: false,
      celebrable: hasHighPriorityFeast
          ? (defaultPrecedence >= 1 && defaultPrecedence <= 6)
          : true,
    ));

    // --- 3. Optimized Sort ---
    tempItems.sort((a, b) {
      // Priority 1: Precedence value (lower is more important)
      if (a.precedence != b.precedence) {
        return a.precedence.compareTo(b.precedence);
      }
      // Priority 2: If tied, items from feastList take precedence over the default
      if (a.fromFeastList != b.fromFeastList) {
        return a.fromFeastList ? -1 : 1;
      }
      return 0;
    });

    // --- 4. Final conversion to FeastItem ---
    final finalItems = tempItems
        .map((it) => FeastItem(
              precedence: it.precedence,
              celebrationTitle: it.celebrationTitle,
              celebrable: it.celebrable,
            ))
        .toList();

    // --- 5. Return the complete Record ---
    return (
      liturgicalTime: dayContent.liturgicalTime,
      color: dayContent.liturgicalColor, // Maps "liturgicalColor" to "color"
      breviaryWeek: dayContent.breviaryWeek,
      celebrationList: finalItems,
    );
  }

//////////

  /// function that returns the list of Feasts for the day
  /// sorted by precedence.
  /// If there is a precedence higher than 6, the lower feasts are no
  /// more celebrable.
  List<FeastItem> getSortedItemsForDay(DateTime date) {
    final dayContent = calendarData[date];
    if (dayContent == null) return [];

    // 1. Identify minHigh
    int? minHigh;

    if (dayContent.precedence >= 1 && dayContent.precedence <= 6) {
      minHigh = dayContent.precedence;
    }

    for (final precedence in dayContent.feastList.keys) {
      if (precedence >= 1 && precedence <= 6) {
        if (minHigh == null || precedence < minHigh) {
          minHigh = precedence;
        }
      }
    }

    final bool hasHighPriorityFeast = minHigh != null;
    final celebrationList = <({
      int precedence,
      String celebrationTitle,
      bool fromFeastList,
      bool celebrable
    })>[];

    // 2. Add feastList item
    for (final entry in dayContent.feastList.entries) {
      final precedence = entry.key;
      celebrationList.add((
        precedence: precedence,
        celebrationTitle: entry.value.first,
        fromFeastList: true,
        celebrable:
            hasHighPriorityFeast ? (precedence >= 1 && precedence <= 6) : true,
      ));
    }

    // 3. Add default item
    final defaultPrecedence = dayContent.precedence;
    celebrationList.add((
      precedence: defaultPrecedence,
      celebrationTitle: dayContent.defaultCelebrationTitle,
      fromFeastList: false,
      celebrable: hasHighPriorityFeast
          ? (defaultPrecedence >= 1 && defaultPrecedence <= 6)
          : true,
    ));

    // 4. Sort
    celebrationList.sort((a, b) {
      if (a.precedence != b.precedence) {
        return a.precedence.compareTo(b.precedence);
      }
      if (a.fromFeastList != b.fromFeastList) {
        return a.fromFeastList ? -1 : 1;
      }
      return 0;
    });

    // 5. Map
    return celebrationList
        .map((celebration) => FeastItem(
              precedence: celebration.precedence,
              celebrationTitle: celebration.celebrationTitle,
              celebrable: celebration.celebrable,
            ))
        .toList();
  }
}

/*

  /// !!! Ordinary Time must be displayed before facultative memorials
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

    feastCelebrations.sort((a, b) => a.key.compareTo(b.key));
    return feastCelebrations;
  }
  */

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
