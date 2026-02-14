import '../classes/psalms_class.dart';
import '../classes/hymns_class.dart';

/// Hardcoded evangelic canticles and Notre Père.
/// These texts are invariable and do not need to be loaded from YAML.

const Psalm magnificat = Psalm(
  title: 'Cantique de Marie',
  subtitle: null,
  commentary: null,
  biblicalReference: 'Lc 1',
  shortReference: 'NT 1',
  content: '{47}Mon âme ex_a_lte le Seigneur,\n'
      'exulte mon esprit en Die_u_, mon Sauveur !\n'
      '\n'
      '{48}Il s\'est penché sur son h_u_mble servante ;\n'
      'désormais, tous les âges me dir_o_nt bienheureuse.\n'
      '\n'
      '{49}Le Puissant fit pour m_o_i des merveilles ;\n'
      'S_a_int est son nom !\n'
      '\n'
      '{50}Son amour s\'ét_e_nd d\'âge en âge\n'
      'sur ce_u_x qui le craignent ;\n'
      '\n'
      '{51}Déployant la f_o_rce de son bras,\n'
      'il disp_e_rse les superbes.\n'
      '\n'
      '{52}Il renverse les puiss_a_nts de leurs trônes,\n'
      'il él_è_ve les humbles.\n'
      '\n'
      '{53}Il comble de bi_e_ns les affamés,\n'
      'renvoie les r_i_ches les mains vides.\n'
      '\n'
      '{54}Il relève Isra_ë_l, son serviteur,\n'
      'il se souvi_e_nt de son amour,\n'
      '\n'
      '{55}de la promesse f_a_ite à nos pères,\n'
      'en faveur d\'Abraham et de sa r_a_ce, à jamais.',
);

const Psalm benedictus = Psalm(
  title: 'Cantique de Zacharie',
  subtitle: null,
  commentary: null,
  biblicalReference: 'Lc 1',
  shortReference: 'NT 2',
  content: '{68}Béni soit le Seigneur, le Die_u_ d\'Israël,\n'
      'qui visite et rach_è_te son peuple.\n'
      '\n'
      '{69}Il a fait surgir la f_o_rce qui nous sauve\n'
      'dans la maison de Dav_i_d, son serviteur,\n'
      '\n'
      '{70}comme il l\'avait dit par la bo_u_che des saints,\n'
      'par ses prophètes, depuis les t_e_mps anciens :\n'
      '\n'
      '{71}salut qui nous arr_a_che à l\'ennemi,\n'
      'à la main de to_u_s nos oppresseurs,\n'
      '\n'
      '{72}amour qu\'il m_o_ntre envers nos pères,\n'
      'mémoire de son alli_a_nce sainte,\n'
      '\n'
      '{73}serment juré à notre p_è_re Abraham\n'
      'de nous r_e_ndre sans crainte,\n'
      '\n'
      '{74}afin que, délivrés de la m_a_in des ennemis, +\n'
      '{75}nous le servions dans la just_i_ce et la sainteté,\n'
      'en sa présence, tout au l_o_ng de nos jours.\n'
      '\n'
      '{76}Et toi, petit enfant, tu seras appelé\n'
      '>proph_è_te du Très-Haut : *\n'
      'tu marcheras devant, à la face du Seigneur,\n'
      '>et tu préparer_a_s ses chemins\n'
      '\n'
      '{77}pour donner à son peuple de conn_a_ître le salut\n'
      'par la rémissi_o_n de ses péchés,\n'
      '\n'
      '{78}grâce à la tendresse, à l\'amo_u_r de notre Dieu,\n'
      'quand nous visite l\'_a_stre d\'en haut,\n'
      '\n'
      '{79}pour illuminer ceux qui habitent les ténèbres\n'
      '>et l\'_o_mbre de la mort, *\n'
      'pour conduire nos pas\n'
      '>au chem_i_n de la paix.',
);

const Psalm nuncDimittis = Psalm(
  title: 'Cantique de Syméon',
  subtitle: null,
  commentary: null,
  biblicalReference: 'Lc 2',
  shortReference: 'NT 3',
  content: '{29}Maintenant, ô M_a_ître souverain, +\n'
      'tu peux laisser ton servite_u_r s\'en aller\n'
      'en paix, sel_o_n ta parole.\n'
      '\n'
      '{30}Car mes yeux ont v_u_ le salut\n'
      '{31}que tu préparais à la f_a_ce des peuples :\n'
      '\n'
      '{32}lumière qui se rév_è_le aux nations\n'
      'et donne gloire à ton pe_u_ple Israël.',
);

const String teDeum = 'À toi Dieu, notre louange !\n'
    'Nous t\'acclamons, tu es Seigneur !\n'
    'À toi Père éternel,\n'
    'L\'hymne de l\'univers.\n'
    '\n'
    'Devant toi se prosternent les archanges,\n'
    'les anges et les esprits des cieux ;\n'
    'ils te rendent grâce ;\n'
    'ils adorent et ils chantent :\n'
    '\n'
    'Saint, Saint, Saint, le Seigneur,\n'
    'Dieu de l\'univers ;\n'
    'le ciel et la terre sont remplis de ta gloire.\n'
    '\n'
    'C\'est toi que les Apôtres glorifient,\n'
    'toi que proclament les prophètes,\n'
    'toi dont témoignent les martyrs ;\n'
    'c\'est toi que par le monde entier\n'
    'l\'Église annonce et reconnaît.\n'
    '\n'
    'Dieu, nous t\'adorons :\n'
    'Père infiniment saint,\n'
    'Fils éternel et bien-aimé,\n'
    'Esprit de puissance et de paix.\n'
    '\n'
    'Christ, le Fils du Dieu vivant,\n'
    'le Seigneur de la gloire,\n'
    'tu n\'as pas craint de prendre chair\n'
    'dans le corps d\'une vierge\n'
    'pour libérer l\'humanité captive.\n'
    '\n'
    'Par ta victoire sur la mort,\n'
    'tu as ouvert à tout croyant\n'
    'les portes du Royaume ;\n'
    'tu règnes à la droite du Père ;\n'
    'tu viendras pour le jugement.\n'
    '\n'
    'Montre-toi le défenseur et l\'ami\n'
    'des hommes sauvés par ton sang :\n'
    'prends-les avec tous les saints\n'
    'dans ta joie et dans ta lumière.';

const Hymns notrePere = Hymns(
  title: 'Notre Père',
  content: 'Notre Père, qui es aux cieux,\n'
      'que ton nom soit sanctifié,\n'
      'que ton règne vienne,\n'
      'que ta volonté soit faite sur la terre\n'
      '> comme au ciel.\n'
      '\n'
      'Donne-nous aujourd\'hui\n'
      '> notre pain de ce jour.\n'
      'Pardonne-nous nos offenses,\n'
      'comme nous pardonnons aussi\n'
      '> à ceux qui nous ont offensés.\n'
      'Et ne nous laisse pas entrer en tentation\n'
      'mais délivre-nous du Mal.\n'
      'Amen.',
);
