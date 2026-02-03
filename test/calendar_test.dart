import 'package:test/test.dart';
import 'package:offline_liturgy/feasts/main_calendar_fill.dart'; // Adjust path
import 'package:offline_liturgy/classes/calendar_class.dart';

void main() {
  group('Liturgical Calendar Logic Tests', () {
    late Calendar calendar;

    setUp(() {
      calendar = Calendar();
    });

    test('Christmas 2025 (Liturgical Year 2026) check', () {
      // Christmas is Dec 25, 2025
      // Based on your logic, this belongs to liturgicalYear 2026
      calendar = calendarFill(calendar, DateTime(2025, 12, 25), 'france');

      final christmasDate = DateTime(2025, 12, 25);
      final content = calendar.getDayContent(christmasDate);

      expect(content, isNotNull,
          reason: 'Christmas Day should exist in calendar');
      expect(content!.liturgicalColor, equals('white'));
      expect(content.precedence, equals(2));
      expect(content.defaultCelebrationTitle, equals('nativity'));
    });

    test('Ash Wednesday 2025 check', () {
      // Ash Wednesday 2025 is March 5th
      calendar = calendarFill(calendar, DateTime(2025, 3, 5), 'france');

      final ashWednesday = DateTime(2025, 3, 5);
      final content = calendar.getDayContent(ashWednesday);

      expect(content, isNotNull);
      expect(content!.liturgicalTime, equals('lent'));
      expect(content.liturgicalColor, equals('violet'));
      expect(content.precedence, equals(2));
    });

    test('Sunday Precedence in Ordinary Time', () {
      // Feb 9, 2025 is a Sunday in OT
      calendar = calendarFill(calendar, DateTime(2025, 2, 9), 'france');

      final sundayDate = DateTime(2025, 2, 9);
      final content = calendar.getDayContent(sundayDate);

      expect(content, isNotNull);
      // In your code: precedence = date.isSunday ? 6 : 13;
      expect(content!.precedence, equals(6),
          reason: 'Sunday in OT should be precedence 6');
      expect(content.liturgicalColor, equals('green'));
    });
  });
}
