import 'dart:convert'; //sert à la conversion en JSON
import 'dart:io'; //sert à l'importation et exportation d'un fichier JSON

class DayContent {
  final int liturgicalYear;
  final String liturgicalTime;
  final String defaultCelebrationTitle;
  final int liturgicalGrade;
  final String liturgicalColor;
  final int? breviaryWeek;
  Map<int, List<String>> priority;

  DayContent({
    required this.liturgicalYear,
    required this.liturgicalTime,
    required this.defaultCelebrationTitle,
    required this.liturgicalGrade,
    required this.liturgicalColor,
    required this.breviaryWeek,
    required this.priority,
  });

//JSON export method
  Map<String, dynamic> toJson() => {
        'liturgicalYear': liturgicalYear,
        'liturgicalTime': liturgicalTime,
        'defaultCelebrationTitle': defaultCelebrationTitle,
        'liturgicalGrade': liturgicalGrade,
        'liturgicalColor': liturgicalColor,
        'breviaryWeek': breviaryWeek,
        'priority':
            priority.map((key, value) => MapEntry(key.toString(), value)),
      };
  factory DayContent.fromJson(Map<String, dynamic> json) => DayContent(
        liturgicalYear: json['liturgicalYear'],
        liturgicalTime: json['liturgicalTime'],
        defaultCelebrationTitle: json['defaultCelebrationTitle'],
        liturgicalGrade: json['liturgicalGrade'],
        liturgicalColor: json['liturgicalColor'],
        breviaryWeek: json['breviaryWeek'],
        priority: (json['priority'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(int.parse(key), List<String>.from(value)),
        ),
      );
}

class Calendar {
  final Map<DateTime, DayContent> _calendarData = {};
  Calendar(); //constructeur par défaut

  // mise en place d'un getter
  Map<DateTime, DayContent> get calendarData => _calendarData;

  void addDayContent(DateTime date, DayContent content) {
    _calendarData[date] = content;
  }

  DayContent? getDayContent(DateTime date) {
    return _calendarData[date];
  }

  void addItemToDay(DateTime date, int priorityLevel, String item) {
    if (_calendarData.containsKey(date)) {
      DayContent dayContent = _calendarData[date]!;
      // Trouver la priorité actuelle de l'item, s'il existe
      int? existingPriority = dayContent.priority.entries
          .firstWhere(
            (entry) => entry.value.contains(item),
            orElse: () => const MapEntry(-1, []),
          )
          .key;
      // Si l'item est déjà à la bonne priorité, ne rien faire
      if (existingPriority == priorityLevel) return;
      // Si l'item existe à une autre priorité (logiquement moins importante), le supprimer
      if (existingPriority != -1) {
        removeCelebrationFromDay(date, item);
      }
      // Ajouter l'item à la nouvelle priorité sans écraser les autres
      dayContent.priority.putIfAbsent(priorityLevel, () => []);
      if (!dayContent.priority[priorityLevel]!.contains(item)) {
        dayContent.priority[priorityLevel]!.add(item);
      }
    }
  }

  void addFeastsToCalendar(Map<String, dynamic> feastList, int liturgicalYear,
      Map<String, DateTime> generalCalendar) {
    DateTime beginOfLiturgicalYear = generalCalendar['ADVENT']!;
    DateTime endOfLiturgicalYear =
        generalCalendar['CHRIST_KING']!.add(Duration(days: 6));
    int yearToRecord = liturgicalYear;

    feastList.forEach((key, value) {
      final int month = value.month;
      final int day = value.day;

      yearToRecord =
          DateTime(liturgicalYear, month, day).isAfter(endOfLiturgicalYear)
              ? liturgicalYear - 1
              : liturgicalYear;

      DateTime feastDate = DateTime(yearToRecord, month, day);
      if (feastDate.isAfter(beginOfLiturgicalYear) &&
          feastDate.isBefore(endOfLiturgicalYear)) {
        addItemToDay(feastDate, value.priority, key);
      }
    });
  }

  void addItemRelatedToFeast(
      DateTime date, int shift, int priorityLevel, String item) {
    //ajoute une date en relation avec une autre: par exemple
    // Notre-Dame de Fourvière le samedi après le 2ème dimanche de Pâques
    // on donne le shift de jours pour décaler du nombre de jour par rapport à la date demandée.
    addItemToDay(
        DateTime(date.year, date.month, date.day + shift), priorityLevel, item);
  }

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

