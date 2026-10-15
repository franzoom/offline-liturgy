import 'dart:math' show min;
import '../classes/calendar_class.dart';
import '../classes/office_elements_class.dart';
import '../tools/data_loader.dart';
import '../tools/date_tools.dart';
import '../tools/constants.dart';
import '../tools/celebration_index.dart';
import 'ferial_layers.dart';
import '../tools/yaml_map_loader.dart';

/// function returning the possible offices for a given day

/// Data extracted from a celebration YAML file
class CelebrationYamlData {
  final String? title;
  final String? subtitle;
  final String? description;
  final String? color;
  final List<String> commons;

  const CelebrationYamlData({
    this.title,
    this.subtitle,
    this.description,
    this.color,
    this.commons = const [],
  });
}

/// Reads the `celebration:` header of a parsed celebration file, or null
/// when the file has none.
CelebrationYamlData? _celebrationHeader(Map<String, dynamic>? data) {
  final celebrationData = data?['celebration'];
  if (celebrationData is! Map<String, dynamic>) return null;

  final commons = celebrationData['commons'];
  return CelebrationYamlData(
    title: celebrationData['title']?.toString(),
    subtitle: celebrationData['subtitle']?.toString(),
    description: celebrationData['description']?.toString(),
    color: celebrationData['color']?.toString(),
    commons: commons is List ? commons.whereType<String>().toList() : const [],
  );
}

/// Returns the effective sort precedence for a celebration.
/// Ferial days at precedence 13 rank before optional memorials (12).
double effectivePrecedence(int precedence, String code) {
  if (precedence == 13 && ferialDayCheck(code)) return 11.5;
  return precedence.toDouble();
}

/// Per-calendar memo of [detectCelebrations], keyed by date. An [Expando]
/// holds its values weakly with respect to the calendar: once a calendar is
/// no longer used (the app rebuilds one on each region change, or for the
/// calendar view of another year), its entries are released with it,
/// instead of being kept alive forever by a global map.
final Expando<Map<DateTime, Future<List<CelebrationContext>>>>
    _detectCelebrationsCache = Expando('detectCelebrationsCache');

/// Detects all possible celebrations for a given date
/// Returns a list of CelebrationContext sorted by precedence (lowest first)
///
/// This is the common function used by all office detection wrappers
/// (morning, readings, vespers, etc.) — several of which call it for the
/// same (calendar, date) within a single day's rendering (e.g. Vespers and
/// Compline each call it twice, for today and tomorrow), so the result is
/// memoized per (calendar, date). Not keyed by dataLoader: some consumers
/// (e.g. Flutter) construct a fresh loader per call despite it always
/// resolving the same underlying asset source, so including it in the key
/// would defeat the cache; calendar already changes when the data source
/// does (e.g. switching location rebuilds it).
///
/// An empty or failed result is not kept: the next call must be able to
/// retry instead of showing an empty day for as long as the calendar lives.
Future<List<CelebrationContext>> detectCelebrations(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
) {
  final perDate = _detectCelebrationsCache[calendar] ??= {};
  final cached = perDate[date];
  if (cached != null) return cached;

  final future = _detectCelebrationsImpl(calendar, date, dataLoader);
  perDate[date] = future;
  void forget() {
    if (identical(perDate[date], future)) perDate.remove(date);
  }

  // The caller gets the error itself; this listener only drops the entry
  future.then((result) {
    if (result.isEmpty) forget();
  }, onError: (Object _) {
    forget();
  });
  return future;
}

