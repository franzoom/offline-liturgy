class Morning {
  int? celebrationGrade;
  String? celebrationTitle;
  String? invitatoryAntiphon1;
  String? invitatoryAntiphon2;
  String? invitaroryPsalm;
  String? morningHymn;
  String? morningPsalm1Antiphon1;
  String? morningPsalm1Antiphon2;
  String? psalm1Ref;
  String? morningPsalm2Antiphon1;
  String? morningPsalm2Antiphon2;
  String? psalm2Ref;
  String? morningPsalm3Antiphon1;
  String? morningPsalm3Antiphon2;
  String? psalm3Ref;
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

  factory Morning.fromJson(Map<String, dynamic> json) {
    //méthode fromJSON pour instancier la classe à partir d'un fichier JSON
    return Morning()
      ..celebrationGrade = json['celebrationGrade']
      ..celebrationTitle = json['celebrationTitle']
      ..invitatoryAntiphon1 = json['invitatoryAntiphon1']
      ..invitatoryAntiphon2 = json['invitatoryAntiphon2']
      ..invitaroryPsalm = json['invitaroryPsalm']
      ..morningHymn = json['morningHymn']
      ..morningPsalm1Antiphon1 = json['morningPsalm1Antiphon1']
      ..morningPsalm1Antiphon2 = json['morningPsalm1Antiphon2']
      ..psalm1Ref = json['psalm1Ref']
      ..morningPsalm2Antiphon1 = json['morningPsalm2Antiphon1']
      ..morningPsalm2Antiphon2 = json['morningPsalm2Antiphon2']
      ..psalm2Ref = json['psalm2Ref']
      ..morningPsalm3Antiphon1 = json['morningPsalm3Antiphon1']
      ..morningPsalm3Antiphon2 = json['morningPsalm3Antiphon2']
      ..psalm3Ref = json['psalm3Ref']
      ..morningReadingRef = json['morningReadingRef']
      ..morningReading = json['morningReading']
      ..morningResponsory = json['morningResponsory']
      ..morningEvangelicAntiphon = json['morningEvangelicAntiphon']
      ..morningEvangelicAntiphonA = json['morningEvangelicAntiphonA']
      ..morningEvangelicAntiphonB = json['morningEvangelicAntiphonB']
      ..morningEvangelicAntiphonC = json['morningEvangelicAntiphonC']
      ..morningIntercessionDescription = json['morningIntercessionDescription']
      ..morningIntercession = json['morningIntercession']
      ..morningOration = json['morningOration'];
  }

  void mergeWith(Morning morningData) {
    // écrase dans l'instance par les champs non nuls de l'instance morningData
    if (morningData.celebrationGrade != null) {
      celebrationGrade = morningData.celebrationGrade;
    }
    if (morningData.celebrationTitle != null) {
      celebrationTitle = morningData.celebrationTitle;
    }
    if (morningData.invitatoryAntiphon1 != null) {
      invitatoryAntiphon1 = morningData.invitatoryAntiphon1;
    }
    if (morningData.invitatoryAntiphon2 != null) {
      invitatoryAntiphon2 = morningData.invitatoryAntiphon2;
    }
    if (morningData.invitaroryPsalm != null) {
      invitaroryPsalm = morningData.invitaroryPsalm;
    }
    if (morningData.morningHymn != null) {
      morningHymn = morningData.morningHymn;
    }
    if (morningData.morningPsalm1Antiphon1 != null) {
      morningPsalm1Antiphon1 = morningData.morningPsalm1Antiphon1;
    }
    if (morningData.morningPsalm1Antiphon2 != null) {
      morningPsalm1Antiphon2 = morningData.morningPsalm1Antiphon2;
    }
    if (morningData.psalm1Ref != null) {
      psalm1Ref = morningData.psalm1Ref;
    }
    if (morningData.morningPsalm2Antiphon1 != null) {
      morningPsalm2Antiphon1 = morningData.morningPsalm2Antiphon1;
    }
    if (morningData.morningPsalm2Antiphon2 != null) {
      morningPsalm2Antiphon2 = morningData.morningPsalm2Antiphon2;
    }
    if (morningData.psalm2Ref != null) {
      psalm2Ref = morningData.psalm2Ref;
    }
    if (morningData.morningPsalm3Antiphon1 != null) {
      morningPsalm3Antiphon1 = morningData.morningPsalm3Antiphon1;
    }
    if (morningData.morningPsalm3Antiphon2 != null) {
      morningPsalm3Antiphon2 = morningData.morningPsalm3Antiphon2;
    }
    if (morningData.psalm3Ref != null) {
      psalm3Ref = morningData.psalm3Ref;
    }
    if (morningData.morningReadingRef != null) {
      morningReadingRef = morningData.morningReadingRef;
    }
    if (morningData.morningReading != null) {
      morningReading = morningData.morningReading;
    }
    if (morningData.morningResponsory != null) {
      morningResponsory = morningData.morningResponsory;
    }
    if (morningData.morningEvangelicAntiphon != null) {
      morningEvangelicAntiphon = morningData.morningEvangelicAntiphon;
    }
    if (morningData.morningEvangelicAntiphonA != null) {
      morningEvangelicAntiphonA = morningData.morningEvangelicAntiphonA;
    }
    if (morningData.morningEvangelicAntiphonB != null) {
      morningEvangelicAntiphonB = morningData.morningEvangelicAntiphonB;
    }
    if (morningData.morningEvangelicAntiphonC != null) {
      morningEvangelicAntiphonC = morningData.morningEvangelicAntiphonC;
    }
    if (morningData.morningIntercessionDescription != null) {
      morningIntercessionDescription =
          morningData.morningIntercessionDescription;
    }
    if (morningData.morningIntercession != null) {
      morningIntercession = morningData.morningIntercession;
    }
    if (morningData.morningOration != null) {
      morningOration = morningData.morningOration;
    }
  }
}
