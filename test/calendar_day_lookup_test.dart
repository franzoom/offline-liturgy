// Calendar.getDayContent finds a day whatever the time of day or UTC/local
// mode of the date it is given (days are stored at local midnight).

import 'package:test/test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';

void main() {
  test('getDayContent ignores the time and UTC mode of the date', () {
    final calendar = getCalendar(
        Calendar(), DateTime(2026, 6, 1), 'romain', LiturgyData.empty());
    final day = calendar.getDayContent(DateTime(2026, 6, 1));
    expect(day, isNotNull);
    expect(calendar.getDayContent(DateTime(2026, 6, 1, 18, 30)), same(day));
    expect(calendar.getDayContent(DateTime.utc(2026, 6, 1)), same(day));
  });
}