Future<List<CelebrationContext>> _detectCelebrationsImpl(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
) async {
  // Get day content directly from calendar
  final dayContent = calendar.getDayContent(date);
  if (dayContent == null) {
    return [];
  }

  // Extract root data
  final String rootColor = dayContent.liturgicalColor;
  final int? breviaryWeek = dayContent.breviaryWeek;
  final String liturgicalTime = dayContent.liturgicalTime;
  final String defaultCelebrationTitle = dayContent.defaultCelebrationTitle;
  final int defaultPrecedence = dayContent.precedence;

  // Determine ferialCode: root code if it's a ferial day
  final String? ferialCode =
      ferialDayCheck(defaultCelebrationTitle) ? defaultCelebrationTitle : null;

  // Build list of all celebrations with source tracking
  final List<({int precedence, String code, bool isFromRoot})> allCelebrations =
      [];

  // Add celebrations from feastList
  for (final entry in dayContent.feastList.entries) {
    final precedence = entry.key;
    for (final code in entry.value) {
      allCelebrations.add((
        precedence: precedence,
        code: code,
        isFromRoot: false,
      ));
    }
  }

  // Add default celebration from root
  allCelebrations.add((
    precedence: defaultPrecedence,
    code: defaultCelebrationTitle,
    isFromRoot: true,
  ));

  // On Ordinary Time Saturdays, add the Marian memory when no obligatory
  // celebration is already present: no solemnity or feast (≤ 9), and no
  // obligatory memorial either (10: General Calendar, 11: proper calendars).
  // Optional memorials (12) don't exclude it — the reader then chooses.
  if (date.weekday == DateTime.saturday &&
      liturgicalTime == 'ot' &&
      allCelebrations.every((c) => c.precedence > 11)) {
    allCelebrations.add((
      precedence: 12,
      code: 'roman/virgin_mary_memory',
      isFromRoot: false,
    ));
  }

  // Check if there's a high priority celebration (feast or above: precedence <= 8)
  final bool hasHighPriority =
      allCelebrations.any((c) => c.precedence >= 1 && c.precedence <= 8);
  final int bestPrecedence =
      allCelebrations.map((c) => c.precedence).reduce(min);

  // Sort: by precedence ascending, with special rule for ferial days (precedence 13)
  // Ferial days at precedence 13 should come before optional memorials (precedence 12)
  allCelebrations.sort((a, b) {
    final aEff = effectivePrecedence(a.precedence, a.code);
    final bEff = effectivePrecedence(b.precedence, b.code);
    if (aEff != bEff) return aEff.compareTo(bEff);
    if (a.isFromRoot != b.isFromRoot) return a.isFromRoot ? -1 : 1;
    return 0;
  });

  // Read the header of every celebration file in one parallel pass.
  // Compound codes (advent-N_W_D and christmas-N_W_D) have no single YAML
  // file: their header is the dated day's own file, and the week's day file
  // (their first ferial layer) gives the weekday title prefix.
  bool isCompound(String code) =>
      code.startsWith('advent-') || code.startsWith('christmas-');
  Future<String> celebrationPath(String code) async {
    if (!isCompound(code)) return celebrationFilePath(code, dataLoader);
    final layers = ferialLayers(code, date);
    final specialDay = layers.adventSpecialDay;
    return specialDay != null
        ? FerialLayers.adventSpecialPath(specialDay)
        : layers.paths.last;
  }

  final headerList = await Future.wait(allCelebrations.map((c) async =>
      _celebrationHeader(
          await loadYamlMap(await celebrationPath(c.code), dataLoader))));
  final Map<String, CelebrationYamlData> headers = {
    for (int i = 0; i < allCelebrations.length; i++)
      if (headerList[i] != null) allCelebrations[i].code: headerList[i]!,
  };

  // For compound codes (advent-N_W_D and christmas-N_W_D), read the ferial
  // week file to get the weekday title prefix, then compose with the
  // day-specific title:
  // "Lundi de la première semaine de la férie de Noël — 2 janvier".
  final compoundCodes =
      allCelebrations.map((c) => c.code).where(isCompound).toList();
  final weekTitles = await Future.wait(compoundCodes.map((code) async =>
      _celebrationHeader(await loadYamlMap(
              ferialLayers(code, date).paths.first, dataLoader))
          ?.title));
  final Map<String, String> specialFerialTitles = {
    for (int i = 0; i < compoundCodes.length; i++)
      if (weekTitles[i]?.isNotEmpty ?? false) compoundCodes[i]: weekTitles[i]!,
  };

  // Load common titles in parallel for all unique common codes
  final commonCodes = {
    for (final header in headers.values) ...header.commons,
  }.toList();
  final commonFiles = await Future.wait(commonCodes
      .map((code) => loadYamlMap('$commonsFilePath/$code.yaml', dataLoader)));
  final Map<String, String> commonTitlesMap = {
    for (int i = 0; i < commonCodes.length; i++)
      commonCodes[i]:
          commonFiles[i]?['commonTitle']?.toString() ?? commonCodes[i],
  };

  // Build the list of detected celebrations
  final List<CelebrationContext> detectedCelebrations = [];

  for (final celebration in allCelebrations) {
    final String celebrationCode = celebration.code;
    final int precedence = celebration.precedence;

    // A celebration genuinely outranked by the Triduum, a Solemnity, or a
    // privileged Sunday of Advent/Lent/Easter (bestPrecedence <= 3) isn't
    // merely uncelebrated — per the Table of Liturgical Days it is
    // suppressed for the year entirely, so it's dropped here rather than
    // surfacing as a browsable "not celebrated" option (e.g. an optional
    // memorial that lands on Ascension or Holy Saturday). Ties
    // (precedence == bestPrecedence) are unaffected. Below that threshold
    // (an ordinary Feast, Sunday, or weekday outranking a memorial) the
    // usual isCelebrable: false path still applies.
    //
    // Exception: the day's own Sunday root is never dropped this way, even
    // when outranked (e.g. the Commemoration of All Souls, itself item 3,
    // landing on an Ordinary Time Sunday). It stays available for
    // detectOfficeCelebrations below to hand back to the Divine Office,
    // which — unlike Mass — defers to the Sunday in that specific case.
    final bool isSundayRoot =
        celebration.isFromRoot && date.weekday == DateTime.sunday;
    if (bestPrecedence <= 3 && precedence > bestPrecedence && !isSundayRoot) {
      continue;
    }

    // Determine isCelebrable based on precedence rules
    final bool isSundayFerial = date.weekday == DateTime.sunday &&
        ferialDayCheck(celebrationCode) &&
        !(liturgicalTime == 'ot' && bestPrecedence <= 3);
    final bool isCelebrable = hasHighPriority
        ? (precedence <= bestPrecedence || isSundayFerial)
        : true;

    // Initialize with default values
    String celebrationLiturgicalColor = rootColor;
    String celebrationGlobalName = celebrationCode;
    String celebrationTitle = celebrationCode;
    String? celebrationDescription;
    List<String> commonList = [];

    // Check YAML data (pre-loaded for non-ferial, may also exist for ferial)
    final yamlData = headers[celebrationCode];

    if (yamlData != null) {
      celebrationLiturgicalColor = yamlData.color ?? celebrationLiturgicalColor;
      celebrationDescription = yamlData.description;
      commonList = yamlData.commons;

      // Use title as celebrationTitle, build full name with subtitle.
      // For special Advent days (Dec 17-24), prepend the weekday ferial title:
      // "Vendredi de la troisième semaine de l'Avent — 17 décembre".
      if (yamlData.title != null && yamlData.title!.isNotEmpty) {
        final ferialPrefix = specialFerialTitles[celebrationCode];
        if (ferialPrefix != null) {
          celebrationTitle = '$ferialPrefix — ${yamlData.title!}';
          celebrationGlobalName = celebrationTitle;
        } else {
          celebrationTitle = yamlData.title!;
          celebrationGlobalName = yamlData.title!;
          if (yamlData.subtitle != null && yamlData.subtitle!.isNotEmpty) {
            final sub = yamlData.subtitle!;
            celebrationGlobalName +=
                ', ${sub[0].toLowerCase()}${sub.substring(1)}';
          }
        }
      }
    }

    // Filter commonTitles for this celebration's commons
    final Map<String, String> celebrationCommonTitles = {
      for (final code in commonList)
        if (commonTitlesMap.containsKey(code)) code: commonTitlesMap[code]!,
    };

    detectedCelebrations.add(CelebrationContext(
      celebrationTitle: celebrationTitle,
      celebrationGlobalName: celebrationGlobalName,
      celebrationCode: celebrationCode,
      ferialCode: ferialCode,
      commonList: commonList,
      date: date,
      liturgicalTime: liturgicalTime,
      breviaryWeek: breviaryWeek,
      precedence: precedence,
      liturgicalColor: celebrationLiturgicalColor,
      isCelebrable: isCelebrable,
      dataLoader: dataLoader,
      celebrationDescription: celebrationDescription,
      commonTitles: celebrationCommonTitles,
      celebrationOrigin: dayContent.feastOrigins[celebrationCode],
      liturgicalYear: dayContent.liturgicalYear,
    ));
  }

  return detectedCelebrations;
}

