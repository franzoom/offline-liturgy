import 'office_elements_class.dart';

/// Class representing the Vespers (Evening Prayer) structure
class Vespers {
  Celebration? celebration;
  List<String>? hymn;
  List<PsalmEntry>? psalmody;
  Reading? reading;
  String? responsory;
  EvangelicAntiphon? evangelicAntiphon;
  Intercession? intercession;
  List<String>? oration;

  Vespers({
    this.celebration,
    this.hymn,
    this.psalmody,
    this.reading,
    this.responsory,
    this.evangelicAntiphon,
    this.intercession,
    this.oration,
  });

  /// Creates Vespers instance from YAML data
  factory Vespers.fromJson(Map<String, dynamic> yamlData) {
    return Vespers(
      celebration: yamlData['celebration'] != null
          ? Celebration.fromJson(
              yamlData['celebration'] as Map<String, dynamic>)
          : null,
      hymn:
          yamlData['hymn'] != null ? List<String>.from(yamlData['hymn']) : null,
      psalmody: yamlData['psalmody'] != null
          ? (yamlData['psalmody'] as List)
              .map((e) => PsalmEntry.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      reading: yamlData['reading'] != null
          ? Reading.fromJson(yamlData['reading'] as Map<String, dynamic>)
          : null,
      responsory: yamlData['responsory'] as String?,
      evangelicAntiphon: yamlData['evangelicAntiphon'] != null
          ? EvangelicAntiphon.fromJson(
              yamlData['evangelicAntiphon'] as Map<String, dynamic>)
          : null,
      intercession: yamlData['intercession'] != null
          ? Intercession.fromJson(
              yamlData['intercession'] as Map<String, dynamic>)
          : null,
      oration: yamlData['oration'] != null
          ? List<String>.from(yamlData['oration'])
          : null,
    );
  }

  /// Overlays this Vespers instance with data from another Vespers instance
  /// Non-null fields from the overlay take precedence
  /// For psalmody: intelligently merges psalms and antiphons
  void overlayWith(Vespers overlay) {
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
    if (overlay.reading != null) {
      reading = overlay.reading;
    }
    if (overlay.responsory != null) {
      responsory = overlay.responsory;
    }
    if (overlay.evangelicAntiphon != null) {
      evangelicAntiphon = overlay.evangelicAntiphon;
    }
    if (overlay.intercession != null) {
      intercession = overlay.intercession;
    }
    if (overlay.oration != null) {
      oration = overlay.oration;
    }
  }

  /// Selective overlay for common when precedence > 6
  /// Only overlays: reading, responsory, evangelicAntiphon, intercession, oration
  /// Does NOT overlay: celebration, hymn, psalmody
  void overlayWithCommon(Vespers commonVespers) {
    if (commonVespers.reading != null) {
      reading = commonVespers.reading;
    }
    if (commonVespers.responsory != null) {
      responsory = commonVespers.responsory;
    }
    if (commonVespers.evangelicAntiphon != null) {
      evangelicAntiphon = commonVespers.evangelicAntiphon;
    }
    if (commonVespers.intercession != null) {
      intercession = commonVespers.intercession;
    }
    if (commonVespers.oration != null) {
      oration = commonVespers.oration;
    }
  }

  /// Returns true if all fields are null (empty Vespers)
  bool get isEmpty =>
      celebration == null &&
      hymn == null &&
      psalmody == null &&
      reading == null &&
      responsory == null &&
      evangelicAntiphon == null &&
      intercession == null &&
      oration == null;
}

/// Definition of Vespers type for a given day
/// This class is used to transmit informations through the resolution of the possible Vespers Offices
class VespersDefinition {
  final String
      vespersDescription; // description of the office (e.g., "Vespers of the 2nd Sunday of Lent")
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
  final bool
      isFirstVespers; // true if these are First Vespers (I Vespers) of a following day celebration

  VespersDefinition({
    required this.vespersDescription,
    required this.celebrationCode,
    required this.ferialCode,
    this.commonList,
    this.liturgicalTime,
    this.breviaryWeek,
    required this.precedence,
    required this.isCelebrable,
    required this.liturgicalColor,
    this.celebrationDescription,
    this.isFirstVespers = false,
  });
}
