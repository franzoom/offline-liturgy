// Compare le calendrier produit par le programme, pour le lieu "france",
// à un référentiel de dates connues (solennités, fêtes du Seigneur et de la
// Vierge, fêtes de saints de précédence < 8, mercredi des Cendres) couvrant
// 2011-2025. Ce référentiel a été établi indépendamment du code du package
// (algorithme de Pâques de Meeus/Jones/Butcher + règles officielles de
// report du Missel pour les dates mobiles ; les fêtes de saints sont à date
// fixe, reprises de assets/calendar_data/common_feasts.yaml), puis vérifié
// par sondage sur des cas limites via l'API AELF (calendrier liturgique
// officiel francophone) :
//   - reports de l'Immaculée Conception (2013, 2019, 2024 : 8 déc = dimanche)
//   - reports de l'Annonciation (2013, 2016, 2018, 2024 : semaine sainte)
//   - report de Saint Joseph (2017, 2023 : 19 mars = dimanche)
//
// Cas connu non couvert par ce test : en 2022, le Sacré-Cœur et la Nativité
// de saint Jean-Baptiste tombent le même jour (24 juin, seule occurrence
// 2011-2025). Le programme reporte Jean-Baptiste au 25 juin (règle du
// Missel en cas de collision de même rang) ; le calendrier AELF réellement
// publié cette année-là n'affiche que la mémoire du Cœur immaculé de Marie,
// sans report. Le référentiel suit la règle du Missel (donc ce test valide
// le comportement du programme sur ce point, pas la pratique AELF réelle).
//
// Voir test/fixtures/reference_solemnities_feasts_france.csv pour les
// données, et CLAUDE.md pour le système de precedence (1-3 solennités,
// 4-5 fêtes).

import 'dart:io';
import 'package:test/test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';

const String _location = 'france';
const String _fixturePath =
    'test/fixtures/reference_solemnities_feasts_france.csv';

const String _green = '\x1B[32m';
const String _red = '\x1B[31m';
const String _reset = '\x1B[0m';

/// Fragment de nom attendu dans le titre gagnant du jour, par nom français
/// de référentiel. "Pâques" et "Mercredi des Cendres" sont traités à part :
/// ils n'ont pas de clé "roman/xxx" propre dans le code.
const Map<String, String> _expectedSlug = {
  'Marie Mère de Dieu': 'mary_mother_of_god',
  'Épiphanie': 'epiphany',
  'Saint Joseph': 'saint_joseph',
  'Annonciation': 'annunciation',
  'Ascension': 'ascension',
  'Pentecôte': 'pentecost',
  'Sainte Trinité': 'holy_trinity',
  'Saint-Sacrement (Fête-Dieu)': 'corpus_domini',
  'Sacré-Cœur': 'sacred_heart',
  'Saint Jean-Baptiste': 'saint_john_the_baptist',
  'Saints Pierre et Paul': 'saint_pieter_and_saint_paul',
  'Assomption': 'assumption',
  'Toussaint': 'all_saints',
  'Immaculée Conception': 'immaculate_conception',
  'Noël': 'nativity',
  'Christ Roi': 'christ_king',
  'Baptême du Seigneur': 'baptism',
  'Présentation du Seigneur': 'presentation_of_the_lord',
  'Sainte Famille': 'holy_family',
  'Transfiguration': 'transfiguration',
  'Exaltation de la Sainte Croix': 'exaltation_of_the_holy_cross',
  // Fêtes de saints (et assimilés) de précédence < 8 dans le calendrier
  // universel — cf. assets/calendar_data/common_feasts.yaml.
  'Conversion de saint Paul': 'conversion_of_saint_paul',
  'Chaire de saint Pierre': 'chair_of_saint_peter',
  'Saint Marc, évangéliste': 'mark_evangelist',
  'Saints Philippe et Jacques, apôtres': 'philip_and_james',
  'Saint Matthias, apôtre': 'matthias',
  'Visitation de la Vierge Marie': 'visitation_of_mary',
  'Saint Thomas, apôtre': 'thomas_apostle',
  'Sainte Marie-Madeleine': 'mary_magdalene',
  'Saint Jacques, apôtre': 'james_apostle',
  'Saint Laurent, diacre': 'lawrence_of_rome',
  'Saint Barthélemy, apôtre': 'bartholomew',
  'Nativité de la Vierge Marie': 'nativity_of_the_blessed_virgin_mary',
  'Saint Matthieu, apôtre': 'matthew_apostle',
  'Saints Michel, Gabriel et Raphaël, archanges': 'archangels',
  'Saint Luc, évangéliste': 'luke_evangelist',
  'Saints Simon et Jude, apôtres': 'simon_and_jude',
  'Saint André, apôtre': 'andrew_apostle',
  // Pas un saint, mais même précédence (7) et même mécanisme de résolution :
  // ajoutée avec le lot pour ne pas laisser de trou dans le référentiel.
  'Dédicace de la basilique du Latran': 'lateran_basilica',
};

class _ReferenceRow {
  final int year;
  final DateTime date;
  final String category; // Solennite | Fete | Autre
  final String name;
  _ReferenceRow(this.year, this.date, this.category, this.name);
}

/// Découpe une ligne CSV en respectant les champs entre guillemets (un nom
/// de fête peut contenir une virgule, ex. "Saint Marc, évangéliste").
List<String> _splitCsvLine(String line) {
  final fields = <String>[];
  final current = StringBuffer();
  bool inQuotes = false;
  for (int i = 0; i < line.length; i++) {
    final char = line[i];
    if (char == '"') {
      inQuotes = !inQuotes;
    } else if (char == ',' && !inQuotes) {
      fields.add(current.toString());
      current.clear();
    } else {
      current.write(char);
    }
  }
  fields.add(current.toString());
  return fields;
}

