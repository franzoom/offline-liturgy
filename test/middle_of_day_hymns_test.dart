// A ferial file may declare its own Middle of Day hymn: `middleOfDay.hymn`
// applies to tierce, sexte and none, and a `hymn` inside one hour overrides
// it for that hour only. Good Friday (lent_6_5) and Holy Saturday (lent_6_6)
// declare one, which must win over the seasonal hymns of
// hymns/000_list.yaml (the Lent ones, since there is no holyweek entry).

import 'package:test/test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';

void main() {
  group('MiddleOfDay.fromJson hymns', () {
    test('a shared hymn applies to all three hours', () {
      final office = MiddleOfDay.fromJson({
        'hymn': ['shared'],
      });
      expect(office.hymnTierce?.single.code, 'shared');
      expect(office.hymnSexte?.single.code, 'shared');
      expect(office.hymnNone?.single.code, 'shared');
    });

    test('an hour hymn overrides the shared one for that hour only', () {
      final office = MiddleOfDay.fromJson({
        'hymn': ['shared'],
        'sexte': {
          'hymn': ['own'],
        },
      });
      expect(office.hymnTierce?.single.code, 'shared');
      expect(office.hymnSexte?.single.code, 'own');
      expect(office.hymnNone?.single.code, 'shared');
    });

    test('no hymn declared leaves the hours empty', () {
      final office = MiddleOfDay.fromJson({});
      expect(office.hymnTierce, isNull);
      expect(office.hymnSexte, isNull);
      expect(office.hymnNone, isNull);
    });
  });

  final cases = <String, (DateTime, String?)>{
    'Good Friday': (DateTime(2027, 3, 26), 'sur-les-chemins'),
    'Holy Saturday': (DateTime(2027, 3, 27), 'la-parole-en-silence-3-4'),
    // A plain Lenten weekday keeps the seasonal hymns
    'Lent weekday': (DateTime(2027, 3, 3), null),
  };

  group('Middle of Day hymns on resolved days', () {
    for (final entry in cases.entries) {
      test(entry.key, () async {
        final (date, properHymn) = entry.value;
        final data = await LiturgyData.load();
        final dataLoader = FileSystemDataLoader();
        final calendar = getCalendar(Calendar(), date, 'romain', data);

        final contexts = await middleOfDayDetection(calendar, date, dataLoader);
        final office = await middleOfDayExport(contexts.values.first);
        final hours = [office.hymnTierce, office.hymnSexte, office.hymnNone];

        if (properHymn != null) {
          for (final hymns in hours) {
            expect(hymns?.map((h) => h.code), [properHymn]);
          }
        } else {
          expect(office.hymnTierce?.map((h) => h.code), ['ami-des-hommes']);
          expect(
              office.hymnSexte?.map((h) => h.code), ['comme-le-feu-calcine']);
          expect(office.hymnNone?.map((h) => h.code),
              ['o-toi-qui-es-sans-changement']);
        }
      });
    }
  });
}
