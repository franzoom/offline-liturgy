import 'office_elements_class.dart';

/// Class representing the Vespers (Evening Prayer) structure
class Vespers {
  Celebration? celebration;
  Invitatory? invitatory; // Added for consistency with other hours
  List<String>? hymn;
  List<PsalmEntry>? psalmody;
  Reading? reading;
  String? responsory;
  EvangelicAntiphon? evangelicAntiphon;
  Intercession? intercession;
  List<String>? oration;

  Vespers({
    this.celebration,
    this.invitatory,
    this.hymn,
    this.psalmody,
    this.reading,
    this.responsory,
    this.evangelicAntiphon,
    this.intercession,
    this.oration,
  });

  /// Creates Vespers instance from dynamic data (YAML/JSON) with type safety
  factory Vespers.fromJson(Map<String, dynamic> data) {
    return Vespers(
      celebration: data['celebration'] is Map<String, dynamic>
          ? Celebration.fromJson(data['celebration'] as Map<String, dynamic>)
          : null,
      invitatory: data['invitatory'] is Map<String, dynamic>
          ? Invitatory.fromJson(data['invitatory'] as Map<String, dynamic>)
          : null,
      hymn: (data['hymn'] as List?)?.map((e) => e.toString()).toList(),
      psalmody: (data['psalmody'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map((e) => PsalmEntry.fromJson(e))
          .toList(),
      reading: data['reading'] is Map<String, dynamic>
          ? Reading.fromJson(data['reading'] as Map<String, dynamic>)
          : null,
      responsory: data['responsory']?.toString(),
      evangelicAntiphon: data['evangelicAntiphon'] is Map<String, dynamic>
          ? EvangelicAntiphon.fromJson(
              data['evangelicAntiphon'] as Map<String, dynamic>)
          : null,
      intercession: data['intercession'] is Map<String, dynamic>
          ? Intercession.fromJson(data['intercession'] as Map<String, dynamic>)
          : null,
      oration: (data['oration'] as List?)?.map((e) => e.toString()).toList(),
    );
  }

  /// Overlays this Vespers instance with data from another instance
  /// Intelligently merges psalmody (psalms + antiphons)
  void overlayWith(Vespers overlay) {
    if (overlay.celebration != null) celebration = overlay.celebration;
    if (overlay.invitatory != null) invitatory = overlay.invitatory;
    if (overlay.hymn != null) hymn = overlay.hymn;

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

    if (overlay.reading != null) reading = overlay.reading;
    if (overlay.responsory != null) responsory = overlay.responsory;
    if (overlay.evangelicAntiphon != null)
      evangelicAntiphon = overlay.evangelicAntiphon;
    if (overlay.intercession != null) intercession = overlay.intercession;
    if (overlay.oration != null) oration = overlay.oration;
  }

  /// Selective overlay for Common elements (Precedence > 6)
  /// Used for Memories to take specific elements from the Common
  void overlayWithCommon(Vespers common) {
    if (common.hymn != null) hymn = common.hymn;
    if (common.reading != null) reading = common.reading;
    if (common.responsory != null) responsory = common.responsory;
    if (common.evangelicAntiphon != null)
      evangelicAntiphon = common.evangelicAntiphon;
    if (common.intercession != null) intercession = common.intercession;
    if (common.oration != null) oration = common.oration;
  }

  bool get isEmpty =>
      celebration == null &&
      hymn == null &&
      psalmody == null &&
      reading == null &&
      responsory == null &&
      evangelicAntiphon == null &&
      intercession == null &&
      oration == null;
}

/// Metadata for Vespers resolution
@Deprecated('Use CelebrationContext instead. This class will be removed in a future version.')
class VespersDefinition {
  final String vespersDescription;
  final String celebrationCode;
  final String ferialCode;
  final List<String>? commonList;
  final String? liturgicalTime;
  final String? breviaryWeek;
  final int precedence;
  final String liturgicalColor;
  final bool isCelebrable;
  final String? celebrationDescription;
  final bool isFirstVespers;

  const VespersDefinition({
    required this.vespersDescription,
    required this.celebrationCode,
    required this.ferialCode,
    this.commonList,
    this.liturgicalTime,
    this.breviaryWeek,
    required this.precedence,
    required this.isCelebrable,
    required this.liturgicalColor,
    this.celebrationDescription,
    this.isFirstVespers = false,
  });
}
