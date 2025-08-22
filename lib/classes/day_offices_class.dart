import 'dart:mirrors';

class DayOffices {
  String? celebrationTitle;
  String? celebrationSubtitle;
  String? celebrationDescription;
  List? commons;
  int? liturgicalGrade;
  String? liturgicalColor;
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
  String? firstVespersOration;
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
  String? readingsOration;
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
  String? morningOration;
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
  String? middleOfDayOration;
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
  String? vespersOration;
  String? evangelicAntiphon;
  String? oration;
  String? oration2;

  /// default no-argument constructor
  DayOffices();

  /// Factory constructor to create an instance from JSON using reflection
  factory DayOffices.fromJSON(Map<String, dynamic> json) {
    final instance = DayOffices();
    final mirror = reflect(instance);
    final classMirror = mirror.type;

    // Iterate through all class fields
    classMirror.declarations.forEach((symbol, declaration) {
      if (declaration is VariableMirror && !declaration.isStatic) {
        final fieldName = MirrorSystem.getName(symbol);
        // If the field exists in the JSON
        if (json.containsKey(fieldName)) {
          final value = json[fieldName];
          // Assign the value according to its type
          if (declaration.type.reflectedType == String) {
            mirror.setField(symbol, value as String?);
          } else if (declaration.type.reflectedType == int) {
            mirror.setField(symbol, value as int?);
          } else if (declaration.type.reflectedType == List) {
            mirror.setField(symbol, value as List?);
          }
        }
      }
    });
    return instance;
  }
}
