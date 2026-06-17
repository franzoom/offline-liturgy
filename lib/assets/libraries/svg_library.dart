import 'dart:developer';

import '../../classes/psalms_class.dart';
import '../../tools/data_loader.dart';

/// SVG music sheet library — loads psalm score files as raw SVG strings.
///
/// Psalm SVG filenames are resolved in two ways:
/// 1. Explicit: the psalm YAML declares `psalmSVG` (string or list of names).
/// 2. Default: derive from the psalm code by stripping the trailing part suffix
///    when more than one underscore is present.
///    Examples: PSALM_117_4 → PSALM_117, OT_4 → OT_4, PSALM_23 → PSALM_23.
///
/// Files are loaded from `svg/{source}/{name}.svg` via the DataLoader.
/// Missing files are silently skipped.
class SvgLibrary {
  static String _svgBaseName(String psalmCode) {
    final parts = psalmCode.split('_');
    if (parts.length > 2 && int.tryParse(parts.last) != null) {
      return parts.sublist(0, parts.length - 1).join('_');
    }
    return psalmCode;
  }

  /// Returns the list of raw SVG strings for [psalmCode].
  ///
  /// Uses [psalmData.psalmSVG] when available; otherwise falls back to the
  /// name derived from [psalmCode]. Empty files are excluded from the result.
  static Future<List<String>> getSvgForPsalm(
    String psalmCode,
    Psalm? psalmData,
    String svgSource,
    DataLoader dataLoader,
  ) async {
    final List<String> names =
        psalmData?.psalmSVG ?? [_svgBaseName(psalmCode)];

    final results = await Future.wait(
      names.map((name) async {
        try {
          return await dataLoader.load('svg/$svgSource/$name.svg');
        } catch (e) {
          log('SVG not found: svg/$svgSource/$name.svg ($e)',
              name: 'SvgLibrary');
          return '';
        }
      }),
    );

    return results.where((s) => s.isNotEmpty).toList();
  }
}
