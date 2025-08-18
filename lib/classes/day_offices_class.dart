import 'dart:mirrors';

class DayOffices {
  String? commonTitle;
  int? liturgicalGrade;
  String? liturgicalColor;
  String? celebrationTitle;
  String? celebrationSubtitle;
  String? invitatoryAntiphon;
  String? invitatoryAntiphon2;
  String? invitatoryPsalm;
  String? sundayEvangelicAntiphonA;
  String? sundayEvangelicAntiphonB;
  String? sundayEvangelicAntiphonC;
  String? firstVespersHymn;
  String? firstVespersPsalm1Antiphon;
  String? firstVespersPsalm1Antiphon2;
  String? firstVespersPsalm1;
  String? firstVespersPsalm2Antiphon;
  String? firstVespersPsalm2Antiphon2;
  String? firstVespersPsalm2;
  String? firstVespersPsalm3Antiphon;
  String? firstVespersPsalm3Antiphon2;
  String? firstVespersPsalm3;
  String? firstVespersEvangelicAntiphon;
  String? firstVespersReadingRef;
  String? firstVespersReading;
  String? firstVespersIntercession;
  String? firstVespersResponsory;
  String? readingsHymn;
  String? readingsPsalm1Antiphon;
  String? readingsPsalm1;
  String? readingsPsalm2Antiphon;
  String? readingsPsalm2;
  String? readingsPsalm3Antiphon;
  String? readingsPsalm3;
  String? readingsVerse;
  String? readingsBiblicalReadingTitle;
  String? readingsBiblicalReadingRef;
  String? readingsBiblicalReadingContent;
  String? readingsBiblicalReadingResponsory;
  String? readingsBiblicalReadingTitle2;
  String? readingsBiblicalReadingRef2;
  String? readingsBiblicalReadingContent2;
  String? readingsBiblicalReadingResponsory2;
  String? readingsPatristicReadingTitle;
  String? readingsPatristicReadingSubtitle;
  String? readingsPatristicReadingContent;
  String? readingsPatristicReadingResponsory;
  String? readingsPatristicReadingTitle2;
  String? readingsPatristicReadingSubtitle2;
  String? readingsPatristicReadingContent2;
  String? readingsPatristicReadingResponsory2;
  String? readingsPatristicReadingTitle3;
  String? readingsPatristicReadingSubtitle3;
  String? readingsPatristicReadingContent3;
  String? readingsPatristicReadingResponsory3;
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
  String? morningEvangelicAntiphon;
  String? morningReadingRef;
  String? morningReading;
  String? morningIntercessionDescription;
  String? morningIntercession;
  String? morningIntercession2;
  String? morningResponsory;
  String? middleOfDayTierceAntiphon;
  String? middleOfDaySexteAntiphon;
  String? middleOfDayNoneAntiphon;
  String? middleOfDayReading1Ref;
  String? middleOfDayReading1Content;
  String? middleOfDayReading2Ref;
  String? middleOfDayReading2Content;
  String? middleOfDayReading3Ref;
  String? middleOfDayReading3Content;
  String? middleOfDayResponsory1;
  String? middleOfDayResponsory2;
  String? middleOfDayResponsory3;
  String? vespersHymn;
  String? vespersHymn2;
  String? vespersHymn3;
  String? vespersPsalm1Antiphon;
  String? vespersPsalm1Antiphon2;
  String? vespersPsalm1;
  String? vespersPsalm2Antiphon;
  String? vespersPsalm2Antiphon2;
  String? vespersPsalm2;
  String? vespersPsalm3Antiphon;
  String? vespersPsalm3Antiphon2;
  String? vespersPsalm3;
  String? vespersEvangelicAntiphon;
  String? vespersReadingRef;
  String? vespersReading;
  String? vespersIntercession;
  String? vespersResponsory;
  String? oration;
  String? oration2;

  /// Constructeur par défaut
  DayOffices();

