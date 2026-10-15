import '../../classes/vespers_class.dart';
import '../../classes/office_elements_class.dart';
import './ferial_vespers_resolution.dart';
import './vespers_extract.dart';
import '../../tools/hierarchical_common_loader.dart';
import '../compose_office.dart';
import '../../assets/usual_texts.dart';

/// Resolves the Vespers (Evening Prayer) by orchestrating different sources:
/// 1. Ferial base
/// 2. Common (if applicable)
/// 3. Proper (Sanctoral or Special)
Future<Vespers> vespersExport(CelebrationContext celebrationContext) async {
  // STEPS 1-4: Ferial base, Common and proper layers
  final vespersOffice = await composeHourPrayer<Vespers>(
    celebrationContext,
    empty: Vespers.new,
    ferial: () => ferialVespersResolution(celebrationContext),
    proper: (path) => vespersExtract(path, celebrationContext.dataLoader,
        section: celebrationContext.vespersSection),
    common: () => loadVespersHierarchicalCommon(celebrationContext),
  );

  // Append Lucernaire hymn, except during Lent and Holy Week, unless a layer
  // (e.g. the ferial day) already lists it
  final lt = celebrationContext.liturgicalTime ?? '';
  final bool hasLucernaire =
      vespersOffice.hymn?.any((h) => h.code == 'joie-et-lumiere') ?? false;
  if (lt != 'lent' && lt != 'holyweek' && !hasLucernaire) {
    vespersOffice.hymn = [
      ...?vespersOffice.hymn,
      HymnEntry(code: 'joie-et-lumiere'),
    ];
  }

  // Texts, evangelic antiphons of the year, paschal alléluia, Magnificat.
  // For First Vespers the context is tomorrow's, so the eve of the 1st
  // Sunday of Advent already takes the new liturgical year.
  await completeHourPrayer(vespersOffice, celebrationContext,
      canticle: magnificat, canticleSvgCode: 'NT_1');

  return vespersOffice;
}
