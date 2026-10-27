import 'dart:developer';

import '../../classes/readings_class.dart';
import '../../classes/office_elements_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/yaml_map_loader.dart';
import '../../tools/date_tools.dart';

/// Two-year cycle key ('Even' / 'Odd') for [context], or null when the
/// annual cycle is used.
String? _biblicalCycleFor(CelebrationContext context) =>
    context.twoYearReadingCycle
        ? twoYearReadingCycle(context.effectiveLiturgicalYear)
        : null;

/// [readingsExtract] for [context]: its data loader and, when enabled,
/// its two-year cycle.
Future<Readings> readingsExtractFor(
        CelebrationContext context, String relativePath, {String? year}) =>
    readingsExtract(relativePath, context.dataLoader,
        year: year, biblicalCycle: _biblicalCycleFor(context));

/// Extracts Readings (Office of Readings) data from a YAML file.
///
/// It focuses on the 'readings' section which typically includes
/// biblical lessons, patristic texts, and their respective responsories.
Future<Readings> readingsExtract(String relativePath, DataLoader dataLoader,
    {String? year, String? biblicalCycle}) async {
  final data = await loadYamlMap(relativePath, dataLoader);
  if (data == null) return Readings();

  try {
    // 1. Extract the specific Readings section, if any
    final readingsData = data['readings'];
    final readings = readingsData is Map<String, dynamic>
        ? Readings.fromJson(readingsData,
            year: year, biblicalCycle: biblicalCycle)
        : Readings();

    // 2. Fallback for Oration: if the section doesn't have one (or there is
    // no section, e.g. a Common giving only its oration, like
    // dedicace_inside), look at the root level
    readings.oration ??= asTextList(data['oration']);

    return readings;
  } catch (e) {
    // Graceful error handling to prevent UI blocking
    log('Error during readingsExtract for $relativePath',
        name: 'ReadingsExtract', level: 1000, error: e);
    return Readings();
  }
}
