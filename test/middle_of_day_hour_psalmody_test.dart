// An hour of the Middle of Day office may declare its own psalmody
// (`middleOfDay.tierce.psalmody`, etc.). When present it wins over the
// shared, Sunday or gradual psalmody that middleOfDayExport would otherwise
// resolve for that hour; hours without one keep that resolution.
//
// Epiphany declares one for each hour: before this, it got the gradual
// psalms (weekday) or the Sunday I psalms (on a Sunday) at all three hours.

import 'package:test/test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';

List<String?>? codes(List<PsalmEntry>? psalms) =>
    psalms?.map((p) => p.psalm).toList();

Future<(CelebrationContext, MiddleOfDay)> resolve(
    DateTime date, String location) async {
  final data = await LiturgyData.load();
  final calendar = getCalendar(Calendar(), date, location, data);
  final contexts =
      await middleOfDayDetection(calendar, date, FileSystemDataLoader());
  final context = contexts.values.first;
  return (context, await middleOfDayExport(context));
}

void main() {
  group('HourOffice psalmody parsing', () {
    test('an hour psalmody is read', () {
      final office = MiddleOfDay.fromJson({
        'tierce': {
          'psalmody': [
            {'psalm': 'PSALM_46'},
            {'psalm': 'PSALM_97'},
          ],
        },
      });
      expect(codes(office.tierce?.psalmody), ['PSALM_46', 'PSALM_97']);
      expect(office.sexte, isNull);
    });

    test('an hour overlay keeps the psalmody it does not redefine', () {
      final base = HourOffice(
        psalmody: [PsalmEntry(psalm: 'PSALM_46')],
        antiphon: 'base',
      );
      base.overlayWith(HourOffice(antiphon: 'overlay'));
      expect(codes(base.psalmody), ['PSALM_46']);
      expect(base.antiphon, 'overlay');
    });
  });

  const epiphanyTierce = ['PSALM_46', 'PSALM_85_1', 'PSALM_97'];
  const epiphanySexte = ['PSALM_122', 'PSALM_123', 'PSALM_124'];
  const epiphanyNone = ['PSALM_125', 'PSALM_126', 'PSALM_127'];

  group('Epiphany takes its own psalmody at each hour', () {
    final cases = <String, (DateTime, String)>{
      'on January 6, a weekday (Belgium)': (DateTime(2027, 1, 6), 'belgium'),
      'on a Sunday (France)': (DateTime(2027, 1, 3), 'france'),
    };
    for (final entry in cases.entries) {
      test(entry.key, () async {
        final (date, location) = entry.value;
        final (context, office) = await resolve(date, location);
        expect(context.celebrationCode, 'roman/epiphany',
            reason: 'sanity check: this date must actually be Epiphany');
        expect(codes(office.psalmodyTierce), epiphanyTierce);
        expect(codes(office.psalmodySexte), epiphanySexte);
        expect(codes(office.psalmodyNone), epiphanyNone);
        // Each hour's own antiphon is applied to its psalms
        expect(
            office.psalmodyTierce!.first.antiphon, [office.tierce!.antiphon]);
      });
    }
  });

  group('Non-regression', () {
    test('a weekday solemnity without hour psalmody keeps the gradual psalms',
        () async {
      // Assumption 2028 falls on a Tuesday
      final (_, office) = await resolve(DateTime(2028, 8, 15), 'romain');
      expect(codes(office.psalmodyTierce),
          ['PSALM_119', 'PSALM_120', 'PSALM_121']);
      expect(codes(office.psalmodySexte), epiphanySexte);
      expect(codes(office.psalmodyNone), epiphanyNone);
    });

    test('an ordinary weekday uses the shared psalmody at all hours', () async {
      final (_, office) = await resolve(DateTime(2027, 7, 7), 'romain');
      final shared = codes(office.psalmody);
      expect(shared, isNotEmpty);
      expect(codes(office.psalmodyTierce), shared);
      expect(codes(office.psalmodySexte), shared);
      expect(codes(office.psalmodyNone), shared);
    });
  });
}
