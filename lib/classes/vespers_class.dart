class Vespers {
  Map<String, String?> data;

  Vespers({
    String? vespersHymn,
    String? vespersPsalm1Antiphon1,
    String? vespersPsalm1Antiphon2,
    String? psalm1Ref,
    String? vespersPsalm2Antiphon1,
    String? vespersPsalm2Antiphon2,
    String? psalm2Ref,
    String? vespersPsalm3Antiphon1,
    String? vespersPsalm3Antiphon2,
    String? psalm3Ref,
    String? vespersReadingRef,
    String? vespersReading,
    String? vespersResponsory,
    String? vespersIntercessionDescription,
    String? vespersIntercession,
    String? vespersEvangelicAntiphon,
    String? vespersOration,
  }) : data = {
          'vespersHymn': vespersHymn,
          'vespersPsalm1Antiphon': vespersPsalm1Antiphon1,
          'vespersPsalm1Antiphon2': vespersPsalm1Antiphon2,
          'psalm1Ref': psalm1Ref,
          'vespersPsalm2Antiphon': vespersPsalm2Antiphon1,
          'vespersPsalm2Antiphon2': vespersPsalm2Antiphon2,
          'psalm2Ref': psalm2Ref,
          'vespersPsalm3Antiphon1': vespersPsalm3Antiphon1,
          'vespersPsalm3Antiphon2': vespersPsalm3Antiphon2,
          'psalm3Ref': psalm3Ref,
          'vespersReadingRef': vespersReading,
          'vespersReading': vespersReading,
          'vespersResponsory': vespersResponsory,
          'vespersIntercessionDescription': vespersIntercessionDescription,
          'vespersIntercession': vespersIntercession,
          'vespersEvangelicAntiphon': vespersEvangelicAntiphon,
          'vespersOration': vespersOration,
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