  /// Constructeur factory pour créer une instance depuis un JSON
  factory DayOffices.fromJSON(Map<String, dynamic> json) {
    final instance = DayOffices();

    instance.commonTitle = json['commonTitle'] as String?;
    instance.liturgicalGrade = json['liturgicalGrade'] as int?;
    instance.liturgicalColor = json['liturgicalColor'] as String?;
    instance.celebrationTitle = json['celebrationTitle'] as String?;
    instance.celebrationSubtitle = json['celebrationSubtitle'] as String?;
    instance.invitatoryAntiphon = json['invitatoryAntiphon'] as String?;
    instance.invitatoryAntiphon2 = json['invitatoryAntiphon2'] as String?;
    instance.invitatoryPsalm = json['invitatoryPsalm'] as String?;
    instance.sundayEvangelicAntiphonA =
        json['sundayEvangelicAntiphonA'] as String?;
    instance.sundayEvangelicAntiphonB =
        json['sundayEvangelicAntiphonB'] as String?;
    instance.sundayEvangelicAntiphonC =
        json['sundayEvangelicAntiphonC'] as String?;
    instance.firstVespersHymn = json['firstVespersHymn'] as String?;
    instance.firstVespersPsalm1Antiphon =
        json['firstVespersPsalm1Antiphon'] as String?;
    instance.firstVespersPsalm1Antiphon2 =
        json['firstVespersPsalm1Antiphon2'] as String?;
    instance.firstVespersPsalm1 = json['firstVespersPsalm1'] as String?;
    instance.firstVespersPsalm2Antiphon =
        json['firstVespersPsalm2Antiphon'] as String?;
    instance.firstVespersPsalm2Antiphon2 =
        json['firstVespersPsalm2Antiphon2'] as String?;
    instance.firstVespersPsalm2 = json['firstVespersPsalm2'] as String?;
    instance.firstVespersPsalm3Antiphon =
        json['firstVespersPsalm3Antiphon'] as String?;
    instance.firstVespersPsalm3Antiphon2 =
        json['firstVespersPsalm3Antiphon2'] as String?;
    instance.firstVespersPsalm3 = json['firstVespersPsalm3'] as String?;
    instance.firstVespersEvangelicAntiphon =
        json['firstVespersEvangelicAntiphon'] as String?;
    instance.firstVespersReadingRef = json['firstVespersReadingRef'] as String?;
    instance.firstVespersReading = json['firstVespersReading'] as String?;
    instance.firstVespersIntercession =
        json['firstVespersIntercession'] as String?;
    instance.firstVespersResponsory = json['firstVespersResponsory'] as String?;
    instance.readingsHymn = json['readingsHymn'] as String?;
    instance.readingsPsalm1Antiphon = json['readingsPsalm1Antiphon'] as String?;
    instance.readingsPsalm1 = json['readingsPsalm1'] as String?;
    instance.readingsPsalm2Antiphon = json['readingsPsalm2Antiphon'] as String?;
    instance.readingsPsalm2 = json['readingsPsalm2'] as String?;
    instance.readingsPsalm3Antiphon = json['readingsPsalm3Antiphon'] as String?;
    instance.readingsPsalm3 = json['readingsPsalm3'] as String?;
    instance.readingsVerse = json['readingsVerse'] as String?;
    instance.readingsBiblicalReadingTitle =
        json['readingsBiblicalReadingTitle'] as String?;
    instance.readingsBiblicalReadingRef =
        json['readingsBiblicalReadingRef'] as String?;
    instance.readingsBiblicalReadingContent =
        json['readingsBiblicalReadingContent'] as String?;
    instance.readingsBiblicalReadingResponsory =
        json['readingsBiblicalReadingResponsory'] as String?;
    instance.readingsBiblicalReadingTitle2 =
        json['readingsBiblicalReadingTitle2'] as String?;
    instance.readingsBiblicalReadingRef2 =
        json['readingsBiblicalReadingRef2'] as String?;
    instance.readingsBiblicalReadingContent2 =
        json['readingsBiblicalReadingContent2'] as String?;
    instance.readingsBiblicalReadingResponsory2 =
        json['readingsBiblicalReadingResponsory2'] as String?;
    instance.readingsPatristicReadingTitle =
        json['readingsPatristicReadingTitle'] as String?;
    instance.readingsPatristicReadingSubtitle =
        json['readingsPatristicReadingSubtitle'] as String?;
    instance.readingsPatristicReadingContent =
        json['readingsPatristicReadingContent'] as String?;
    instance.readingsPatristicReadingResponsory =
        json['readingsPatristicReadingResponsory'] as String?;
    instance.readingsPatristicReadingTitle2 =
        json['readingsPatristicReadingTitle2'] as String?;
    instance.readingsPatristicReadingSubtitle2 =
        json['readingsPatristicReadingSubtitle2'] as String?;
    instance.readingsPatristicReadingContent2 =
        json['readingsPatristicReadingContent2'] as String?;
    instance.readingsPatristicReadingResponsory2 =
        json['readingsPatristicReadingResponsory2'] as String?;
    instance.readingsPatristicReadingTitle3 =
        json['readingsPatristicReadingTitle3'] as String?;
    instance.readingsPatristicReadingSubtitle3 =
        json['readingsPatristicReadingSubtitle3'] as String?;
    instance.readingsPatristicReadingContent3 =
        json['readingsPatristicReadingContent3'] as String?;
    instance.readingsPatristicReadingResponsory3 =
        json['readingsPatristicReadingResponsory3'] as String?;
    instance.morningHymn = json['morningHymn'] as String?;
    instance.morningPsalm1Antiphon = json['morningPsalm1Antiphon'] as String?;
    instance.morningPsalm1Antiphon2 = json['morningPsalm1Antiphon2'] as String?;
    instance.morningPsalm1 = json['morningPsalm1'] as String?;
    instance.morningPsalm2Antiphon = json['morningPsalm2Antiphon'] as String?;
    instance.morningPsalm2Antiphon2 = json['morningPsalm2Antiphon2'] as String?;
    instance.morningPsalm2 = json['morningPsalm2'] as String?;
    instance.morningPsalm3Antiphon = json['morningPsalm3Antiphon'] as String?;
    instance.morningPsalm3Antiphon2 = json['morningPsalm3Antiphon2'] as String?;
    instance.morningPsalm3 = json['morningPsalm3'] as String?;
    instance.morningEvangelicAntiphon =
        json['morningEvangelicAntiphon'] as String?;
    instance.morningReadingRef = json['morningReadingRef'] as String?;
    instance.morningReading = json['morningReading'] as String?;
    instance.morningIntercessionDescription =
        json['morningIntercessionDescription'] as String?;
    instance.morningIntercession = json['morningIntercession'] as String?;
    instance.morningIntercession2 = json['morningIntercession2'] as String?;
    instance.morningResponsory = json['morningResponsory'] as String?;
    instance.middleOfDayTierceAntiphon =
        json['middleOfDayTierceAntiphon'] as String?;
    instance.middleOfDaySexteAntiphon =
        json['middleOfDaySexteAntiphon'] as String?;
    instance.middleOfDayNoneAntiphon =
        json['middleOfDayNoneAntiphon'] as String?;
    instance.middleOfDayReading1Ref = json['middleOfDayReading1Ref'] as String?;
    instance.middleOfDayReading1Content =
        json['middleOfDayReading1Content'] as String?;
    instance.middleOfDayReading2Ref = json['middleOfDayReading2Ref'] as String?;
    instance.middleOfDayReading2Content =
        json['middleOfDayReading2Content'] as String?;
    instance.middleOfDayReading3Ref = json['middleOfDayReading3Ref'] as String?;
    instance.middleOfDayReading3Content =
        json['middleOfDayReading3Content'] as String?;
    instance.middleOfDayResponsory1 = json['middleOfDayResponsory1'] as String?;
    instance.middleOfDayResponsory2 = json['middleOfDayResponsory2'] as String?;
    instance.middleOfDayResponsory3 = json['middleOfDayResponsory3'] as String?;
    instance.vespersHymn = json['vespersHymn'] as String?;
    instance.vespersHymn2 = json['vespersHymn2'] as String?;
    instance.vespersHymn3 = json['vespersHymn3'] as String?;
    instance.vespersPsalm1Antiphon = json['vespersPsalm1Antiphon'] as String?;
    instance.vespersPsalm1Antiphon2 = json['vespersPsalm1Antiphon2'] as String?;
    instance.vespersPsalm1 = json['vespersPsalm1'] as String?;
    instance.vespersPsalm2Antiphon = json['vespersPsalm2Antiphon'] as String?;
    instance.vespersPsalm2Antiphon2 = json['vespersPsalm2Antiphon2'] as String?;
    instance.vespersPsalm2 = json['vespersPsalm2'] as String?;
    instance.vespersPsalm3Antiphon = json['vespersPsalm3Antiphon'] as String?;
    instance.vespersPsalm3Antiphon2 = json['vespersPsalm3Antiphon2'] as String?;
    instance.vespersPsalm3 = json['vespersPsalm3'] as String?;
    instance.vespersEvangelicAntiphon =
        json['vespersEvangelicAntiphon'] as String?;
    instance.vespersReadingRef = json['vespersReadingRef'] as String?;
    instance.vespersReading = json['vespersReading'] as String?;
    instance.vespersIntercession = json['vespersIntercession'] as String?;
    instance.vespersResponsory = json['vespersResponsory'] as String?;
    instance.oration = json['oration'] as String?;
    instance.oration2 = json['oration2'] as String?;
    return instance;
  }

