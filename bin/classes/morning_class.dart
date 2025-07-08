class Morning {
  Map<String, String?> data;

  Morning({
    String? morningHymn,
    String? morningPsalm1Antiphon1,
    String? morningPsalm1Antiphon2,
    String? psalm1Ref,
    String? morningPsalm2Antiphon1,
    String? morningPsalm2Antiphon2,
    String? psalm2Ref,
    String? morningPsalm3Antiphon1,
    String? morningPsalm3Antiphon2,
    String? psalm3Ref,
    String? morningReading,
    String? morningResponsory,
    String? morningIntercessionDescription,
    String? morningIntercession,
    String? morningEvangelicAntiphon,
    String? morningOration,
  }) : data = {
          'morningHymn': morningHymn,
          'morningPsalm1Antiphon': morningPsalm1Antiphon1,
          'morningPsalm1Antiphon2': morningPsalm1Antiphon2,
          'psalm1Ref': psalm1Ref,
          'morningPsalm2Antiphon': morningPsalm2Antiphon1,
          'morningPsalm2Antiphon2': morningPsalm2Antiphon2,
          'psalm2Ref': psalm2Ref,
          'morningPsalm3Antiphon1': morningPsalm3Antiphon1,
          'morningPsalm3Antiphon2': morningPsalm3Antiphon2,
          'psalm3Ref': psalm3Ref,
          'morningReading': morningReading,
          'morningResponsory': morningResponsory,
          'morningIntercessionDescription': morningIntercessionDescription,
          'morningIntercession': morningIntercession,
          'morningEvangelicAntiphon': morningEvangelicAntiphon,
          'morningOration': morningOration,
        };

  String? get(String key) => data[key];

  void set(String key, String value) {
    if (data.containsKey(key)) {
      data[key] = value;
    } else {
      throw ArgumentError('Clé invalide : $key');
    }
  }
}
