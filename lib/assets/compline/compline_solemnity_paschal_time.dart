import "../../classes/compline_class.dart";
import "../../classes/office_elements_class.dart";

final Map<String, Compline> solemnityComplinePaschalTime = {
  "saturday": Compline(
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_4",
        antiphon: ["Dans la paix, je reposerai."],
      ),
      PsalmEntry(
        psalm: "PSALM_133",
        antiphon: ["Dans la paix, je reposerai."],
      ),
    ],
    responsory:
        "<p>R/ En tes mains, Seigneur, je remets mon esprit.<br>* Alléluia, alléluia.<br>V/ Tu es le Dieu fidèle qui garde son Alliance.<br>* Alléluia, alléluia.<br>Gloire au Père et au Fils et au Saint-Esprit. R/</p>",
    evangelicAntiphon: EvangelicAntiphon(
      common:
          "Le Seigneur est ressuscité, alléluia, il nous remplit de sa lumière. Alléluia.",
    ),
    oration: [
      "Dieu du ciel et de la terre, nous levons les mains vers toi pour te bénir, car tu nous as bénis en ton Fils bien-aimé. Dans la nuit que tu nous donnes pour unir notre prière à la sienne, nous te supplions de nous bénir encore. Par Jésus le Christ, notre Seigneur. Amen."
    ],
    marialHymnRef: [
      HymnEntry(code: "o-vierge-marie-quelle-joie"),
      HymnEntry(code: "reine-du-ciel-rejouis-toi"),
      HymnEntry(code: "regina-caeli"),
    ],
  ),
  "sunday": Compline(
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_90",
        antiphon: ["Dieu puissant, mon rempart et ma foi !"],
      ),
    ],
    responsory:
        "<p>R/ En tes mains, Seigneur, je remets mon esprit.<br>* Alléluia, alléluia.<br>V/ Sur ton serviteur que s'illumine ta face.<br>* Alléluia, alléluia.<br>Gloire au Père et au Fils et au Saint-Esprit. R/</p>",
    evangelicAntiphon: EvangelicAntiphon(
      common:
          "Le Seigneur est ressuscité, alléluia, il nous remplit de sa lumière. Alléluia.",
    ),
    oration: [
      "Nous t'en supplions, Seigneur, visite cette maison, et repousse loin d'elle toutes les embûches de l'ennemi&nbsp;; que tes saints anges viennent l'habiter pour nous garder dans la paix; et que ta bénédiction demeure à jamais sur nous. Par le Christ notre Seigneur. Amen."
    ],
    marialHymnRef: [
      HymnEntry(code: "o-vierge-marie-quelle-joie"),
      HymnEntry(code: "reine-du-ciel-rejouis-toi"),
      HymnEntry(code: "regina-caeli"),
    ],
  ),
};