  /// Superpose les données d'une autre instance DayOffices sur cette instance
  /// Si une valeur existe dans [overlay], elle remplace la valeur existante
  /// Pour les champs avec variants (2, 3), si le variant n'existe pas dans [overlay],
  /// il est supprimé de cette instance
  void overlayWith(DayOffices overlay) {
    // utilisation: dayOffice1.overlayWith(dayOffice2): superpose dayOffice2 sur dayOffice1
    // Utilisation de la réflexion pour obtenir tous les champs
    final mirror = reflect(this);
    final overlayMirror = reflect(overlay);
    final classMirror = mirror.type;

    // Grouper les champs par famille (sans suffixe numérique)
    final fieldFamilies = <String, List<String>>{};

    for (final declaration in classMirror.declarations.values) {
      if (declaration is VariableMirror) {
        final fieldName = MirrorSystem.getName(declaration.simpleName);
        final baseFieldName = _getBaseFieldName(fieldName);

        fieldFamilies.putIfAbsent(baseFieldName, () => []).add(fieldName);
      }
    }

    // Traiter chaque famille de champs
    for (final family in fieldFamilies.values) {
      _processFieldFamily(mirror, overlayMirror, family);
    }
  }

  /// Extrait le nom de base d'un champ (sans suffixe numérique)
  String _getBaseFieldName(String fieldName) {
    final match = RegExp(r'^(.+?)(\d+)?$').firstMatch(fieldName);
    return match?.group(1) ?? fieldName;
  }

