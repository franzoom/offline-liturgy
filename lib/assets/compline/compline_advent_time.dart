import '../../classes/compline_class.dart';

final Map<String, Compline> adventTimeCompline = {
  "saturday": Compline(
    psalmody: [
      {
        "psalm": "PSALM_4",
        "antiphon": ["Sur nous,Seigneur, que s'illumine ton visage!"]
      },
      {
        "psalm": "PSALM_133",
        "antiphon": ["Les ténèbres s'en vont, déjà brille la vraie lumière."]
      }
    ],
    evangelicAntiphon:
        "Avant de connaître la mort, tu verras le Christ, ton Sauveur.",
  ),
  "sunday": Compline(
    psalmody: [
      {
        "psalm": "PSALM_90",
        "antiphon": ["Dieu puissant, mon rempart et ma foi!"]
      }
    ],
    evangelicAntiphon:
        "Avant de connaître la mort, tu verras le Christ, ton Sauveur.",
  ),
  "monday": Compline(
    psalmody: [
      {
        "psalm": "PSALM_85",
        "antiphon": ["Vers toi, Seigneur, j'élève mon âme: veille sur moi."]
      }
    ],
  ),
  "tuesday": Compline(
    psalmody: [
      {
        "psalm": "PSALM_142",
        "antiphon": [
          "Vers toi, Seignuer j'élève mon âme, ne me cache pas ton visage."
        ]
      }
    ],
  ),
  "wednesday": Compline(
    psalmody: [
      {
        "psalm": "PSALM_30_1",
        "antiphon": ["Mes jours sont dans ta main, Seigneur, j'espère en toi."]
      },
      {
        "psalm": "PSALM_129",
        "antiphon": ["", ""]
      }
    ],
  ),
  "thursday": Compline(
    psalmody: [
      {
        "psalm": "PSALM_15",
        "antiphon": ["Viens, Seigneur, montre-moi le chemin de la vie."]
      }
    ],
  ),
  "friday": Compline(
    psalmody: [
      {
        "psalm": "PSALM_87",
        "antiphon": ["Je t'appelle, Seigneur, je tends les mains vers toi."]
      }
    ],
  ),
};
