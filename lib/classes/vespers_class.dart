class Vespers {
  Map<String, String?> data;

  Vespers({
    String? celebrationTitle,
    String? celebrationSubtitle,
    String? celebrationDescription,
    String? commonTitle,
    int? precedence,
    String? liturgicalColor,
    String? vespersHymn,
    String? vespersPsalm1Antiphon,
    String? vespersPsalm1Antiphon2,
    String? vespersPsalm1,
    String? vespersPsalm2Antiphon,
    String? vespersPsalm2Antiphon2,
    String? vespersPsalm2,
    String? vespersPsalm3Antiphon,
    String? vespersPsalm3Antiphon2,
    String? vespersPsalm3,
    String? vespersReadingRef,
    String? vespersReading,
    String? vespersResponsory,
    String? vespersIntercessionDescription,
    String? vespersIntercession,
    String? vespersEvangelicAntiphon,
    String? vespersOration,
  }) : data = {
          'vespersHymn': vespersHymn,
          'vespersPsalm1Antiphon': vespersPsalm1Antiphon,
          'vespersPsalm1Antiphon2': vespersPsalm1Antiphon2,
          'vespersPsalm1': vespersPsalm1,
          'vespersPsalm2Antiphon': vespersPsalm2Antiphon,
          'vespersPsalm2Antiphon2': vespersPsalm2Antiphon2,
          'vespersPsalm2': vespersPsalm2,
          'vespersPsalm3Antiphon': vespersPsalm3Antiphon,
          'vespersPsalm3Antiphon2': vespersPsalm3Antiphon2,
          'vespersPsalm3': vespersPsalm3,
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