  /// Traite une famille de champs (version de base + variants)
  void _processFieldFamily(InstanceMirror mirror, InstanceMirror overlayMirror,
      List<String> family) {
    // Trier pour avoir la version de base en premier
    family.sort((a, b) {
      final aIsBase = !RegExp(r'\d+$').hasMatch(a);
      final bIsBase = !RegExp(r'\d+$').hasMatch(b);

      if (aIsBase && !bIsBase) return -1;
      if (!aIsBase && bIsBase) return 1;
      return a.compareTo(b);
    });

    // Vérifier quels champs existent dans overlay
    final overlayHasFields = <String, bool>{};
    for (final fieldName in family) {
      final overlayValue = overlayMirror.getField(Symbol(fieldName)).reflectee;
      overlayHasFields[fieldName] = overlayValue != null;
    }

    // Appliquer la logique de superposition
    for (final fieldName in family) {
      final isVariant = RegExp(r'\d+$').hasMatch(fieldName);

      if (overlayHasFields[fieldName]!) {
        // Le champ existe dans overlay, on le copie
        final overlayValue =
            overlayMirror.getField(Symbol(fieldName)).reflectee;
        mirror.setField(Symbol(fieldName), overlayValue);
      } else if (isVariant) {
        // C'est un variant qui n'existe pas dans overlay, on le supprime
        mirror.setField(Symbol(fieldName), null);
      }
      // Sinon (champ de base inexistant dans overlay), on ne change rien
    }
  }
}
