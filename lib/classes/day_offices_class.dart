import 'office_structures.dart'; // Import the new structure classes

/// Main class for liturgical office data
/// Structured with nested office objects
class DayOffices {
  Celebration? celebration;

  // Nested office structures
  InvitatoryOffice? invitatory;
  MorningOffice? morning;
  ReadingsOffice? readings;
  VespersOffice? vespers;
  VespersOffice? firstVespers; // Uses same structure as vespers
  MiddleOfDayOffice? middleOfDay;

  // Legacy fields that may still be needed at top level
  String? sundayEvangelicAntiphonA;
  String? sundayEvangelicAntiphonB;
  String? sundayEvangelicAntiphonC;
  String? evangelicAntiphon;
  List<String>? oration;

  DayOffices({
    this.celebration,
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
  });

  factory DayOffices.fromJSON(Map<String, dynamic> json) {
    return DayOffices(
      celebration: json['celebration'] != null
          ? Celebration.fromJson(json['celebration'] as Map<String, dynamic>)
          : null,

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

      // Legacy fields at top level
      sundayEvangelicAntiphonA: json['sundayEvangelicAntiphonA'] as String?,
      sundayEvangelicAntiphonB: json['sundayEvangelicAntiphonB'] as String?,
      sundayEvangelicAntiphonC: json['sundayEvangelicAntiphonC'] as String?,
      evangelicAntiphon: json['evangelicAntiphon'] as String?,
      oration:
          json['oration'] != null ? List<String>.from(json['oration']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (celebration != null) 'celebration': celebration!.toJson(),
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
    };
  }
}
