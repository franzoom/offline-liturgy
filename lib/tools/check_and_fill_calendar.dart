import 'dart:convert';
import 'dart:io';
import '../feasts/main_calendar_fill.dart';
import '../classes/calendar_class.dart';

Calendar checkAndFillCalendar(
    Calendar calendar, DateTime date, String location) {
  // adding the missing years, if needed
  final calendarFile = File('./lib/assets/calendar.json');
  String savedLocation = locationRead();

  if (!calendarFile.existsSync() || savedLocation != location) {
    // if calendar.json doesn't exist, of if the location has changed, run the calendar calculation
    calendar.calendarData
        .addAll(calendarFill(calendar, date, location).calendarData);
    calendar.exportToJsonFile('./lib/assets/calendar.json');
    locationSave(location);
    return calendar;
  } else {
    String jsonString = calendarFile.readAsStringSync(); // synchronous read
    if (jsonString.trim().isEmpty) {
      // vérifier que le fichier n'est pas vide, auquel cas le remplir de l'année demandé
      calendar.calendarData
          .addAll(calendarFill(calendar, date, location).calendarData);
      calendar.exportToJsonFile('./lib/assets/calendar.json');
      return calendar;
    }
    // si le fichier existe et n'est pas vide, le lire
    calendar = Calendar.importFromJsonFile('./lib/assets/calendar.json');
    if (calendar.calendarData.isEmpty) {
      calendar.calendarData.addAll(
          calendarFill(calendar, date, location) as Map<DateTime, DayContent>);
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
      calendar = calendarFill(calendar, date, location);
    }
  } else if (date.isAfter(lastDate)) {
    for (int year = lastDate.year + 1; year <= date.year; year++) {
      calendar = calendarFill(calendar, date, location);
    }
  }

  calendar.exportToJsonFile('./lib/assets/calendar.json');

  return calendar;
}

String locationRead() {
  // retrieving of the location date in parameters.json
  final parametersFile = File('./lib/assets/parameters.json');
  String location = "";
  if (!parametersFile.existsSync()) {
    // if the file parameters.json doesn't exist, create an empty one
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
  // records the location parmater in parameters.json
  Map<String, dynamic> parametersData = {
    'location': location,
  };
  final parametersFile = File('./lib/assets/parameters.json');
  // if the file exists or not, write it.
  parametersFile.writeAsString(jsonEncode(parametersData));
}
