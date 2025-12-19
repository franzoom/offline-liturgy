import 'office_elements_class.dart';

/// Middle of day office structure with tierce/sexte/none
class MiddleOfDayOffice {
  final HourOffice? tierce;
  final HourOffice? sexte;
  final HourOffice? none;
  final List<PsalmEntry>? psalmody;
  final List<String>? oration;
  // Legacy fields for direct psalm references
  final String? psalm1;
  final String? psalm2;
  final String? psalm3;

  MiddleOfDayOffice({
    this.tierce,
    this.sexte,
    this.none,
    this.psalmody,
    this.oration,
    this.psalm1,
    this.psalm2,
    this.psalm3,
  });

  factory MiddleOfDayOffice.fromJson(Map<String, dynamic> json) {
    return MiddleOfDayOffice(
      tierce: json['tierce'] != null
          ? HourOffice.fromJson(json['tierce'] as Map<String, dynamic>)
          : null,
      sexte: json['sexte'] != null
          ? HourOffice.fromJson(json['sexte'] as Map<String, dynamic>)
          : null,
      none: json['none'] != null
          ? HourOffice.fromJson(json['none'] as Map<String, dynamic>)
          : null,
      psalmody: json['psalmody'] != null
          ? (json['psalmody'] as List)
              .map((e) => PsalmEntry.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      oration:
          json['oration'] != null ? List<String>.from(json['oration']) : null,
      psalm1: json['psalm1'] as String?,
      psalm2: json['psalm2'] as String?,
      psalm3: json['psalm3'] as String?,
    );
  }
}
