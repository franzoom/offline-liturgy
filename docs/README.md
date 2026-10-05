# offline_liturgy

A Dart package that builds a universal Catholic liturgical calendar and resolves the full content of the Divine Office (Liturgy of the Hours) and the Mass for any given day and location.

---

## Overview

`offline_liturgy` operates in two stages:

1. **Calendar building** — computes a complete liturgical calendar for a given year and location, with all feasts, seasons, and priorities resolved.
2. **Office resolution** — for any day in that calendar, retrieves the full content of each liturgical hour (Morning Prayer / Lauds, Vespers, Office of Readings, Compline, Midday Prayer) and of the Mass.

All content (psalms, hymns, readings, antiphons) is stored locally as YAML files and loaded on demand. No network connection is required.

---

## Core Concepts

### Liturgical Calendar

The Catholic liturgical year is divided into seasons:

| Code | Season |
|---|---|
| `advent` | Advent |
| `nativity` | Christmas Day |
| `christmasoctave` | Octave of Christmas (Dec 26–31) |
| `christmas` | Christmas Time (Jan 1 → Baptism of the Lord) |
| `lent` | Lent |
| `holyweek` | Holy Week |
| `paschaloctave` | Octave of Easter |
| `paschaltime` | Easter Time (after the octave) |
| `ot` | Ordinary Time |

Each day has a **precedence level** (1–13) that determines which celebration takes priority when multiple feasts coincide:

| Level | Type |
|---|---|
| 1–4 | Triduum, major days, solemnities (general, then proper) |
| 5 | Feasts of the Lord |
| 6 | Sundays of Christmas Time and Ordinary Time |
| 7–8 | Feasts (general calendar, then proper) |
| 9 | Privileged ferials: Advent 17–24 Dec, Christmas octave days, Lent |
| 10–11 | Obligatory memorials (general, then proper) |
| 12 | Optional memorials |
| 13 | Ferial days (weekdays of a season) |

The full table is in `preseances.md`. Ferial days (13) are sorted before optional memorials (12) by `effectivePrecedence()`, so the ferial stays the default choice.

During privileged times (Advent from Dec 17, Lent, the Christmas and Easter octaves), obligatory memorials are automatically downgraded to optional (`downgradeMemorialsDuringPrivilegedTimes()`).

### Locations

The package supports a hierarchical geography of liturgical locations, each with its own proper feasts:

```
Continent → Country → Diocese → City → Church / Community
```

Each location can add feasts, override a parent's feast (same file name) or move one to another date. Locations are defined in YAML files under `assets/locations/` (see `location_geography.md`).

### Liturgical Years (A / B / C)

The three-year cycle (A, B, C) governs which patristic readings, evangelic antiphons and Sunday Mass readings are used on a given year; weekday Mass readings follow a two-year cycle (I / II).

---

## Getting Started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  offline_liturgy:
    path: ../offline-liturgy  # or published package reference
```

### 1. Load liturgical data

```dart
import 'package:offline_liturgy/offline_liturgy.dart';

final data = await LiturgyData.load(); // CLI / Dart standalone
// or, in Flutter:
// final data = await LiturgyData.loadFromDataLoader(myDataLoader);
```

`LiturgyData` loads all universal feasts and location definitions from the asset files.

### 2. Build the calendar

```dart
final calendar = getCalendar(
  Calendar(),
  DateTime(2026, 2, 18), // any date in the target liturgical year
  'lyon',                 // location ID (matches a file in assets/locations/)
  data,
);
```

This returns a `Calendar` covering **two full liturgical years** (year N and N+1) to handle boundary dates correctly. Optional named parameters `epiphanyOverride`, `ascensionOverride` and `corpusDominiOverride` take precedence over the location's own settings.

### 3. Inspect a day

```dart
final day = calendar.getDayContent(DateTime(2026, 3, 25));

