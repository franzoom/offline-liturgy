import "../../classes/compline_class.dart";

final Map<String, Compline> solemnityComplineLentTime = {
  "saturday": Compline(
    psalmody: [
      {
        "psalm": "PSALM_4",
        "antiphon": ["Dans la paix, je reposerai."]
      },
      {
        "psalm": "PSALM_133",
        "antiphon": ["Dans la paix, je reposerai."]
      }
    ],
    evangelicAntiphon:
        "Dieu saint, Dieu fort, Dieu immortel, ta pitié soit sur nous.",
    oration: [
      "Dieu du ciel et de la terre, nous levons les mains vers toi pour te bénir, car tu nous as bénis en ton Fils bien-aimé. Dans la nuit que tu nous donnes pour unir notre prière à la sienne, nous te supplions de nous bénir encore. Par Jésus le Christ, notre Seigneur. Amen."
    ],
    marialHymnRef: [
      "sub-tuum-praesidium",
      "sous-l-abri-de-ta-misericorde",
      "salut-reine-des-cieux",
      "ave-regina-caelorum"
    ],
  ),
  "sunday": Compline(
    psalmody: [
      {
        "psalm": "PSALM_90",
        "antiphon": ["Dieu puissant, mon rempart et ma foi !"]
      }
    ],
    evangelicAntiphon:
        "Dieu saint, Dieu fort, Dieu immortel, ta pitié soit sur nous.",
    oration: [
      "Nous t’en supplions, Seigneur, visite cette maison, et repousse loin d’elle toutes les embûches de l’ennemi; que tes saints anges viennent l’habiter pour nous garder dans la paix; et que ta bénédiction demeure à jamais sur nous. Par le Christ notre Seigneur. Amen."
    ],
    marialHymnRef: [
      "sub-tuum-praesidium",
      "sous-l-abri-de-ta-misericorde",
      "salut-reine-des-cieux",
      "ave-regina-caelorum"
    ],
  ),
};
