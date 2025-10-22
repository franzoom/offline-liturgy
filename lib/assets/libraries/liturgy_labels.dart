/// Bibliothèque de traductions pour les éléments liturgiques

/// Types de célébration
const Map<String, String> celebrationTypeLabels = {
  'Solemnity': 'Solennité',
  'SolemnityEve': 'Veille de Solennité',
  'holy_thursday': 'Jeudi Saint',
  'holy_friday': 'Vendredi Saint',
  'holy_saturday': 'Samedi Saint',
  'normal': 'Férie',
};

/// Temps liturgiques
const Map<String, String> liturgicalTimeLabels = {
  'OrdinaryTime': 'Temps Ordinaire',
  'LentTime': 'Temps du Carême',
  'PaschalTime': 'Temps Pascal',
  'AdventTime': 'Temps de l\'Avent',
  'ChristmasTime': 'Temps de Noël',
};

/// Jours de la semaine
const Map<String, String> dayOfWeekLabels = {
  'sunday': 'Dimanche',
  'monday': 'Lundi',
  'tuesday': 'Mardi',
  'wednesday': 'Mercredi',
  'thursday': 'Jeudi',
  'friday': 'Vendredi',
  'saturday': 'Samedi',
};

/// Noms de célébrations (pour éviter les underscores)
const Map<String, String> celebrationNameLabels = {
  'christmas': 'Noël',
  'easter': 'Pâques',
  'pentecost': 'Pentecôte',
  'ascension': 'Ascension',
  'epiphany': 'Épiphanie',
  'all_saints': 'Toussaint',
  'assumption': 'Assomption',
  'immaculate_conception': 'Immaculée Conception',
  // Ajoutez d'autres noms au besoin
};
