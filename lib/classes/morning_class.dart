import 'day_offices_class.dart';
import 'office_structures.dart';

/// Morning prayer class with deeply nested structure support
/// Extracts data from DayOffices and provides helper methods for access
class Morning {
  // Celebration information (nested object)
  Celebration? celebration;

  // Invitatory data (nested object)
  Invitatory? invitatory;

  // Morning office elements
  List<String>? hymn;
  List<PsalmEntry>? psalmody;

  // Reading (nested object)
  Reading? reading;

  String? responsory;

  // Evangelic antiphon (nested object)
  EvangelicAntiphon? evangelicAntiphon;

  // Intercession (nested object)
  Intercession? intercession;

  // Oration as list
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
    this.oration,
  });

  /// Creates a Morning instance from DayOffices data
  /// Maps corresponding fields from DayOffices to Morning
  static Morning fromDayOffices(DayOffices dayOffices) {
    // Build Celebration object
    Celebration? celebration;
    if (dayOffices.celebration != null) {
      celebration = Celebration(
        title: dayOffices.celebration!.title,
        subtitle: dayOffices.celebration!.subtitle,
        description: dayOffices.celebration!.description,
        commons: dayOffices.celebration!.commons,
        grade: dayOffices.celebration!.grade,
        color: dayOffices.celebration!.color,
      );
    }

    // Build Invitatory object
    Invitatory? invitatory;
    if (dayOffices.invitatory != null) {
      invitatory = Invitatory(
        antiphon: dayOffices.invitatory!.antiphon,
        psalms: null, // Will be set by setInvitatoryPsalms
      );
    }

    // Build Reading object
    Reading? reading;
    if (dayOffices.morning?.reading != null) {
      reading = Reading(
        biblicalReference: dayOffices.morning!.reading!.biblicalReference,
        content: dayOffices.morning!.reading!.content,
      );
    }

    // Build EvangelicAntiphon object
    EvangelicAntiphon? evangelicAntiphon;

    // Priority:
    // 1. Use morning.evangelicAntiphon object if it exists (already structured)
    // 2. Fall back to legacy root-level fields
    if (dayOffices.morning?.evangelicAntiphon != null) {
      evangelicAntiphon = EvangelicAntiphon(
        common: dayOffices.morning!.evangelicAntiphon!.common,
        yearA: dayOffices.morning!.evangelicAntiphon!.yearA,
        yearB: dayOffices.morning!.evangelicAntiphon!.yearB,
        yearC: dayOffices.morning!.evangelicAntiphon!.yearC,
      );
    } else if (dayOffices.evangelicAntiphon != null ||
        dayOffices.sundayEvangelicAntiphonA != null ||
        dayOffices.sundayEvangelicAntiphonB != null ||
        dayOffices.sundayEvangelicAntiphonC != null) {
      // Legacy: build from root-level fields
      evangelicAntiphon = EvangelicAntiphon(
        common: dayOffices.evangelicAntiphon,
        yearA: dayOffices.sundayEvangelicAntiphonA,
        yearB: dayOffices.sundayEvangelicAntiphonB,
        yearC: dayOffices.sundayEvangelicAntiphonC,
      );
    }

    // Build Intercession object
    Intercession? intercession;
    if (dayOffices.morning?.intercession != null) {
      intercession = Intercession(
        description: dayOffices.morning!.intercession!.description,
        content: dayOffices.morning!.intercession!.content,
      );
    }

    // Build oration list
    List<String>? oration;
    if (dayOffices.morning?.oration != null) {
      oration = List<String>.from(dayOffices.morning!.oration!);
    } else if (dayOffices.oration != null) {
      oration = List<String>.from(dayOffices.oration!);
    }

    return Morning(
      celebration: celebration,
      invitatory: invitatory,
      hymn: dayOffices.morning?.hymn,
      psalmody: dayOffices.morning?.psalmody,
      reading: reading,
      responsory: dayOffices.morning?.responsory,
      evangelicAntiphon: evangelicAntiphon,
      intercession: intercession,
      oration: oration,
    );
  }

  /// Overlays data from another Morning instance onto this instance
  /// If a value exists in [overlay], it replaces the existing value
  void overlayWith(Morning overlay) {
    // Celebration - field by field
    if (overlay.celebration != null) {
      if (celebration == null) {
        celebration = Celebration(
          title: overlay.celebration!.title,
          subtitle: overlay.celebration!.subtitle,
          description: overlay.celebration!.description,
          commons: overlay.celebration!.commons,
          grade: overlay.celebration!.grade,
          color: overlay.celebration!.color,
        );
      } else {
        if (overlay.celebration!.title != null) {
          celebration = Celebration(
            title: overlay.celebration!.title,
            subtitle: celebration!.subtitle,
            description: celebration!.description,
            commons: celebration!.commons,
            grade: celebration!.grade,
            color: celebration!.color,
          );
        }
        if (overlay.celebration!.subtitle != null) {
          celebration = Celebration(
            title: celebration!.title,
            subtitle: overlay.celebration!.subtitle,
            description: celebration!.description,
            commons: celebration!.commons,
            grade: celebration!.grade,
            color: celebration!.color,
          );
        }
        if (overlay.celebration!.description != null) {
          celebration = Celebration(
            title: celebration!.title,
            subtitle: celebration!.subtitle,
            description: overlay.celebration!.description,
            commons: celebration!.commons,
            grade: celebration!.grade,
            color: celebration!.color,
          );
        }
        if (overlay.celebration!.commons != null) {
          celebration = Celebration(
            title: celebration!.title,
            subtitle: celebration!.subtitle,
            description: celebration!.description,
            commons: overlay.celebration!.commons,
            grade: celebration!.grade,
            color: celebration!.color,
          );
        }
        if (overlay.celebration!.grade != null) {
          celebration = Celebration(
            title: celebration!.title,
            subtitle: celebration!.subtitle,
            description: celebration!.description,
            commons: celebration!.commons,
            grade: overlay.celebration!.grade,
            color: celebration!.color,
          );
        }
        if (overlay.celebration!.color != null) {
          celebration = Celebration(
            title: celebration!.title,
            subtitle: celebration!.subtitle,
            description: celebration!.description,
            commons: celebration!.commons,
            grade: celebration!.grade,
            color: overlay.celebration!.color,
          );
        }
      }
    }

    // Invitatory - field by field
    if (overlay.invitatory != null) {
      if (invitatory == null) {
        invitatory = Invitatory(
          antiphon: overlay.invitatory!.antiphon,
          psalms: overlay.invitatory!.psalms,
        );
      } else {
        if (overlay.invitatory!.antiphon != null) {
          invitatory = Invitatory(
            antiphon: overlay.invitatory!.antiphon,
            psalms: invitatory!.psalms,
          );
        }
        if (overlay.invitatory!.psalms != null) {
          invitatory = Invitatory(
            antiphon: invitatory!.antiphon,
            psalms: overlay.invitatory!.psalms,
          );
        }
      }
    }

    // Hymn
    if (overlay.hymn != null) {
      hymn = overlay.hymn;
    }

    // Reading - field by field
    if (overlay.reading != null) {
      if (reading == null) {
        reading = Reading(
          biblicalReference: overlay.reading!.biblicalReference,
          content: overlay.reading!.content,
        );
      } else {
        if (overlay.reading!.biblicalReference != null) {
          reading = Reading(
            biblicalReference: overlay.reading!.biblicalReference,
            content: reading!.content,
          );
        }
        if (overlay.reading!.content != null) {
          reading = Reading(
            biblicalReference: reading!.biblicalReference,
            content: overlay.reading!.content,
          );
        }
      }
    }

    // Responsory
    if (overlay.responsory != null) {
      responsory = overlay.responsory;
    }

    // Psalmody - replace entire list if overlay has one
    if (overlay.psalmody != null) {
      psalmody = overlay.psalmody;
    }

    // Evangelic antiphon - field by field
    if (overlay.evangelicAntiphon != null) {
      if (evangelicAntiphon == null) {
        evangelicAntiphon = EvangelicAntiphon(
          common: overlay.evangelicAntiphon!.common,
          yearA: overlay.evangelicAntiphon!.yearA,
          yearB: overlay.evangelicAntiphon!.yearB,
          yearC: overlay.evangelicAntiphon!.yearC,
        );
      } else {
        if (overlay.evangelicAntiphon!.common != null) {
          evangelicAntiphon = EvangelicAntiphon(
            common: overlay.evangelicAntiphon!.common,
            yearA: overlay.evangelicAntiphon!.yearA ?? evangelicAntiphon!.yearA,
            yearB: overlay.evangelicAntiphon!.yearB ?? evangelicAntiphon!.yearB,
            yearC: overlay.evangelicAntiphon!.yearC ?? evangelicAntiphon!.yearC,
          );
        }
        if (overlay.evangelicAntiphon!.yearA != null) {
          evangelicAntiphon = EvangelicAntiphon(
            common: evangelicAntiphon!.common,
            yearA: overlay.evangelicAntiphon!.yearA,
            yearB: evangelicAntiphon!.yearB,
            yearC: evangelicAntiphon!.yearC,
          );
        }
        if (overlay.evangelicAntiphon!.yearB != null) {
          evangelicAntiphon = EvangelicAntiphon(
            common: evangelicAntiphon!.common,
            yearA: evangelicAntiphon!.yearA,
            yearB: overlay.evangelicAntiphon!.yearB,
            yearC: evangelicAntiphon!.yearC,
          );
        }
        if (overlay.evangelicAntiphon!.yearC != null) {
          evangelicAntiphon = EvangelicAntiphon(
            common: evangelicAntiphon!.common,
            yearA: evangelicAntiphon!.yearA,
            yearB: evangelicAntiphon!.yearB,
            yearC: overlay.evangelicAntiphon!.yearC,
          );
        }
      }
    }

    // Intercession - field by field
    if (overlay.intercession != null) {
      if (intercession == null) {
        intercession = Intercession(
          description: overlay.intercession!.description,
          content: overlay.intercession!.content,
        );
      } else {
        if (overlay.intercession!.description != null) {
          intercession = Intercession(
            description: overlay.intercession!.description,
            content: intercession!.content,
          );
        }
        if (overlay.intercession!.content != null) {
          intercession = Intercession(
            description: intercession!.description,
            content: overlay.intercession!.content,
          );
        }
      }
    }

    // Oration
    if (overlay.oration != null) {
      oration = overlay.oration;
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

    List filteredPsalms =
        availablePsalms.where((psalm) => !usedPsalms.contains(psalm)).toList();

    if (invitatory == null) {
      invitatory = Invitatory(
        antiphon: null,
        psalms: filteredPsalms,
      );
    } else {
      invitatory = Invitatory(
        antiphon: invitatory!.antiphon,
        psalms: filteredPsalms,
      );
    }
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

  /// Get reading biblical reference
  String? getReadingBiblicalReference() {
    return reading?.biblicalReference;
  }

  /// Get reading content
  String? getReadingContent() {
    return reading?.content;
  }

  // ============================================================================
  // Helper methods for accessing invitatory data
  // ============================================================================

  /// Get invitatory antiphon by index
  ///
  /// Example: getInvitatoryAntiphon(0) returns first invitatory antiphon
  String? getInvitatoryAntiphon(int index) {
    if (invitatory?.antiphon == null || index >= invitatory!.antiphon!.length) {
      return null;
    }
    return invitatory!.antiphon![index];
  }

  /// Get count of invitatory antiphons
  int getInvitatoryAntiphonCount() {
    return invitatory?.antiphon?.length ?? 0;
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

  // ============================================================================
  // Helper methods for accessing evangelic antiphon
  // ============================================================================

  /// Get common evangelic antiphon
  String? getEvangelicAntiphonCommon() {
    return evangelicAntiphon?.common;
  }

  /// Get evangelic antiphon for year A
  String? getEvangelicAntiphonYearA() {
    return evangelicAntiphon?.yearA;
  }

  /// Get evangelic antiphon for year B
  String? getEvangelicAntiphonYearB() {
    return evangelicAntiphon?.yearB;
  }

  /// Get evangelic antiphon for year C
  String? getEvangelicAntiphonYearC() {
    return evangelicAntiphon?.yearC;
  }

  // ============================================================================
  // Helper methods for accessing intercession
  // ============================================================================

  /// Get intercession description
  String? getIntercessionDescription() {
    return intercession?.description;
  }

  /// Get intercession content
  String? getIntercessionContent() {
    return intercession?.content;
  }

  // ============================================================================
  // Helper methods for accessing oration
  // ============================================================================

  /// Get oration by index
  ///
  /// Example: getOration(0) returns first oration
  String? getOration(int index) {
    if (oration == null || index >= oration!.length) {
      return null;
    }
    return oration![index];
  }

  /// Get count of orations
  int getOrationCount() {
    return oration?.length ?? 0;
  }

  // ============================================================================
  // Helper methods for accessing celebration data
  // ============================================================================

  /// Get celebration title
  String? getCelebrationTitle() {
    return celebration?.title;
  }

  /// Get celebration subtitle
  String? getCelebrationSubtitle() {
    return celebration?.subtitle;
  }

  /// Get celebration description
  String? getCelebrationDescription() {
    return celebration?.description;
  }

  /// Get celebration commons
  List? getCelebrationCommons() {
    return celebration?.commons;
  }

  /// Get liturgical grade
  int? getLiturgicalGrade() {
    return celebration?.grade;
  }

  /// Get liturgical color
  String? getLiturgicalColor() {
    return celebration?.color;
  }
}
