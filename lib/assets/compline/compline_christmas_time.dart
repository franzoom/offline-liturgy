import '../../classes/compline_class.dart';

final Map<String, Compline> christmasTimeCompline = {
  "saturday": Compline(
    psalmody: [
      {
        "psalm": "PSALM_4",
        "antiphon": [
          "Nos yeux ont vu le salut: qui peut nous ravir notre joie&nbsp;?"
        ]
      },
      {
        "psalm": "PSALM_133",
        "antiphon": ["Sur le pays de l'ombre, une lumière s'est levée."]
      }
    ],
    evangelicAntiphon: "J'ai vu de mes yeux le Sauveur: lumière des peuples.",
  ),
  "sunday": Compline(
    psalmody: [
      {
        "psalm": "PSALM_90",
        "antiphon": ["Il suffit que tu ouvres les yeux, tu verras le salut."]
      }
    ],
    evangelicAntiphon: "J'ai vu de mes yeux le Sauveur: lumière des peuples.",
  ),
  "monday": Compline(
    psalmody: [
      {
        "psalm": "PSALM_85",
        "antiphon": [
          "Tous les peuples viendront t'adorer, car tu fais des merveilles."
        ]
      }
    ],
  ),
  "tuesday": Compline(
    psalmody: [
      {
        "psalm": "PSALM_142",
        "antiphon": [
          "Sur l'œuvre de tes mains, je médite, je tends le mains vers toi."
        ]
      }
    ],
  ),
  "wednesday": Compline(
    psalmody: [
      {
        "psalm": "PSALM_30_1",
        "antiphon": [
          "Plus qu'un veilleur ne guette l'aurore, attends le Seigneur."
        ]
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
        "antiphon": ["J'ai dit au Seigneur: Tu es mon Dieu!"]
      }
    ],
  ),
  "friday": Compline(
    psalmody: [
      {
        "psalm": "PSALM_87",
        "antiphon": [
          "Seigneur, mon Dieu et mon salut!",
        ]
      }
    ],
  ),
};
