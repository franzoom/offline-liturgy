import '../tools/psalms_list_management.dart';

final Map<int, Map<String, List<String>>> morningDefaultDistribution = {
  1: {
    'sunday': ['PSALM_62', 'AT_41', 'PSALM_149'],
    'monday': ['PSALM_5', 'AT_4', 'PSALM_28'],
    'tuesday': ['PSALM_23', 'AT_5', 'PSALM_32'],
    'wednesday': ['PSALM_35', 'AT_7', 'PSALM_46'],
    'thursday': ['PSALM_56', 'AT_36', 'PSALM_47'],
    'friday': ['PSALM_50', 'AT_27', 'PSALM_99'],
    'saturday': ['PSALM_118_19', 'AT_1', 'PSALM_116'],
  },
  2: {
    'sunday': ['PSALM_117', 'AT_40', 'PSALM_150'],
    'monday': ['PSALM_41', 'AT_15', 'PSALM_18A'],
    'tuesday': ['PSALM_42', 'AT_23', 'PSALM_64'],
    'wednesday': ['PSALM_76', 'AT_3', 'PSALM_96'],
    'thursday': ['PSALM_79', 'AT_19', 'PSALM_80'],
    'friday': ['PSALM_50', 'AT_43', 'PSALM_147'],
    'saturday': ['PSALM_91', 'AT_2', 'PSALM_8'],
  },
  3: {
    'sunday': ['PSALM_92', 'AT_41', 'PSALM_148'],
    'monday': ['PSALM_83', 'AT_17', 'PSALM_95'],
    'tuesday': ['PSALM_84', 'AT_20', 'PSALM_66'],
    'wednesday': ['PSALM_85', 'AT_22', 'PSALM_97'],
    'thursday': ['PSALM_86', 'AT_25', 'PSALM_98'],
    'friday': ['PSALM_50', 'AT_34', 'PSALM_99'],
    'saturday': ['PSALM_118_19', 'AT_10', 'PSALM_116'],
  },
  4: {
    'sunday': ['PSALM_117', 'AT_40', 'PSALM_150'],
    'monday': ['PSALM_89', 'AT_26', 'PSALM_134_1'],
    'tuesday': ['PSALM_100', 'AT_39', 'PSALM_143a'],
    'wednesday': ['PSALM_107', 'AT_30', 'PSALM_145'],
    'thursday': ['PSALM_142', 'AT_32', 'PSALM_146'],
    'friday': ['PSALM_50', 'AT_6', 'PSALM_147'],
    'saturday': ['PSALM_91', 'AT_38', 'PSALM_8'],
  }
};
final Map<int, Map<String, List<String>>> morningPaschalOctaveDistribution = {
  1: {
    'sunday': ['PSALM_62', 'AT_41', 'PSALM_149'],
    'monday': ['PSALM_62', 'AT_41', 'PSALM_149'],
    'tuesday': ['PSALM_62', 'AT_41', 'PSALM_149'],
    'wednesday': ['PSALM_62', 'AT_41', 'PSALM_149'],
    'thursday': ['PSALM_62', 'AT_41', 'PSALM_149'],
    'friday': ['PSALM_62', 'AT_41', 'PSALM_149'],
    'saturday': ['PSALM_62', 'AT_41', 'PSALM_149'],
  },
  2: {
    'sunday': ['PSALM_62', 'AT_41', 'PSALM_149'],
  }
};

List<String>? morningPsalms(
    String liturgicalTime, int liturgicalWeek, String dayName) {
  Map<int, Map<String, List<String>>> finalList = morningDefaultDistribution;
// pour l'octave pascal:
  if (liturgicalTime == 'PaschalOctave') {
    finalList = mergePsalms(
        morningDefaultDistribution, morningPaschalOctaveDistribution);
  }
  List<String>? psalmsList = finalList[liturgicalWeek]?[dayName];
  return psalmsList;
}
