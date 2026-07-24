/// Standard French Mass-reading announcements ("Lecture du livre de..."),
/// keyed by the normalized book abbreviation used at the start of a
/// `biblicalRef` (e.g. "Rm 12, 1-2" -> key "RM" -> "Romains").
///
/// Covers the Old and New Testament books used as a Mass first/second
/// reading (READING/EPISTLE part type). Deliberately excludes:
/// - the four Gospels, announced differently ("Évangile de Jésus Christ
///   selon saint ..."), see `evangelistName` in french_liturgy_labels.dart
/// - the Psalms and OT canticles, announced as "Psaume"/"Cantique de ..."
///   rather than "Lecture de ...", handled by the PSALM/CANTICLE part type
const Map<String, String> readingAnnouncements = {
  // Pentateuque
  'GN': 'Lecture du livre de la Genèse',
  'EX': 'Lecture du livre de l’Exode',
  'LV': 'Lecture du livre du Lévitique',
  'NB': 'Lecture du livre des Nombres',
  'DT': 'Lecture du livre du Deutéronome',
  // Livres historiques
  'JOS': 'Lecture du livre de Josué',
  'JG': 'Lecture du livre des Juges',
  'RT': 'Lecture du livre de Ruth',
  '1S': 'Lecture du 1er livre de Samuel',
  '1SM': 'Lecture du 1er livre de Samuel',
  '2S': 'Lecture du 2ème livre de Samuel',
  '2SM': 'Lecture du 2ème livre de Samuel',
  '1R': 'Lecture du 1er livre des Rois',
  '2R': 'Lecture du 2ème livre des Rois',
  '1CH': 'Lecture du 1er livre des Chroniques',
  '1CHR': 'Lecture du 1er livre des Chroniques',
  '2CH': 'Lecture du 2ème livre des Chroniques',
  '2CHR': 'Lecture du 2ème livre des Chroniques',
  'ESD': 'Lecture du livre d’Esdras',
  'NE': 'Lecture du livre de Néhémie',
  'TB': 'Lecture du livre de Tobie',
  'JDT': 'Lecture du livre de Judith',
  'EST': 'Lecture du livre d’Esther',
  '1M': 'Lecture du premier livre des Maccabées',
  '2M': 'Lecture du second livre des Maccabées',
  // Livres poétiques et sapientiaux
  'JB': 'Lecture du livre de Job',
  'PR': 'Lecture du livre des Proverbes',
  'QO': 'Lecture du livre de Qohélet',
  'CT': 'Lecture du Cantique des cantiques',
  'SG': 'Lecture du livre de la Sagesse',
  'SI': 'Lecture du livre de Ben Sira le Sage',
  // Grands prophètes
  'IS': 'Lecture du livre d’Isaïe',
  'JR': 'Lecture du livre de Jérémie',
  'LM': 'Lecture du livre des Lamentations',
  'BA': 'Lecture du livre de Baruch',
  'EZ': 'Lecture du livre d’Ézéchiel',
  'DN': 'Lecture du livre de Daniel',
  // Petits prophètes
  'OS': 'Lecture du livre d’Osée',
  'JL': 'Lecture du livre de Joël',
  'AM': 'Lecture du livre d’Amos',
  'AB': 'Lecture du livre d’Abdias',
  'JON': 'Lecture du livre de Jonas',
  'MI': 'Lecture du livre de Michée',
  'NA': 'Lecture du livre de Nahum',
  'HA': 'Lecture du livre d’Habacuc',
  'SO': 'Lecture du livre de Sophonie',
  'AG': 'Lecture du livre d’Aggée',
  'ZA': 'Lecture du livre de Zacharie',
  'ML': 'Lecture du livre de Malachie',
  // Nouveau Testament
  'AC': 'Lecture du livre des Actes des Apôtres',
  'RM': 'Lecture de la lettre aux Romains',
  '1CO': 'Lecture de la 1ère lettre aux Corinthiens',
  '2CO': 'Lecture de la 2ème lettre aux Corinthiens',
  'GA': 'Lecture de la lettre aux Galates',
  'EP': 'Lecture de la lettre aux Éphésiens',
  'PH': 'Lecture de la lettre aux Philippiens',
  'COL': 'Lecture de la lettre aux Colossiens',
  '1TH': 'Lecture de la 1ère lettre ux Thessaloniciens',
  '2TH': 'Lecture de la 2ème lettre aux Thessaloniciens',
  '1TM': 'Lecture de la 1ère lettre à Timothée',
  '2TM': 'Lecture de la 2ème lettre à Timothée',
  'TT': 'Lecture de la lettre à Tite',
  'PHM': 'Lecture du billet à Philémon',
  'HE': 'Lecture de la lettre aux Hébreux',
  'JC': 'Lecture de la lettre de saint Jacques',
  '1P': 'Lecture de la 1ère lettre de saint Pierre',
  '2P': 'Lecture de la 2ème lettre de saint Pierre',
  '1JN': 'Lecture de la 1ère lettre de saint Jean',
  '2JN': 'Lecture de la 2ème lettre de saint Jean',
  '3JN': 'Lecture de la 3ème lettre de saint Jean',
  'JUDE': 'Lecture de l’épître de Jude',
  'JD': 'Lecture de l’épître de Jude',
  'AP': 'Lecture du livre de l’Apocalypse de saint Jean',
};

/// Matches an optional "cf." marker, optional stray leading punctuation
/// (e.g. a stray opening quote), an optional book-number prefix (1-4) and
/// the book's letters, e.g. "Cf. 1 Co 12, 3-7" -> groups ("1", "Co").
final RegExp _bookAbbreviationRegExp = RegExp(
  r'^(?:cf\.?\s*)?[^A-Za-zÀ-ÿ0-9]*(\d)?\s*([A-Za-zÀ-ÿ]+)',
  caseSensitive: false,
);

/// Extracts the standard Mass-reading announcement from a `biblicalRef`
/// such as "Gn 2, 18-24" or "1 Co 15, 1-11". Returns null if the reference
/// doesn't start with a recognized non-Gospel book abbreviation.
String? readingAnnouncement(String? biblicalRef) {
  if (biblicalRef == null) return null;
  final match = _bookAbbreviationRegExp.firstMatch(biblicalRef.trim());
  if (match == null) return null;
  final key = '${match.group(1) ?? ''}${match.group(2)!.toUpperCase()}';
  return readingAnnouncements[key];
}
