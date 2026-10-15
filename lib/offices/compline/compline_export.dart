import '../../classes/compline_class.dart';
import '../../tools/data_loader.dart';
import '../../tools/resolve_office_content.dart';
import '../../tools/paschal_antiphon.dart';
import '../../assets/usual_texts.dart';
import 'compline_extract.dart';

/// Hydrates a SINGLE chosen ComplineDefinition into a full Compline object with text.
/// This is called AFTER the user has picked a specific Compline option.
Future<Compline> complineExport(ComplineDefinition choice) async {
  final dataLoader = choice.dataLoader;

  // 1. Get the text structure from YAML files
  final compline = await _complineText(choice, dataLoader);

  // 2. Hydrate dynamic content (psalms, hymns, Marian hymns)
  await resolveOfficeContent(
    psalmody: compline.psalmody,
    hymns: [...?compline.hymns, ...?compline.marialHymnRef],
    dataLoader: dataLoader,
    showImprecatoryVerses: choice.showImprecatoryVerses,
  );

  // 3. Assign the evangelic canticle (Nunc Dimittis)
  compline.evangelicCanticle = nuncDimittis;

  // 4. Apply paschal alléluia to psalm antiphons and evangelic antiphon
  applyPaschalToPsalmody(compline.psalmody, choice.liturgicalTime);
  compline.evangelicAntiphon = applyPaschalToAntiphonMap(
      compline.evangelicAntiphon, choice.liturgicalTime);

  return compline;
}

// --- TEXT RESOLUTION LOGIC ---

const String _base = 'calendar_data/complines';

/// Loads and merges the correct YAML files for the given ComplineDefinition.
Future<Compline> _complineText(
    ComplineDefinition def, DataLoader dataLoader) async {
  final String day = def.dayOfCompline;
  final String time = def.liturgicalTime.toLowerCase();
  final String ct = def.celebrationType.toLowerCase();

  // Layer 3: solemnity/time override
  final (String? overridePath, String overrideDay) = switch (ct) {
    'holy_thursday' || 'holy_friday' || 'holy_saturday' => ('$_base/lent.yaml', ct),
    'solemnity' || 'solemnityeve' => switch (time) {
        'paschaloctave' || 'paschaltime' => ('$_base/solemnity_paschal.yaml', day),
        'lent' => ('$_base/solemnity_lent.yaml', day),
        'advent' ||
        'christmas' ||
        'christmasoctave' =>
          ('$_base/solemnity_advent_christmas.yaml', day),
        _ => ('$_base/solemnity_ot.yaml', day),
      },
    _ => switch (time) {
        'paschaloctave' || 'paschaltime' => ('$_base/paschal.yaml', day),
        'holyweek' || 'lent' => ('$_base/lent.yaml', day),
        'advent' => ('$_base/advent.yaml', day),
        'christmas' || 'christmasoctave' => ('$_base/christmas.yaml', day),
        _ => (null, day),
      },
  };

  // Layer 2: for advent/christmas solemnities, the time-specific file comes
  // first so its antiphons and psalms serve as the intermediate base
  final String? intermediatePath = (ct == 'solemnity' || ct == 'solemnityeve')
      ? switch (time) {
          'advent' => '$_base/advent.yaml',
          'christmas' || 'christmasoctave' => '$_base/christmas.yaml',
          _ => null,
        }
      : null;

  // Layers over the default base, each one's fields winning over the
  // previous ones. The Nativity's own Complines — the eve (Dec 24 evening)
  // as well as the day — already belong to Christmas Time: christmas.yaml
  // alone applies, with no solemnity layer on top
  // (solemnity_advent_christmas.yaml would replace its antiphons). The eve
  // can't rely on liturgicalTime, which is still today's 'advent'; the
  // day's own value is 'nativity'.
  final layers = def.celebrationCode == 'roman/nativity'
      ? [('$_base/christmas.yaml', day)]
      : [
          if (intermediatePath != null) (intermediatePath, day),
          if (overridePath != null) (overridePath, overrideDay),
        ];

  final complines = await Future.wait([
    complineExtract('$_base/default.yaml', day, dataLoader),
    for (final (path, dayKey) in layers)
      complineExtract(path, dayKey, dataLoader),
  ]);
  return complines
      .reduce((base, layer) => base.mergeWith(layer))
      .copyWith(celebrationType: def.celebrationType);
}
