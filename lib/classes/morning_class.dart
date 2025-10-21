import 'day_offices_class.dart';
import 'office_structures.dart';

/// Morning prayer class with deeply nested structure support
/// Extracts data from DayOffices and provides helper methods for access
class Morning {
  // General celebration information
  String? celebrationTitle;
  String? celebrationSubtitle;
  String? celebrationDescription;
  String? commonTitle;
  int? liturgicalGrade;
  String? liturgicalColor;

  // Invitatory data (keeps prefix as it's not part of morning office proper)
  List<String>? invitatoryAntiphon;
  List? invitatoryPsalms;

  // Morning office elements (no prefix needed - we're in Morning class)
  List<String>? hymn;
  List<PsalmEntry>? psalmody;

  // Reading fields (extracted from nested object)
  String? readingRef;
  String? reading;

  String? responsory;
  String? evangelicAntiphon;
  String? evangelicAntiphonA;
  String? evangelicAntiphonB;
  String? evangelicAntiphonC;
  String? intercessionDescription;
  String? intercession;
  String? oration;

  Morning({
    this.celebrationTitle,
    this.celebrationSubtitle,
    this.celebrationDescription,
    this.commonTitle,
    this.liturgicalGrade,
    this.liturgicalColor,
    this.invitatoryAntiphon,
    this.invitatoryPsalms,
    this.hymn,
    this.psalmody,
    this.readingRef,
    this.reading,
    this.responsory,
    this.evangelicAntiphon,
    this.evangelicAntiphonA,
    this.evangelicAntiphonB,
    this.evangelicAntiphonC,
    this.intercessionDescription,
    this.intercession,
    this.oration,
  });

  /// Creates a Morning instance from DayOffices data
  /// Maps corresponding fields from DayOffices to Morning
  static Morning fromDayOffices(DayOffices dayOffices) {
    return Morning()
      // Direct field mappings
      ..celebrationTitle = dayOffices.celebrationTitle
      ..celebrationSubtitle = dayOffices.celebrationSubtitle
      ..celebrationDescription = dayOffices.celebrationDescription
      ..liturgicalGrade = dayOffices.liturgicalGrade
      ..liturgicalColor = dayOffices.liturgicalColor

      // Invitatory data - now a list
      ..invitatoryAntiphon = dayOffices.invitatory?.antiphon

      // Morning office data
      ..hymn = dayOffices.morning?.hymn
      ..psalmody = dayOffices.morning?.psalmody

      // Reading - extract from nested object
      ..readingRef = dayOffices.morning?.reading?.ref
      ..reading = dayOffices.morning?.reading?.content
      ..responsory = dayOffices.morning?.responsory
      ..evangelicAntiphon =
          dayOffices.morning?.evangelicAntiphon ?? dayOffices.evangelicAntiphon
      ..evangelicAntiphonA = dayOffices.morning?.evangelicAntiphonA ??
          dayOffices.sundayEvangelicAntiphonA
      ..evangelicAntiphonB = dayOffices.morning?.evangelicAntiphonB ??
          dayOffices.sundayEvangelicAntiphonB
      ..evangelicAntiphonC = dayOffices.morning?.evangelicAntiphonC ??
          dayOffices.sundayEvangelicAntiphonC
      ..intercessionDescription = dayOffices.morning?.intercessionDescription
      ..intercession = dayOffices.morning?.intercession
      ..oration = dayOffices.morning?.oration ?? dayOffices.oration;
  }

