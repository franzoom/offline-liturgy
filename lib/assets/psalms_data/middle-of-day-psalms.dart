import '../../tools/psalms_list_management.dart';

final Map<int, Map<String, List<String>>> middleOfDayDefaultDistribution = {
  1: {
    'sunday': ['PSALM_117_1', 'PSALM_117_2', 'PSALM_117_3'],
    'monday': ['PSALM_18B', 'PSALM_7_1', 'PSALM_7_2'],
    'tuesday': ['PSALM_118_1', 'PSALM_12', 'PSALM_13'],
    'wednesday': ['PSALM_118_2', 'PSALM_16_1', 'PSALM_16_2'],
    'thursday': ['PSALM_118_3', 'PSALM_24_1', 'PSALM_24_2'],
    'friday': ['PSALM_118_4', 'PSALM_25', 'PSALM_27'],
    'saturday': ['PSALM_118_5', 'PSALM_33_1', 'PSALM_33_2']
  },
  2: {
    'sunday': ['PSALM_22', 'PSALM_75_1', 'PSALM_75_2'],
    'monday': ['PSALM_118_6', 'PSALM_39_1', 'PSALM_39_2'],
    'tuesday': ['PSALM_118_7', 'PSALM_52', 'PSALM_53'],
    'wednesday': ['PSALM_118_8', 'PSALM_54_1_2', 'PSALM_54_3'],
    'thursday': ['PSALM_118_9', 'PSALM_55', 'PSALM_56'],
    'friday': ['PSALM_118_10', 'PSALM_58', 'PSALM_59'],
    'saturday': ['PSALM_118_11', 'PSALM_60', 'PSALM_63']
  },
  3: {
    'sunday': ['PSALM_117_1', 'PSALM_117_2', 'PSALM_117_3'],
    'monday': ['PSALM_118_12', 'PSALM_70_1', 'PSALM_70_2'],
    'tuesday': ['PSALM_118_13', 'PSALM_73_1', 'PSALM_73_2'],
    'wednesday': ['PSALM_118_14', 'PSALM_69', 'PSALM_74'],
    'thursday': ['PSALM_118_15', 'PSALM_78', 'PSALM_79'],
    'friday': ['PSALM_21_1', 'PSALM_21_2', 'PSALM_21_3'],
    'saturday': ['PSALM_118_16', 'PSALM_33_1', 'PSALM_33_2']
  },
  4: {
    'sunday': ['PSALM_22', 'PSALM_75_1', 'PSALM_75_2'],
    'monday': ['PSALM_118_17', 'PSALM_81', 'PSALM_119'],
    'tuesday': ['PSALM_118_18', 'PSALM_87_1', 'PSALM_87_2'],
    'wednesday': ['PSALM_118_19', 'PSALM_93_1', 'PSALM_93_2'],
    'thursday': ['PSALM_118_20', 'PSALM_127', 'PSALM_128'],
    'friday': ['PSALM_118_21', 'PSALM_132', 'PSALM_139'],
    'saturday': ['PSALM_118_22', 'PSALM_44_1', 'PSALM_44_2']
  }
};
final Map<int, Map<String, List<String>>> middleOfDayPaschalOctaveDistribution =
    {
  1: {
    'sunday': ['PSALM_8', 'PSALM_18A', 'PSALM_18B'],
    'monday': ['PSALM_118_1', 'PSALM_15', 'PSALM_22'],
    'tuesday': ['PSALM_118_2', 'PSALM_27', 'PSALM_115'],
    'wednesday': ['PSALM_118_3', 'PSALM_29_1', 'PSALM_29_2'],
    'thursday': ['PSALM_118_4', 'PSALM_75_1', 'PSALM_75_2'],
    'friday': ['PSALM_118_5', 'PSALM_95_1', 'PSALM_95_2']
  },
  2: {
    'saturday': ['PSALM_117_1', 'PSALM_117_2', 'PSALM_117_3']
  }
};

List<String>? middleOfDayPsalms(
    String liturgicalTime, int liturgicalWeek, String dayName) {
  Map<int, Map<String, List<String>>> finalList =
      middleOfDayDefaultDistribution;
// pour l'octave pascal:
  if (liturgicalTime == 'PaschalOctave') {
    finalList = mergePsalms(
        middleOfDayDefaultDistribution, middleOfDayPaschalOctaveDistribution);
  }
  List<String>? psalmsList = finalList[liturgicalWeek]?[dayName];
  return psalmsList;
}
