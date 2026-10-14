// liturgicalYearOf() is the civil year up to the eve of the 1st Sunday of
// Advent, then the next one: Advent 2026 (Nov 29) belongs to 2027.

import 'package:test/test.dart';
import 'package:offline_liturgy/calendar_management/common_calendar_definitions.dart';

void main() {
  test('liturgicalYearOf switches on the 1st Sunday of Advent', () {
    expect(liturgicalYearOf(DateTime(2026, 1, 1)), 2026);
    expect(liturgicalYearOf(DateTime(2026, 11, 28)), 2026);
    expect(liturgicalYearOf(DateTime(2026, 11, 29)), 2027);
    expect(liturgicalYearOf(DateTime(2026, 12, 31)), 2027);
    expect(liturgicalYearOf(DateTime(2027, 1, 1)), 2027);
  });
}
