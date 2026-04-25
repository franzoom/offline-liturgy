import '../../classes/calendar_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/data_loader.dart';
import '../office_detection.dart';

/// Returns a map of possible Readings Offices, sorted by precedence (lowest first).
Future<Map<String, CelebrationContext>> readingsDetection(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
) =>
    buildDetectionMap(calendar, date, dataLoader, 'readings');
