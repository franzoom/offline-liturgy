// LocationFeast.fromYaml checks a feast entry when the data is loaded, so a
// malformed entry is reported with its key instead of failing later while
// the calendar is filled.

import 'package:test/test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';

void main() {
  test('a fixed or relative feast with a precedence is read', () {
    final fixed = LocationFeast.fromYaml(
        'irenaeus', {'month': 6, 'day': 28, 'precedence': 10});
    expect((fixed.month, fixed.day, fixed.precedence), (6, 28, 10));
    final relative = LocationFeast.fromYaml(
        'fourviere', {'relativeTo': 'EASTER', 'shift': 13, 'precedence': 11});
    expect((relative.relativeTo, relative.shift), ('EASTER', 13));
  });

  test('a feast without precedence or date is rejected', () {
    expect(() => LocationFeast.fromYaml('a', {'month': 6, 'day': 28}),
        throwsFormatException);
    expect(() => LocationFeast.fromYaml('b', {'month': 6, 'precedence': 10}),
        throwsFormatException);
    expect(() => LocationFeast.fromYaml('c', 'not a map'),
        throwsFormatException);
  });
}
