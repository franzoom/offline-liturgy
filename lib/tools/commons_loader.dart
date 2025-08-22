import 'dart:convert';
import 'dart:io';
import '../../../classes/day_offices_class.dart';

/// Loads and overlays JSON liturgical office files according to defined hierarchy
///
/// [commonType] : Format "x", "x_y" or "x_y_z" where x, y and z are character strings
/// [liturgicalTime] : "lent", "paschal", "advent" or "christmas"
///
/// Overlay order for x_y_z :
/// 1. x.json (base)
/// 2. x_liturgicalTime.json (if exists)
/// 3. x_y.json (if exists)
/// 4. x_y_liturgicalTime.json (if exists)
/// 5. x_y_z.json (if exists)
/// 6. x_y_z_liturgicalTime.json (if exists)
DayOffices commonLoad(String commonType, String liturgicalTime) {
  // Parameter validation
  if (!['lent', 'paschal', 'advent', 'christmas'].contains(liturgicalTime)) {
    throw ArgumentError(
        'liturgicalTime must be one of: lent, paschal, advent, christmas');
  }

  // Parse commonType
  final parts = commonType.split('_');
  final x = parts[0];
  final y = parts.length > 1 ? parts[1] : null;
  final z = parts.length > 2 ? parts[2] : null;

  try {
    // 1. Load x.json (mandatory)
    final baseJson = _loadJsonFile('$x.json');
    if (baseJson == null) {
      throw Exception('Base file $x.json not found');
    }

    // Start with base JSON
    Map<String, dynamic> resultJson = Map.from(baseJson);

    // 2. Overlay x_liturgicalTime.json (if exists)
    final liturgicalJson = _loadJsonFile('${x}_$liturgicalTime.json');
    if (liturgicalJson != null) {
      resultJson = _mergeJsonMaps(resultJson, liturgicalJson);
    }

    // 3. If y exists, overlay x_y.json
    if (y != null) {
      final specificJson = _loadJsonFile('${x}_$y.json');
      if (specificJson != null) {
        resultJson = _mergeJsonMaps(resultJson, specificJson);
      }

      // 4. Overlay x_y_liturgicalTime.json (if exists)
      final specificLiturgicalJson =
          _loadJsonFile('${x}_${y}_$liturgicalTime.json');
      if (specificLiturgicalJson != null) {
        resultJson = _mergeJsonMaps(resultJson, specificLiturgicalJson);
      }

      // 5. If z exists, overlay x_y_z.json
      if (z != null) {
        final moreSpecificJson = _loadJsonFile('${x}_${y}_$z.json');
        if (moreSpecificJson != null) {
          resultJson = _mergeJsonMaps(resultJson, moreSpecificJson);
        }

        // 6. Overlay x_y_z_liturgicalTime.json (if exists)
        final moreSpecificLiturgicalJson =
            _loadJsonFile('${x}_${y}_${z}_$liturgicalTime.json');
        if (moreSpecificLiturgicalJson != null) {
          resultJson = _mergeJsonMaps(resultJson, moreSpecificLiturgicalJson);
        }
      }
    }

    // Create final DayOffices instance
    return DayOffices.fromJSON(resultJson);
  } catch (e) {
    throw Exception('Error loading liturgical offices: $e');
  }
}

/// Merges two JSON maps, with values from [overlay] taking precedence
Map<String, dynamic> _mergeJsonMaps(
    Map<String, dynamic> base, Map<String, dynamic> overlay) {
  final result = Map<String, dynamic>.from(base);

  overlay.forEach((key, value) {
    if (value != null) {
      result[key] = value;
    }
  });

  return result;
}

/// Loads a JSON file from the file system synchronously
/// Returns null if the file doesn't exist
Map<String, dynamic>? _loadJsonFile(String filename) {
  try {
    final file = File(
        './lib/assets/calendar_data/commons/$filename'); // Adjust path according to your structure
    if (!file.existsSync()) {
      return null;
    }
    final String jsonString = file.readAsStringSync();
    return json.decode(jsonString) as Map<String, dynamic>;
  } catch (e) {
    // File doesn't exist or parsing error
    return null;
  }
}



/// Usage examples:
///
/// ```dart
/// // For a commonType "saint" with liturgical time "lent"
/// final offices1 = commonLoad('saint', 'lent');
/// // Loads: saint.json → saint_lent.json
///
/// // For a commonType "saint_martyr" with liturgical time "paschal"
/// final offices2 = commonLoad('saint_martyr', 'paschal');
/// // Loads: saint.json → saint_paschal.json → saint_martyr.json → saint_martyr_paschal.json
///
/// // For a commonType "saint_martyr_bishop" with liturgical time "advent"
/// final offices3 = commonLoad('saint_martyr_bishop', 'advent');
/// // Loads: saint.json → saint_advent.json → saint_martyr.json → saint_martyr_advent.json 
/// //        → saint_martyr_bishop.json → saint_martyr_bishop_advent.json
/// ```