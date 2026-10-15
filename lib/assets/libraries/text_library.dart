import 'dart:developer';

import '../../tools/data_loader.dart';

/// Texts referenced by code (psalms, hymns, prefaces...): one YAML file per
/// code under [folder], read with [parse].
///
/// Each text is loaded once and shared, the load in progress included. The
/// cache is content-addressed by code — not by which DataLoader instance
/// fetched it, since a fresh loader is created per call in some consumers
/// (e.g. Flutter) despite always resolving the same underlying asset source.
/// A code that gives no text is kept as such only with [keepMisses], so that
/// it isn't reloaded on every lookup; otherwise the next lookup retries.
class TextLibrary<T extends Object> {
  final String folder;
  final T? Function(String content) parse;
  final bool keepMisses;
  final Map<String, Future<T?>> _cache = {};

  TextLibrary(this.folder, this.parse, {this.keepMisses = false});

  /// The text of [code], or null if its file is missing or invalid (logged).
  Future<T?> get(String code, DataLoader dataLoader) {
    return _cache[code] ??= () async {
      T? text;
      try {
        final content = await dataLoader.loadYaml('$folder/$code.yaml');
        if (content.isEmpty) {
          log('No file for $folder/$code', name: 'TextLibrary', level: 900);
        } else {
          text = parse(content);
        }
      } catch (e) {
        log('Cannot read $folder/$code',
            name: 'TextLibrary', level: 1000, error: e);
      }
      if (text == null && !keepMisses) _cache.remove(code);
      return text;
    }();
  }
}
