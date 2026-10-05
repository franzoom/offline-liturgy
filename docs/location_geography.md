# Location Geography System

## Overview

The location system lets you declare liturgical feasts that apply only to a specific geographic scope — a continent, country, diocese, city, or church. Feasts are defined in YAML files under `assets/locations/`. When a calendar is built for a given location, the system walks the ancestor chain from the broadest scope down to the most specific, applying each level in turn.

## File structure

Each file in `assets/locations/` describes one location. The filename (without `.yaml`) is the location's identifier.

```yaml
language: french
geography: diocese       # continent | country | diocese | city | church | community
parent: france           # identifier of the parent location file
frenchName: diocèse de Lyon
frenchLocative: dans le diocèse de Lyon

epiphanyDate: sunday       # optional: 'sunday' or 'day' (Jan 6 fixed)
ascensionDate: thursday    # optional: 'sunday' (moved) or 'thursday' (39 days after Easter)
corpusDominiDate: sunday   # optional: 'sunday' (default, 63 days after Easter) or 'thursday'

feasts:
  ...

move:
  ...
```

`parent` is optional. A location without a parent is a root node (e.g. `europe.yaml`).

`frenchName` and `frenchLocative` should be self-contained and descriptive. For countries, the bare name suffices (`France`, `en France`). For dioceses, cities, and churches, include the geographic type to avoid ambiguity (`diocèse de Lyon`, `dans le diocèse de Lyon`).

## Ancestor chain resolution

When building the calendar for `"lyon"`, the system builds the chain:

```
europe → france → lyon
```

Each level's feasts are applied in order, from root to leaf (`localCalendarFill()` in `lib/calendar_management/local_calendar_fill.dart`). This means a diocese can override (same base name, see below) or move (`move:`) anything declared at the country or continent level, without the parent file knowing about it. There is no section to remove a feast.

## Feast keys and content files

Every feast declared in a location YAML uses a **short key** (no location prefix):

```yaml
feasts:
  joan_of_arc_virgin:
    month: 5
    day: 30
    precedence: 12
```

Internally, `applyToCalendar` prefixes the key with the location id before storing it in the calendar: `france/joan_of_arc_virgin`. The corresponding content file lives at `assets/calendar_data/sanctoral/france/joan_of_arc_virgin.yaml`.

Universal Roman feasts (from `common_feasts.yaml`) are stored with the `roman/` prefix: `roman/andrew_apostle`, matching the file at `sanctoral/roman/andrew_apostle.yaml`.

### Override by base name

When a location adds a feast, the calendar (`Calendar.addItemToDay()`) checks whether any existing entry on that day shares the same **base name** (the part after `/`). If so, the new entry replaces the old one — including any precedence change. This means a diocese feast automatically overrides a national or Roman feast with the same filename.

One exception: if the new qualified key has no content file of its own (it is absent from `index.json`, i.e. from `LiturgyData.knownCodes`), the existing key is kept and only its precedence is updated. A location can thus raise a Roman feast's rank (e.g. to a solemnity for a patron saint) without duplicating its content file.

Example: `europe/benedict_of_nursia_abbot` (precedence 5) overrides `roman/benedict_of_nursia_abbot` (precedence 10) automatically when Europe's feasts are applied.

## The `feasts:` section

Declares feasts that are added to the calendar for this location and all its descendants.

### Fixed date feast

```yaml
feasts:
  joan_of_arc_virgin:
    month: 5
    day: 30
    precedence: 12
```

`month` and `day` are required. `precedence` follows the standard 1–13 scale. Only dates falling within the liturgical year being built are added.

### Feast relative to a mobile date

```yaml
feasts:
  our_lady_of_fourviere:
    relativeTo: EASTER
    shift: 13
    precedence: 7
```

`relativeTo` is a key from `liturgicalMainFeasts` (e.g. `EASTER`, `ADVENT`, `SACRED_HEART`, `CORPUS_DOMINI`). `shift` is the number of days after that anchor (0 if omitted).

## The `move:` section

Moves a feast that already exists in the calendar (Roman, from a parent location, or local) to a different date within the liturgical year for this location. The key is the short feast name — `Calendar.moveItemToDate()` finds it by base name, whatever its prefix. An entry whose feast is not found is ignored.

```yaml
move:
  joseph_of_calasanz_priest:
    month: 8
    day: 26
    precedence: 12
```

## Sanctoral directory layout

```
assets/calendar_data/sanctoral/
  roman/          ← universal Roman calendar feasts
  europe/         ← feasts proper to Europe
  france/         ← feasts proper to France
  lyon/           ← feasts proper to the diocese of Lyon
  belgium/
  bordeaux/
  ...
```

Content files are named after the short feast key. The calendar key `france/joan_of_arc_virgin` maps directly to `sanctoral/france/joan_of_arc_virgin.yaml`.

`index.json` is generated by `scripts/make_index.py` and must be regenerated whenever sanctoral files are added or renamed.

## Feast origin tracking

Every feast added by a location records a `LocationOrigin {name, locative}` in `feastOrigins` on the day. This flows through to `CelebrationContext.celebrationOrigin`, making the location name and locative available throughout office resolution and to the consumer app.

## `epiphanyDate`, `ascensionDate` and `corpusDominiDate`

These control calendar structure for the whole location. They are resolved by walking the ancestor chain from most specific to root and taking the first non-null value found (`getEpiphanyDate()` / `getAscensionDate()` / `getCorpusDominiDate()`); when no ancestor sets them, the defaults are `sunday` / `thursday` / `sunday`. `getCalendar()` also accepts explicit overrides that take precedence over the location files.

| field | values | meaning |
|---|---|---|
| `epiphanyDate` | `day` | January 6, fixed |
| | `sunday` (default) | First Sunday after January 1 |
| `ascensionDate` | `thursday` (default) | 39 days after Easter (traditional) |
| | `sunday` | Moved to the following Sunday (42 days after Easter) |
| `corpusDominiDate` | `sunday` (default if unset) | 63 days after Easter |
| | `thursday` | 60 days after Easter |

## Geography priority

When building the location tree (`buildLocationTree`), nodes are sorted by priority within each level. Priority is used for display ordering only, not for feast application order (which is always ancestor → descendant).

| geography | priority |
|---|---|
| continent, community | 1 |
| country | 2 |
| diocese | 3 |
| city, church | 4 |

## Adding a new location

1. Create `assets/locations/my-location.yaml` with at minimum `language`, `geography`, `frenchName`, `frenchLocative`, and `parent` (unless it is a root).
2. Create `assets/calendar_data/sanctoral/my-location/` and add feast YAML files there.
3. Add feast keys (short form, no prefix) under `feasts:` and/or relocations under `move:`.
4. Run `python3 scripts/make_index.py` to regenerate `index.json`.
5. Pass the location identifier to `getCalendar()` — the system picks it up automatically from the flat map loaded by `LiturgyData`.
