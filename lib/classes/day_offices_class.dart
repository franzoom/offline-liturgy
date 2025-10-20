import 'office_structures.dart'; // Import the new structure classes

/// Main class for liturgical office data
/// Structured with nested office objects
class DayOffices {
  String? celebrationTitle;
  String? celebrationSubtitle;
  String? celebrationDescription;
  List? commons;
  int? liturgicalGrade;
  String? liturgicalColor;

  // Nested office structures
  InvitatoryOffice? invitatory;
  MorningOffice? morning;
  ReadingsOffice? readings;
  VespersOffice? vespers;
  VespersOffice? firstVespers; // Uses same structure as vespers
  MiddleOfDayOffice? middleOfDay;

  // Legacy fields that may still be needed
  String? sundayEvangelicAntiphonA;
  String? sundayEvangelicAntiphonB;
  String? sundayEvangelicAntiphonC;
  String? evangelicAntiphon;
  String? oration;
  String? oration2;

  DayOffices({
    this.celebrationTitle,
    this.celebrationSubtitle,
    this.celebrationDescription,
    this.commons,
    this.liturgicalGrade,
    this.liturgicalColor,
    this.invitatory,
    this.morning,
    this.readings,
    this.vespers,
    this.firstVespers,
    this.middleOfDay,
    this.sundayEvangelicAntiphonA,
    this.sundayEvangelicAntiphonB,
    this.sundayEvangelicAntiphonC,
    this.evangelicAntiphon,
    this.oration,
    this.oration2,
  });

  factory DayOffices.fromJSON(Map<String, dynamic> json) {
    return DayOffices(
      celebrationTitle: json['celebrationTitle'] as String?,
      celebrationSubtitle: json['celebrationSubtitle'] as String?,
      celebrationDescription: json['celebrationDescription'] as String?,
      commons: json['commons'] as List?,
      liturgicalGrade: json['liturgicalGrade'] as int?,
      liturgicalColor: json['liturgicalColor'] as String?,

      // Parse nested office structures
      invitatory: json['invitatory'] != null
          ? InvitatoryOffice.fromJson(
              json['invitatory'] as Map<String, dynamic>)
          : null,
      morning: json['morning'] != null
          ? MorningOffice.fromJson(json['morning'] as Map<String, dynamic>)
          : null,
      readings: json['readings'] != null
          ? ReadingsOffice.fromJson(json['readings'] as Map<String, dynamic>)
          : null,
      vespers: json['vespers'] != null
          ? VespersOffice.fromJson(json['vespers'] as Map<String, dynamic>)
          : null,
      firstVespers: json['firstVespers'] != null
          ? VespersOffice.fromJson(json['firstVespers'] as Map<String, dynamic>)
          : null,
      middleOfDay: json['middleOfDay'] != null
          ? MiddleOfDayOffice.fromJson(
              json['middleOfDay'] as Map<String, dynamic>)
          : null,

      // Legacy fields
      sundayEvangelicAntiphonA: json['sundayEvangelicAntiphonA'] as String?,
      sundayEvangelicAntiphonB: json['sundayEvangelicAntiphonB'] as String?,
      sundayEvangelicAntiphonC: json['sundayEvangelicAntiphonC'] as String?,
      evangelicAntiphon: json['evangelicAntiphon'] as String?,
      oration: json['oration'] as String?,
      oration2: json['oration2'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (celebrationTitle != null) 'celebrationTitle': celebrationTitle,
      if (celebrationSubtitle != null)
        'celebrationSubtitle': celebrationSubtitle,
      if (celebrationDescription != null)
        'celebrationDescription': celebrationDescription,
      if (commons != null) 'commons': commons,
      if (liturgicalGrade != null) 'liturgicalGrade': liturgicalGrade,
      if (liturgicalColor != null) 'liturgicalColor': liturgicalColor,
      if (invitatory != null) 'invitatory': invitatory!.toJson(),
      if (morning != null) 'morning': morning!.toJson(),
      if (readings != null) 'readings': readings!.toJson(),
      if (vespers != null) 'vespers': vespers!.toJson(),
      if (firstVespers != null) 'firstVespers': firstVespers!.toJson(),
      if (middleOfDay != null) 'middleOfDay': middleOfDay!.toJson(),
      if (sundayEvangelicAntiphonA != null)
        'sundayEvangelicAntiphonA': sundayEvangelicAntiphonA,
      if (sundayEvangelicAntiphonB != null)
        'sundayEvangelicAntiphonB': sundayEvangelicAntiphonB,
      if (sundayEvangelicAntiphonC != null)
        'sundayEvangelicAntiphonC': sundayEvangelicAntiphonC,
      if (evangelicAntiphon != null) 'evangelicAntiphon': evangelicAntiphon,
      if (oration != null) 'oration': oration,
      if (oration2 != null) 'oration2': oration2,
    };
  }
}
