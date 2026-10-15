import '../../classes/morning_class.dart';
import '../../classes/office_elements_class.dart';
import './ferial_morning_resolution.dart';
import './morning_extract.dart';
import '../../tools/hierarchical_common_loader.dart';
import '../compose_office.dart';
import '../../assets/usual_texts.dart';

/// Resolves the Morning Prayer (Lauds).
/// Priority logic: Proper > Common > Ferial base.
Future<Morning> morningExport(CelebrationContext celebrationContext) async {
  // 1-4. Ferial base, Common and proper layers
  final morningOffice = await composeHourPrayer<Morning>(
    celebrationContext,
    empty: Morning.new,
    ferial: () => ferialMorningResolution(celebrationContext),
    proper: (path) => morningExtract(path, celebrationContext.dataLoader),
    common: () => loadMorningHierarchicalCommon(celebrationContext),
  );

  // 5. Invitatory: exclude psalms already used in the final, merged Lauds
  // psalmody (must run after merging — a Memorial's invitatory may come from
  // the Common while the day keeps the ferial psalmody, or vice versa).
  final invitatoryPsalms = morningOffice.invitatory?.psalms;
  if (invitatoryPsalms != null) {
    final usedPsalms = morningOffice.psalmody
            ?.where((entry) => entry.psalm != null)
            .map((entry) => entry.psalm!)
            .toSet() ??
        {};
    morningOffice.invitatory = Invitatory(
      antiphon: morningOffice.invitatory!.antiphon,
      psalms: invitatoryPsalms
          .where((psalm) => !usedPsalms.contains(psalm))
          .toList(),
    );
  }

  // 6. Texts, evangelic antiphons of the year, paschal alléluia, Benedictus
  await completeHourPrayer(morningOffice, celebrationContext,
      canticle: benedictus,
      canticleSvgCode: 'NT_2',
      invitatory: morningOffice.invitatory);

  return morningOffice;
}
