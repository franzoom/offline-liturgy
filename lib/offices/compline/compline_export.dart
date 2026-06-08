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
  if (dataLoader == null) {
    throw Exception("ComplineDefinition is missing a DataLoader");
  }

  // 1. Get the text structure from YAML files
  final compline = await getComplineText(choice, dataLoader);

  if (compline == null) {
    throw Exception("Could not resolve text for the chosen Compline");
  }

  // 2. Hydrate dynamic content (psalms, hymns, Marian hymns) in parallel
  await Future.wait([
    resolveOfficeContent(
      psalmody: compline.psalmody,
      hymns: compline.hymns,
      dataLoader: dataLoader,
      showImprecatoryVerses: choice.showImprecatoryVerses,
    ),
    if (compline.marialHymnRef != null)
      resolveOfficeContent(
        hymns: compline.marialHymnRef,
        dataLoader: dataLoader,
        showImprecatoryVerses: choice.showImprecatoryVerses,
      ),
  ]);

  // 3. Assign the evangelic canticle (Nunc Dimittis)
  compline.evangelicCanticle = nuncDimittis;

  // 4. Apply paschal alléluia to evangelic antiphon
  compline.evangelicAntiphon = applyPaschalToAntiphonMap(
      compline.evangelicAntiphon, choice.liturgicalTime);

  return compline;
}

// --- TEXT RESOLUTION LOGIC ---

const String _base = 'calendar_data/complines';

/// Loads and merges the correct YAML files for the given ComplineDefinition.
Future<Compline?> getComplineText(
    ComplineDefinition def, DataLoader dataLoader) async {
  final String day = def.dayOfCompline;
  final String time = def.liturgicalTime.toLowerCase();
  final String ct = def.celebrationType.toLowerCase();

  // Layer 1: default base
  Compline base =
      await complineExtract('$_base/default.yaml', day, dataLoader);

  // Layer 2: for advent/christmas solemnities, merge the time-specific file
  // first so its antiphons and psalms serve as the intermediate base
  if (ct == 'solemnity' || ct == 'solemnityeve') {
    final String? intermediatePath = switch (time) {
      'advent' => '$_base/advent.yaml',
      'christmas' || 'christmasoctave' => '$_base/christmas.yaml',
      _ => null,
    };
    if (intermediatePath != null) {
      final Compline intermediate =
          await complineExtract(intermediatePath, day, dataLoader);
      if (!intermediate.isEmpty) base = base.mergeWith(intermediate);
    }
  }

  // Layer 3: solemnity/time override
  final (String? path, String overrideDay) = switch (ct) {
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

  if (path == null) {
    return base.copyWith(celebrationType: def.celebrationType);
  }

  final Compline correction =
      await complineExtract(path, overrideDay, dataLoader);

  final result = correction.isEmpty ? base : base.mergeWith(correction);
  return result.copyWith(celebrationType: def.celebrationType);
}
