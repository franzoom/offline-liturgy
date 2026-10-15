/// Classes for deeply nested structured liturgical office data
library;

import '../tools/data_loader.dart';
import '../tools/bible_text_provider.dart' show BibleTextProvider;
import '../assets/libraries/french_liturgy_labels.dart';
import 'calendar_class.dart' show LocationOrigin;
import '../calendar_management/common_calendar_definitions.dart'
    show liturgicalYearOf;
import 'psalms_class.dart';
import 'hymns_class.dart';

/// Invitatory with antiphon and psalms
class Invitatory {
  final List<String>? antiphon;
  final List<String>? psalms;
  List<Psalm>? psalmsData;
  List<List<String>?>? psalmsSvgData;

  Invitatory({this.antiphon, this.psalms, this.psalmsData, this.psalmsSvgData});

  factory Invitatory.fromJson(Map<String, dynamic> json) {
    return Invitatory(
      antiphon: _asAntiphon(json['antiphon']),
      psalms: asYamlList(json['psalms'])?.map((e) => e.toString()).toList(),
    );
  }
}

/// Parses evangelicAntiphon from YAML data.
/// Returns a `Map<String, List<String>>` with keys: "antiphon", "A", "B", "C".
/// Values are always lists for uniform downstream handling.
/// Input can be a String, a `List<String>`, or a Map with common/yearA/yearB/yearC keys.
Map<String, List<String>>? parseEvangelicAntiphon(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    return {
      'antiphon': [value]
    };
  }
  if (value is List) {
    final list = value.whereType<String>().toList();
    return list.isNotEmpty ? {'antiphon': list} : null;
  }
  if (value is Map) {
    final map = <String, List<String>>{};
    final common = value['common'];
    if (common is List) {
      final list = common.whereType<String>().toList();
      if (list.isNotEmpty) map['antiphon'] = list;
    } else if (common != null) {
      map['antiphon'] = [common.toString()];
    }
    if (value['yearA'] != null) map['A'] = [value['yearA'].toString()];
    if (value['yearB'] != null) map['B'] = [value['yearB'].toString()];
    if (value['yearC'] != null) map['C'] = [value['yearC'].toString()];
    return map.isNotEmpty ? map : null;
  }
  return null;
}

/// Merges evangelic antiphon maps: [overlay]'s keys win, [base]'s others
/// are kept.
Map<String, List<String>>? mergeEvangelicAntiphons(
        Map<String, List<String>>? base, Map<String, List<String>>? overlay) =>
    overlay == null ? base : {...?base, ...overlay};

/// Reads an antiphon field: a single text or a list of texts.
List<String>? _asAntiphon(dynamic value) => switch (value) {
      List list => list.map((e) => e.toString()).toList(),
      String s => [s],
      _ => null,
    };

/// Defensively coerces a YAML value into a list, wrapping a lone scalar into
/// a single-element list so a malformed field (e.g. `commons: martyrs`
/// instead of `commons: [martyrs]`) degrades gracefully instead of throwing.
List<dynamic>? asYamlList(dynamic value) => switch (value) {
      null => null,
      List list => list,
      _ => [value],
    };

/// Coerces a YAML value into a list of texts, dropping empty items (e.g. a
/// bare `- ` placeholder left in a file). Returns null when no text is left,
/// so the field counts as absent and a lower layer (Common, ferial) applies.
List<String>? asTextList(dynamic value) {
  final texts = asYamlList(value)
      ?.where((e) => e != null && e.toString().trim().isNotEmpty)
      .map((e) => e.toString())
      .toList();
  return (texts == null || texts.isEmpty) ? null : texts;
}

/// Intercessions / Preces
class Intercession {
  final String? description;
  final String? content;

  const Intercession({this.description, this.content});

  factory Intercession.fromJson(Map<String, dynamic> json) {
    return Intercession(
      description: json['description']?.toString(),
      content: json['content']?.toString(),
    );
  }
}

/// Psalm with its antiphons
class PsalmEntry {
  final String? psalm;
  final List<String>? antiphon;
  Psalm? psalmData;
  List<String>? svgData;

  PsalmEntry({this.psalm, this.antiphon, this.psalmData, this.svgData});

  factory PsalmEntry.fromJson(Map<String, dynamic> json) {
    return PsalmEntry(
      psalm: json['psalm']?.toString(),
      antiphon: _asAntiphon(json['antiphon']),
    );
  }
}

