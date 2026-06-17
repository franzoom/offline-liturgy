# offline_liturgy

A Dart package that builds a universal Catholic liturgical calendar and resolves the full content of the Divine Office (Liturgy of the Hours) and the Mass for any given day and location.

---

## Overview

`offline_liturgy` operates in two stages:

1. **Calendar building** — computes a complete liturgical calendar for a given year and location, with all feasts, seasons, and priorities resolved.
2. **Office resolution** — for any day in that calendar, retrieves the full content of each liturgical hour: Morning Prayer (Lauds), Vespers, Office of Readings, Compline, and Midday Prayer.

All content (psalms, hymns, readings, antiphons) is stored locally as YAML files and loaded on demand. No network connection is required.

---

## Core Concepts

### Liturgical Calendar

The Catholic liturgical year is divided into seasons:

| Code | Season |
|---|---|
| `advent` | Advent |
| `nativity` | Christmas Day |
| `christmasoctave` | Octave of Christmas (Dec 26–Jan 1) |
| `christmas` | Christmas Time (after octave) |
| `lent` | Lent |
| `holyweek` | Holy Week |
| `paschaloctave` | Octave of Easter |
| `easter` | Easter Time |
| `ot` | Ordinary Time |

Each day has a **precedence level** (1–13) that determines which celebration takes priority when multiple feasts coincide:

| Level | Type |
|---|---|
| 1–3 | Solemnities |
| 4–5 | Feasts |
| 6–9 | Obligatory memorials |
| 10–11 | Optional memorials |
| 12 | Commemorations |
| 13 | Ferial days (weekdays of a season) |

During privileged seasons (Advent, Lent, Octaves), obligatory memorials are automatically downgraded to optional.

### Locations

The package supports a hierarchical geography of liturgical locations, each with its own proper feasts:

```
Continent → Country → Diocese → City → Church / Community
```

Each location can add, suppress, or move feasts relative to the universal Roman calendar. Locations are defined in YAML files under `assets/locations/`.

### Liturgical Years (A / B / C)

The three-year cycle (A, B, C) governs which patristic readings and evangelic antiphons are used on a given year.

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

This returns a `Calendar` covering **two full liturgical years** (year N and N+1) to handle boundary dates correctly.

### 3. Inspect a day

```dart
final day = calendar.getDayContent(DateTime(2026, 3, 25));

print(day.liturgicalTime);          // e.g. 'lent'
print(day.liturgicalColor);         // e.g. 'violet'
print(day.precedence);              // e.g. 3
print(day.defaultCelebrationTitle); // e.g. 'Annonciation du Seigneur'
print(day.feastList);               // Map<int, List<String>> — feasts by precedence
```

### 4. Detect available offices for a day

```dart
final celebrations = await detectCelebrations(calendar, DateTime(2026, 3, 25), dataLoader);
// returns a List<CelebrationContext> sorted by precedence (most solemn first)
```

Each `CelebrationContext` contains everything needed to load the office content: celebration code, liturgical season, breviary week, commons list, liturgical color, origin location, etc. Set the optional `svgSource` field to load SVG music sheets alongside psalm text (see SVG Music Sheets below).

### 5. Load an office

Pass the `CelebrationContext` to the appropriate resolution function:

```dart
// Morning Prayer (Lauds)
final morning = await morningExtract(context.celebrationCode, dataLoader);

// Vespers
final vespers = await vespersExtract(context.celebrationCode, dataLoader);

// Office of Readings
final readings = await readingsExtract(context.celebrationCode, dataLoader);

// Compline
final compline = await complineExtract(context.celebrationCode, dataLoader);
```

For **ferial days** (ordinary weekdays), use the ferial resolution functions which apply the 4-week psalter cycle, seasonal overlays, and hierarchical commons:

