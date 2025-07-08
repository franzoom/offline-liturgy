import '../classes/feasts.dart';
//fêtes du calendrier général

Map<String, FeastDates> generateFeastList() {
  Map<String, FeastDates> feastList = {
    'mary_mother_of_god': FeastDates(month: 1, day: 1, priority: 3),
    'basil_the_great_and_gregory_nazianzen_bishops':
        FeastDates(month: 1, day: 2, priority: 10),
    'most_holy_name_of_jesus': FeastDates(month: 1, day: 3, priority: 12),
    'raymond_of_penyafort_priest': FeastDates(month: 1, day: 7, priority: 12),
    'hilary_of_poitiers_bishop': FeastDates(month: 1, day: 13, priority: 12),
    'anthony_of_egypt_abbot': FeastDates(month: 1, day: 17, priority: 10),
    'fabian_i_pope': FeastDates(month: 1, day: 20, priority: 12),
    'sebastian_of_milan_martyr': FeastDates(month: 1, day: 20, priority: 12),
    'agnes_of_rome_virgin': FeastDates(month: 1, day: 21, priority: 10),
    'vincent_of_saragossa_deacon': FeastDates(month: 1, day: 22, priority: 12),
    'francis_de_sales_bishop': FeastDates(month: 1, day: 24, priority: 10),
    'conversion_of_saint_paul_the_apostle':
        FeastDates(month: 1, day: 25, priority: 7),
    'timothy_of_ephesus_and_titus_of_crete_bishops':
        FeastDates(month: 1, day: 26, priority: 10),
    'angela_merici_virgin': FeastDates(month: 1, day: 27, priority: 12),
    'thomas_aquinas_priest': FeastDates(month: 1, day: 28, priority: 10),
    'john_bosco_priest': FeastDates(month: 1, day: 31, priority: 10),
    'presentation_of_the_lord': FeastDates(month: 2, day: 2, priority: 5),
    'blaise_of_sebaste_bishop': FeastDates(month: 2, day: 3, priority: 12),
    'ansgar_of_hamburg_bishop': FeastDates(month: 2, day: 3, priority: 12),
    'agatha_of_sicily_virgin': FeastDates(month: 2, day: 5, priority: 10),
    'paul_miki_and_companions_martyrs':
        FeastDates(month: 2, day: 6, priority: 10),
    'jerome_emiliani': FeastDates(month: 2, day: 8, priority: 12),
    'josephine_bakhita_virgin': FeastDates(month: 2, day: 8, priority: 12),
    'scholastica_of_nursia_virgin': FeastDates(month: 2, day: 10, priority: 10),
    'our_lady_of_lourdes': FeastDates(month: 2, day: 11, priority: 12),
    'cyril_constantine_the_philosopher_monk_and_methodius_michael_of_thessaloniki_bishop':
        FeastDates(month: 2, day: 14, priority: 10),
    'seven_holy_founders_of_the_servite_order':
        FeastDates(month: 2, day: 17, priority: 12),
    'peter_damian_bishop': FeastDates(month: 2, day: 21, priority: 12),
    'chair_of_saint_peter_the_apostle':
        FeastDates(month: 2, day: 22, priority: 7),
    'polycarp_of_smyrna_bishop': FeastDates(month: 2, day: 23, priority: 10),
    'gregory_of_narek_abbot': FeastDates(month: 2, day: 27, priority: 12),
    'casimir_of_poland': FeastDates(month: 3, day: 4, priority: 12),
    'perpetua_of_carthage_and_felicity_of_carthage_martyrs':
        FeastDates(month: 3, day: 7, priority: 10),
    'john_of_god_duarte_cidade_religious':
        FeastDates(month: 3, day: 8, priority: 12),
    'frances_of_rome_religious': FeastDates(month: 3, day: 9, priority: 12),
    'patrick_of_ireland_bishop': FeastDates(month: 3, day: 17, priority: 12),
    'cyril_of_jerusalem_bishop': FeastDates(month: 3, day: 18, priority: 12),
    'turibius_of_mogrovejo_bishop': FeastDates(month: 3, day: 23, priority: 12),
    'francis_of_paola_hermit': FeastDates(month: 4, day: 2, priority: 12),
    'isidore_of_seville_bishop': FeastDates(month: 4, day: 4, priority: 12),
    'vincent_ferrer_priest': FeastDates(month: 4, day: 5, priority: 12),
    'john_baptist_de_la_salle_priest':
        FeastDates(month: 4, day: 7, priority: 10),
    'stanislaus_of_szczepanow_bishop':
        FeastDates(month: 4, day: 11, priority: 10),
    'martin_i_pope': FeastDates(month: 4, day: 13, priority: 12),
    'anselm_of_canterbury_bishop': FeastDates(month: 4, day: 21, priority: 12),
    'george_of_lydda_martyr': FeastDates(month: 4, day: 23, priority: 12),
    'adalbert_of_prague_bishop': FeastDates(month: 4, day: 23, priority: 12),
    'fidelis_of_sigmaringen_priest':
        FeastDates(month: 4, day: 24, priority: 12),
    'mark_evangelist': FeastDates(month: 4, day: 25, priority: 7),
    'peter_chanel_priest': FeastDates(month: 4, day: 28, priority: 12),
    'louis_grignion_de_montfort_priest':
        FeastDates(month: 4, day: 28, priority: 12),
    'catherine_of_siena_virgin': FeastDates(month: 4, day: 29, priority: 10),
    'pius_v_pope': FeastDates(month: 4, day: 30, priority: 12),
    'joseph_the_worker': FeastDates(month: 5, day: 1, priority: 12),
    'athanasius_of_alexandria_bishop':
        FeastDates(month: 5, day: 2, priority: 10),
    'philip_and_james_apostles': FeastDates(month: 5, day: 3, priority: 7),
    'john_of_avila_priest': FeastDates(month: 5, day: 10, priority: 12),
    'nereus_of_terracina_and_achilleus_of_terracina_martyrs':
        FeastDates(month: 5, day: 12, priority: 12),
    'pancras_of_rome_martyr': FeastDates(month: 5, day: 12, priority: 12),
    'our_lady_of_fatima': FeastDates(month: 5, day: 13, priority: 12),
    'matthias_apostle': FeastDates(month: 5, day: 14, priority: 7),
    'john_i_pope': FeastDates(month: 5, day: 18, priority: 12),
    'bernardine_of_siena_priest': FeastDates(month: 5, day: 20, priority: 12),
    'christopher_magallanes_priest_and_companions_martyrs':
        FeastDates(month: 5, day: 21, priority: 12),
    'rita_of_cascia_religious': FeastDates(month: 5, day: 22, priority: 12),
    'bede_the_venerable_priest': FeastDates(month: 5, day: 25, priority: 12),
    'gregory_vii_pope': FeastDates(month: 5, day: 25, priority: 12),
    'mary_magdalene_de_pazzi_virgin':
        FeastDates(month: 5, day: 25, priority: 12),
    'philip_neri_priest': FeastDates(month: 5, day: 26, priority: 10),
    'augustine_of_canterbury_bishop':
        FeastDates(month: 5, day: 27, priority: 12),
    'paul_vi_pope': FeastDates(month: 5, day: 29, priority: 12),
    'visitation_of_mary': FeastDates(month: 5, day: 31, priority: 7),
    'justin_martyr': FeastDates(month: 6, day: 1, priority: 10),
    'marcellinus_of_rome_and_peter_the_exorcist_martyrs':
        FeastDates(month: 6, day: 2, priority: 12),
    'charles_lwanga_and_companions_martyrs':
        FeastDates(month: 6, day: 3, priority: 10),
    'boniface_of_mainz_bishop': FeastDates(month: 6, day: 5, priority: 10),
    'norbert_of_xanten_bishop': FeastDates(month: 6, day: 6, priority: 12),
    'ephrem_the_syrian_deacon': FeastDates(month: 6, day: 9, priority: 12),
    'barnabas_apostle': FeastDates(month: 6, day: 11, priority: 10),
    'anthony_of_padua_priest': FeastDates(month: 6, day: 13, priority: 10),
    'romuald_of_ravenna_abbot': FeastDates(month: 6, day: 19, priority: 12),
    'aloysius_gonzaga_religious': FeastDates(month: 6, day: 21, priority: 10),
    'paulinus_of_nola_bishop': FeastDates(month: 6, day: 22, priority: 12),
    'john_fisher_bishop_and_thomas_more_martyrs':
        FeastDates(month: 6, day: 22, priority: 12),
    'cyril_of_alexandria_bishop': FeastDates(month: 6, day: 27, priority: 12),
    'irenaeus_of_lyon_bishop': FeastDates(month: 6, day: 28, priority: 10),
    'first_martyrs_of_the_holy_roman_church':
        FeastDates(month: 6, day: 30, priority: 12),
    'thomas_apostle': FeastDates(month: 7, day: 3, priority: 7),
    'elizabeth_of_portugal': FeastDates(month: 7, day: 4, priority: 12),
    'anthony_zaccaria_priest': FeastDates(month: 7, day: 5, priority: 12),
    'maria_goretti_virgin': FeastDates(month: 7, day: 6, priority: 12),
    'augustine_zhao_rong_priest_and_companions_martyrs':
        FeastDates(month: 7, day: 9, priority: 12),
    'benedict_of_nursia_abbot': FeastDates(month: 7, day: 11, priority: 10),
    'henry_ii_emperor': FeastDates(month: 7, day: 13, priority: 12),
    'camillus_de_lellis_priest': FeastDates(month: 7, day: 14, priority: 12),
    'bonaventure_of_bagnoregio_bishop':
        FeastDates(month: 7, day: 15, priority: 10),
    'our_lady_of_mount_carmel': FeastDates(month: 7, day: 16, priority: 12),
    'apollinaris_of_ravenna_bishop':
        FeastDates(month: 7, day: 20, priority: 12),
    'lawrence_of_brindisi_priest': FeastDates(month: 7, day: 21, priority: 12),
    'mary_magdalene': FeastDates(month: 7, day: 22, priority: 7),
    'bridget_of_sweden_religious': FeastDates(month: 7, day: 23, priority: 12),
    'sharbel_makhluf_priest': FeastDates(month: 7, day: 24, priority: 12),
    'james_apostle': FeastDates(month: 7, day: 25, priority: 7),
    'joachim_and_anne_parents_of_mary':
        FeastDates(month: 7, day: 26, priority: 10),
    'martha_of_bethany_mary_of_bethany_and_lazarus_of_bethany':
        FeastDates(month: 7, day: 29, priority: 10),
    'peter_chrysologus_bishop': FeastDates(month: 7, day: 30, priority: 12),
    'ignatius_of_loyola_priest': FeastDates(month: 7, day: 31, priority: 10),
    'alphonsus_mary_liguori_bishop': FeastDates(month: 8, day: 1, priority: 10),
    'eusebius_of_vercelli_bishop': FeastDates(month: 8, day: 2, priority: 12),
    'peter_julian_eymard_priest': FeastDates(month: 8, day: 2, priority: 12),
    'john_mary_vianney_priest': FeastDates(month: 8, day: 4, priority: 10),
    'dedication_of_the_basilica_of_saint_mary_major':
        FeastDates(month: 8, day: 5, priority: 12),
    'sixtus_ii_pope_and_companions_martyrs':
        FeastDates(month: 8, day: 7, priority: 12),
    'cajetan_of_thiene_priest': FeastDates(month: 8, day: 7, priority: 12),
    'dominic_de_guzman_priest': FeastDates(month: 8, day: 8, priority: 10),
    'teresa_benedicta_of_the_cross_stein_virgin':
        FeastDates(month: 8, day: 9, priority: 12),
    'lawrence_of_rome_deacon': FeastDates(month: 8, day: 10, priority: 7),
    'clare_of_assisi_virgin': FeastDates(month: 8, day: 11, priority: 10),
    'jane_frances_de_chantal_religious':
        FeastDates(month: 8, day: 12, priority: 12),
    'pontian_i_pope_and_hippolytus_of_rome_priest':
        FeastDates(month: 8, day: 13, priority: 12),
    'maximilian_mary_raymund_kolbe_priest':
        FeastDates(month: 8, day: 14, priority: 10),
    'stephen_i_of_hungary': FeastDates(month: 8, day: 16, priority: 12),
    'john_eudes_priest': FeastDates(month: 8, day: 19, priority: 12),
    'bernard_of_clairvaux_abbot': FeastDates(month: 8, day: 20, priority: 10),
    'pius_x_pope': FeastDates(month: 8, day: 21, priority: 10),
    'queenship_of_the_blessed_virgin_mary':
        FeastDates(month: 8, day: 22, priority: 10),
    'rose_of_lima_virgin': FeastDates(month: 8, day: 23, priority: 12),
    'bartholomew_apostle': FeastDates(month: 8, day: 24, priority: 7),
    'louis_ix_of_france': FeastDates(month: 8, day: 25, priority: 12),
    'joseph_of_calasanz_priest': FeastDates(month: 8, day: 25, priority: 12),
    'monica_of_hippo': FeastDates(month: 8, day: 27, priority: 10),
    'augustine_of_hippo_bishop': FeastDates(month: 8, day: 28, priority: 10),
    'passion_of_saint_john_the_baptist':
        FeastDates(month: 8, day: 29, priority: 10),
    'gregory_i_the_great_pope': FeastDates(month: 9, day: 3, priority: 10),
    'nativity_of_the_blessed_virgin_mary':
        FeastDates(month: 9, day: 8, priority: 7),
    'peter_claver_priest': FeastDates(month: 9, day: 9, priority: 12),
    'most_holy_name_of_mary': FeastDates(month: 9, day: 12, priority: 12),
    'john_chrysostom_bishop': FeastDates(month: 9, day: 13, priority: 10),
    'exaltation_of_the_holy_cross': FeastDates(month: 9, day: 14, priority: 5),
    'our_lady_of_sorrows': FeastDates(month: 9, day: 15, priority: 10),
    'cornelius_i_pope_and_cyprian_of_carthage_bishop_martyrs':
        FeastDates(month: 9, day: 16, priority: 10),
    'hildegard_of_bingen_abbess': FeastDates(month: 9, day: 17, priority: 12),
    'robert_bellarmine_bishop': FeastDates(month: 9, day: 17, priority: 12),
    'januarius_i_of_benevento_bishop':
        FeastDates(month: 9, day: 19, priority: 12),
    'andrew_kim_tae_gon_priest_paul_chong_ha_sang_and_companions_martyrs':
        FeastDates(month: 9, day: 20, priority: 10),
    'matthew_apostle': FeastDates(month: 9, day: 21, priority: 7),
    'pius_francesco_forgione_priest':
        FeastDates(month: 9, day: 23, priority: 10),
    'cosmas_of_cilicia_and_damian_of_cilicia_martyrs':
        FeastDates(month: 9, day: 26, priority: 12),
    'vincent_de_paul_priest': FeastDates(month: 9, day: 27, priority: 10),
    'wenceslaus_i_of_bohemia_martyr':
        FeastDates(month: 9, day: 28, priority: 12),
    'lawrence_ruiz_and_companions_martyrs':
        FeastDates(month: 9, day: 28, priority: 12),
    'michael_gabriel_and_raphael_archangels':
        FeastDates(month: 9, day: 29, priority: 7),
    'jerome_of_stridon_priest': FeastDates(month: 9, day: 30, priority: 10),
    'therese_of_the_child_jesus_and_the_holy_face_of_lisieux_virgin':
        FeastDates(month: 10, day: 1, priority: 10),
    'holy_guardian_angels': FeastDates(month: 10, day: 2, priority: 10),
    'francis_of_assisi': FeastDates(month: 10, day: 4, priority: 10),
    'faustina_kowalska_virgin': FeastDates(month: 10, day: 5, priority: 12),
    'bruno_of_cologne_priest': FeastDates(month: 10, day: 6, priority: 12),
    'our_lady_of_the_rosary': FeastDates(month: 10, day: 7, priority: 10),
    'denis_of_paris_bishop_and_companions_martyrs':
        FeastDates(month: 10, day: 9, priority: 12),
    'john_leonardi_priest': FeastDates(month: 10, day: 9, priority: 12),
    'john_xxiii_pope': FeastDates(month: 10, day: 11, priority: 12),
    'callistus_i_pope': FeastDates(month: 10, day: 14, priority: 12),
    'teresa_of_jesus_of_avila_virgin':
        FeastDates(month: 10, day: 15, priority: 10),
    'hedwig_of_silesia_religious': FeastDates(month: 10, day: 16, priority: 12),
    'margaret_mary_alacoque_virgin':
        FeastDates(month: 10, day: 16, priority: 12),
    'ignatius_of_antioch_bishop': FeastDates(month: 10, day: 17, priority: 10),
    'luke_evangelist': FeastDates(month: 10, day: 18, priority: 7),
    'john_de_brebeuf_isaac_jogues_priests_and_companions_martyrs':
        FeastDates(month: 10, day: 19, priority: 12),
    'paul_of_the_cross_priest': FeastDates(month: 10, day: 19, priority: 12),
    'john_paul_ii_pope': FeastDates(month: 10, day: 22, priority: 12),
    'john_of_capistrano_priest': FeastDates(month: 10, day: 23, priority: 12),
    'anthony_mary_claret_bishop': FeastDates(month: 10, day: 24, priority: 12),
    'simon_and_jude_apostles': FeastDates(month: 10, day: 28, priority: 7),
    'martin_de_porres_religious': FeastDates(month: 11, day: 3, priority: 12),
    'charles_borromeo_bishop': FeastDates(month: 11, day: 4, priority: 10),
    'dedication_of_the_lateran_basilica':
        FeastDates(month: 11, day: 9, priority: 7),
    'leo_i_the_great_pope': FeastDates(month: 11, day: 10, priority: 10),
    'martin_of_tours_bishop': FeastDates(month: 11, day: 11, priority: 10),
    'josaphat_kuntsevych_bishop': FeastDates(month: 11, day: 12, priority: 10),
    'albert_the_great_bishop': FeastDates(month: 11, day: 15, priority: 12),
    'margaret_of_scotland': FeastDates(month: 11, day: 16, priority: 12),
    'gertrude_the_great_virgin': FeastDates(month: 11, day: 16, priority: 12),
    'elizabeth_of_hungary_religious':
        FeastDates(month: 11, day: 17, priority: 10),
    'dedication_of_the_basilicas_of_saints_peter_and_paul_apostles':
        FeastDates(month: 11, day: 18, priority: 12),
    'presentation_of_the_blessed_virgin_mary':
        FeastDates(month: 11, day: 21, priority: 10),
    'cecilia_of_rome_virgin': FeastDates(month: 11, day: 22, priority: 10),
    'clement_i_pope': FeastDates(month: 11, day: 23, priority: 12),
    'columban_of_luxeuil_abbot': FeastDates(month: 11, day: 23, priority: 12),
    'andrew_dung_lac_priest_and_companions_martyrs':
        FeastDates(month: 11, day: 24, priority: 10),
    'catherine_of_alexandria_virgin':
        FeastDates(month: 11, day: 25, priority: 12),
    'andrew_apostle': FeastDates(month: 11, day: 30, priority: 7),
    'francis_xavier_priest': FeastDates(month: 12, day: 3, priority: 10),
    'john_damascene_priest': FeastDates(month: 12, day: 4, priority: 12),
    'nicholas_of_myra_bishop': FeastDates(month: 12, day: 6, priority: 12),
    'ambrose_of_milan_bishop': FeastDates(month: 12, day: 7, priority: 10),
    'juan_diego_cuauhtlatoatzin': FeastDates(month: 12, day: 9, priority: 12),
    'our_lady_of_loreto': FeastDates(month: 12, day: 10, priority: 12),
    'damasus_i_pope': FeastDates(month: 12, day: 11, priority: 12),
    'our_lady_of_guadalupe': FeastDates(month: 12, day: 12, priority: 12),
    'lucy_of_syracuse_virgin': FeastDates(month: 12, day: 13, priority: 10),
    'john_of_the_cross_priest': FeastDates(month: 12, day: 14, priority: 10),
    'peter_canisius_priest': FeastDates(month: 12, day: 21, priority: 12),
    'john_of_kanty_priest': FeastDates(month: 12, day: 23, priority: 12),
    'stephen_the_first_martyr': FeastDates(month: 12, day: 26, priority: 7),
    'john_apostle': FeastDates(month: 12, day: 27, priority: 7),
    'holy_innocents_martyrs': FeastDates(month: 12, day: 28, priority: 7),
    'thomas_becket_bishop': FeastDates(month: 12, day: 29, priority: 12),
    'sylvester_i_pope': FeastDates(month: 12, day: 31, priority: 12),
  };
  return feastList;
}