/// Merges [overlay] onto [base], entry by entry: an overlay entry with its
/// own `psalm` replaces the base entry outright; one without (antiphon-only)
/// keeps the base's psalm and takes the overlay's antiphon if present, else
/// the base's. Falls back to whichever side is non-empty when the other
/// is null/empty.
List<PsalmEntry>? mergePsalmody(
    List<PsalmEntry>? base, List<PsalmEntry>? overlay) {
  if (overlay == null || overlay.isEmpty) return base;
  if (base == null || base.isEmpty) return overlay;
  final merged = <PsalmEntry>[];
  for (int i = 0; i < overlay.length; i++) {
    final entry = overlay[i];
    if (entry.psalm != null) {
      merged.add(entry);
    } else if (i < base.length) {
      merged.add(PsalmEntry(
        psalm: base[i].psalm,
        antiphon: entry.antiphon ?? base[i].antiphon,
      ));
    } else {
      merged.add(entry);
    }
  }
  return merged;
}

/// Merges hymn lists: [overlay]'s hymns first (the first one stays the
/// default), then [base]'s not already listed, so that the earlier layers'
/// hymns (e.g. the liturgical season's) remain selectable.
List<HymnEntry>? mergeHymns(List<HymnEntry>? base, List<HymnEntry>? overlay) {
  if (overlay == null || overlay.isEmpty) return base;
  if (base == null || base.isEmpty) return overlay;
  final codes = overlay.map((h) => h.code).toSet();
  return [...overlay, ...base.where((h) => codes.add(h.code))];
}

/// Hymn entry with code and resolved data
class HymnEntry {
  final String code;
  Hymns? hymnData;

  HymnEntry({required this.code, this.hymnData});

  /// Returns null for a null/empty YAML entry instead of a bogus "null" code.
  static HymnEntry? fromJson(dynamic json) =>
      json == null ? null : HymnEntry(code: json.toString());

  /// Create Hymn Entry list from a list of codes, skipping null entries.
  static List<HymnEntry> fromCodes(List<dynamic>? codes) {
    if (codes == null) return [];
    return codes.map(HymnEntry.fromJson).whereType<HymnEntry>().toList();
  }
}

/// Biblical short reading (Lauds / Vespers)
class Reading {
  final String? biblicalReference;
  final String? content;

  const Reading({this.biblicalReference, this.content});

  factory Reading.fromJson(Map<String, dynamic> json) {
    return Reading(
      biblicalReference: json['biblicalReference']?.toString(),
      content: json['content']?.toString(),
    );
  }
}

/// Long Biblical reading (Office of Readings)
class BiblicalReading {
  final String? title;
  final String? subtitle;
  final String? ref;
  final String? content;
  final String? responsory;

  const BiblicalReading(
      {this.title, this.subtitle, this.ref, this.content, this.responsory});

  factory BiblicalReading.fromJson(Map<String, dynamic> json) {
    return BiblicalReading(
      title: json['title']?.toString(),
      subtitle: json['subtitle']?.toString(),
      ref: json['ref']?.toString(),
      content: json['content']?.toString(),
      responsory: json['responsory']?.toString(),
    );
  }

  BiblicalReading copyWith({
    String? title,
    String? subtitle,
    String? ref,
    String? content,
    String? responsory,
  }) {
    return BiblicalReading(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      ref: ref ?? this.ref,
      content: content ?? this.content,
      responsory: responsory ?? this.responsory,
    );
  }
}

/// Patristic reading (Office of Readings)
class PatristicReading {
  final String? title;
  final String? subtitle;
  final String? content;
  final String? responsory;

  const PatristicReading(
      {this.title, this.subtitle, this.content, this.responsory});

  factory PatristicReading.fromJson(Map<String, dynamic> json) {
    return PatristicReading(
      title: json['title']?.toString(),
      subtitle: json['subtitle']?.toString(),
      content: json['content']?.toString(),
      responsory: json['responsory']?.toString(),
    );
  }
}

/// Midday office structure (Tierce, Sexte, None)
class HourOffice {
  String? antiphon;
  // This hour's own psalmody, as written in the data; when present it wins
  // over the shared/gradual/Sunday psalmody (see middleOfDayExport).
  List<PsalmEntry>? psalmody;
  Reading? reading;
  String? responsory;
  String? oration;

  HourOffice({
    this.antiphon,
    this.psalmody,
    this.reading,
    this.responsory,
    this.oration,
  });

  factory HourOffice.fromJson(Map<String, dynamic> json) {
    return HourOffice(
      antiphon: json['antiphon']?.toString(),
      psalmody: asYamlList(json['psalmody'])
          ?.whereType<Map<String, dynamic>>()
          .map((e) => PsalmEntry.fromJson(e))
          .toList(),
      reading: json['reading'] is Map<String, dynamic>
          ? Reading.fromJson(json['reading'] as Map<String, dynamic>)
          : null,
      responsory: json['responsory']?.toString(),
      oration: json['oration']?.toString(),
    );
  }

