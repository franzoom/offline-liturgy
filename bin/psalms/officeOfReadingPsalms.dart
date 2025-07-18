import '../tools/psalms_list_management.dart';

final Map<int, Map<String, List<String>>> readingPsalmsDefaultDistribution = {
  1: {
    'monday': ['PSALM_1', 'PSALM_2', 'PSALM_3'],
    'tuesday': ['PSALM_6', 'PSALM_9A_1', 'PSALM_9A_2'],
    'wednesday': ['PSALM_9B_1', 'PSALM_9B_2', 'PSALM_11'],
    'thursday': ['PSALM_17_1', 'PSALM_17_2', 'PSALM_17_3'],
    'friday': ['PSALM_17_4', 'PSALM_17_5', 'PSALM_17_6'],
    'saturday': ['PSALM_34_1', 'PSALM_34_2', 'PSALM_34_3'],
    'sunday': ['PSALM_130', 'PSALM_131_1', 'PSALM_131_2'],
  },
  2: {
    'monday': ['PSALM_103_1', 'PSALM_103_2', 'PSALM_103_3'],
    'tuesday': ['PSALM_30_1', 'PSALM_30_2', 'PSALM_30_3'],
    'wednesday': ['PSALM_36_1', 'PSALM_36_2', 'PSALM_36_3'],
    'thursday': ['PSALM_38_1', 'PSALM_38_2', 'PSALM_51'],
    'friday': ['PSALM_43_1', 'PSALM_43_2', 'PSALM_43_3'],
    'saturday': ['PSALM_37_1', 'PSALM_37_2', 'PSALM_37_3'],
    'sunday': ['PSALM_135_1', 'PSALM_135_2', 'PSALM_135_3'],
  },
  3: {
    'monday': ['PSALM_144_1', 'PSALM_144_2', 'PSALM_144_3'],
    'tuesday': ['PSALM_49_1', 'PSALM_49_2', 'PSALM_49_3'],
    'wednesday': ['PSALM_67_1', 'PSALM_67_2', 'PSALM_67_3'],
    'thursday': ['PSALM_88_1', 'PSALM_88_2', 'PSALM_88_3'],
    'friday': ['PSALM_88_4', 'PSALM_88_5', 'PSALM_89'],
    'saturday': ['PSALM_68_1', 'PSALM_68_2', 'PSALM_68_3'],
    'sunday': ['PSALM_106_1', 'PSALM_106_2', 'PSALM_106_3'],
  },
  4: {
    'monday': ['PSALM_23', 'PSALM_65_1', 'PSALM_65_2'],
    'tuesday': ['PSALM_72_1', 'PSALM_72_2', 'PSALM_72_3'],
    'wednesday': ['PSALM_101_1', 'PSALM_101_2', 'PSALM_101_3'],
    'thursday': ['PSALM_102_1', 'PSALM_102_2', 'PSALM_102_3'],
    'friday': ['PSALM_43_1', 'PSALM_43_2', 'PSALM_43_3'],
    'saturday': ['PSALM_54_1', 'PSALM_54_2', 'PSALM_54_3'],
    'sunday': ['PSALM_49_1', 'PSALM_49_2', 'PSALM_49_3'],
  },
};

final Map<int, Map<String, List<String>>> readingPsalmsNonOrdinaryDistribution =
    {
  // distribution des psaumes lorsque ce n'est pas le Temps Ordinaire
  1: {
    'saturday': ['PSALM_104_1', 'PSALM_104_2', 'PSALM_104_3'],
  },
  2: {
    'saturday': ['PSALM_105_1', 'PSALM_105_2', 'PSALM_105_3'],
  },
  4: {
    'friday': ['PSALM_77_1', 'PSALM_77_2', 'PSALM_77_3'],
    'saturday': ['PSALM_77_4', 'PSALM_77_5', 'PSALM_77_6'],
  },
};

final Map<int, Map<String, List<String>>>
    readingPsalmsPaschalOctaveDistribution = {
  1: {
    'sunday': ['PSALM_0', 'PSALM_0', 'PSALM_0'],
    'monday': ['PSALM_1', 'PSALM_2', 'PSALM_3'],
    'tuesday': ['PSALM_23', 'PSALM_65_1', 'PSALM_65_2'],
    'wednesday': ['PSALM_103_1', 'PSALM_103_2', 'PSALM_103_3'],
    'thursday': ['PSALM_117_1', 'PSALM_117_2', 'PSALM_117_3'],
    'friday': ['PSALM_135_1', 'PSALM_135_2', 'PSALM_135_3'],
    'saturday': ['PSALM_144_1', 'PSALM_144_2', 'PSALM_144_3'],
  },
  2: {
    'sunday': ['PSALM_1', 'PSALM_2', 'PSALM_3'],
  },
};

List<String>? officeOfReadingsPsalms(
    String liturgicalTime, int liturgicalWeek, String dayName) {
  Map<int, Map<String, List<String>>> finalList =
      readingPsalmsDefaultDistribution;
// en dehors du temps ordinaire:
  if (liturgicalTime != 'OrdinaryTime') {
    finalList = mergePsalms(readingPsalmsDefaultDistribution,
        readingPsalmsPaschalOctaveDistribution);
  }
  if (liturgicalTime == 'PaschalOctave') {
    finalList = mergePsalms(readingPsalmsDefaultDistribution,
        readingPsalmsPaschalOctaveDistribution);
  }
  List<String>? psalmsList = finalList[liturgicalWeek]?[dayName];
  return psalmsList;
}