```dart
final morning = await ferialMorningResolution(context, dataLoader);
```

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
}
```

The `Invitatory` offers up to 4 candidate psalms (`PSALM_94`, `PSALM_66`, `PSALM_99`, `PSALM_23` by default). Any candidate already present in that day's **final, merged** Lauds `psalmody` is excluded. This exclusion runs in `morningExport`, after ferial/common/proper overlays are fully resolved — not while extracting an individual YAML file, since a Memorial's invitatory can come from the Common while the day keeps its ferial psalmody (or vice versa).

### Vespers

Same structure as Morning, with `Magnificat` as the evangelic canticle. Vespers distinguishes between `vespers1` (first vespers, eve of a solemnity) and `vespers2` (second vespers, the day itself).

### Office of Readings

```dart
class Readings {
  List<PsalmEntry>? psalmody;
  List<BiblicalReading>? biblicalReading;    // Long biblical passage
  List<PatristicReading>? patristicReading;  // Patristic or hagiographic text
  bool? tedeum;                              // Te Deum included (feasts/solemnities)
}
```

### Compline

```dart
class Compline {
  String? celebrationType;     // 'normal' | 'solemnity' | 'eve'
  List<HymnEntry>? hymns;
  List<PsalmEntry>? psalmody;
  Reading? reading;
  Psalm? evangelicCanticle;   // Nunc Dimittis
  List<HymnEntry>? marialHymnRef; // Marian antiphon (varies by day/season)
}
```

### Midday Prayer (Terce, Sext, None)

```dart
class MiddleOfDay {
  HourOffice? tierce;   // Antiphon + reading + responsory + oration
  HourOffice? sexte;
  HourOffice? none;
}
```

---

## Hierarchical Commons

When a feast has no proper office of its own, the package resolves a **common** — a set of texts appropriate to the type of saint (apostle, martyr, virgin, doctor, etc.).

Commons are resolved hierarchically: a more specific common inherits from and overrides a more general one. Seasonal variants are applied automatically.

Example: `martyrs_male_priest` during Lent loads and overlays:

```
commons/martyrs.yaml
commons/martyrs_lent.yaml
commons/martyrs_male.yaml
commons/martyrs_male_lent.yaml
commons/martyrs_male_priest.yaml
commons/martyrs_male_priest_lent.yaml
```

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
  hymns/                        # ~60 liturgical hymns (French)
  psalms/                       # PSALM_1–150, OT_1–43, NT_1–12 + gradual psalms
                                 # each psalm YAML may optionally declare psalmSVG (see below)
  svg/                          # SVG music sheets, organised by source
    seminaire-emmanuel/         # e.g. PSALM_23.svg, OT_4.svg
    seminaire-paris/
  mass_missal/                  # Mass texts
```

---

## DataLoader

The `DataLoader` abstraction decouples asset loading from the runtime environment:

```dart
abstract class DataLoader {
  Future<String> load(String relativePath);
  Future<String> loadYaml(String relativePath);
  Future<List<String>> listFiles(String prefix);
}
```

- `FileSystemDataLoader` — reads from disk (CLI / Dart standalone)
- Provide your own implementation for Flutter (`rootBundle`) or other environments

---

## SVG Music Sheets

Morning Prayer and Vespers support loading psalm music scores as raw SVG strings. This allows the consumer to display or post-process them (e.g. replace font family or colours).

### Enabling SVG loading

Set `svgSource` on the `CelebrationContext` before calling `morningExport()` or `vespersExport()`:

```dart
final context = selected.copyWith(
  commonList: common != null ? [common] : [],
  svgSource: 'seminaire-emmanuel', // directory name under assets/svg/
);

final morning = await morningExport(context);
```

### Consuming SVG data

After export, each `PsalmEntry` in `psalmody` may carry a `svgData` field:

```dart
for (final entry in morning.psalmody ?? []) {
  for (final svg in entry.svgData ?? []) {
    final customised = svg
        .replaceAll('font-family="Lato"', 'font-family="Playfair Display"')
        .replaceAll('fill="black"', 'fill="#3b2a1a"');
    // display customised SVG
  }
}
```

`svgData` is `null` when no SVG file was found for a psalm (not all psalms have a score). Missing files are silently skipped.

### SVG filename resolution

The package looks for `svg/{svgSource}/{name}.svg`. The filename is resolved in two ways:

1. **Explicit** — the psalm YAML file declares `psalmSVG: PSALM_131-II` (string) or `psalmSVG: [name1, name2]` (list). This handles psalms whose SVG filename differs from the psalm code.
2. **Default** — derived from the psalm code by stripping the trailing part number when more than one underscore is present:
   - `PSALM_117_4` → `PSALM_117.svg`
   - `PSALM_23` → `PSALM_23.svg`
   - `OT_4` → `OT_4.svg`

### Adding `psalmSVG` to a psalm YAML

```yaml
# assets/psalms/PSALM_131_2.yaml
title: Psaume 131-II
psalmSVG: PSALM_131-II   # overrides the default PSALM_131 derivation
content: |-
  ...
```

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
