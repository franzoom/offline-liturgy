import 'office_elements_class.dart';

/// Class representing the Middle of Day Prayer (Tierce, Sexte, None) structure
class MiddleOfDay {
  Celebration? celebration;
  List<PsalmEntry>? psalmody;
  HourOffice? tierce;
  HourOffice? sexte;
  HourOffice? none;
  List<String>? oration;

  MiddleOfDay({
    this.celebration,
    this.psalmody,
    this.tierce,
    this.sexte,
    this.none,
    this.oration,
  });

  /// Creates MiddleOfDay instance from YAML data
  factory MiddleOfDay.fromJson(Map<String, dynamic> yamlData) {
    return MiddleOfDay(
      celebration: yamlData['celebration'] != null
          ? Celebration.fromJson(
              yamlData['celebration'] as Map<String, dynamic>)
          : null,
      psalmody: yamlData['psalmody'] != null
          ? (yamlData['psalmody'] as List)
              .map((e) => PsalmEntry.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      tierce: yamlData['tierce'] != null
          ? HourOffice.fromJson(yamlData['tierce'] as Map<String, dynamic>)
          : null,
      sexte: yamlData['sexte'] != null
          ? HourOffice.fromJson(yamlData['sexte'] as Map<String, dynamic>)
          : null,
      none: yamlData['none'] != null
          ? HourOffice.fromJson(yamlData['none'] as Map<String, dynamic>)
          : null,
      oration: yamlData['oration'] != null
          ? List<String>.from(yamlData['oration'])
          : null,
    );
  }

  /// Overlays this MiddleOfDay instance with data from another MiddleOfDay instance
  /// Non-null fields from the overlay take precedence
  /// For psalmody: intelligently merges psalms and antiphons
  void overlayWith(MiddleOfDay overlay) {
    if (overlay.celebration != null) {
      celebration = overlay.celebration;
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
    if (overlay.tierce != null) {
      tierce = overlay.tierce;
    }
    if (overlay.sexte != null) {
      sexte = overlay.sexte;
    }
    if (overlay.none != null) {
      none = overlay.none;
    }
    if (overlay.oration != null) {
      oration = overlay.oration;
    }
  }

  /// Selective overlay for common when precedence > 6
  /// Only overlays: tierce, sexte, none, oration
  /// Does NOT overlay: celebration, psalmody
  void overlayWithCommon(MiddleOfDay commonMiddleOfDay) {
    if (commonMiddleOfDay.tierce != null) {
      tierce = commonMiddleOfDay.tierce;
    }
    if (commonMiddleOfDay.sexte != null) {
      sexte = commonMiddleOfDay.sexte;
    }
    if (commonMiddleOfDay.none != null) {
      none = commonMiddleOfDay.none;
    }
    if (commonMiddleOfDay.oration != null) {
      oration = commonMiddleOfDay.oration;
    }
  }

  /// Returns true if all fields are null (empty MiddleOfDay)
  bool get isEmpty =>
      celebration == null &&
      psalmody == null &&
      tierce == null &&
      sexte == null &&
      none == null &&
      oration == null;
}

/// Definition of MiddleOfDay type for a given day
/// This class is used to transmit informations through the resolution of the possible MiddleOfDay Offices
class MiddleOfDayDefinition {
  final String
      middleOfDayDescription; // description of the office (e.g., "Middle of Day of the 2nd Sunday of Lent")
  final String
      celebrationCode; // original code used to identify the celebration (e.g., "CHRISTMAS", "advent_1_0")
  final String
      ferialCode; // code given by the root of the day in Calendar: ferial code or Solemnity
  final List<String>? commonList;
  final String? liturgicalTime;
  final String? breviaryWeek;
  final int precedence;
  final String liturgicalColor;
  final bool
      isCelebrable; // false if a higher precedence celebration prevents this office from being celebrated
  final String?
      celebrationDescription; // detailed description of the celebration from YAML

  MiddleOfDayDefinition({
    required this.middleOfDayDescription,
    required this.celebrationCode,
    required this.ferialCode,
    this.commonList,
    this.liturgicalTime,
    this.breviaryWeek,
    required this.precedence,
    required this.isCelebrable,
    required this.liturgicalColor,
    this.celebrationDescription,
  });
}

/// Legacy class name for backwards compatibility
/// @deprecated Use MiddleOfDay instead
typedef MiddleOfDayOffice = MiddleOfDay;
