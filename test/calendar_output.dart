import 'dart:io';
import 'package:offline_liturgy/offline_liturgy.dart';

Future<void> main() async {
  final data = await LiturgyData.load();
  final calendar = getCalendar(Calendar(), DateTime(2026, 2, 18), 'lyon', data);

  File('./test/calendar_output.txt')
      .writeAsStringSync(calendar.formattedDisplay);
  print('Calendrier ecrit dans calendar_output.txt');
}
