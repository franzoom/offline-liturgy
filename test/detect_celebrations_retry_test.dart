// detectCelebrations() memoizes its result per calendar and date; a failed
// detection must not be kept, so that the next call retries.

import 'package:test/test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/offices/office_detection.dart';

/// Fails on its first read, then reads the package assets.
class _FailingOnceLoader extends FileSystemDataLoader {
  bool failed = false;

  @override
  Future<String> load(String path) {
    if (!failed) {
      failed = true;
      throw StateError('asset not ready');
    }
    return super.load(path);
  }
}

void main() {
  test('a failed detection is retried on the next call', () async {
    final calendar = getCalendar(
        Calendar(), DateTime(2026, 6, 1), 'romain', LiturgyData.empty());
    final date = DateTime(2026, 6, 1);
    final loader = _FailingOnceLoader();

    await expectLater(
        detectCelebrations(calendar, date, loader), throwsStateError);
    expect(await detectCelebrations(calendar, date, loader), isNotEmpty);
  });
}
