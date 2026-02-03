import 'office_elements_class.dart';

/// Class representing the Middle of Day Prayer (Tierce, Sexte, None) structure
class MiddleOfDay {
  Celebration? celebration;
  List<PsalmEntry>? psalmody;
  HourOffice? tierce;
  HourOffice? sexte;
  HourOffice? none;
  List<String>? oration;

  MiddleOfDay({
    this.celebration,
    this.psalmody,
    this.tierce,
    this.sexte,
    this.none,
    this.oration,
  });

  /// Creates MiddleOfDay instance from dynamic data (YAML/JSON) with type safety
  factory MiddleOfDay.fromJson(Map<String, dynamic> data) {
    return MiddleOfDay(
      celebration: data['celebration'] is Map<String, dynamic>
          ? Celebration.fromJson(data['celebration'] as Map<String, dynamic>)
          : null,
      psalmody: (data['psalmody'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map((e) => PsalmEntry.fromJson(e))
          .toList(),
      tierce: data['tierce'] is Map<String, dynamic>
          ? HourOffice.fromJson(data['tierce'] as Map<String, dynamic>)
          : null,
      sexte: data['sexte'] is Map<String, dynamic>
          ? HourOffice.fromJson(data['sexte'] as Map<String, dynamic>)
          : null,
      none: data['none'] is Map<String, dynamic>
          ? HourOffice.fromJson(data['none'] as Map<String, dynamic>)
          : null,
      oration: (data['oration'] as List?)?.map((e) => e.toString()).toList(),
    );
  }

  /// Overlays this MiddleOfDay instance with data from another instance
  void overlayWith(MiddleOfDay overlay) {
    if (overlay.celebration != null) celebration = overlay.celebration;

    if (overlay.psalmody != null && overlay.psalmody!.isNotEmpty) {
      if (psalmody != null && psalmody!.isNotEmpty) {
        List<PsalmEntry> merged = [];
        for (int i = 0; i < overlay.psalmody!.length; i++) {
          final ov = overlay.psalmody![i];
          if (ov.psalm != null) {
            merged.add(ov);
          } else if (i < psalmody!.length) {
            merged.add(PsalmEntry(
              psalm: psalmody![i].psalm,
              antiphon: ov.antiphon ?? psalmody![i].antiphon,
            ));
          } else {
            merged.add(ov);
          }
        }
        psalmody = merged;
      } else {
        psalmody = overlay.psalmody;
      }
    }

    if (overlay.tierce != null) tierce = overlay.tierce;
    if (overlay.sexte != null) sexte = overlay.sexte;
    if (overlay.none != null) none = overlay.none;
    if (overlay.oration != null) oration = overlay.oration;
  }

  /// Selective overlay for Common elements (Precedence > 6)
  void overlayWithCommon(MiddleOfDay common) {
    if (common.tierce != null) tierce = common.tierce;
    if (common.sexte != null) sexte = common.sexte;
    if (common.none != null) none = common.none;
    if (common.oration != null) oration = common.oration;
  }

  bool get isEmpty =>
      celebration == null &&
      psalmody == null &&
      tierce == null &&
      sexte == null &&
      none == null &&
      oration == null;
}

/// Definition of MiddleOfDay type for a given day
class MiddleOfDayDefinition {
  final String middleOfDayDescription;
  final String celebrationCode;
  final String ferialCode;
  final List<String>? commonList;
  final String? liturgicalTime;
  final String? breviaryWeek;
  final int precedence;
  final String liturgicalColor;
  final bool isCelebrable;
  final String? celebrationDescription;

  const MiddleOfDayDefinition({
    required this.middleOfDayDescription,
    required this.celebrationCode,
    required this.ferialCode,
    this.commonList,
    this.liturgicalTime,
    this.breviaryWeek,
    required this.precedence,
    required this.isCelebrable,
    required this.liturgicalColor,
    this.celebrationDescription,
  });
}

typedef MiddleOfDayOffice = MiddleOfDay;
