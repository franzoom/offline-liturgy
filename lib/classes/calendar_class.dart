class DayContent {
  final int liturgicalYear;
  final String liturgicalTime;
  final String defaultCelebrationTitle;
  final int precedence;
  final String liturgicalColor;
  final int? breviaryWeek;
  Map<int, List<String>> feastList;

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

  void addItemToDay(DateTime date, int precedence, String item) {
    if (calendarData.containsKey(date)) {
      DayContent dayContent = calendarData[date]!;
      // Find the current precedence of the item, if it exists
      int? existingPrecedence = dayContent.feastList.entries
          .firstWhere(
            (entry) => entry.value.contains(item),
            orElse: () => const MapEntry(-1, []),
          )
          .key;
      // If the item is already at the correct precedence, do nothing
      if (existingPrecedence == precedence) return;
      // If the item exists at another precedence (logically less important), remove it
      if (existingPrecedence != -1) {
        removeCelebrationFromDay(date, item);
      }
      // Add the item to the new precedence without overwriting others
      dayContent.feastList.putIfAbsent(precedence, () => []);
      if (!dayContent.feastList[precedence]!.contains(item)) {
        dayContent.feastList[precedence]!.add(item);
      }
    }
  }

  void addFeastsToCalendar(Map<String, dynamic> feastList, int liturgicalYear,
      Map<String, DateTime> generalCalendar) {
    DateTime beginOfLiturgicalYear = generalCalendar['ADVENT']!;
    DateTime endOfLiturgicalYear =
        generalCalendar['CHRIST_KING']!.add(Duration(days: 6));
    int yearToRecord = liturgicalYear;

    feastList.forEach((precedence, feastTitle) {
      final int month = feastTitle.month;
      final int day = feastTitle.day;

      yearToRecord =
          DateTime(liturgicalYear, month, day).isAfter(endOfLiturgicalYear)
              ? liturgicalYear - 1
              : liturgicalYear;

      DateTime feastDate = DateTime(yearToRecord, month, day);
      if (feastDate.isAfter(beginOfLiturgicalYear) &&
          feastDate.isBefore(endOfLiturgicalYear)) {
        addItemToDay(feastDate, feastTitle.precedence, precedence);
      }
    });
  }

  /// Adds a date related to another one: for example
  /// Notre-Dame de Fourvière on the Saturday after the 2nd Sunday of Easter
  /// The shift parameter specifies the number of days to offset from the requested date.
  void addItemRelatedToFeast(
      DateTime date, int shift, int precedence, String item) {
    addItemToDay(
        DateTime(date.year, date.month, date.day + shift), precedence, item);
  }

  /// Removes a specific celebration from a given date.
  /// If the precedence list becomes empty after removal, it is removed.
  void removeCelebrationFromDay(DateTime date, String title) {
    if (!calendarData.containsKey(date)) return;
    DayContent content = calendarData[date]!;
    final keysToRemove = <int>[];
    content.feastList.forEach((precedence, items) {
      items.remove(title);
      if (items.isEmpty) {
        keysToRemove.add(precedence);
      }
    });
    for (var key in keysToRemove) {
      content.feastList.remove(key);
    }
  }

  /// Moves an item by applying a day offset from its current position.
  /// The offset can be positive (forward in time) or negative (backward in time).
  /// If the item exists at multiple dates, only the first occurrence found will be moved.
  void moveItemByDays(String itemTitle, int dayShift) {
    DateTime? itemDate;
    int? itemPrecedence;
    bool itemFound = false;

    if (dayShift == 0) {
      print("0-day offset: no move performed for '$itemTitle'");
      return;
    }

    // Iterate through all calendar dates
    calendarData.forEach((date, dayContent) {
      if (!itemFound) {
        // Search in precedences
        dayContent.feastList.forEach((precedence, items) {
          if (!itemFound && items.contains(itemTitle)) {
            itemDate = date;
            itemPrecedence = precedence;
            itemFound = true;
          }
        });
      }
    });

    if (!itemFound) {
      print("Item '$itemTitle' was not found in the calendar");
      return;
    }

    DateTime newDate = itemDate!.add(Duration(days: dayShift));
    removeCelebrationFromDay(itemDate!, itemTitle);
    addItemToDay(newDate, itemPrecedence!, itemTitle);

    String direction = dayShift > 0 ? "moved forward" : "moved backward";
    print("Item '$itemTitle' $direction by ${dayShift.abs()} day(s): "
        "from ${_formatDateForLog(itemDate!)} to ${_formatDateForLog(newDate)} "
        "(precedence $itemPrecedence)");
  }

  List<MapEntry<int, String>> getSortedItemsForDay(DateTime date) {
    final dayContent = calendarData[date];
    if (dayContent == null) return [];
    String liturgicalTime = dayContent.liturgicalTime;
    final List<MapEntry<int, String>> items = [];
    // Add elements from the feastList map
    dayContent.feastList.forEach((precedence, titles) {
      for (var title in titles) {
        items.add(MapEntry(precedence, title));
      }
    });
    // Add the default celebration
    items.add(
        MapEntry(dayContent.precedence, dayContent.defaultCelebrationTitle));
    // MODULE FOR REMOVING FEASTS WITH TOO LOW PRECEDENCE
    // Determine the most important precedence (the lowest between 1 and 6)
    // Step 1: search for the smallest precedence between 1 and 6
    int? minPrecedence;
    for (int i = 1; i <= 6; i++) {
      if (items.any((item) => item.key == i)) {
        minPrecedence = i;
        break;
      }
    }
    if (minPrecedence != null) {
      // Keep only elements with this precedence
      items.removeWhere((item) => item.key != minPrecedence);
    } else {
      // Step 2: if there is a precedence ≤ 9, remove those > 9
      final hasPrecedenceBelowOrEqual9 = items.any((item) => item.key <= 9);
      if (hasPrecedenceBelowOrEqual9) {
        items.removeWhere((item) => item.key > 9);
      }
    }

    // Step 3: adjust precedences 10 or 11 to 12 if liturgicalTime == "LentFeriale"
    // obligatory memorials become optional during Lent
    if (liturgicalTime == "LentFeriale") {
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        if (item.key == 10 || item.key == 11) {
          items[i] = MapEntry(12, item.value);
        }
      }
    }

    items.sort((a, b) => a.key.compareTo(b.key));
    return items;
  }

  /// Utility method to format a date in logs
  String _formatDateForLog(DateTime date) {
    return '${_pad(date.day)}/${_pad(date.month)}/${date.year}';
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
