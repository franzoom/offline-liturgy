// complineDetection()/complineExport() must give Holy Thursday, Good Friday
// and Holy Saturday their own proper Compline (complines/lent.yaml's
// 'holy_thursday'/'holy_friday'/'holy_saturday' entries — Psalm 90, a proper
// responsory), not the plain Thursday/Friday/Saturday-of-Lent one (Psalm
// 15/87, no responsory) that a Lenten ferial week would otherwise get.
//
// The mismatch: these three days are tagged 'lent_6_4'/'lent_6_5'/'lent_6_6'
// by the calendar (see main_calendar_fill.dart), never the literal words
// 'holy_thursday'/'holy_friday'/'holy_saturday' — see holyWeekCodes in
// constants.dart.

import 'package:test/test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';

void main() {
  final dates = <String, DateTime>{
    'Holy Thursday': DateTime(2027, 3, 25),
    'Good Friday': DateTime(2027, 3, 26),
    'Holy Saturday': DateTime(2027, 3, 27),
  };

  group('Compline on the Triduum days', () {
    for (final entry in dates.entries) {
      test('${entry.key} gets its own proper Compline, not a plain Lenten one',
          () async {
        final data = await LiturgyData.load();
        final dataLoader = FileSystemDataLoader();
        final date = entry.value;
        final calendar = getCalendar(Calendar(), date, 'romain', data);

        expect(calendar.getDayContent(date)?.liturgicalTime, 'holyweek',
            reason: 'sanity check: this date must actually be in Holy Week');

        final complines = await complineDetection(calendar, date, dataLoader);
        expect(complines, hasLength(1),
            reason: 'the Triduum has no other Compline option');
        final choice = complines.values.single;

        final compline = await complineExport(choice);

        // Psalm 90 ("Qui habitat"), with its own responsory, is proper to
        // the Triduum — a plain Thursday/Friday/Saturday of Lent gets
        // Psalm 15/87 instead, and no responsory at all.
        expect(compline.psalmody?.single.psalm, 'PSALM_90');
        expect(compline.responsory, isNotNull);
      });
    }
  });
}
