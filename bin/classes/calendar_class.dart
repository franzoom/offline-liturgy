import 'dart:convert'; //sert à la conversion en JSON
import 'dart:io'; //sert à l'importation et exportation d'un fichier JSON

class DayContent {
  final int liturgicalYear;
  final String liturgicalTime;
  final String defaultCelebration;
  final int defaultPriority;
  final String defaultColor;
  final int? breviaryWeek;
  Map<int, List<String>> priority;

  DayContent({
    required this.liturgicalYear,
    required this.liturgicalTime,
    required this.defaultCelebration,
    required this.defaultPriority,
    required this.defaultColor,
    required this.breviaryWeek,
    required this.priority,
  });

//méthodes d'exportation en JSON
  Map<String, dynamic> toJson() => {
        'liturgicalYear': liturgicalYear,
        'liturgicalTime': liturgicalTime,
        'defaultCelebration': defaultCelebration,
        'defaultPriority': defaultPriority,
        'defaultColor': defaultColor,
        'breviaryWeek': breviaryWeek,
        'priority':
            priority.map((key, value) => MapEntry(key.toString(), value)),
      };
  factory DayContent.fromJson(Map<String, dynamic> json) => DayContent(
        liturgicalYear: json['liturgicalYear'],
        liturgicalTime: json['liturgicalTime'],
        defaultCelebration: json['defaultCelebration'],
        defaultPriority: json['defaultPriority'],
        defaultColor: json['defaultColor'],
        breviaryWeek: json['breviaryWeek'],
        priority: (json['priority'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(int.parse(key), List<String>.from(value)),
        ),
      );
}

class Calendar {
  final Map<DateTime, DayContent> _calendarData = {};
  Calendar(); //constructeur par défaut

  void addDayContent(DateTime date, DayContent content) {
    _calendarData[date] = content;
  }

  DayContent? getDayContent(DateTime date) {
    return _calendarData[date];
  }

  void addItemToDay(DateTime date, int priorityLevel, String item) {
    // Vérifier que la date existe pour éviter une erreur
    if (_calendarData.containsKey(date)) {
      DayContent content = _calendarData[date]!;
      // Ajouter l'élément à la bonne priorité
      if (content.priority.containsKey(priorityLevel)) {
        content.priority[priorityLevel]!.add(item);
      } else {
        content.priority[priorityLevel] = [item];
      }
    }
  }

  void addItemRelatedToFeast(
      DateTime date, int shift, int priorityLevel, String item) {
    //ajoute une date en relation avec une autre: par exemple
    // Notre-Dame de Fourvière le samedi après le 2ème dimanche de Pâques
    addItemToDay(
        DateTime(date.year, date.month, date.day + shift), priorityLevel, item);
  }

// mise en place d'un getter
  Map<DateTime, DayContent> get calendarData => _calendarData;

  /// Supprime une célébration spécifique à une date donnée.
  /// Si la liste de priorité devient vide après suppression, elle est retirée.
  void removeCelebrationFromDay(DateTime date, String title) {
    if (!_calendarData.containsKey(date)) return;
    DayContent content = _calendarData[date]!;
    final keysToRemove = <int>[];
    content.priority.forEach((priorityLevel, items) {
      items.remove(title);
      if (items.isEmpty) {
        keysToRemove.add(priorityLevel);
      }
    });
    for (var key in keysToRemove) {
      content.priority.remove(key);
    }
  }

