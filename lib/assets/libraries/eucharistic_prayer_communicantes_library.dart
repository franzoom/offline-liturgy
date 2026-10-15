import 'package:yaml/yaml.dart';
import '../../classes/mass_class.dart';
import 'text_library.dart';

/// Communicantes inserts of the eucharistic prayers, from
/// assets/mass_missal/eucharistic_prayer_communicantes/.
final communicantesLibrary = TextLibrary<EucharisticPrayerCommunicantes>(
    'mass_missal/eucharistic_prayer_communicantes',
    (content) =>
        EucharisticPrayerCommunicantes.fromJson(loadYaml(content) as List));
