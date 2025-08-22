class Morning {
  String? celebrationTitle;
  String? celebrationSubtitle;
  String? celebrationDescription;
  String? commonTitle;
  int? liturgicalGrade;
  String? liturgicalColor;
  String? invitatoryAntiphon;
  String? invitatoryAntiphon2;
  List? invitaroryPsalms;
  String? morningHymn;
  String? morningPsalm1Antiphon;
  String? morningPsalm1Antiphon2;
  String? morningPsalm1;
  String? morningPsalm2Antiphon;
  String? morningPsalm2Antiphon2;
  String? morningPsalm2;
  String? morningPsalm3Antiphon;
  String? morningPsalm3Antiphon2;
  String? morningPsalm3;
  String? morningReadingRef;
  String? morningReading;
  String? morningResponsory;
  String? morningEvangelicAntiphon;
  String? morningEvangelicAntiphonA;
  String? morningEvangelicAntiphonB;
  String? morningEvangelicAntiphonC;
  String? morningIntercessionDescription;
  String? morningIntercession;
  String? morningOration;

  Morning();

  /// Overlays data from another Morning instance onto this instance
  /// If a value exists in [overlay], it replaces the existing value
  /// For fields with variants (2, 3), if the variant doesn't exist in [overlay],
  /// it is removed from this instance
  void overlay(Morning overlay) {
    // Simple fields - replace if overlay has a value
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
    if (overlay.invitaroryPsalms != null) {
      invitaroryPsalms = overlay.invitaroryPsalms;
    }
    if (overlay.morningHymn != null) {
      morningHymn = overlay.morningHymn;
    }
    if (overlay.morningReadingRef != null) {
      morningReadingRef = overlay.morningReadingRef;
    }
    if (overlay.morningReading != null) {
      morningReading = overlay.morningReading;
    }
    if (overlay.morningResponsory != null) {
      morningResponsory = overlay.morningResponsory;
    }
    if (overlay.morningIntercessionDescription != null) {
      morningIntercessionDescription = overlay.morningIntercessionDescription;
    }
    if (overlay.morningIntercession != null) {
      morningIntercession = overlay.morningIntercession;
    }
    if (overlay.morningOration != null) {
      morningOration = overlay.morningOration;
    }

    // Handling fields with variants - invitatoryAntiphon
    if (overlay.invitatoryAntiphon != null) {
      invitatoryAntiphon = overlay.invitatoryAntiphon;
      // If overlay doesn't have variant 2, remove it
      if (overlay.invitatoryAntiphon2 == null) {
        invitatoryAntiphon2 = null;
      }
    }
    if (overlay.invitatoryAntiphon2 != null) {
      invitatoryAntiphon2 = overlay.invitatoryAntiphon2;
    }

    // Handling fields with variants - morningPsalm1
    if (overlay.morningPsalm1 != null) {
      morningPsalm1 = overlay.morningPsalm1;
    }
    if (overlay.morningPsalm1Antiphon != null) {
      morningPsalm1Antiphon = overlay.morningPsalm1Antiphon;
      // If overlay doesn't have variant 2, remove it
      if (overlay.morningPsalm1Antiphon2 == null) {
        morningPsalm1Antiphon2 = null;
      }
    }
    if (overlay.morningPsalm1Antiphon2 != null) {
      morningPsalm1Antiphon2 = overlay.morningPsalm1Antiphon2;
    }

    // Handling fields with variants - morningPsalm2
    if (overlay.morningPsalm2 != null) {
      morningPsalm2 = overlay.morningPsalm2;
    }
    if (overlay.morningPsalm2Antiphon != null) {
      morningPsalm2Antiphon = overlay.morningPsalm2Antiphon;
      // If overlay doesn't have variant 2, remove it
      if (overlay.morningPsalm2Antiphon2 == null) {
        morningPsalm2Antiphon2 = null;
      }
    }
    if (overlay.morningPsalm2Antiphon2 != null) {
      morningPsalm2Antiphon2 = overlay.morningPsalm2Antiphon2;
    }

    // Handling fields with variants - morningPsalm3
    if (overlay.morningPsalm3 != null) {
      morningPsalm3 = overlay.morningPsalm3;
    }
    if (overlay.morningPsalm3Antiphon != null) {
      morningPsalm3Antiphon = overlay.morningPsalm3Antiphon;
      // If overlay doesn't have variant 2, remove it
      if (overlay.morningPsalm3Antiphon2 == null) {
        morningPsalm3Antiphon2 = null;
      }
    }
    if (overlay.morningPsalm3Antiphon2 != null) {
      morningPsalm3Antiphon2 = overlay.morningPsalm3Antiphon2;
    }

    // Handling fields with variants - morningEvangelicAntiphon
    if (overlay.morningEvangelicAntiphon != null) {
      morningEvangelicAntiphon = overlay.morningEvangelicAntiphon;
      // If overlay doesn't have variants A, B, C, remove them
      if (overlay.morningEvangelicAntiphonA == null) {
        morningEvangelicAntiphonA = null;
      }
      if (overlay.morningEvangelicAntiphonB == null) {
        morningEvangelicAntiphonB = null;
      }
      if (overlay.morningEvangelicAntiphonC == null) {
        morningEvangelicAntiphonC = null;
      }
    }
    if (overlay.morningEvangelicAntiphonA != null) {
      morningEvangelicAntiphonA = overlay.morningEvangelicAntiphonA;
    }
    if (overlay.morningEvangelicAntiphonB != null) {
      morningEvangelicAntiphonB = overlay.morningEvangelicAntiphonB;
    }
    if (overlay.morningEvangelicAntiphonC != null) {
      morningEvangelicAntiphonC = overlay.morningEvangelicAntiphonC;
    }
  }

  void setInvitatoryPsalms() {
    List<String> availablePsalms = [
      'PSALM_94',
      'PSALM_99',
      'PSALM_66',
      'PSALM_23'
    ];
    List<String> usedPsalms = [];

    if (morningPsalm1 != null && morningPsalm1!.isNotEmpty) {
      usedPsalms.add(morningPsalm1!);
    }

    if (morningPsalm3 != null && morningPsalm3!.isNotEmpty) {
      usedPsalms.add(morningPsalm3!);
    }

    invitaroryPsalms =
        availablePsalms.where((psalm) => !usedPsalms.contains(psalm)).toList();
  }
}
