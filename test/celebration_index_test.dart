// celebrationDirIndex() caches index.json for the whole process; an empty
// or failed first load must not be kept, or every sanctoral code would be
// looked up in the ferial directory until the app restarts.

import 'package:test/test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/tools/celebration_index.dart';

class _FlakyLoader extends DataLoader {
  final List<String> answers;
  _FlakyLoader(this.answers);

  @override
  Future<String> load(String relativePath) async => answers.removeAt(0);
}

void main() {
  test('an empty index.json is retried on the next call', () async {
    final loader =
        _FlakyLoader(['', '{"roman/saint": {"dir": "sanctoral"}}']);
    expect(await celebrationDirIndex(loader), isEmpty);
    expect(await celebrationDirIndex(loader), {'roman/saint': 'sanctoral'});
    expect(await dirPathForCode('roman/saint', loader),
        'calendar_data/sanctoral');
  });
}
