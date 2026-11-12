// When June 24 is the day of the Sacred Heart (2022, 2033), the Nativity of
// St John the Baptist is anticipated to Thursday June 23 (as AELF published
// it in 2022): its First Vespers move to the evening of the 22nd, and the
// Immaculate Heart of Mary keeps Saturday the 25th.

import 'package:test/test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';

void main() {
  late LiturgyData data;
  final dataLoader = FileSystemDataLoader();

  setUpAll(() async => data = await LiturgyData.load());

  const john = 'roman/saint_john_the_baptist';

  for (final year in [2022, 2033]) {
    group('$year', () {
      late Calendar calendar;
      setUp(() => calendar =
          getCalendar(Calendar(), DateTime(year, 6, 1), 'france', data));

      bool hasFeast(int day, String code) => calendar
          .getDayContent(DateTime(year, 6, day))!
          .feastList
          .values
          .any((codes) => codes.contains(code));

      test('John the Baptist on June 23, Sacred Heart on June 24', () {
        expect(hasFeast(23, john), isTrue);
        expect(hasFeast(24, john), isFalse);
        expect(hasFeast(25, john), isFalse);
        expect(hasFeast(24, 'roman/sacred_heart'), isTrue);
        expect(hasFeast(25, 'roman/immaculate_heart_of_mary'), isTrue);
      });

      test('First Vespers on the evening of June 22', () async {
        final eve = DateTime(year, 6, 22);
        final vespers = await vespersDetection(calendar, eve, dataLoader);
        final first = vespers.values.first;
        expect(first.celebrationCode, john);
        expect(first.isFirstVespers, isTrue);
      });

      test('Vigil Mass and Mass of the day listed on June 23', () async {
        // As on AELF, the Vigil Mass is listed with the solemnity's day
        final masses =
            await massDetection(calendar, DateTime(year, 6, 23), dataLoader);
        expect(masses.values.where((m) => m.celebrationCode == john).length, 2);
        final sacredHeart =
            await massDetection(calendar, DateTime(year, 6, 24), dataLoader);
        expect(
            sacredHeart.values.any((m) => m.celebrationCode == john), isFalse);
      });
    });
  }
}
