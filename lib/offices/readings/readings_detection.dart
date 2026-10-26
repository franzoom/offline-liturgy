import '../../classes/calendar_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/hierarchical_common_loader.dart';
import '../compose_office.dart';
import '../office_detection.dart';
import './readings_extract.dart';

/// Returns a map of possible Readings Offices, sorted by precedence (lowest
/// first), each telling whether choosing its Common makes any difference.
Future<Map<String, CelebrationContext>> readingsDetection(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
) async =>
    withCommonDifference(
      await buildDetectionMap(calendar, date, dataLoader, 'readings'),
      proper: readingsExtractFor,
      common: loadReadingsHierarchicalCommon,
      supplies: (common, proper, {required memorial}) =>
          common.suppliesTextsMissingFrom(proper, memorial: memorial),
    );