List<_ReferenceRow> _loadFixture() {
  final lines = File(_fixturePath).readAsLinesSync();
  return lines.skip(1).where((l) => l.trim().isNotEmpty).map((line) {
    final fields = _splitCsvLine(line);
    final dateParts = fields[1].split('-').map(int.parse).toList();
    return _ReferenceRow(
      int.parse(fields[0]),
      DateTime(dateParts[0], dateParts[1], dateParts[2]),
      fields[3],
      fields[4],
    );
  }).toList();
}

/// La cellule gagnante du jour : la plus haute autorité entre le contenu
/// par défaut du jour et tout ce qui a été surajouté dans feastList
/// (précédence numérique la plus basse = rang le plus élevé).
class _Winner {
  final int precedence;
  final String title;
  final String liturgicalTime;
  _Winner(this.precedence, this.title, this.liturgicalTime);
}

_Winner _resolveWinner(DayContent content) {
  int bestPrecedence = content.precedence;
  String bestTitle = content.defaultCelebrationTitle;
  for (final entry in content.feastList.entries) {
    if (entry.key < bestPrecedence) {
      bestPrecedence = entry.key;
      bestTitle = entry.value.join(', ');
    } else if (entry.key == bestPrecedence) {
      bestTitle = '$bestTitle + ${entry.value.join(', ')}';
    }
  }
  return _Winner(bestPrecedence, bestTitle, content.liturgicalTime);
}

/// Vrai si [slug] apparaît dans le titre par défaut du jour ou dans
/// n'importe quelle entrée de feastList, à n'importe quelle précédence.
bool _isPresentAnywhere(DayContent content, String slug) {
  if (content.defaultCelebrationTitle.toLowerCase().contains(slug)) {
    return true;
  }
  for (final list in content.feastList.values) {
    if (list.any((v) => v.toLowerCase().contains(slug))) return true;
  }
  return false;
}

bool _matches(_ReferenceRow row, DayContent content) {
  if (row.name == 'Pâques') {
    final winner = _resolveWinner(content);
    return winner.liturgicalTime == 'paschaloctave' && winner.precedence == 1;
  }
  if (row.name == 'Mercredi des Cendres') {
    return content.defaultCelebrationTitle == 'lent_0_3';
  }

  final slug = _expectedSlug[row.name];
  if (slug == null) return false;

  if (row.category == 'Solennite') {
    // Une solennité doit toujours gagner le jour (aucune règle de report
    // dans ce référentiel ne laisse une solennité perdre face à autre
    // chose, sauf le cas Pâques déjà traité à part).
    return _resolveWinner(content).title.toLowerCase().contains(slug);
  }

  // Fêtes du Seigneur/de la Vierge/de saints : un dimanche ou une
  // solennité de rang supérieur peut légitimement l'emporter le jour où
  // ils coïncident (ex. Sainte Marie-Madeleine un dimanche de temps
  // ordinaire). On vérifie alors que la fête est bien présente dans
  // feastList, pas qu'elle gagne — sa disparition complète, elle,
  // révélerait un vrai trou de calendrier.
  return _isPresentAnywhere(content, slug);
}

void main() {
  late Calendar calendar;

  setUpAll(() async {
    final data = await LiturgyData.load();
    calendar = Calendar();
    // Un ancrage au 1er juillet de chaque année couvre janvier à décembre
    // de cette même année civile (cf. getCalendar : deux années liturgiques
    // consécutives sont fusionnées dans le même Calendar).
    for (int year = 2010; year <= 2026; year++) {
      getCalendar(calendar, DateTime(year, 7, 1), _location, data);
    }
  });

  test('Solennités, fêtes et mercredi des Cendres — $_location 2011-2025', () {
    final rows = _loadFixture();
    final mismatches = <String>[];

    for (final row in rows) {
      final content = calendar.getDayContent(row.date);
      final dateStr = '${row.date.year}-'
          '${row.date.month.toString().padLeft(2, '0')}-'
          '${row.date.day.toString().padLeft(2, '0')}';

      if (content == null) {
        mismatches.add('[ABSENT] $dateStr — attendu "${row.name}"');
        print('$_red[ABSENT] $dateStr — ${row.name}$_reset');
        continue;
      }

      if (_matches(row, content)) {
        print('$_green[OK] $dateStr — ${row.name}$_reset');
      } else {
        final winner = _resolveWinner(content);
        final detail = '[DIFF] $dateStr — attendu "${row.name}" '
            '(${row.category}) — programme: precedence=${winner.precedence} '
            'title="${winner.title}" (liturgicalTime=${winner.liturgicalTime})';
        mismatches.add(detail);
        print('$_red$detail$_reset');
      }
    }

    print('\n===================== RÉSUMÉ =====================');
    print('${rows.length} ligne(s) comparée(s) pour $_location.');
    if (mismatches.isEmpty) {
      print('${_green}Aucune divergence détectée.$_reset');
    } else {
      print('$_red${mismatches.length} divergence(s) :$_reset');
      for (final m in mismatches) {
        print('  $m');
      }
    }

    expect(mismatches, isEmpty,
        reason:
            '${mismatches.length} divergence(s) — voir le résumé ci-dessus');
  });
}
