import '../../classes/calendar_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/hierarchical_common_loader.dart';
import '../compose_office.dart';
import '../office_detection.dart';
import './morning_extract.dart';

/// Returns a map of possible Morning Offices, sorted by precedence (lowest
/// first), each telling whether choosing its Common makes any difference.
Future<Map<String, CelebrationContext>> morningDetection(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
) async =>
    withCommonDifference(
      await buildDetectionMap(calendar, date, dataLoader, 'morning'),
      proper: (c, path) => morningExtract(path, c.dataLoader),
      common: loadMorningHierarchicalCommon,
    );
