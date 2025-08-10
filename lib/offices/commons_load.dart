import 'dart:convert';
import 'dart:io';
import '../../../classes/day_offices_class.dart';

// Import de votre classe DayOffices
// import 'day_offices.dart'; // Ajustez le chemin selon votre structure

/// Charge et superpose les fichiers JSON d'offices liturgiques selon la hiérarchie définie
///
/// [commonType] : Format "x" ou "x_y" où x et y sont des chaînes de caractères
/// [liturgicalTime] : "lent", "paschal", "advent" ou "christmas"
///
/// Ordre de superposition :
/// 1. x.json (base)
/// 2. x_liturgicalTime.json (si existe)
/// 3. x_y.json (si y existe)
/// 4. x_y_liturgicalTime.json (si y existe et fichier existe)
DayOffices commonLoad(String commonType, String liturgicalTime) {
  // Validation des paramètres
  if (!['lent', 'paschal', 'advent', 'christmas'].contains(liturgicalTime)) {
    throw ArgumentError(
        'liturgicalTime must be one of: lent, paschal, advent, christmas');
  }

  // Parse du commonType
  final parts = commonType.split('_');
  final x = parts[0];
  final y = parts.length > 1 ? parts[1] : null;

  // Instance de base
  DayOffices result = DayOffices();

  try {
    // 1. Charger x.json (obligatoire)
    final baseJson = _loadJsonFile('$x.json');
    result = DayOffices.fromJSON(baseJson!);

    // 2. Superposer x_liturgicalTime.json (si existe)
    final liturgicalJson = _loadJsonFile('${x}_$liturgicalTime.json');
    if (liturgicalJson != null) {
      final liturgicalOffices = DayOffices.fromJSON(liturgicalJson);
      result.overlayWith(liturgicalOffices);
    }

    // 3. Si y existe, superposer x_y.json
    if (y != null) {
      final specificJson = _loadJsonFile('${x}_$y.json');
      if (specificJson != null) {
        final specificOffices = DayOffices.fromJSON(specificJson);
        result.overlayWith(specificOffices);

        // 4. Superposer x_y_liturgicalTime.json (si existe)
        final specificLiturgicalJson =
            _loadJsonFile('${x}_${y}_$liturgicalTime.json');
        if (specificLiturgicalJson != null) {
          final specificLiturgicalOffices =
              DayOffices.fromJSON(specificLiturgicalJson);
          result.overlayWith(specificLiturgicalOffices);
        }
      }
    }
  } catch (e) {
    throw Exception('Erreur lors du chargement des offices liturgiques: $e');
  }

  return result;
}

/// Charge un fichier JSON depuis le système de fichiers de façon synchrone
/// Retourne null si le fichier n'existe pas
Map<String, dynamic>? _loadJsonFile(String filename) {
  try {
    final file = File(
        'path/to/your/json/files/$filename'); // Ajustez le chemin selon votre structure
    if (!file.existsSync()) {
      return null;
    }
    final String jsonString = file.readAsStringSync();
    return json.decode(jsonString) as Map<String, dynamic>;
  } catch (e) {
    // Le fichier n'existe pas ou erreur de parsing
    return null;
  }
}

/// Exemple d'utilisation :
/// 
/// ```dart
/// // Pour un commonType "saint" avec temps liturgique "lent"
/// final offices1 = loadLiturgicalOffices('saint', 'lent');
/// 
/// // Pour un commonType "saint_martyr" avec temps liturgique "paschal"
/// final offices2 = loadLiturgicalOffices('saint_martyr', 'paschal');
/// ```