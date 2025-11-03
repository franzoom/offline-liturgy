import '../../classes/compline_class.dart';

final Map<String, Compline> defaultCompline = {
  "saturday": Compline(
    hymns: ["ferme-mes-yeux", "te-lucis-ante-terminum"],
    psalmody: [
      {
        "psalm": "PSALM_4",
        "antiphon": ["Sur nous, Seigneur, que s'illumine ton visage!."]
      },
      {
        "psalm": "PSALM_133",
        "antiphon": ["Au long des nuits, bénissez le Seigneur ! "]
      }
    ],
    reading: {
      "ref": "Dt 6, 4-8a",
      "content":
          "Écoute, Israël : le Seigneur notre Dieu est l'Unique. Tu aimeras le Seigneur ton Dieu de tout ton cœur, de toute ton âme et de toute ta force. Ces commandements que je te donne aujourd'hui resteront gravés dans ton cœur. Tu les rediras à tes fils, tu les répéteras sans cesse, à la maison ou en voyage, que tu sois couché ou que tu sois levé."
    },
    responsory:
        "<p>R/ En tes mains, Seigneur, je remets mon esprit.<br>V/ Tu es le Dieu fidèle qui garde son Alliance. R/<br>Gloire au Père et au Fils et au Saint-Esprit. R/</p>",
    evangelicAntiphon:
        "Sauve-nous, Seigneur, quand nous veillons ; garde-nous quand nous dormons : nous veillerons avec le Christ et nous reposerons en paix.",
    oration: [
      "Dieu éternel, tu as écouté la prière de ton Christ, et tu l'as délivré de la mort; ne permets pas que nos cœurs se troublent, rassure-nous dans notre nuit, comble-nous de ta joie, et nous attendrons dans le silence et la paix que se lève sur nous la lumière de la Résurrection. Par Jésus, le Christ, notre Seigneur. Amen."
    ],
    marialHymnRef: [
      "sainte-mere-du-redempteur",
      "salut-reine-des-cieux",
      "heureuse-es-tu-vierge-marie",
      "nous-te-saluons-vierge-marie",
      "sous-l-abri-de-ta-misericorde",
      "alma-redemptoris-mater",
      "ave-regina-caelorum",
      "salve-regina",
      "sub-tuum-praesidium",
    ],
  ),
  "sunday": Compline(
    hymns: ["avant-la-fin-de-la-lumiere", "te-lucis-ante-terminum"],
    psalmody: [
      {
        "psalm": "PSALM_90",
        "antiphon": [
          "Le Seigneur te couvre de ses ailes, rien à craindre des terreurs de la nuit.",
          ""
        ]
      }
    ],
    reading: {
      "ref": "Ap 22, 4-5",
      "content":
          "Les serviteurs de Dieu verront son visage, et son nom sera écrit sur leur front. La nuit n'existera plus, ils n'auront plus besoin de la lumière d'une lampe ni de la lumière du soleil, parce que le Seigneur Dieu les illuminera, et ils régneront pour les siècles des siècles."
    },
    responsory:
        "<p>R/ En tes mains, Seigneur, je remets mon esprit.<br>V/ Sur ton serviteur, que s'illumine ta face. R/<br>Gloire au Père et au Fils et au Saint-Esprit. R/</p>",
    evangelicAntiphon:
        "Sauve-nous, Seigneur, quand nous veillons ; garde-nous quand nous dormons : nous veillerons avec le Christ et nous reposerons en paix.",
    oration: [
      "Notre Seigneur et notre Dieu, tu nous as fait entendre ton amour au matin de la Résurrection ; quand viendra pour nous le moment de mourir, que ton souffle de vie nous conduise en ta présence. Par Jésus, le Christ, notre Seigneur. Amen.",
      "Seigneur Dieu, notre maître souverain, tu as illuminé nos yeux par la lumière de ton Verbe éternel; alors qu'il fait nuit maintenant, garde nos âmes dans ta paix, et quand notre vie s'éteindra, laisse-nous aller dans ton paradis avec ton Fils, Jésus-Christ notre Seigneur. Amen."
    ],
    marialHymnRef: [
      "sainte-mere-du-redempteur",
      "salut-reine-des-cieux",
      "heureuse-es-tu-vierge-marie",
      "nous-te-saluons-vierge-marie",
      "sous-l-abri-de-ta-misericorde",
      "alma-redemptoris-mater",
      "ave-regina-caelorum",
      "salve-regina",
      "sub-tuum-praesidium",
    ],
  ),
  "monday": Compline(
    hymns: ["en-toi-seigneur", "te-lucis-ante-terminum"],
    psalmody: [
      {
        "psalm": "PSALM_85",
        "antiphon": [
          "Toi qui es bon et qui pardonnes, écoute ma prière!",
          "Dieu de tendresse et de pitié, prends pitié de moi!"
        ]
      }
    ],
    reading: {
      "ref": "1Th 5, 9b-10",
      "content":
          "Dieu nous a destinés à entrer en possession du salut par notre Seigneur Jésus Christ, mort pour nous afin de nous faire vivre avec lui, que nous soyons encore éveillés ou déjà endormis dans la mort."
    },
    responsory:
        "<p>R/ En tes mains, Seigneur, je remets mon esprit.<br>V/ C'est toi qui nous rachètes, Seigneur, Dieu de vérité. R/<br>Gloire au Père et au Fils et au Saint-Esprit. R/</p>",
    evangelicAntiphon:
        "Sauve-nous, Seigneur, quand nous veillons ; garde-nous quand nous dormons : nous veillerons avec le Christ et nous reposerons en paix.",
    oration: [
      "Seigneur, tandis que nous dormirons en paix, fais germer et grandir jusqu'à la moisson la semence du Royaume des cieux que nous avons jetée en terre par le travail de cette journée. Par Jésus, le Christ, notre Seigneur. Amen."
    ],
    marialHymnRef: [
      "sainte-mere-du-redempteur",
      "salut-reine-des-cieux",
      "heureuse-es-tu-vierge-marie",
      "nous-te-saluons-vierge-marie",
      "sous-l-abri-de-ta-misericorde",
      "alma-redemptoris-mater",
      "ave-regina-caelorum",
      "salve-regina",
      "sub-tuum-praesidium",
    ],
  ),
  "tuesday": Compline(
    hymns: ["vienne-la-nuit-de-dieu", "te-lucis-ante-terminum"],
    psalmody: [
      {
        "psalm": "PSALM_142",
        "antiphon": [
          "Pour l'honneur de ton nom, Seigneur, fais-moi vivre.",
          "J'ai un abri auprès de toi, car tu es mon Dieu."
        ]
      }
    ],
    reading: {
      "ref": "1P 5, 8-9a",
      "content":
          "Soyez sobres, soyez vigilants : votre adversaire, le démon, comme un lion qui rugit, va et vient, à la recherche de sa proie. Résistez-lui avec la force de la foi."
    },
    responsory:
        "<p>R/ En tes mains, Seigneur, je remets mon esprit.<br>V/ Écoute, et viens me délivrer. R/<br>Gloire au Père et au Fils et au Saint-Esprit. R/</p>",
    evangelicAntiphon:
        "Sauve-nous, Seigneur, quand nous veillons ; garde-nous quand nous dormons : nous veillerons avec le Christ et nous reposerons en paix.",
    oration: [
      "Dieu qui es fidèle et juste, réponds à ton Église en prière, comme tu as répondu à Jésus, ton serviteur. Quand le souffle en elle s'épuise, fais-la vivre du souffle de ton Esprit : qu'elle médite sur l'œuvre de tes mains, pour avancer, libre et confiante, vers le matin de sa Pâque. Par Jésus, le Christ, notre Seigneur. Amen."
    ],
    marialHymnRef: [
      "sainte-mere-du-redempteur",
      "salut-reine-des-cieux",
      "heureuse-es-tu-vierge-marie",
      "nous-te-saluons-vierge-marie",
      "sous-l-abri-de-ta-misericorde",
      "alma-redemptoris-mater",
      "ave-regina-caelorum",
      "salve-regina",
      "sub-tuum-praesidium",
    ],
  ),
  "wednesday": Compline(
    hymns: ["avant-la-fin-de-la-lumiere", "te-lucis-ante-terminum"],
    psalmody: [
      {
        "psalm": "PSALM_30_1",
        "antiphon": [
          "Dieu, ma forteresse et mon abri !",
          "Devant moi tu as ouvert un passage."
        ]
      },
      {
        "psalm": "PSALM_129",
        "antiphon": [
          "Près de toi se trouve le pardon.",
          "J'espère le Seigneur de toute mon âme."
        ]
      }
    ],
    reading: {
      "ref": "Ep 4, 30.32",
      "content":
          "En vue de votre délivrance, vous avez reçu en vous la marque du Saint-Esprit de Dieu : ne le contristez pas. Soyez entre vous pleins de générosité et de tendresse. Pardonnez-vous les uns aux autres, comme Dieu vous a pardonné dans le Christ."
    },
    responsory:
        "<p>R/ En tes mains, Seigneur, je remets mon esprit.<br>V/ Tu vois ma misère, tu sais ma détresse. R/<br>Gloire au Père et au Fils et au Saint-Esprit. R/</p>",
    evangelicAntiphon:
        "Sauve-nous, Seigneur, quand nous veillons ; garde-nous quand nous dormons : nous veillerons avec le Christ et nous reposerons en paix.",
    oration: [
      "Seigneur Jésus Christ, dont le joug est facile et le fardeau léger, nous venons remettre en tes mains le fardeau de ce jour, accorde-nous de trouver près de toi le repos. Toi qui règnes pour les siècles des siècles. Amen."
    ],
    marialHymnRef: [
      "sainte-mere-du-redempteur",
      "salut-reine-des-cieux",
      "heureuse-es-tu-vierge-marie",
      "nous-te-saluons-vierge-marie",
      "sous-l-abri-de-ta-misericorde",
      "alma-redemptoris-mater",
      "ave-regina-caelorum",
      "salve-regina",
      "sub-tuum-praesidium",
    ],
  ),
  "thursday": Compline(
    hymns: ["en-toi-seigneur", "te-lucis-ante-terminum"],
    psalmody: [
      {
        "psalm": "PSALM_15",
        "antiphon": [
          "Garde-moi, mon Dieu, mon refuge est en toi.",
          "Ma chair reposera en confiance."
        ]
      }
    ],
    reading: {
      "ref": "1Th 5, 23",
      "content":
          "Que le Dieu de la paix lui-même vous sanctifie tout entiers, et qu'il garde parfaits et sans reproche votre esprit, votre âme et votre corps, pour la venue de notre Seigneur Jésus Christ."
    },
    responsory:
        "<p>R/ En tes mains, Seigneur, je remets mon esprit.<br>V/ Je suis sûr de toi, tu es mon Dieu. R/<br>Gloire au Père et au Fils et au Saint-Esprit. R/</p>",
    evangelicAntiphon:
        "Sauve-nous, Seigneur, quand nous veillons ; garde-nous quand nous dormons : nous veillerons avec le Christ et nous reposerons en paix.",
    oration: [
      "Seigneur, notre part d'héritage, donne-nous de ne chercher qu'en toi notre bonheur et d'attendre avec confiance, au-delà de la nuit de notre mort, la joie de vivre en ta présence. Par Jésus, le Christ, notre Seigneur. Amen."
    ],
    marialHymnRef: [
      "sainte-mere-du-redempteur",
      "salut-reine-des-cieux",
      "heureuse-es-tu-vierge-marie",
      "nous-te-saluons-vierge-marie",
      "sous-l-abri-de-ta-misericorde",
      "alma-redemptoris-mater",
      "ave-regina-caelorum",
      "salve-regina",
      "sub-tuum-praesidium",
    ],
  ),
  "friday": Compline(
    hymns: ["l-heure-s-avance-fais-nous-grace", "te-lucis-ante-terminum"],
    psalmody: [
      {
        "psalm": "PSALM_87",
        "antiphon": [
          "Dans ma nuit, je crie vers toi, Seigneur.",
          "Que ma prière parvienne jusqu'à toi."
        ]
      }
    ],
    reading: {
      "ref": "Jr 14, 7-9b",
      "content":
          "Si nos fautes parlent contre nous, agis, Seigneur, pour l'honneur de ton nom ! Tu es au milieu de nous, et ton nom a été invoqué sur nous ; ne nous abandonne pas, Seigneur, notre Dieu."
    },
    responsory:
        "<p>R/ En tes mains, Seigneur, je remets mon esprit.<br>V/ Mes jours sont dans ta main, sauve-moi. R/<br>Gloire au Père et au Fils et au Saint-Esprit. R/</p>",
    evangelicAntiphon:
        "Sauve-nous, Seigneur, quand nous veillons ; garde-nous quand nous dormons : nous veillerons avec le Christ et nous reposerons en paix.",
    oration: [
      "Seigneur notre Dieu, que la splendeur de la Résurrection nous illumine, pour que nous puissions échapper à l'ombre de la mort et parvenir à la lumière éternelle dans ton Royaume. Par Jésus, le Christ, notre Seigneur. Amen."
    ],
    marialHymnRef: [
      "sainte-mere-du-redempteur",
      "salut-reine-des-cieux",
      "heureuse-es-tu-vierge-marie",
      "nous-te-saluons-vierge-marie",
      "sous-l-abri-de-ta-misericorde",
      "alma-redemptoris-mater",
      "ave-regina-caelorum",
      "salve-regina",
      "sub-tuum-praesidium",
    ],
  ),
};