  /// Change la priorité d'une célébration à une date donnée.
  /// Si la célébration est trouvée à une priorité plus basse, elle est déplacée à la nouvelle priorité.
  void changeCelebrationPriority(DateTime date, String title, int newPriority) {
    if (!_calendarData.containsKey(date)) return;
    DayContent content = _calendarData[date]!;
    int? currentPriority;
    // Trouver la priorité actuelle de la célébration
    content.priority.forEach((priorityLevel, items) {
      if (items.contains(title)) {
        currentPriority = priorityLevel;
      }
    });
    // Si trouvée et la nouvelle priorité est plus haute (numériquement plus basse)
    if (currentPriority != null && currentPriority != newPriority) {
      content.priority[currentPriority!]!.remove(title);
      if (content.priority[currentPriority!]!.isEmpty) {
        content.priority.remove(currentPriority);
      }
      // Ajouter à la nouvelle priorité
      if (content.priority.containsKey(newPriority)) {
        content.priority[newPriority]!.add(title);
      } else {
        content.priority[newPriority] = [title];
      }
    }
  }

//méthode de conversion en JSON
  Map<String, dynamic> toJson() => _calendarData.map(
        (key, value) => MapEntry(key.toIso8601String(), value.toJson()),
      );
  String toJsonString() => jsonEncode(toJson());

//méthode d'enregistrement du fichier JSON
  void exportToJsonFile(String filePath) {
    final jsonString = jsonEncode(toJson());
    final file = File(filePath);
    file.writeAsString(jsonString);
  }

//méthode de conversion à partir d'une chaîne JSON
  static Calendar fromJson(Map<String, dynamic> json) {
    final calendar = Calendar();
    json.forEach((key, value) {
      final date = DateTime.parse(key);
      final dayContent = DayContent.fromJson(value);
      calendar._calendarData[date] = dayContent;
    });
    return calendar;
  }

//méthode d'importation d'un fichier JSON
  static Calendar importFromJsonFile(String filePath) {
    final file = File(filePath);
    String jsonString = file.readAsStringSync(); // Lecture synchrone
    if (jsonString.trim().isEmpty) {
      jsonString = "{ }";
    }
    final jsonData = jsonDecode(jsonString);
    return Calendar.fromJson(jsonData);
  }
}

// méthode d'affichage du calendrier
// pour l'extension de la classe Calendar
extension CalendarDisplay on Calendar {
  String get formattedDisplay {
    final buffer = StringBuffer();
    buffer.writeln('📆 *Calendrier Liturgique*');
    buffer.writeln('══════════════════════════════════════');
    if (_calendarData.isEmpty) {
      buffer.writeln('Aucun jour enregistré dans le calendrier.');
      return buffer.toString();
    }

    final sortedDates = _calendarData.keys.toList()..sort();
    for (final date in sortedDates) {
      final content = _calendarData[date]!;
      buffer.writeln('📅 ${_formatDate(date)}');
      buffer.writeln('──────────────────────────────');
      buffer.writeln('🗓️ Année liturgique  : ${content.liturgicalYear}');
      buffer.writeln('⛪ Temps liturgique   : ${content.liturgicalTime}');
      buffer.writeln('🎉 Célébration        : ${content.defaultCelebration}');
      buffer.writeln('⭐ Priorité par défaut: ${content.defaultPriority}');
      buffer.writeln('🎨 Couleur liturgique : ${content.defaultColor}');
      buffer.writeln(
          '📖 Semaine bréviaire  : ${content.breviaryWeek ?? "Non spécifiée"}');
      buffer.writeln('📌 Autres célébrations :');
      if (content.priority.isEmpty) {
        buffer.writeln('  (Aucune célébration supplémentaire)');
      } else {
        final sortedPriorities = content.priority.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        for (final entry in sortedPriorities) {
          buffer.writeln(
              '  🔹 Priorité ${entry.key} : ${entry.value.join(", ")}');
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

Calendar addFeastsToCalendar(
    Calendar calendar, feastList, int liturgicalYear, generalCalendar) {
  // fonction d'ajout des calendriers. Le commun, puis les propres
  DateTime beginOfLiturgicalYear = generalCalendar['ADVENT'];
  DateTime endOfLiturgicalYear =
      generalCalendar['CHRIST_KING'].add(Duration(days: 6));
  int yearToRecord = liturgicalYear;
  feastList.forEach((key, value) {
    final int month = value.month;
    final int day = value.day;

    DateTime(liturgicalYear, month, day).isAfter(endOfLiturgicalYear)
        // l'attribution des fêtes se fait par année liturgique.
        // donc les fêtes après le Christ-Roi de l'année civile
        // appartiennent à l'année civile précédente
        ? yearToRecord = liturgicalYear - 1
        : yearToRecord = liturgicalYear;

    if (DateTime(yearToRecord, month, day).isAfter(beginOfLiturgicalYear) &&
        DateTime(yearToRecord, month, day).isBefore(endOfLiturgicalYear))
    // si la date est comprise entre le début et la fin de l'année liturgique
    // (car par exemple en 2025 le 30 novembre n'est pas dans l'année liturgique !)
    {
      calendar.addItemToDay(
          DateTime(yearToRecord, month, day), value.priority, key);
    }
  });
  return calendar;
}
