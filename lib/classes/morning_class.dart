import 'hour_prayer_class.dart';
import 'office_elements_class.dart';

/// Class representing the Morning Prayer (Laudes) structure
class Morning extends HourPrayer {
  Invitatory? invitatory;

  Morning({
    this.invitatory,
    super.hymn,
    super.psalmody,
    super.reading,
    super.responsory,
    super.evangelicAntiphon,
    super.evangelicCanticle,
    super.intercession,
    super.oration,
    super.canticleSvgData,
  });

  /// Creates Morning instance from dynamic data (JSON/YAML) with type safety
  Morning.fromJson(super.data)
      : invitatory = data['invitatory'] is Map<String, dynamic>
            ? Invitatory.fromJson(data['invitatory'] as Map<String, dynamic>)
            : null,
        super.fromJson();

  @override
  void overlayWith(Morning overlay, {bool keepBaseHymns = false}) {
    if (overlay.invitatory != null) invitatory = overlay.invitatory;
    super.overlayWith(overlay, keepBaseHymns: keepBaseHymns);
  }

  @override
  void overlayWithCommon(Morning common) {
    if (common.invitatory != null) invitatory = common.invitatory;
    super.overlayWithCommon(common);
  }
}
