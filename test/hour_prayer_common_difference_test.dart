// Lauds, Vespers and the Office of Readings tell whether choosing a celebration's Common — or none —
// makes any difference (CelebrationContext.commonMakesDifference): it does
// when one of its Commons supplies a text the proper lacks. The Common's
// hymns, only offered after a proper hymn, don't count.

import 'package:test/test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';

void main() {
  late LiturgyData data;
  final dataLoader = FileSystemDataLoader();

  setUpAll(() async => data = await LiturgyData.load());

  Future<CelebrationContext> lauds(DateTime date, String code) async {
    final calendar = getCalendar(Calendar(), date, 'lyon', data);
    final offices = await morningDetection(calendar, date, dataLoader);
    return offices.values.firstWhere((c) => c.celebrationCode == code);
  }

  test("a memorial whose proper lacks the Common's texts (Saint Agatha)",
      () async {
    final agatha =
        await lauds(DateTime(2027, 2, 5), 'roman/agatha_of_sicily_virgin');
    expect(agatha.commonMakesDifference, isTrue);

    final calendar =
        getCalendar(Calendar(), DateTime(2027, 2, 5), 'lyon', data);
    final vespers =
        await vespersDetection(calendar, DateTime(2027, 2, 5), dataLoader);
    expect(
        vespers.values
            .firstWhere(
                (c) => c.celebrationCode == 'roman/agatha_of_sicily_virgin')
            .commonMakesDifference,
        isTrue);
  });

  test('a feast whose proper has every text (the Visitation)', () async {
    final visitation =
        await lauds(DateTime(2027, 5, 31), 'roman/visitation_of_mary');
    expect(visitation.commonList, isNotEmpty);
    expect(visitation.commonMakesDifference, isFalse);
  });

  test('the ferial day is not concerned', () async {
    final calendar =
        getCalendar(Calendar(), DateTime(2027, 2, 5), 'lyon', data);
    final offices =
        await morningDetection(calendar, DateTime(2027, 2, 5), dataLoader);
    expect(offices.values.firstWhere((c) => !c.hasProper).commonMakesDifference,
        isNull);
  });

  group('the Office of Readings', () {
    Future<CelebrationContext> readings(DateTime date, String code) async {
      final calendar = getCalendar(Calendar(), date, 'lyon', data);
      final offices = await readingsDetection(calendar, date, dataLoader);
      return offices.values.firstWhere((c) => c.celebrationCode == code);
    }

    test("Saint Agatha's Common supplies texts her proper lacks", () async {
      final agatha =
          await readings(DateTime(2027, 2, 5), 'roman/agatha_of_sicily_virgin');
      expect(agatha.commonMakesDifference, isTrue);
    });

    test('the Conversion of Saint Paul has every text of its own', () async {
      final conversion = await readings(
          DateTime(2027, 1, 25), 'roman/conversion_of_saint_paul_the_apostle');
      expect(conversion.commonList, isNotEmpty);
      expect(conversion.commonMakesDifference, isFalse);
    });

    test("a memorial keeps the day's biblical reading, a feast doesn't", () {
      final common = Readings(biblicalReading: [BiblicalReading()]);
      expect(
          common.suppliesTextsMissingFrom(Readings(), memorial: true), isFalse);
      expect(
          common.suppliesTextsMissingFrom(Readings(), memorial: false), isTrue);
    });
  });

  group('suppliesTextsMissingFrom', () {
    final hymn = [HymnEntry(code: 'some-hymn')];

    test("the Common's hymns don't count after a proper hymn", () {
      expect(
          Morning(hymn: hymn)
              .suppliesTextsMissingFrom(Morning(hymn: hymn), memorial: true),
          isFalse);
      expect(
          Morning(hymn: hymn)
              .suppliesTextsMissingFrom(Morning(), memorial: true),
          isTrue);
    });

    test("a memorial keeps the day's psalmody, a feast takes the Common's", () {
      final common = Morning(psalmody: [PsalmEntry(psalm: 'PSALM_62')]);
      expect(
          common.suppliesTextsMissingFrom(Morning(), memorial: true), isFalse);
      expect(
          common.suppliesTextsMissingFrom(Morning(), memorial: false), isTrue);
    });
  });
}
