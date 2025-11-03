import "../../classes/compline_class.dart";

final Map<String, Compline> lentTimeCompline = {
  "saturday": Compline(
    psalmody: [
      {
        "psalm": "PSALM_4",
        "antiphon": ["Pitié pour moi, Seigneur, écoute ma prière."]
      },
      {
        "psalm": "PSALM_133",
        "antiphon": ["Pitié pour moi, Seigneur, écoute ma prière."]
      }
    ],
    evangelicAntiphon:
        "Dieu saint, Dieu fort, Dieu immortel, ta pitié soit sur nous.",
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
        "antiphon": ["À l’ombre de ses ailes, n’aie plus peur de la nuit."]
      }
    ],
    evangelicAntiphon:
        "Dieu saint, Dieu fort, Dieu immortel, ta pitié soit sur nous.",
    marialHymnRef: [
      "sub-tuum-praesidium",
      "sous-l-abri-de-ta-misericorde",
      "salut-reine-des-cieux",
      "ave-regina-caelorum"
    ],
  ),
  "monday": Compline(
    psalmody: [
      {
        "psalm": "PSALM_85",
        "antiphon": ["Rassemble mon cœur pour qu’il te craigne."]
      }
    ],
    marialHymnRef: [
      "sub-tuum-praesidium",
      "sous-l-abri-de-ta-misericorde",
      "salut-reine-des-cieux",
      "ave-regina-caelorum"
    ],
  ),
  "tuesday": Compline(
    hymns: ["vienne_la_nuit_de_dieu_lent", "te-lucis-ante-terminum"],
    psalmody: [
      {
        "psalm": "PSALM_142",
        "antiphon": ["Ne me cache pas ton visage, car je compte sur toi."]
      }
    ],
    marialHymnRef: [
      "sub-tuum-praesidium",
      "sous-l-abri-de-ta-misericorde",
      "salut-reine-des-cieux",
      "ave-regina-caelorum"
    ],
  ),
  "wednesday": Compline(
    psalmody: [
      {
        "psalm": "PSALM_30_1",
        "antiphon": ["Auprès du Seigneur est la grâce, la pleine délivrance."]
      },
      {
        "psalm": "PSALM_129",
        "antiphon": ["Auprès du Seigneur est la grâce, la pleine délivrance."]
      }
    ],
    marialHymnRef: [
      "sub-tuum-praesidium",
      "sous-l-abri-de-ta-misericorde",
      "salut-reine-des-cieux",
      "ave-regina-caelorum"
    ],
  ),
  "thursday": Compline(
    psalmody: [
      {
        "psalm": "PSALM_15",
        "antiphon": ["Mon Dieu, tu ne peux m’abandonner à la mort."]
      }
    ],
    marialHymnRef: [
      "sub-tuum-praesidium",
      "sous-l-abri-de-ta-misericorde",
      "salut-reine-des-cieux",
      "ave-regina-caelorum"
    ],
  ),
  "friday": Compline(
    psalmody: [
      {
        "psalm": "PSALM_87",
        "antiphon": [
          "Pourquoi me rejeter, Seigneur ? Pourquoi cacher ta face ?"
        ]
      }
    ],
    marialHymnRef: [
      "sub-tuum-praesidium",
      "sous-l-abri-de-ta-misericorde",
      "salut-reine-des-cieux",
      "ave-regina-caelorum"
    ],
  ),
  "holy_thursday": Compline(
    psalmody: [
      {
        "psalm": "PSALM_90",
        "antiphon": ["À l’ombre de ses ailes, n’aie plus peur de la nuit."]
      }
    ],
    responsory:
        "R/ Le Christ s’est fait pour nous obéissant jusqu’à la mort.<br>V/ Voici l’heure où le Fils de l’homme a été livré, voici le pouvoir des ténèbres. R/",
    evangelicAntiphon:
        "Dieu saint, Dieu fort, Dieu immortel, ta pitié soit sur nous.",
    marialHymnRef: [
      "sub-tuum-praesidium",
      "sous-l-abri-de-ta-misericorde",
      "salut-reine-des-cieux",
      "ave-regina-caelorum"
    ],
  ),
  "holy_friday": Compline(
    psalmody: [
      {
        "psalm": "PSALM_90",
        "antiphon": ["À l’ombre de ses ailes, n’aie plus peur de la nuit."]
      }
    ],
    responsory:
        "R/ Le Christ s’est fait pour nous obéissant jusqu’à la mort, et la mort de la croix.<br>V/ Lui, le Fils, il a appris l’obéissance par les souffrances de sa passion. R/",
    evangelicAntiphon:
        "Dieu saint, Dieu fort, Dieu immortel, ta pitié soit sur nous.",
    marialHymnRef: [
      "sub-tuum-praesidium",
      "sous-l-abri-de-ta-misericorde",
      "salut-reine-des-cieux",
      "ave-regina-caelorum"
    ],
  ),
  "holy_saturday": Compline(
    commentary:
        "Si on ne participe pas à la Veillée pascale, on dit les Complies.",
    psalmody: [
      {
        "psalm": "PSALM_90",
        "antiphon": ["À l’ombre de ses ailes, n’aie plus peur de la nuit."]
      }
    ],
    responsory:
        "R/ Le Christ s’est fait pour nous obéissant jusqu’à la mort, et la mort de la croix. <br>V/ C’est pourquoi Dieu l’a exalté et lui a donné le Nom qui est au-dessus de tout nom. R/",
    evangelicAntiphon:
        "Dieu saint, Dieu fort, Dieu immortel, ta pitié soit sur nous.",
    marialHymnRef: [
      "sub-tuum-praesidium",
      "sous-l-abri-de-ta-misericorde",
      "salut-reine-des-cieux",
      "ave-regina-caelorum"
    ],
  ),
};
