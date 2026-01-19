import 'office_elements_class.dart';

/// Class representing the Readings Office structure
class Readings {
  Celebration? celebration;
  List<String>? hymn;
  List<PsalmEntry>? psalmody;
  List<BiblicalReading>? biblicalReading;
  List<PatristicReading>? patristicalReading;
  bool? tedeum;
  String? verse;
  List<String>? oration;

  Readings({
    this.celebration,
    this.hymn,
    this.psalmody,
    this.biblicalReading,
    this.patristicalReading,
    this.tedeum,
    this.verse,
    this.oration,
  });

  /// Creates Readings instance from JSON data
  factory Readings.fromJson(Map<String, dynamic> json) {
    // Helper to safely get a Map from dynamic value
    Map<String, dynamic>? getMap(dynamic value) {
      if (value == null) return null;
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      print('WARNING: Expected Map but got ${value.runtimeType}: $value');
      return null;
    }

    final celebrationMap = getMap(json['celebration']);

    // Parse biblicalReading - can be a list or a single object
    List<BiblicalReading>? biblicalReadingList;
    if (json['biblicalReading'] != null) {
      if (json['biblicalReading'] is List) {
        biblicalReadingList = (json['biblicalReading'] as List)
            .map((e) {
              final map = getMap(e);
              return map != null ? BiblicalReading.fromJson(map) : null;
            })
            .whereType<BiblicalReading>()
            .toList();
      } else {
        final map = getMap(json['biblicalReading']);
        if (map != null) {
          biblicalReadingList = [BiblicalReading.fromJson(map)];
        }
      }
    }

    // Parse patristicalReading - can be a list or a single object
    // Note: YAML files use 'patristicReading' (without 'al')
    List<PatristicReading>? patristicalReadingList;
    if (json['patristicReading'] != null) {
      if (json['patristicReading'] is List) {
        patristicalReadingList = (json['patristicReading'] as List)
            .map((e) {
              final map = getMap(e);
              return map != null ? PatristicReading.fromJson(map) : null;
            })
            .whereType<PatristicReading>()
            .toList();
      } else {
        final map = getMap(json['patristicReading']);
        if (map != null) {
          patristicalReadingList = [PatristicReading.fromJson(map)];
        }
      }
    }

    return Readings(
      celebration: celebrationMap != null
          ? Celebration.fromJson(celebrationMap)
          : null,
      hymn: json['hymn'] != null ? List<String>.from(json['hymn']) : null,
      psalmody: json['psalmody'] != null
          ? (json['psalmody'] as List)
              .map((e) {
                final map = getMap(e);
                return map != null ? PsalmEntry.fromJson(map) : PsalmEntry();
              })
              .toList()
          : null,
      biblicalReading: biblicalReadingList,
      patristicalReading: patristicalReadingList,
      tedeum: json['tedeum'] as bool?,
      verse: json['verse'] as String?,
      oration:
          json['oration'] != null ? List<String>.from(json['oration']) : null,
    );
  }

  /// Overlays this Readings instance with data from another Readings instance
  /// Non-null fields from the overlay take precedence
  /// For psalmody: intelligently merges psalms and antiphons
  void overlayWith(Readings overlay) {
    if (overlay.celebration != null) {
      celebration = overlay.celebration;
    }
    if (overlay.hymn != null) {
      hymn = overlay.hymn;
    }
    if (overlay.psalmody != null) {
      // Smart merge of psalmody: if overlay has antiphons without psalms,
      // merge them with existing psalms
      if (psalmody != null && psalmody!.isNotEmpty) {
        List<PsalmEntry> mergedPsalmody = [];
        for (int i = 0; i < overlay.psalmody!.length; i++) {
          final overlayEntry = overlay.psalmody![i];
          // If overlay has both psalm and antiphon, use it completely
          if (overlayEntry.psalm != null) {
            mergedPsalmody.add(overlayEntry);
          } else if (i < psalmody!.length) {
            // If overlay only has antiphon, merge with existing psalm
            mergedPsalmody.add(PsalmEntry(
              psalm: psalmody![i].psalm,
              antiphon: overlayEntry.antiphon ?? psalmody![i].antiphon,
            ));
          } else {
            // No existing psalm at this index, use overlay as-is
            mergedPsalmody.add(overlayEntry);
          }
        }
        psalmody = mergedPsalmody;
      } else {
        // No existing psalmody, just use overlay
        psalmody = overlay.psalmody;
      }
    }
    if (overlay.biblicalReading != null) {
      biblicalReading = overlay.biblicalReading;
    }
    if (overlay.patristicalReading != null) {
      patristicalReading = overlay.patristicalReading;
    }
    if (overlay.tedeum != null) {
      tedeum = overlay.tedeum;
    }
    if (overlay.verse != null) {
      verse = overlay.verse;
    }
    if (overlay.oration != null) {
      oration = overlay.oration;
    }
  }

  /// Selective overlay for common when precedence > 6
  /// Only overlays: biblicalReading, patristicalReading, oration
  /// Does NOT overlay: celebration, hymn, psalmody, tedeum
  void overlayWithCommon(Readings commonReadings) {
    if (commonReadings.biblicalReading != null) {
      biblicalReading = commonReadings.biblicalReading;
    }
    if (commonReadings.patristicalReading != null) {
      patristicalReading = commonReadings.patristicalReading;
    }
    if (commonReadings.oration != null) {
      oration = commonReadings.oration;
    }
  }

  /// Returns true if all fields are null or empty (empty Readings)
  bool get isEmpty =>
      celebration == null &&
      (hymn == null || hymn!.isEmpty) &&
      (psalmody == null || psalmody!.isEmpty) &&
      (biblicalReading == null || biblicalReading!.isEmpty) &&
      (patristicalReading == null || patristicalReading!.isEmpty) &&
      tedeum == null &&
      (verse == null || verse!.isEmpty) &&
      (oration == null || oration!.isEmpty);
}

/// Definition of Readings type for a given day
/// This class is used to transmit informations through the resolution of the possible Readings Offices
class ReadingsDefinition {
  final String
      readingsDescription; // description of the office (e.g., "readings Office of the 2nd sunday of Lent")
  final String
      celebrationCode; // original code used to identify the celebration (e.g., "CHRISTMAS", "advent_1_0")
  final String
      ferialCode; // code given by the root of the day in Calendar: ferial code or Solmenity
  final List<String>? commonList;
  final String? liturgicalTime;
  final String? breviaryWeek;
  final int precedence;
  final String liturgicalColor;
  final bool
      isCelebrable; // false if a higher precedence celebration (< 4) prevents this office from being celebrated
  final String?
      celebrationDescription; // detailed description of the celebration from JSON
  final bool teDeum; // true if Te Deum should be displayed (Sunday except Lent, or precedence < 6)

  ReadingsDefinition({
    required this.readingsDescription,
    required this.celebrationCode,
    required this.ferialCode,
    this.commonList,
    this.liturgicalTime,
    this.breviaryWeek,
    required this.precedence,
    required this.isCelebrable,
    required this.liturgicalColor,
    this.celebrationDescription,
    required this.teDeum,
  });
}
