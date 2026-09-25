// complineDetection() built its CelebrationContexts without ever setting
// celebrationTitle — only officeDescription (the long display text, e.g.
// "Complies – Vendredi Saint"). A consumer that reads celebrationTitle to
// name the day's celebration (see aelf-flutter's drawer header) always saw
// it empty, on every solemnity and on the Triduum days alike — not just on
// Holy Thursday/Good Friday/Holy Saturday, though that's where it shows
// most, since a plain ferial day's celebrationTitle is just its weekday
// name anyway.

import 'package:test/test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';

void main() {
  Future<Map<String, ComplineDefinition>> complinesFor(DateTime date) async {
    final data = await LiturgyData.load();
    final loader = FileSystemDataLoader();
    final calendar = getCalendar(Calendar(), date, 'romain', data);
    return complineDetection(calendar, date, loader);
  }

  group('complineDetection sets celebrationTitle', () {
    test('on each of the three Triduum days', () async {
      final titles = <String, String>{
        'Holy Thursday': 'Jeudi Saint',
        'Good Friday': 'Vendredi Saint',
        'Holy Saturday': 'Samedi Saint',
      };
      final dates = <String, DateTime>{
        'Holy Thursday': DateTime(2027, 3, 25),
        'Good Friday': DateTime(2027, 3, 26),
        'Holy Saturday': DateTime(2027, 3, 27),
      };

      for (final day in titles.keys) {
        final complines = await complinesFor(dates[day]!);
        final choice = complines.values.single;
        expect(choice.context.celebrationTitle, titles[day], reason: day);
      }
    });

    test('on an ordinary solemnity (Christmas Day)', () async {
      final complines = await complinesFor(DateTime(2027, 12, 25));
      final choice = complines.values.single;

      expect(choice.context.celebrationTitle, 'Nativité du Seigneur');
    });

    test('on an eve Compline (the eve of All Saints)', () async {
      final complines = await complinesFor(DateTime(2026, 10, 31));
      final eve = complines.values.firstWhere((c) => c.isEveCompline);

      expect(eve.context.celebrationTitle, 'Tous les Saints');
    });
  });
}
