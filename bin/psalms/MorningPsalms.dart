import '../tools/psalms_list_management.dart';

final Map<int, Map<String, List<String>>> MorningDefaultDistribution = {
  1: {
    'sunday': ['PSALM_62', 'PSALM_149', 'AT_41'],
    'monday': ['PSALM_5', 'PSALM_28', 'AT_4'],
    'tuesday': ['PSALM_23', 'PSALM_32', 'AT_5'],
    'wednesday': ['PSALM_35', 'PSALM_46', 'AT_7'],
    'thursday': ['PSALM_56', 'PSALM_47', 'AT_36'],
    'friday': ['PSALM_50', 'PSALM_99', 'AT_27'],
    'saturday': ['PSALM_118_19', 'PSALM_116', 'AT_1'],
  },
  2: {
    'sunday': ['PSALM_117', 'PSALM_150', 'AT_40'],
    'monday': ['PSALM_41', 'PSALM_18A', 'AT_15'],
    'tuesday': ['PSALM_42', 'PSALM_64', 'AT_23'],
    'wednesday': ['PSALM_76', 'PSALM_96', 'AT_3'],
    'thursday': ['PSALM_79', 'PSALM_80', 'AT_19'],
    'friday': ['PSALM_50', 'PSALM_147', 'AT_43'],
    'saturday': ['PSALM_91', 'PSALM_8', 'AT_2'],
  },
  3: {
    'sunday': ['PSALM_92', 'PSALM_148', 'AT_41'],
    'monday': ['PSALM_83', 'PSALM_95', 'AT_17'],
    'tuesday': ['PSALM_84', 'PSALM_66', 'AT_20'],
    'wednesday': ['PSALM_85', 'PSALM_97', 'AT_22'],
    'thursday': ['PSALM_86', 'PSALM_98', 'AT_25'],
    'friday': ['PSALM_50', 'PSALM_99', 'AT_34'],
    'saturday': ['PSALM_118_19', 'PSALM_116', 'AT_10'],
  },
  4: {
    'sunday': ['PSALM_117', 'PSALM_150', 'AT_40'],
    'monday': ['PSALM_89', 'PSALM_134_1', 'AT_26'],
    'tuesday': ['PSALM_100', 'PSALM_143a', 'AT_39'],
    'wednesday': ['PSALM_107', 'PSALM_145', 'AT_30'],
    'thursday': ['PSALM_142', 'PSALM_146', 'AT_32'],
    'friday': ['PSALM_50', 'PSALM_147', 'AT_6'],
    'saturday': ['PSALM_91', 'PSALM_8', 'AT_38'],
  },
};
final Map<int, Map<String, List<String>>> MorningPaschalOctaveDistribution = {
  1: {
    'sunday': ['PSALM_62', 'PSALM_149', 'AT_41'],
    'monday': ['PSALM_62', 'PSALM_149', 'AT_41'],
    'tuesday': ['PSALM_62', 'PSALM_149', 'AT_41'],
    'wednesday': ['PSALM_62', 'PSALM_149', 'AT_41'],
    'thursday': ['PSALM_62', 'PSALM_149', 'AT_41'],
    'friday': ['PSALM_62', 'PSALM_149', 'AT_41'],
    'saturday': ['PSALM_62', 'PSALM_149', 'AT_41'],
  },
  2: {
    'sunday': ['PSALM_62', 'PSALM_149', 'AT_41'],
  },
};

List<String>? MorningPsalms(
    String liturgicalTime, int liturgicalWeek, String dayName) {
  Map<int, Map<String, List<String>>> finalList = MorningDefaultDistribution;
// en dehors du temps ordinaire:
  if (liturgicalTime == 'PaschalOctave') {
    finalList = mergePsalms(
        MorningDefaultDistribution, MorningPaschalOctaveDistribution);
  }
  List<String>? psalmsList = finalList[liturgicalWeek]?[dayName];
  return psalmsList;
}
