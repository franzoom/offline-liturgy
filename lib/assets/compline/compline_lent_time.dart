import "../../classes/compline_class.dart";
import "../../classes/office_elements_class.dart";

final Map<String, Compline> lentTimeCompline = {
  "saturday": Compline(
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_4",
        antiphon: ["Pitié pour moi, Seigneur, écoute ma prière."],
      ),
      PsalmEntry(
        psalm: "PSALM_133",
        antiphon: ["Pitié pour moi, Seigneur, écoute ma prière."],
      ),
    ],
    evangelicAntiphon: EvangelicAntiphon(
      common: "Dieu saint, Dieu fort, Dieu immortel, ta pitié soit sur nous.",
    ),
    marialHymnRef: [
      HymnEntry(code: "sub-tuum-praesidium"),
      HymnEntry(code: "sous-l-abri-de-ta-misericorde"),
      HymnEntry(code: "salut-reine-des-cieux"),
      HymnEntry(code: "ave-regina-caelorum"),
    ],
  ),
  "sunday": Compline(
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_90",
        antiphon: ["À l'ombre de ses ailes, n'aie plus peur de la nuit."],
      ),
    ],
    evangelicAntiphon: EvangelicAntiphon(
      common: "Dieu saint, Dieu fort, Dieu immortel, ta pitié soit sur nous.",
    ),
    marialHymnRef: [
      HymnEntry(code: "sub-tuum-praesidium"),
      HymnEntry(code: "sous-l-abri-de-ta-misericorde"),
      HymnEntry(code: "salut-reine-des-cieux"),
      HymnEntry(code: "ave-regina-caelorum"),
    ],
  ),
  "monday": Compline(
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_85",
        antiphon: ["Rassemble mon cœur pour qu'il te craigne."],
      ),
    ],
    marialHymnRef: [
      HymnEntry(code: "sub-tuum-praesidium"),
      HymnEntry(code: "sous-l-abri-de-ta-misericorde"),
      HymnEntry(code: "salut-reine-des-cieux"),
      HymnEntry(code: "ave-regina-caelorum"),
    ],
  ),
  "tuesday": Compline(
    hymns: [
<<<<<<< HEAD
      HymnEntry(code: "vienne-la-nuit-de-dieu-lent"),
=======
      HymnEntry(code: "vienne_la_nuit_de_dieu_lent"),
>>>>>>> italic
      HymnEntry(code: "te-lucis-ante-terminum")
    ],
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_142",
        antiphon: ["Ne me cache pas ton visage, car je compte sur toi."],
      ),
    ],
    marialHymnRef: [
      HymnEntry(code: "sub-tuum-praesidium"),
      HymnEntry(code: "sous-l-abri-de-ta-misericorde"),
      HymnEntry(code: "salut-reine-des-cieux"),
      HymnEntry(code: "ave-regina-caelorum"),
    ],
  ),
  "wednesday": Compline(
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_30_1",
        antiphon: ["Auprès du Seigneur est la grâce, la pleine délivrance."],
      ),
      PsalmEntry(
        psalm: "PSALM_129",
        antiphon: ["Auprès du Seigneur est la grâce, la pleine délivrance."],
      ),
    ],
    marialHymnRef: [
      HymnEntry(code: "sub-tuum-praesidium"),
      HymnEntry(code: "sous-l-abri-de-ta-misericorde"),
      HymnEntry(code: "salut-reine-des-cieux"),
      HymnEntry(code: "ave-regina-caelorum"),
    ],
  ),
  "thursday": Compline(
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_15",
        antiphon: ["Mon Dieu, tu ne peux m'abandonner à la mort."],
      ),
    ],
    marialHymnRef: [
      HymnEntry(code: "sub-tuum-praesidium"),
      HymnEntry(code: "sous-l-abri-de-ta-misericorde"),
      HymnEntry(code: "salut-reine-des-cieux"),
      HymnEntry(code: "ave-regina-caelorum"),
    ],
  ),
  "friday": Compline(
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_87",
        antiphon: ["Pourquoi me rejeter, Seigneur ? Pourquoi cacher ta face ?"],
      ),
    ],
    marialHymnRef: [
      HymnEntry(code: "sub-tuum-praesidium"),
      HymnEntry(code: "sous-l-abri-de-ta-misericorde"),
      HymnEntry(code: "salut-reine-des-cieux"),
      HymnEntry(code: "ave-regina-caelorum"),
    ],
  ),
  "holy_thursday": Compline(
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_90",
        antiphon: ["À l'ombre de ses ailes, n'aie plus peur de la nuit."],
      ),
    ],
    responsory:
        "R/ Le Christ s'est fait pour nous obéissant jusqu'à la mort.\nV/ Voici l'heure où le Fils de l'homme a été livré, voici le pouvoir des ténèbres. R/",
    evangelicAntiphon: EvangelicAntiphon(
      common: "Dieu saint, Dieu fort, Dieu immortel, ta pitié soit sur nous.",
    ),
    marialHymnRef: [
      HymnEntry(code: "sub-tuum-praesidium"),
      HymnEntry(code: "sous-l-abri-de-ta-misericorde"),
      HymnEntry(code: "salut-reine-des-cieux"),
      HymnEntry(code: "ave-regina-caelorum"),
    ],
  ),
  "holy_friday": Compline(
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_90",
        antiphon: ["À l'ombre de ses ailes, n'aie plus peur de la nuit."],
      ),
    ],
    responsory:
        "R/ Le Christ s'est fait pour nous obéissant jusqu'à la mort, et la mort de la croix.\nV/ Lui, le Fils, il a appris l'obéissance par les souffrances de sa passion. R/",
    evangelicAntiphon: EvangelicAntiphon(
      common: "Dieu saint, Dieu fort, Dieu immortel, ta pitié soit sur nous.",
    ),
    marialHymnRef: [
      HymnEntry(code: "sub-tuum-praesidium"),
      HymnEntry(code: "sous-l-abri-de-ta-misericorde"),
      HymnEntry(code: "salut-reine-des-cieux"),
      HymnEntry(code: "ave-regina-caelorum"),
    ],
  ),
  "holy_saturday": Compline(
    commentary:
        "Si on ne participe pas à la Veillée pascale, on dit les Complies.",
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_90",
        antiphon: ["À l'ombre de ses ailes, n'aie plus peur de la nuit."],
      ),
    ],
    responsory:
        "R/ Le Christ s'est fait pour nous obéissant jusqu'à la mort, et la mort de la croix. \nV/ C'est pourquoi Dieu l'a exalté et lui a donné le Nom qui est au-dessus de tout nom. R/",
    evangelicAntiphon: EvangelicAntiphon(
      common: "Dieu saint, Dieu fort, Dieu immortel, ta pitié soit sur nous.",
    ),
    marialHymnRef: [
      HymnEntry(code: "sub-tuum-praesidium"),
      HymnEntry(code: "sous-l-abri-de-ta-misericorde"),
      HymnEntry(code: "salut-reine-des-cieux"),
      HymnEntry(code: "ave-regina-caelorum"),
    ],
  ),
};
