import "../../classes/compline_class.dart";
import "../../classes/office_elements_class.dart";

final Map<String, Compline> christmasTimeCompline = {
  "saturday": Compline(
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_4",
        antiphon: [
          "Nos yeux ont vu le salut: qui peut nous ravir notre joie&nbsp;?"
        ],
      ),
      PsalmEntry(
        psalm: "PSALM_133",
        antiphon: ["Sur le pays de l'ombre, une lumière s'est levée."],
      ),
    ],
    evangelicAntiphon: EvangelicAntiphon(
      common: "J'ai vu de mes yeux le Sauveur: lumière des peuples.",
    ),
  ),
  "sunday": Compline(
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_90",
        antiphon: ["Il suffit que tu ouvres les yeux, tu verras le salut."],
      ),
    ],
    evangelicAntiphon: EvangelicAntiphon(
      common: "J'ai vu de mes yeux le Sauveur: lumière des peuples.",
    ),
  ),
  "monday": Compline(
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_85",
        antiphon: [
          "Tous les peuples viendront t'adorer, car tu fais des merveilles."
        ],
      ),
    ],
  ),
  "tuesday": Compline(
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_142",
        antiphon: [
          "Sur l'œuvre de tes mains, je médite, je tends le mains vers toi."
        ],
      ),
    ],
  ),
  "wednesday": Compline(
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_30_1",
        antiphon: [
          "Plus qu'un veilleur ne guette l'aurore, attends le Seigneur."
        ],
      ),
      PsalmEntry(
        psalm: "PSALM_129",
        antiphon: [
          "Près de toi se trouve le pardon.",
          "J'espère le Seigneur de toute mon âme."
        ],
      ),
    ],
  ),
  "thursday": Compline(
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_15",
        antiphon: ["J'ai dit au Seigneur: Tu es mon Dieu!"],
      ),
    ],
  ),
  "friday": Compline(
    psalmody: [
      PsalmEntry(
        psalm: "PSALM_87",
        antiphon: [
          "Seigneur, mon Dieu et mon salut!",
        ],
      ),
    ],
  ),
};
