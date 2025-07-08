class Morning {
  final String? celebrationType;
  final String? morningHymn;
  final String? morningPsalm1Antiphon1;
  final String? morningPsalm1Antiphon2;
  final String? psalm1Ref;
  final String? morningPsalm2Antiphon1;
  final String? morningPsalm2Antiphon2;
  final String? psalm2Ref;
  final String? morningPsalm3Antiphon1;
  final String? morningPsalm3Antiphon2;
  final String? psalm3Ref;
  final String? morningReadingRef;
  final String? morningReading;
  final String? morningResponsory;
  final String? morningEvangelicAntiphon;
  final String? morningEvangelicAntiphonA;
  final String? morningEvangelicAntiphonB;
  final String? morningEvangelicAntiphonC;
  final String? morningIntercessionDescription;
  final String? morningIntercession;
  final String? morningOration;

  const Morning({
    this.celebrationType,
    this.morningHymn,
    this.morningPsalm1Antiphon1,
    this.morningPsalm1Antiphon2,
    this.psalm1Ref,
    this.morningPsalm2Antiphon1,
    this.morningPsalm2Antiphon2,
    this.psalm2Ref,
    this.morningPsalm3Antiphon1,
    this.morningPsalm3Antiphon2,
    this.psalm3Ref,
    this.morningReadingRef,
    this.morningReading,
    this.morningResponsory,
    this.morningEvangelicAntiphon,
    this.morningEvangelicAntiphonA,
    this.morningEvangelicAntiphonB,
    this.morningEvangelicAntiphonC,
    this.morningIntercessionDescription,
    this.morningIntercession,
    this.morningOration,
  });

  Map<String, String?> toMap() => {
        'celebrationType': celebrationType,
        'morningHymn': morningHymn,
        'morningPsalm1Antiphon1': morningPsalm1Antiphon1,
        'morningPsalm1Antiphon2': morningPsalm1Antiphon2,
        'psalm1Ref': psalm1Ref,
        'morningPsalm2Antiphon1': morningPsalm2Antiphon1,
        'morningPsalm2Antiphon2': morningPsalm2Antiphon2,
        'psalm2Ref': psalm2Ref,
        'morningPsalm3Antiphon1': morningPsalm3Antiphon1,
        'morningPsalm3Antiphon2': morningPsalm3Antiphon2,
        'psalm3Ref': psalm3Ref,
        'morningReadingRef': morningReadingRef,
        'morningReading': morningReading,
        'morningResponsory': morningResponsory,
        'morningEvangelicAntiphon': morningEvangelicAntiphon,
        'morningEvangelicAntiphonA': morningEvangelicAntiphonA,
        'morningEvangelicAntiphonB': morningEvangelicAntiphonB,
        'morningEvangelicAntiphonC': morningEvangelicAntiphonC,
        'morningIntercessionDescription': morningIntercessionDescription,
        'morningIntercession': morningIntercession,
        'morningOration': morningOration,
      };
}