  /// Overlays this HourOffice with data from another instance, field by
  /// field — a more specific level (e.g. deeper in a common hierarchy) must
  /// only fill in what it defines, not wipe out fields inherited from a
  /// more general level.
  void overlayWith(HourOffice overlay) {
    if (overlay.antiphon != null) antiphon = overlay.antiphon;
    if (overlay.psalmody != null) psalmody = overlay.psalmody;
    if (overlay.reading != null) reading = overlay.reading;
    if (overlay.responsory != null) responsory = overlay.responsory;
    if (overlay.oration != null) oration = overlay.oration;
  }
}

/// Context class containing all parameters needed for office resolution.
/// This class consolidates MorningDefinition, VespersDefinition, and ReadingsDefinition.
class CelebrationContext {
  final String?
      celebrationType; // e.g. morning, vespers1, vespers2, readings, mass...
  final String celebrationCode; // given by the liturgical calendar
  final String?
      celebrationTitle; // display title (from YAML title or ferial name)
  final String? celebrationGlobalName; // full name with subtitle
  final String? ferialCode; // the day's ferial root; null if not ferial
  final List<String>? commonList; // list of commons for the celebration
  final DateTime date;
  final String? liturgicalTime; // given by the calendar root of the date
  final int? breviaryWeek; // given by the calendar root of the date
  final int? precedence; // given by the calendar for the celebration
  final bool isCelebrable; // to be determined later
  final DataLoader dataLoader; // to load required data
  final String? officeDescription; // description of the office
  final String? liturgicalColor; // liturgical color of the celebration
  final String?
      celebrationDescription; // description of the celebration from YAML
  final Map<String, String> commonTitles; // code -> display title for commons
  final String?
      massName; // massType identifying which Mass of the day this is (e.g. "vigil", "day"), mass only
  final bool
      showImprecatoryVerses; // whether to render imprecatory psalm verses (bracketed sections in YAML)
  // Location that added this feast; null = Roman calendar
  final LocationOrigin? celebrationOrigin;
  final String? svgSource; // URL or path to the SVG psalm score source
  // Reference year for the Sunday (A/B/C) and weekday (I/II) lectionary
  // cycles, from DayContent.liturgicalYear — already accounts for the
  // Advent shift (e.g. Advent 2026 carries liturgicalYear 2027).
  final int? liturgicalYear;
  // Whether "the feast's own readings" (as opposed to the day's) would
  // have anything to offer for this celebration — proper if it declares
  // readingParts, or the selected Common otherwise (a Common can supply
  // readingParts too, inherited from a more general level of its
  // hierarchy) — mass only, set by massDetection. A memorial always uses
  // the day's readings by default (see useProperReadingsForMemorial); this
  // tells the UI whether offering the feast's readings as an alternative
  // is even possible.
  final bool hasFeastReadingParts;
  // Mass only. When this celebration is a memorial/commemoration
  // (precedence > 5) and hasFeastReadingParts is true, selects the feast's
  // own readingParts (proper, gap-filled from the Common) instead of the
  // day's — see massExport. Has no effect for a Feast/Solemnity
  // (precedence <= 5), which always use their own proper readingParts
  // regardless of this flag.
  final bool useProperReadingsForMemorial;
  // Office of Readings only. When true, the biblical reading follows the
  // two-year cycle (biblicalReadingEven / biblicalReadingOdd in the YAML,
  // chosen by the parity of liturgicalYear); otherwise the annual cycle.
  final bool twoYearReadingCycle;
  // Source of the Bible text for readings stored by reference only (no
  // `content` in the YAML). Injected by the consumer, like dataLoader;
  // without it those readings keep a null content.
  final BibleTextProvider? bibleTextProvider;

  const CelebrationContext({
    this.celebrationType,
    required this.celebrationCode,
    this.celebrationTitle,
    this.celebrationGlobalName,
    this.ferialCode,
    this.commonList,
    required this.date,
    this.liturgicalTime,
    this.breviaryWeek,
    this.precedence,
    this.isCelebrable = false,
    required this.dataLoader,
    this.officeDescription,
    this.liturgicalColor,
    this.celebrationDescription,
    this.commonTitles = const {},
    this.massName,
    this.showImprecatoryVerses = false,
    this.celebrationOrigin,
    this.svgSource,
    this.liturgicalYear,
    this.hasFeastReadingParts = false,
    this.useProperReadingsForMemorial = false,
    this.twoYearReadingCycle = false,
    this.bibleTextProvider,
  });

  /// Returns the first common from commonList.
  /// Returns null if no common is available.
  String? get selectedCommon => commonList?.firstOrNull;

