import '../../tools/psalms_list_management.dart';

final Map<int, Map<String, List<String>>> morningDefaultDistribution = {
  1: {
    'sunday': ['PSALM_62', 'OT_41', 'PSALM_149'],
    'monday': ['PSALM_5', 'OT_4', 'PSALM_28'],
    'tuesday': ['PSALM_23', 'OT_5', 'PSALM_32'],
    'wednesday': ['PSALM_35', 'OT_7', 'PSALM_46'],
    'thursday': ['PSALM_56', 'OT_36', 'PSALM_47'],
    'friday': ['PSALM_50', 'OT_27', 'PSALM_99'],
    'saturday': ['PSALM_118_19', 'OT_1', 'PSALM_116'],
  },
  2: {
    'sunday': ['PSALM_117', 'OT_40', 'PSALM_150'],
    'monday': ['PSALM_41', 'OT_15', 'PSALM_18A'],
    'tuesday': ['PSALM_42', 'OT_23', 'PSALM_64'],
    'wednesday': ['PSALM_76', 'OT_3', 'PSALM_96'],
    'thursday': ['PSALM_79', 'OT_19', 'PSALM_80'],
    'friday': ['PSALM_50', 'OT_43', 'PSALM_147'],
    'saturday': ['PSALM_91', 'OT_2', 'PSALM_8'],
  },
  3: {
    'sunday': ['PSALM_92', 'OT_41', 'PSALM_148'],
    'monday': ['PSALM_83', 'OT_17', 'PSALM_95'],
    'tuesday': ['PSALM_84', 'OT_20', 'PSALM_66'],
    'wednesday': ['PSALM_85', 'OT_22', 'PSALM_97'],
    'thursday': ['PSALM_86', 'OT_25', 'PSALM_98'],
    'friday': ['PSALM_50', 'OT_34', 'PSALM_99'],
    'saturday': ['PSALM_118_19', 'OT_10', 'PSALM_116'],
  },
  4: {
    'sunday': ['PSALM_117', 'OT_40', 'PSALM_150'],
    'monday': ['PSALM_89', 'OT_26', 'PSALM_134_1'],
    'tuesday': ['PSALM_100', 'OT_39', 'PSALM_143a'],
    'wednesday': ['PSALM_107', 'OT_30', 'PSALM_145'],
    'thursday': ['PSALM_142', 'OT_32', 'PSALM_146'],
    'friday': ['PSALM_50', 'OT_6', 'PSALM_147'],
    'saturday': ['PSALM_91', 'OT_38', 'PSALM_8'],
  }
};
final Map<int, Map<String, List<String>>> morningPaschalOctaveDistribution = {
  1: {
    'sunday': ['PSALM_62', 'OT_41', 'PSALM_149'],
    'monday': ['PSALM_62', 'OT_41', 'PSALM_149'],
    'tuesday': ['PSALM_62', 'OT_41', 'PSALM_149'],
    'wednesday': ['PSALM_62', 'OT_41', 'PSALM_149'],
    'thursday': ['PSALM_62', 'OT_41', 'PSALM_149'],
    'friday': ['PSALM_62', 'OT_41', 'PSALM_149'],
    'saturday': ['PSALM_62', 'OT_41', 'PSALM_149'],
  },
  2: {
    'sunday': ['PSALM_62', 'OT_41', 'PSALM_149'],
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