  /// Overlays data from another Morning instance onto this instance
  /// If a value exists in [overlay], it replaces the existing value
  void overlayWith(Morning overlay) {
    if (overlay.celebrationTitle != null) {
      celebrationTitle = overlay.celebrationTitle;
    }
    if (overlay.celebrationSubtitle != null) {
      celebrationSubtitle = overlay.celebrationSubtitle;
    }
    if (overlay.celebrationDescription != null) {
      celebrationDescription = overlay.celebrationDescription;
    }
    if (overlay.commonTitle != null) {
      commonTitle = overlay.commonTitle;
    }
    if (overlay.liturgicalGrade != null) {
      liturgicalGrade = overlay.liturgicalGrade;
    }
    if (overlay.liturgicalColor != null) {
      liturgicalColor = overlay.liturgicalColor;
    }
    if (overlay.invitatoryPsalms != null) {
      invitatoryPsalms = overlay.invitatoryPsalms;
    }
    if (overlay.hymn != null) {
      hymn = overlay.hymn;
    }
    if (overlay.readingRef != null) {
      readingRef = overlay.readingRef;
    }
    if (overlay.reading != null) {
      reading = overlay.reading;
    }
    if (overlay.responsory != null) {
      responsory = overlay.responsory;
    }
    if (overlay.intercessionDescription != null) {
      intercessionDescription = overlay.intercessionDescription;
    }
    if (overlay.intercession != null) {
      intercession = overlay.intercession;
    }
    if (overlay.oration != null) {
      oration = overlay.oration;
    }

    // Psalmody - replace entire list if overlay has one
    if (overlay.psalmody != null) {
      psalmody = overlay.psalmody;
    }

    // Invitatory antiphon - now a list
    if (overlay.invitatoryAntiphon != null) {
      invitatoryAntiphon = overlay.invitatoryAntiphon;
    }

    // Evangelic antiphon variants
    if (overlay.evangelicAntiphon != null) {
      evangelicAntiphon = overlay.evangelicAntiphon;
      if (overlay.evangelicAntiphonA == null) {
        evangelicAntiphonA = null;
      }
      if (overlay.evangelicAntiphonB == null) {
        evangelicAntiphonB = null;
      }
      if (overlay.evangelicAntiphonC == null) {
        evangelicAntiphonC = null;
      }
    }
    if (overlay.evangelicAntiphonA != null) {
      evangelicAntiphonA = overlay.evangelicAntiphonA;
    }
    if (overlay.evangelicAntiphonB != null) {
      evangelicAntiphonB = overlay.evangelicAntiphonB;
    }
    if (overlay.evangelicAntiphonC != null) {
      evangelicAntiphonC = overlay.evangelicAntiphonC;
    }
  }

  /// Sets the list of available invitatory psalms
  /// Removes psalms already used in the morning office
  void setInvitatoryPsalms() {
    List<String> availablePsalms = [
      'PSALM_94',
      'PSALM_99',
      'PSALM_66',
      'PSALM_23'
    ];
    List<String> usedPsalms = [];

    // Extract psalms from psalmody list
    if (psalmody != null) {
      for (var entry in psalmody!) {
        if (entry.psalm.isNotEmpty) {
          usedPsalms.add(entry.psalm);
        }
      }
    }

    invitatoryPsalms =
        availablePsalms.where((psalm) => !usedPsalms.contains(psalm)).toList();
  }

  // ============================================================================
  // Helper methods for accessing psalm data
  // ============================================================================

  /// Get psalm reference by index in psalmody
  String? getPsalm(int index) {
    if (psalmody == null || index >= psalmody!.length) return null;
    return psalmody![index].psalm;
  }

  /// Get list of antiphons for a psalm by index
  List<String>? getAntiphonList(int index) {
    if (psalmody == null || index >= psalmody!.length) return null;
    return psalmody![index].antiphon;
  }

  /// Get specific antiphon by psalm index and antiphon index
  ///
  /// Example: getAntiphon(0, 0) returns first antiphon of first psalm
  String? getAntiphon(int psalmodyIndex, int antiphonIndex) {
    final antiphonList = getAntiphonList(psalmodyIndex);
    if (antiphonList == null || antiphonIndex >= antiphonList.length)
      return null;
    return antiphonList[antiphonIndex];
  }

  // ============================================================================
  // Helper methods for accessing reading data
  // ============================================================================

  /// Get reading reference
  String? getReadingRef() {
    return readingRef;
  }

  /// Get reading content
  String? getReadingContent() {
    return reading;
  }

  // ============================================================================
  // Helper methods for accessing invitatory data
  // ============================================================================

  /// Get invitatory antiphon by index
  ///
  /// Example: getInvitatoryAntiphon(0) returns first invitatory antiphon
  String? getInvitatoryAntiphon(int index) {
    if (invitatoryAntiphon == null || index >= invitatoryAntiphon!.length) {
      return null;
    }
    return invitatoryAntiphon![index];
  }

  /// Get count of invitatory antiphons
  int getInvitatoryAntiphonCount() {
    return invitatoryAntiphon?.length ?? 0;
  }

  // ============================================================================
  // Helper methods for accessing psalmody counts
  // ============================================================================

  /// Get number of psalms in psalmody
  int getPsalmodyCount() {
    return psalmody?.length ?? 0;
  }

  /// Get number of antiphons for a specific psalm
  int getAntiphonCount(int psalmodyIndex) {
    final antiphonList = getAntiphonList(psalmodyIndex);
    return antiphonList?.length ?? 0;
  }
}
