class Morning {
  int? liturgicalGrade;
  String? celebrationTitle;
  String? invitatoryAntiphon;
  String? invitatoryAntiphon2;
  String? invitaroryPsalm;
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

  factory Morning.fromJson(Map<String, dynamic> json) {
    //méthode fromJSON pour instancier la classe à partir d'un fichier JSON
    return Morning()
      ..liturgicalGrade = json['liturgicalGrade']
      ..celebrationTitle = json['celebrationTitle']
      ..invitatoryAntiphon = json['invitatoryAntiphon']
      ..invitatoryAntiphon2 = json['invitatoryAntiphon2']
      ..invitaroryPsalm = json['invitaroryPsalm']
      ..morningHymn = json['morningHymn']
      ..morningPsalm1Antiphon = json['morningPsalm1Antiphon']
      ..morningPsalm1Antiphon2 = json['morningPsalm1Antiphon2']
      ..morningPsalm1 = json['morningPsalm1']
      ..morningPsalm2Antiphon = json['morningPsalm2Antiphon']
      ..morningPsalm2Antiphon2 = json['morningPsalm2Antiphon2']
      ..morningPsalm2 = json['morningPsalm2']
      ..morningPsalm3Antiphon = json['morningPsalm3Antiphon']
      ..morningPsalm3Antiphon2 = json['morningPsalm3Antiphon2']
      ..morningPsalm3 = json['morningPsalm3']
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
    if (morningData.liturgicalGrade != null) {
      liturgicalGrade = morningData.liturgicalGrade;
    }
    if (morningData.celebrationTitle != null) {
      celebrationTitle = morningData.celebrationTitle;
    }
    if (morningData.invitatoryAntiphon != null) {
      invitatoryAntiphon = morningData.invitatoryAntiphon;
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
    if (morningData.morningPsalm1Antiphon != null) {
      morningPsalm1Antiphon = morningData.morningPsalm1Antiphon;
    }
    if (morningData.morningPsalm1Antiphon2 != null) {
      morningPsalm1Antiphon2 = morningData.morningPsalm1Antiphon2;
    }
    if (morningData.morningPsalm1 != null) {
      morningPsalm1 = morningData.morningPsalm1;
    }
    if (morningData.morningPsalm2Antiphon != null) {
      morningPsalm2Antiphon = morningData.morningPsalm2Antiphon;
    }
    if (morningData.morningPsalm2Antiphon2 != null) {
      morningPsalm2Antiphon2 = morningData.morningPsalm2Antiphon2;
    }
    if (morningData.morningPsalm2 != null) {
      morningPsalm2 = morningData.morningPsalm2;
    }
    if (morningData.morningPsalm3Antiphon != null) {
      morningPsalm3Antiphon = morningData.morningPsalm3Antiphon;
    }
    if (morningData.morningPsalm3Antiphon2 != null) {
      morningPsalm3Antiphon2 = morningData.morningPsalm3Antiphon2;
    }
    if (morningData.morningPsalm3 != null) {
      morningPsalm3 = morningData.morningPsalm3;
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
