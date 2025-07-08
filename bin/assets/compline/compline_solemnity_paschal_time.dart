import '../../classes/compline_class.dart';

final Map<String, Compline> solemnityComplinePaschalTime = {
  "saturday": Compline(
    complinePsalm1Antiphon1: "Dans la paix, je reposerai.",
    complinePsalm2Antiphon1: "Dans la paix, je reposerai.",
    complineResponsory: """R/ En tes mains, Seigneur, je remets mon esprit.
* Alléluia, alléluia
V/ Tu es le Dieu fidèle qui garde son Alliance.
* Alléluia, alléluia
Gloire au Père et au Fils et au Saint-Esprit. R/""",
    complineEvangelicAntiphon:
        "Le Seigneur est ressuscité, alléluia, il nous remplit de sa lumière. Alléluia.",
    complineOration: [
      "Dieu du ciel et de la terre, nous levons les mains vers toi pour te bénir, car tu nous as bénis en ton Fils bien-aimé. Dans la nuit que tu nous donnes pour unir notre prière à la sienne, nous te supplions de nous bénir encore. Par Jésus le Christ, notre Seigneur. Amen."
    ],
    marialHymnRef: [
      "o-vierge-marie-quelle-joie",
      "reine-du-ciel-rejouis-toi",
      "regina-caeli"
    ],
  ),
  "sunday": Compline(
    complinePsalm1Antiphon1: "Dieu puissant, mon rempart et ma foi !",
    complinePsalm1Antiphon2: " ",
    complineResponsory: """R/ En tes mains, Seigneur, je remets mon esprit.
* Alléluia, alléluia
V/ Tu es le Dieu fidèle qui garde son Alliance.
* Alléluia, alléluia
Gloire au Père et au Fils et au Saint-Esprit. R/""",
    complineEvangelicAntiphon:
        "Le Seigneur est ressuscité, alléluia, il nous remplit de sa lumière. Alléluia.",
    complineOration: [
      "Nous t'en supplions, Seigneur, visite cette maison, et repousse loin d'elle toutes les embûches de l'ennemi; que tes saints anges viennent l'habiter pour nous garder dans la paix; et que ta bénédiction demeure à jamais sur nous. Par le Christ notre Seigneur. Amen."
    ],
    marialHymnRef: [
      "o-vierge-marie-quelle-joie",
      "reine-du-ciel-rejouis-toi",
      "regina-caeli"
    ],
  ),
};
