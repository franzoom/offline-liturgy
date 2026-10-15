import 'package:yaml/yaml.dart';
import '../../classes/mass_class.dart';
import 'text_library.dart';

/// Prefaces of the Mass, from assets/mass_missal/prefaces/.
final prefacesLibrary = TextLibrary<Preface>(
    'mass_missal/prefaces',
    (content) =>
        Preface.fromJson(Map<String, dynamic>.from(loadYaml(content) as Map)));
