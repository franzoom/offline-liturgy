/// Celebration Types
const Map<String, String> celebrationTypeLabels = {
  'Solemnity': 'Solennité',
  'SolemnityEve': 'Veille de Solennité',
  'holy_thursday': 'Jeudi Saint',
  'holy_friday': 'Vendredi Saint',
  'holy_saturday': 'Samedi Saint',
  'normal': 'Férie',
};

/// Liturgical Times
const liturgicalTimeLabels = {
  'advent': 'Temps de l\'Avent',
  'ot': 'Temps Ordinaire',
  'paschal': 'Temps Pascal',
  'lent': 'Carême',
  'christmas': 'Temps de Noël',
  'holyweek': 'Semaine Sainte',
  'paschaloctave': 'Octave Paschal',
  'christmasoctave': 'Octave de Noël',
};

// Map days of the week
const daysOfWeek = [
  'dimanche',
  'lundi',
  'mardi',
  'mercredi',
  'jeudi',
  'vendredi',
  'samedi',
];

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

/// celebration names in french
const Map<String, String> liturgyLabels = {
  'christmas': 'Noël',
  'easter': 'Pâques',
  'pentecost': 'Pentecôte',
  'ascension': 'Ascension',
  'epiphany': 'Épiphanie',
  'all_saints': 'Toussaint',
  'assumption': 'Assomption',
  'immaculate_conception': 'Immaculée Conception',
  'introduction': 'Introduction',
  'simeon_canticle': 'Cantique de Syméon',
  'oration': 'Oraison',
  'marial_hymns': 'Hymnes Mariales',
  'hymns': 'Hymnes',
  'blessing': 'Bénédiction',
  'reading': 'Lecture',
  'word_of_god': 'Parole de Dieu',
  'responsory': 'Répons',
  'our_father': 'Notre Père',
  'intercession': 'Intercession',
  'conclusion': 'Conclusion',
  'zachary_canticle': 'Cantique de Zacharie',
  'invitatory': 'Invitatoire',
};

final Map<String, String> fixedTexts = {
  "officeIntroduction":
      "<p>R/ Dieu, viens à mon aide.<br>V/ Seigneur, à notre secours.</p><p>Gloire au Père, et au Fils, et au Saint-Esprit,<br>au Dieu qui était et qui vient,<br>pour les siècles des siècles.<br>Amen. (Alléluia.)</p>",
  "invitatoryIntroduction":
      "<p>R/ Seigneur, ouvre mes lèvres.<br>V/ Et ma bouche publiera ta louange.</p>",
  "officeBenediction":
      "<p>Que le Seigneur nous bénisse, nous protège de tout mal et nous conduise à la vie éternelle. Amen.</p>",
  "complineIntroduction":
      "On peut commencer par une révision de la journée, ou par un acte pénitentiel dans la célébration commune.",
  "complineConclusion":
      "<p>Que Le Seigneur nous bénisse et nous garde,<br>le Père, le Fils, et le Saint-Esprit.<br>Amen.</p>",
  "or": "<p>ou</p>",
};

String getFrenchOrdinal(int number) {
  if (number == 1) {
    return '1er';
  }
  return '${number}ème';
}
