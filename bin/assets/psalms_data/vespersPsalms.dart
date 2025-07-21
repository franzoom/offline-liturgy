import '../../tools/psalms_list_management.dart';

final Map<int, Map<String, List<String>>> vespersDefaultDistribution = {
  1: {
    'sunday': ['PSALM_109', 'PSALM_113A', 'NT_12'],
    'monday': ['PSALM_10', 'PSALM_14', 'NT_4'],
    'tuesday': ['PSALM_19', 'PSALM_20', 'NT_9'],
    'wednesday': ['PSALM_26_1', 'PSALM_26_2', 'NT_6'],
    'thursday': ['PSALM_29', 'PSALM_31', 'NT_10'],
    'friday': ['PSALM_40', 'PSALM_45', 'NT_11'],
    'saturday': ['PSALM_140', 'PSALM_141', 'NT_5']
  },
  2: {
    'sunday': ['PSALM_109', 'PSALM_113B', 'NT_12'],
    'monday': ['PSALM_44_1', 'PSALM_44_2', 'NT_4'],
    'tuesday': ['PSALM_48_1', 'PSALM_48_2', 'NT_9'],
    'wednesday': ['PSALM_61', 'PSALM_66', 'NT_6'],
    'thursday': ['PSALM_71_1', 'PSALM_71_2', 'NT_10'],
    'friday': ['PSALM_114', 'PSALM_120', 'NT_11'],
    'saturday': ['PSALM_118_14', 'PSALM_15', 'NT_5']
  },
  3: {
    'sunday': ['PSALM_109', 'PSALM_110', 'NT_12'],
    'monday': ['PSALM_122', 'PSALM_123', 'NT_4'],
    'tuesday': ['PSALM_124', 'PSALM_130', 'NT_9'],
    'wednesday': ['PSALM_125', 'PSALM_126', 'NT_6'],
    'thursday': ['PSALM_131_1', 'PSALM_131_2', 'NT_10'],
    'friday': ['PSALM_134_1', 'PSALM_134_2', 'NT_11'],
    'saturday': ['PSALM_112', 'PSALM_115', 'NT_5']
  },
  4: {
    'sunday': ['PSALM_109', 'PSALM_111', 'NT_12'],
    'monday': ['PSALM_135_1', 'PSALM_135_2', 'NT_4'],
    'tuesday': ['PSALM_136', 'PSALM_137', 'NT_9'],
    'wednesday': ['PSALM_138_1', 'PSALM_138_2', 'NT_6'],
    'thursday': ['PSALM_143_1', 'PSALM_143_2', 'NT_10'],
    'friday': ['PSALM_144_1', 'PSALM_144_IIA', 'NT_11'],
    'saturday': ['PSALM_121', 'PSALM_129', 'NT_5']
  }
};
final Map<int, Map<String, List<String>>> vespersLentDistribution = {
  1: {
    'sunday': ['PSALM_109', 'PSALM_113A', 'NT_8']
  },
  2: {
    'sunday': ['PSALM_109', 'PSALM_113B', 'NT_8']
  },
  3: {
    'sunday': ['PSALM_109', 'PSALM_110', 'NT_8']
  },
  4: {
    'sunday': ['PSALM_109', 'PSALM_111', 'NT_8']
  }
};

final Map<int, Map<String, List<String>>> vespersPaschalOctaveDistribution = {
  1: {
    'sunday': ['PSALM_109', 'PSALM_113A', 'NT_12'],
    'monday': ['PSALM_109', 'PSALM_113A', 'NT_12'],
    'tuesday': ['PSALM_109', 'PSALM_113A', 'NT_12'],
    'wednesday': ['PSALM_109', 'PSALM_113A', 'NT_12'],
    'thursday': ['PSALM_109', 'PSALM_113A', 'NT_12'],
    'friday': ['PSALM_109', 'PSALM_113A', 'NT_12'],
  },
  2: {
    'saturday': ['PSALM_109', 'PSALM_113A', 'NT_12'],
  }
};

List<String>? vespersPsalms(
    String liturgicalTime, int liturgicalWeek, String dayName) {
  Map<int, Map<String, List<String>>> finalList = vespersDefaultDistribution;
// pour l'octave pascal:
  if (liturgicalTime == 'PaschalOctave') {
    finalList = mergePsalms(
        vespersDefaultDistribution, vespersPaschalOctaveDistribution);
  }
  List<String>? psalmsList = finalList[liturgicalWeek]?[dayName];
  return psalmsList;
}
