import "../../classes/compline_class.dart";
import "../../classes/office_elements_class.dart";

final Map<String, Compline> paschalTimeCompline = {
  "saturday": Compline(
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_4",
        antiphon: ["Alléluia, alléluia, alléluia !"],
      ),
      PsalmEntry(
        psalm: "PSALM_133",
        antiphon: ["Alléluia, alléluia, alléluia !"],
      ),
    ],
    responsory: """R/ En tes mains, Seigneur, je remets mon esprit.
* Alléluia, alléluia
V/ Tu es le Dieu fidèle qui garde son Alliance.
* Alléluia, alléluia
Gloire au Père et au Fils et au Saint-Esprit. R/""",
    evangelicAntiphon: EvangelicAntiphon(
      common:
          "Le Seigneur est ressuscité, alléluia, il nous remplit de sa lumière. Alléluia.",
    ),
    marialHymnRef: [
      "o-vierge-marie-quelle-joie",
      "reine-du-ciel-rejouis-toi",
      "regina-caeli"
    ],
  ),
  "sunday": Compline(
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_90",
        antiphon: [
          "Alléluia, alléluia, alléluia !",
        ],
      ),
    ],
    responsory: """R/ En tes mains, Seigneur, je remets mon esprit.
* Alléluia, alléluia
V/ Tu es le Dieu fidèle qui garde son Alliance.
* Alléluia, alléluia
Gloire au Père et au Fils et au Saint-Esprit. R/""",
    evangelicAntiphon: EvangelicAntiphon(
      common:
          "Le Seigneur est ressuscité, alléluia, il nous remplit de sa lumière. Alléluia.",
    ),
    marialHymnRef: [
      "o-vierge-marie-quelle-joie",
      "reine-du-ciel-rejouis-toi",
      "regina-caeli"
    ],
  ),
  "monday": Compline(
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_85",
        antiphon: ["Alléluia, alléluia, alléluia !"],
      ),
    ],
    responsory: """R/ En tes mains, Seigneur, je remets mon esprit.
* Alléluia, alléluia
V/ Tu es le Dieu fidèle qui garde son Alliance.
* Alléluia, alléluia
Gloire au Père et au Fils et au Saint-Esprit. R/""",
    evangelicAntiphon: EvangelicAntiphon(
      common:
          "Sauve-nous, Seigneur, quand nous veillons ; garde-nous quand nous dormons : nous veillerons avec le Christ et nous reposerons en paix. Alléluia",
    ),
    marialHymnRef: [
      "o-vierge-marie-quelle-joie",
      "reine-du-ciel-rejouis-toi",
      "regina-caeli"
    ],
  ),
  "tuesday": Compline(
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_142",
        antiphon: ["Alléluia, alléluia, alléluia !"],
      ),
    ],
    responsory: """R/ En tes mains, Seigneur, je remets mon esprit.
* Alléluia, alléluia
V/ Tu es le Dieu fidèle qui garde son Alliance.
* Alléluia, alléluia
Gloire au Père et au Fils et au Saint-Esprit. R/""",
    evangelicAntiphon: EvangelicAntiphon(
      common:
          "Sauve-nous, Seigneur, quand nous veillons ; garde-nous quand nous dormons : nous veillerons avec le Christ et nous reposerons en paix. Alléluia.",
    ),
    marialHymnRef: [
      "o-vierge-marie-quelle-joie",
      "reine-du-ciel-rejouis-toi",
      "regina-caeli"
    ],
  ),
  "wednesday": Compline(
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_30_1",
        antiphon: ["Alléluia, alléluia, alléluia !"],
      ),
      PsalmEntry(
        psalm: "PSALM_129",
        antiphon: ["Alléluia, alléluia, alléluia !"],
      ),
    ],
    responsory: """R/ En tes mains, Seigneur, je remets mon esprit.
* Alléluia, alléluia
V/ Tu es le Dieu fidèle qui garde son Alliance.
* Alléluia, alléluia
Gloire au Père et au Fils et au Saint-Esprit. R/""",
    evangelicAntiphon: EvangelicAntiphon(
      common:
          "Sauve-nous, Seigneur, quand nous veillons ; garde-nous quand nous dormons : nous veillerons avec le Christ et nous reposerons en paix. Alléluia",
    ),
    marialHymnRef: [
      "o-vierge-marie-quelle-joie",
      "reine-du-ciel-rejouis-toi",
      "regina-caeli"
    ],
  ),
  "thursday": Compline(
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_15",
        antiphon: ["Alléluia, alléluia, alléluia !"],
      ),
    ],
    responsory: """R/ En tes mains, Seigneur, je remets mon esprit.
* Alléluia, alléluia
V/ Tu es le Dieu fidèle qui garde son Alliance.
* Alléluia, alléluia
Gloire au Père et au Fils et au Saint-Esprit. R/""",
    evangelicAntiphon: EvangelicAntiphon(
      common:
          "Sauve-nous, Seigneur, quand nous veillons ; garde-nous quand nous dormons : nous veillerons avec le Christ et nous reposerons en paix. Alléluia",
    ),
    marialHymnRef: [
      "o-vierge-marie-quelle-joie",
      "reine-du-ciel-rejouis-toi",
      "regina-caeli"
    ],
  ),
  "friday": Compline(
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_87",
        antiphon: ["Alléluia, alléluia, alléluia !"],
      ),
    ],
    responsory: """R/ En tes mains, Seigneur, je remets mon esprit.
V/ Tu es le Dieu fidèle qui garde son Alliance. R/
Gloire au Père et au Fils et au Saint-Esprit. R/""",
    evangelicAntiphon: EvangelicAntiphon(
      common:
          "Sauve-nous, Seigneur, quand nous veillons ; garde-nous quand nous dormons : nous veillerons avec le Christ et nous reposerons en paix. Alléluia.",
    ),
    marialHymnRef: [
      "o-vierge-marie-quelle-joie",
      "reine-du-ciel-rejouis-toi",
      "regina-caeli"
    ],
  ),
};
