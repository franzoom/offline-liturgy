// complineDetection() builds a ferial Compline's display label with
// liturgicalTimeLabelsDative[liturgicalTime] — see french_liturgy_labels.dart.
// That map used to be keyed 'easter', but DayContent.liturgicalTime is never
// 'easter': it's 'paschaltime' for ordinary Easter-season ferial days (and
// 'paschaloctave' for the Octave, handled by its own branch). The mismatch
// silently dropped "du Temps Pascal" from the label during most of
// Eastertide.

import 'package:test/test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';

void main() {
  test('a ferial Compline during ordinary Easter time names the season',
      () async {
    final data = await LiturgyData.load();
    final dataLoader = FileSystemDataLoader();
    // A plain Thursday well into Easter time (week 3), away from both the
    // Paschal Octave and any solemnity that would take the other branches.
    final date = DateTime(2027, 4, 15);
    final calendar = getCalendar(Calendar(), date, 'romain', data);
    expect(calendar.getDayContent(date)?.liturgicalTime, 'paschaltime',
        reason: 'sanity check: this date must exercise the ordinary-time '
            'branch, not the Paschal Octave one');

    final complines = await complineDetection(calendar, date, dataLoader);

    expect(complines.keys, contains('Complies du Jeudi du Temps Pascal'));
  });
}