  /// Déplace un item en appliquant un décalage en jours par rapport à sa position actuelle.
  /// Le décalage peut être positif (avancer dans le temps) ou négatif (reculer dans le temps).
  /// Si l'item existe à plusieurs dates, seule la première occurrence trouvée sera déplacée.
  void moveItemByDays(String itemTitle, int dayShift) {
    // Chercher l'item dans tout le calendrier
    DateTime? itemDate;
    int? itemPriority;
    bool itemFound = false;

    // Parcourir toutes les dates du calendrier
    _calendarData.forEach((date, dayContent) {
      if (!itemFound) {
        // Chercher dans les priorités
        dayContent.priority.forEach((priorityLevel, items) {
          if (!itemFound && items.contains(itemTitle)) {
            itemDate = date;
            itemPriority = priorityLevel;
            itemFound = true;
          }
        });
      }
    });

    // Si l'item n'est pas trouvé
    if (!itemFound) {
      print("L'item '$itemTitle' n'a pas été trouvé dans le calendrier");
      return;
    }

    // Si le décalage est 0, ne rien faire
    if (dayShift == 0) {
      print(
          "Décalage de 0 jour : aucun déplacement effectué pour '$itemTitle'");
      return;
    }

    // Calculer la nouvelle date
    DateTime newDate = itemDate!.add(Duration(days: dayShift));

    // Supprimer l'item de sa position actuelle
    removeCelebrationFromDay(itemDate!, itemTitle);

    // Ajouter l'item à la nouvelle date avec la même priorité
    addItemToDay(newDate, itemPriority!, itemTitle);

    String direction = dayShift > 0 ? "avancé" : "reculé";
    print("Item '$itemTitle' ${direction} de ${dayShift.abs()} jour(s) : "
        "de ${_formatDateForLog(itemDate!)} vers ${_formatDateForLog(newDate)} "
        "(priorité $itemPriority)");
  }

  /// Méthode utilitaire pour formater une date dans les logs
  String _formatDateForLog(DateTime date) {
    return '${_pad(date.day)}/${_pad(date.month)}/${date.year}';
  }

  String _pad(int number) => number.toString().padLeft(2, '0');

  List<MapEntry<int, String>> getSortedItemsForDay(DateTime date) {
    final dayContent = _calendarData[date];
    if (dayContent == null) return [];
    String liturgicalTime = dayContent.liturgicalTime;
    final List<MapEntry<int, String>> items = [];
    // Ajouter les éléments de la map priority
    dayContent.priority.forEach((priorityNumber, titles) {
      for (var title in titles) {
        items.add(MapEntry(priorityNumber, title));
      }
    });
    // Ajouter la célébration par défaut
    items.add(MapEntry(
        dayContent.liturgicalGrade, dayContent.defaultCelebrationTitle));
    // MODULE DE SUPPRESSION DES FÊTES DONT LA PRÉSÉANCES EST TROP FAIBLE
    // Déterminer la priorité la plus importante (la plus basse entre 1 et 6)
    // Étape 1 : chercher la plus petite priorité entre 1 et 6
    int? minPriority;
    for (int i = 1; i <= 6; i++) {
      if (items.any((item) => item.key == i)) {
        minPriority = i;
        break;
      }
    }
    if (minPriority != null) {
      // Garder uniquement les éléments avec cette priorité
      items.removeWhere((item) => item.key != minPriority);
    } else {
      // Étape 2 : s'il y a une priorité ≤ 9, supprimer celles > 9
      final hasPriorityBelowOrEqual9 = items.any((item) => item.key <= 9);
      if (hasPriorityBelowOrEqual9) {
        items.removeWhere((item) => item.key > 9);
      }
    }

    // Étape 3 : ajuster les priorités 10 ou 11 à 12 si liturgicalTime == "LentFeriale"
    // les méoire obligatoires deviennent facultatives pendant le Carême
    if (liturgicalTime == "LentFeriale") {
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        if (item.key == 10 || item.key == 11) {
          items[i] = MapEntry(12, item.value);
        }
      }
    }

    // Trier ce qui reste par priorité croissante
    items.sort((a, b) => a.key.compareTo(b.key));
    return items;
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
      buffer.writeln(
          '🎉 Célébration        : ${content.defaultCelebrationTitle}');
      buffer.writeln('⭐ Priorité par défaut: ${content.liturgicalGrade}');
      buffer.writeln('🎨 Couleur liturgique : ${content.liturgicalColor}');
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
