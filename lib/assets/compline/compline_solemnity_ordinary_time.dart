import "../../classes/compline_class.dart";
import "../../classes/office_elements_class.dart";

final Map<String, Compline> solemnityComplineOrdinaryTime = {
  "saturday": Compline(
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_4",
        antiphon: ["Dans la paix, je reposerai."],
      ),
      PsalmEntry(
        psalm: "PSALM_133",
        antiphon: ["Au long des nuits, bénissez le Seigneur&nbsp;!"],
      ),
    ],
    oration: [
      "Dieu du ciel et de la terre, nous levons les mains vers toi pour te bénir, car tu nous as bénis en ton Fils bien-aimé. Dans la nuit que tu nous donnes pour unir notre prière à la sienne, nous te supplions de nous bénir encore. Par Jésus le Christ, notre Seigneur. Amen."
    ],
  ),
  "sunday": Compline(
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_90",
        antiphon: ["Dieu puissant, mon rempart et ma foi&nbsp;!"],
      ),
    ],
    oration: [
      "Nous t'en supplions, Seigneur, visite cette maison, et repousse loin d'elle toutes les embûches de l'ennemi&nbsp;; que tes saints anges viennent l'habiter pour nous garder dans la paix; et que ta bénédiction demeure à jamais sur nous. Par le Christ notre Seigneur. Amen."
    ],
  ),
};