// Celebrations whose Divine Office (unlike Mass) defers to a coinciding
// Ordinary Time Sunday. Currently just the Commemoration of All the
// Faithful Departed (Nov 2): at Mass it wins outright — its own rank
// (item 3) already outranks an ordinary Sunday (item 6), no override
// needed — but the Office of the Dead used that day has no place when it
// falls on the Lord's Day; the Sunday's own Office is prayed instead.
const _officeDefersToSundayCodes = {
  'roman/commemoration_of_all_the_faithful_departed',
};

/// Wraps [detectCelebrations] for the non-Mass offices only. On an Ordinary
/// Time Sunday that coincides with one of [_officeDefersToSundayCodes],
/// demotes that celebration's effective precedence below the Sunday's and
/// swaps isCelebrable, so every consumer that branches on either field
/// (isCelebrable-based selection, or a raw precedence threshold like
/// Compline's and Middle of Day's) picks the Sunday. massDetection calls
/// [detectCelebrations] directly and is unaffected — Mass needs no swap.
Future<List<CelebrationContext>> detectOfficeCelebrations(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
) async {
  final celebrations = await detectCelebrations(calendar, date, dataLoader);
  if (date.weekday != DateTime.sunday) return celebrations;

  final deferIndex = celebrations.indexWhere(
      (c) => _officeDefersToSundayCodes.contains(c.celebrationCode));
  final sundayIndex =
      celebrations.indexWhere((c) => c.celebrationCode == c.ferialCode);
  if (deferIndex == -1 || sundayIndex == -1) return celebrations;

  final adjusted = [
    for (int i = 0; i < celebrations.length; i++)
      if (i == deferIndex)
        celebrations[i].copyWith(precedence: 12, isCelebrable: false)
      else if (i == sundayIndex)
        celebrations[i].copyWith(isCelebrable: true)
      else
        celebrations[i],
  ];
  adjusted.sort((a, b) => effectivePrecedence(
          a.precedence ?? 13, a.celebrationCode)
      .compareTo(effectivePrecedence(b.precedence ?? 13, b.celebrationCode)));
  return adjusted;
}

