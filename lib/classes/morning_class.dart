import 'office_elements_class.dart';

/// Class representing the Morning Prayer (Laudes) structure
class Morning {
  Celebration? celebration;
  Invitatory? invitatory;
  List<String>? hymn;
  List<PsalmEntry>? psalmody;
  Reading? reading;
  String? responsory;
  EvangelicAntiphon? evangelicAntiphon;
  Intercession? intercession;
  bool? tedeum;
  List<String>? oration;

  Morning({
    this.celebration,
    this.invitatory,
    this.hymn,
    this.psalmody,
    this.reading,
    this.responsory,
    this.evangelicAntiphon,
    this.intercession,
    this.tedeum,
    this.oration,
  });

  /// Creates Morning instance from JSON data
  factory Morning.fromJson(Map<String, dynamic> json) {
    return Morning(
      celebration: json['celebration'] != null
          ? Celebration.fromJson(json['celebration'] as Map<String, dynamic>)
          : null,
      invitatory: json['invitatory'] != null
          ? Invitatory.fromJson(json['invitatory'] as Map<String, dynamic>)
          : null,
      hymn: json['hymn'] != null ? List<String>.from(json['hymn']) : null,
      psalmody: json['psalmody'] != null
          ? (json['psalmody'] as List)
              .map((e) => PsalmEntry.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      reading: json['reading'] != null
          ? Reading.fromJson(json['reading'] as Map<String, dynamic>)
          : null,
      responsory: json['responsory'] as String?,
      evangelicAntiphon: json['evangelicAntiphon'] != null
          ? EvangelicAntiphon.fromJson(
              json['evangelicAntiphon'] as Map<String, dynamic>)
          : null,
      intercession: json['intercession'] != null
          ? Intercession.fromJson(json['intercession'] as Map<String, dynamic>)
          : null,
      tedeum: json['tedeum'] as bool?,
      oration:
          json['oration'] != null ? List<String>.from(json['oration']) : null,
    );
  }

  /// Overlays this Morning instance with data from another Morning instance
  /// Non-null fields from the overlay take precedence
  /// For psalmody: intelligently merges psalms and antiphons
  void overlayWith(Morning overlay) {
    if (overlay.celebration != null) {
      celebration = overlay.celebration;
    }
    if (overlay.invitatory != null) {
      invitatory = overlay.invitatory;
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
    if (overlay.tedeum != null) {
      tedeum = overlay.tedeum;
    }
    if (overlay.oration != null) {
      oration = overlay.oration;
    }
  }

  /// Selective overlay for common when precedence > 6
  /// Only overlays: invitatory, reading, responsory, evangelicAntiphon, intercession, oration
  /// Does NOT overlay: celebration, hymn, psalmody, tedeum
  void overlayWithCommon(Morning commonMorning) {
    if (commonMorning.invitatory != null) {
      invitatory = commonMorning.invitatory;
    }
    if (commonMorning.reading != null) {
      reading = commonMorning.reading;
    }
    if (commonMorning.responsory != null) {
      responsory = commonMorning.responsory;
    }
    if (commonMorning.evangelicAntiphon != null) {
      evangelicAntiphon = commonMorning.evangelicAntiphon;
    }
    if (commonMorning.intercession != null) {
      intercession = commonMorning.intercession;
    }
    if (commonMorning.oration != null) {
      oration = commonMorning.oration;
    }
  }

  /// Returns true if all fields are null (empty Morning)
  /// use of a direct short-cut: if on element is not empty, returns false.
  bool isEmpty() {
    if (celebration != null) return false;
    if (invitatory != null) return false;
    if (hymn != null) return false;
    if (psalmody != null) return false;
    if (reading != null) return false;
    if (responsory != null) return false;
    if (evangelicAntiphon != null) return false;
    if (intercession != null) return false;
    if (tedeum != null) return false;
    if (oration != null) return false;
    return true;
  }
}

/// Definition of Morning type for a given day
/// This class is used to transmit informations through the resolution of the possible Morning Offices
class MorningDefinition {
  final String
      morningDescription; // description of the office (e.g., "morning Office of the 2nd sunday of Lent")
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

  MorningDefinition({
    required this.morningDescription,
    required this.celebrationCode,
    required this.ferialCode,
    this.commonList,
    this.liturgicalTime,
    this.breviaryWeek,
    required this.precedence,
    required this.isCelebrable,
    required this.liturgicalColor,
  });
}
