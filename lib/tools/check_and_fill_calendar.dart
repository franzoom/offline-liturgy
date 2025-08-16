import 'dart:convert';
import 'dart:io';
import '../main_calendar_fill.dart';
import '../classes/calendar_class.dart';

Calendar checkAndFillCalendar(
    Calendar calendar, DateTime date, String location) {
  // fonction d'ajout des années manquantes si besoin
  final calendarFile = File('./lib/assets/calendar.json');
  String savedLocation = locationRead();

  if (!calendarFile.existsSync() || savedLocation != location) {
    // si le fichier de calendrier n'existe pas, ou que la localisation a changé, laner le calcul du calendrier
    calendar.calendarData
        .addAll(calendarFill(calendar, date.year, location).calendarData);
    calendar.exportToJsonFile('./lib/assets/calendar.json');
    locationSave(location);
    return calendar;
  } else {
    String jsonString = calendarFile.readAsStringSync(); // Lecture synchrone
    if (jsonString.trim().isEmpty) {
      // vérifier que le fichier n'est pas vide, auquel cas le rempli de l'année demandé
      calendar.calendarData
          .addAll(calendarFill(calendar, date.year, location).calendarData);
      calendar.exportToJsonFile('./lib/assets/calendar.json');
      return calendar;
    }
    // si le fichier existe et n'est pas vide, le lire
    calendar = Calendar.importFromJsonFile('./bin/assets/calendar.json');
    if (calendar.calendarData.isEmpty) {
      calendar.calendarData.addAll(calendarFill(calendar, date.year, location)
          as Map<DateTime, DayContent>);
      calendar.exportToJsonFile('./lib/assets/calendar.json');
      return calendar;
    }
  }
// Si le fichier ne contenait pas la date demandée, on rajoute les années manquantes.
  DateTime firstDate = calendar.calendarData.keys.first;
  DateTime lastDate = calendar.calendarData.keys.last;
  if (date.isBefore(firstDate)) {
    calendar = Calendar();
    for (int year = date.year; year <= firstDate.year; year++) {
      calendar = calendarFill(calendar, year, location);
    }
  } else if (date.isAfter(lastDate)) {
    for (int year = lastDate.year + 1; year <= date.year; year++) {
      calendar = calendarFill(calendar, year, location);
    }
  }

  calendar.exportToJsonFile('./lib/assets/calendar.json');

  return calendar;
}

String locationRead() {
  // fonction de lecture de la localisation dans le fichier parameters.json
  final parametersFile = File('./lib/assets/parameters.json');
  String location = "";
  if (!parametersFile.existsSync()) {
    // si le fichier de paramètres n'existe pas, le créer vide.
    parametersFile.writeAsString(jsonEncode({}));
    return location;
  }
  final fileContents = parametersFile.readAsStringSync();
  if (fileContents.trim().isNotEmpty) {
    final parametersData = jsonDecode(fileContents);
    return parametersData['location'] ?? "";
  }
  return "";
}

void locationSave(String location) {
  // fonction d'enregistrement du paramètre de localisation dans le fichier parameters.json
  Map<String, dynamic> parametersData = {
    'location': location,
  };
  final parametersFile = File('./lib/assets/parameters.json');
  // que le fichier existe ou non, écrire la clef. Ca créera le fichier si besoin.
  parametersFile.writeAsString(jsonEncode(parametersData));
}