/// Today's and tomorrow's office celebrations, detected in parallel — for
/// the evening offices (Vespers, Compline), which may anticipate tomorrow.
Future<({List<CelebrationContext> today, List<CelebrationContext> tomorrow})>
    detectTodayAndTomorrow(
        Calendar calendar, DateTime date, DataLoader dataLoader) async {
  final [today, tomorrow] = await Future.wait([
    detectOfficeCelebrations(calendar, date, dataLoader),
    detectOfficeCelebrations(calendar, date.shift(1), dataLoader),
  ]);
  return (today: today, tomorrow: tomorrow);
}

/// The Triduum day among [celebrations] (it has its own evening offices,
/// with no other option), or null.
CelebrationContext? triduumCelebration(List<CelebrationContext> celebrations) =>
    celebrations
        .where((c) => triduumCodes.containsKey(c.celebrationCode))
        .firstOrNull;

/// Generic helper for office detection wrappers (morning, readings, etc.).
/// Converts detected celebrations into a keyed map with the given [celebrationType].
Future<Map<String, CelebrationContext>> buildDetectionMap(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
  String celebrationType,
) async {
  final celebrations =
      await detectOfficeCelebrations(calendar, date, dataLoader);
  // Celebrations are sorted by ascending precedence (best first).
  // putIfAbsent keeps the first (highest-priority) entry when two celebrations
  // share the same title (e.g. france_pothinus_... vs lyon_pothinus_...).
  final map = <String, CelebrationContext>{};
  for (final c in celebrations) {
    final key = c.celebrationTitle ?? c.celebrationCode;
    map.putIfAbsent(
        key,
        () => c.copyWith(
              celebrationType: celebrationType,
              officeDescription: c.celebrationGlobalName,
            ));
  }
  return map;
}