  /// Whether the office is built on the day's ferial texts.
  bool get hasFerialBase => ferialCode?.isNotEmpty ?? false;

  /// Whether the celebration has its own file over the ferial day.
  bool get hasProper => celebrationCode != ferialCode;

  /// Whether a common is selected for the celebration.
  bool get hasSelectedCommon => selectedCommon?.trim().isNotEmpty ?? false;

  /// Memorials (precedence > 9) only take some parts of their common.
  bool get isMemorial => (precedence ?? 13) > 9;

  /// Memorials and feasts (precedence > 4) keep the season's hymns
  /// selectable after their own; solemnities replace them.
  bool get keepsSeasonHymns => (precedence ?? 13) > 4;

  /// [liturgicalYear], or the liturgical year of [date] (Advent shift
  /// included) for a context built without one.
  int get effectiveLiturgicalYear => liturgicalYear ?? liturgicalYearOf(date);

  /// Returns true if this is first vespers (vespers1)
  bool get isFirstVespers => celebrationType == 'vespers1';

  /// Returns true if this is second vespers (vespers2)
  bool get isSecondVespers => celebrationType == 'vespers2';

  /// YAML section holding this Vespers office: 'firstVespers' or 'vespers'.
  String get vespersSection => isFirstVespers ? 'firstVespers' : 'vespers';

  /// Returns the formatted celebration type label, including the geographic
  /// origin when the feast comes from a location-specific calendar.
  /// e.g. "(Europe : solennité)" or "(Solennité)" or "".
  String get celebrationDisplayLabel {
    if (celebrationCode == 'roman/commemoration_of_all_the_faithful_departed') {
      return '';
    }
    final baseLabel = getCelebrationTypeLabel(precedence ?? 13);
    final origin = celebrationOrigin;
    if (baseLabel.isEmpty || origin == null) return baseLabel;
    final inner =
        baseLabel.replaceAll('(', '').replaceAll(')', '').trim().toLowerCase();
    return '(${origin.name} : $inner)';
  }

  /// Creates a copy of this context with the given fields replaced
  CelebrationContext copyWith({
    String? celebrationType,
    String? celebrationCode,
    String? celebrationTitle,
    String? celebrationGlobalName,
    String? ferialCode,
    List<String>? commonList,
    DateTime? date,
    String? liturgicalTime,
    int? breviaryWeek,
    int? precedence,
    bool? isCelebrable,
    DataLoader? dataLoader,
    String? officeDescription,
    String? liturgicalColor,
    String? celebrationDescription,
    Map<String, String>? commonTitles,
    String? massName,
    bool? showImprecatoryVerses,
    LocationOrigin? celebrationOrigin,
    String? svgSource,
    int? liturgicalYear,
    bool? hasFeastReadingParts,
    bool? useProperReadingsForMemorial,
    bool? twoYearReadingCycle,
    BibleTextProvider? bibleTextProvider,
  }) {
    return CelebrationContext(
      celebrationType: celebrationType ?? this.celebrationType,
      celebrationCode: celebrationCode ?? this.celebrationCode,
      celebrationTitle: celebrationTitle ?? this.celebrationTitle,
      celebrationGlobalName:
          celebrationGlobalName ?? this.celebrationGlobalName,
      ferialCode: ferialCode ?? this.ferialCode,
      commonList: commonList ?? this.commonList,
      date: date ?? this.date,
      liturgicalTime: liturgicalTime ?? this.liturgicalTime,
      breviaryWeek: breviaryWeek ?? this.breviaryWeek,
      precedence: precedence ?? this.precedence,
      isCelebrable: isCelebrable ?? this.isCelebrable,
      dataLoader: dataLoader ?? this.dataLoader,
      officeDescription: officeDescription ?? this.officeDescription,
      liturgicalColor: liturgicalColor ?? this.liturgicalColor,
      celebrationDescription:
          celebrationDescription ?? this.celebrationDescription,
      commonTitles: commonTitles ?? this.commonTitles,
      massName: massName ?? this.massName,
      showImprecatoryVerses:
          showImprecatoryVerses ?? this.showImprecatoryVerses,
      celebrationOrigin: celebrationOrigin ?? this.celebrationOrigin,
      svgSource: svgSource ?? this.svgSource,
      liturgicalYear: liturgicalYear ?? this.liturgicalYear,
      hasFeastReadingParts: hasFeastReadingParts ?? this.hasFeastReadingParts,
      useProperReadingsForMemorial:
          useProperReadingsForMemorial ?? this.useProperReadingsForMemorial,
      twoYearReadingCycle: twoYearReadingCycle ?? this.twoYearReadingCycle,
      bibleTextProvider: bibleTextProvider ?? this.bibleTextProvider,
    );
  }
}
