// The Saturday before the 1st Sunday of Advent belongs to Advent from its
// First Vespers on: complineDetection() already switched its Compline's
// season to 'advent', but kept the day's Ordinary Time green as its color.

import 'package:test/test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';

void main() {
  test('the Compline of the eve of Advent takes the violet of Advent',
      () async {
    final data = await LiturgyData.load();
    final dataLoader = FileSystemDataLoader();
    // Saturday before the 1st Sunday of Advent 2026 (Nov 29).
    final date = DateTime(2026, 11, 28);
    final calendar = getCalendar(Calendar(), date, 'romain', data);
    expect(calendar.getDayContent(date)?.liturgicalTime, 'ot',
        reason: 'sanity check: the day itself is still in Ordinary Time');

    final complines = await complineDetection(calendar, date, dataLoader);

    expect(complines, isNotEmpty);
    for (final compline in complines.values) {
      expect(compline.context.liturgicalTime, 'advent');
      expect(compline.context.liturgicalColor, 'violet');
    }
  });
}
