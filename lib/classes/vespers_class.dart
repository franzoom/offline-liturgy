import 'hour_prayer_class.dart';

/// Class representing the Vespers (Evening Prayer) structure
class Vespers extends HourPrayer {
  Vespers({
    super.celebration,
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

  /// Creates Vespers instance from dynamic data (YAML/JSON) with type safety
  Vespers.fromJson(super.data) : super.fromJson();
}