print(day.liturgicalTime);          // e.g. 'lent'
print(day.liturgicalColor);         // e.g. 'violet'
print(day.precedence);              // e.g. 3
print(day.defaultCelebrationTitle); // e.g. 'lent_4_3' (the ferial code)
print(day.feastList);               // Map<int, List<String>> — feasts by precedence
```

### 4. Detect the celebrations of a day

```dart
final celebrations = await detectCelebrations(calendar, DateTime(2026, 3, 25), dataLoader);
// returns a List<CelebrationContext> sorted by precedence (most solemn first)
```

Each `CelebrationContext` contains everything needed to load the office content: celebration code, ferial code, liturgical season, breviary week, precedence, commons list, liturgical color, origin location, etc.

Each office also has its own detection function, which returns the celebrations that office can be said for, keyed by a display label:

```dart
final Map<String, CelebrationContext> morningList =
    await morningDetection(calendar, date, dataLoader);
// likewise: vespersDetection, readingsDetection, middleOfDayDetection,
// massDetection (one entry per celebration *and* Mass)
final Map<String, ComplineDefinition> complineList =
    await complineDetection(calendar, date, dataLoader);
```

### 5. Load an office

Pass the chosen `CelebrationContext` (with `selectedCommon`, `date`… set as needed) to the matching export function. It applies the whole pipeline — ferial base, common, proper, then hydration of psalms, hymns and canticles:

```dart
final Morning morning = await morningExport(context);
final Vespers vespers = await vespersExport(context);
final Readings readings = await readingsExport(context);
final MiddleOfDay middle = await middleOfDayExport(context);
final Mass mass = await massExport(context);
final Compline compline = await complineExport(complineDefinition);
```

Setting `CelebrationContext.svgSource` (e.g. `'seminaire-emmanuel'`) also loads the psalm-tone SVG scores (`assets/svg/{source}/`).

---

## Office Structure

Each office is a Dart class with typed fields:

### Morning (Lauds)

```dart
class Morning {
  Celebration? celebration;
  Invitatory? invitatory;          // Opening psalm + antiphon
  List<HymnEntry>? hymn;
  List<PsalmEntry>? psalmody;      // Psalms with antiphons
  Reading? reading;                // Short biblical reading
  String? responsory;
  Map<String, List<String>>? evangelicAntiphon; // Benedictus antiphon (A/B/C)
  Psalm? evangelicCanticle;        // Benedictus
  Intercession? intercession;
  List<String>? oration;
  List<String>? canticleSvgData;   // Benedictus tone scores, when svgSource is set
}
```

The `Invitatory` offers up to 4 candidate psalms (`PSALM_94`, `PSALM_66`, `PSALM_99`, `PSALM_23` by default). Any candidate already present in that day's **final, merged** Lauds `psalmody` is excluded. This exclusion runs in `morningExport`, after ferial/common/proper overlays are fully resolved — not while extracting an individual YAML file, since a Memorial's invitatory can come from the Common while the day keeps its ferial psalmody (or vice versa).

### Vespers

Same structure as Morning, with `Magnificat` as the evangelic canticle. Vespers distinguishes between `vespers1` (first vespers, eve of a solemnity) and `vespers2` (second vespers, the day itself).

### Office of Readings

```dart
class Readings {
  Celebration? celebration;
  List<HymnEntry>? hymn;
  List<PsalmEntry>? psalmody;
  String? verse;
  List<BiblicalReading>? biblicalReading;    // Long biblical passage
  List<PatristicReading>? patristicReading;  // Patristic or hagiographic text
  Hymns? teDeum;                             // set on Sundays, octaves, feasts and solemnities
  List<String>? oration;
}
```

### Compline

```dart
class Compline {
  String? celebrationType;     // normal day, solemnity or eve of a solemnity
  List<HymnEntry>? hymns;
  List<PsalmEntry>? psalmody;
  Reading? reading;
  String? responsory;
  Map<String, List<String>>? evangelicAntiphon;
  Psalm? evangelicCanticle;    // Nunc Dimittis
  List<String>? oration;
  List<HymnEntry>? marialHymnRef; // Marian antiphon (varies by day/season)
}
```

### Midday Prayer (Terce, Sext, None)

```dart
class MiddleOfDay {
  List<PsalmEntry>? psalmody;        // shared by the three hours
  List<PsalmEntry>? psalmodyTierce;  // gradual psalms, when the hours differ
  List<PsalmEntry>? psalmodySexte;
  List<PsalmEntry>? psalmodyNone;
  List<HymnEntry>? hymnTierce, hymnSexte, hymnNone;
  HourOffice? tierce;   // Antiphon + reading + responsory
  HourOffice? sexte;
  HourOffice? none;
  List<String>? oration;
}
```

### Mass

```dart
class Mass {
  String? massType;                  // DAY_MASS, EASTER_VIGIL, …
  List<MassAntiphon>? entranceAntiphon;
  List<String>? collect;
  List<MassReadingPart>? readingParts; // READING | EPISTLE | PSALM | GOSPEL
  List<String>? offeringPrayer;
  List<PrefaceEntry>? prefaceList;
  List<MassAntiphon>? communionAntiphon;
  List<String>? prayerAfterCommunion;
  // + prayerOnThePeople, solemnBlessingList, sequence, …
}
```

---

## Hierarchical Commons

When a feast has no proper office of its own, the package resolves a **common** — a set of texts appropriate to the type of saint (apostle, martyr, virgin, doctor, etc.).

Commons are resolved hierarchically: a more specific common inherits from and overrides a more general one. Seasonal variants are applied automatically.

Example: `pastors_bishop` during Easter time tries, in this order, and overlays each file that exists:

```
commons/pastors.yaml
commons/pastors_paschal.yaml
commons/pastors_bishop.yaml
commons/pastors_bishop_paschal.yaml
```

Seasonal suffixes (`_advent`, `_christmas`, `_lent`, `_paschal`) are derived from `liturgicalTime` in `hierarchical_common_loader.dart`. A `-` is part of a level's name (`saints-female`), only `_` separates levels.

---

## Mobile Feasts

All moveable feasts are computed from Easter using the Meeus/Jones/Butcher algorithm. Key dates include:

- **Easter** — base for all mobile dates
- **Ascension** — 39 days after Easter (can be moved to Sunday per location)
- **Pentecost** — 49 days after Easter
- **Corpus Christi**, **Sacred Heart**, **Christ the King**
- **Annunciation** — transferred if it falls in Holy Week or the Paschal Octave
- **Saint Joseph** — transferred if it falls in Holy Week
- **Epiphany** — fixed on January 6, or moved to the nearest Sunday (per location)

---

## Asset Structure

```
assets/
  calendar_data/
    common_feasts.yaml          # 200+ universal Roman feasts
    index.json                  # code -> title/color/commons lookup table (generated)
    ferial_days/                # season_week_day.yaml (e.g. ot_3_5.yaml), plus privileged
                                 # days with their own proper text: advent_17–24,
                                 # christmas_26–31, christmas-ferial_before_epiphany_2–7
    commons/                    # hierarchical common texts
    complines/                  # compline texts by weekday and season
    sanctoral/                  # individual feast YAML files, by origin (roman/, lyon/, ...);
                                 # includes structurally distinct days (nativity, easter,
                                 # pentecost, holy_thursday, etc.)
  locations/                    # continent / country / diocese / city YAML files
  hymns/                        # ~320 liturgical hymns (French) + 000_list.yaml (seasonal lists)
  psalms/                       # PSALM_1–150, OT_1–43, NT_1–12 + gradual psalms
  mass_missal/                  # Mass texts: blessings/, prefaces/, eucharistic_prayer_communicantes/, elements/
  svg/                          # psalm-tone scores, one folder per source (seminaire-emmanuel/, seminaire-paris/)
```

---

## DataLoader

The `DataLoader` abstraction decouples asset loading from the runtime environment:

```dart
abstract class DataLoader {
  Future<String> load(String relativePath);
  Future<String> loadJson(String relativePath) => load(relativePath);
  Future<String> loadYaml(String relativePath) => load(relativePath);
  Future<List<String>> listFiles(String prefix) async => const [];
}
```

- `FileSystemDataLoader` — reads from disk (CLI / Dart standalone)
- Provide your own implementation for Flutter (`rootBundle`) or other environments

---

## Language Support

All liturgical content (psalms, hymns, readings, antiphons, feast titles) is currently in **French**. The package architecture supports multiple languages via location YAML files and content libraries; additional language sets can be added without structural changes.

---

## Development

```bash
dart pub get              # install dependencies
dart analyze              # static analysis
dart format lib/ test/    # format source
dart run test/calendar_output.dart  # generate a sample calendar (Lyon, 2026) → test/calendar_output.txt
```
