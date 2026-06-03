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

epiphanyDate: sunday     # optional: 'sunday' or 'day' (Jan 6 fixed)
ascensionDate: thursday  # optional: 'sunday' (moved) or 'thursday' (39 days after Easter)

feasts:
  ...

move:
  ...
```

`parent` is optional. A location without a parent is a root node (e.g. `europe.yaml`).

## Ancestor chain resolution

When building the calendar for `"lyon"`, the system builds the chain:

```
europe → france → lyon
```

Each level's feasts are applied in order, from root to leaf. This means a diocese can override or suppress anything declared at the country or continent level, without the parent file knowing about it.

## The `feasts:` section

Declares feasts that are added to the calendar for this location and all its descendants.

### Fixed date feast

```yaml
feasts:
  france_joan_of_arc_virgin:
    month: 5
    day: 30
    precedence: 12
```

The key is the feast identifier (used throughout the codebase to look up office content). `month` and `day` are required. `precedence` follows the standard 1–13 scale.

### Feast relative to a mobile date

```yaml
feasts:
  lyon_our_lady_of_fourviere:
    relativeTo: EASTER
    shift: 13
    precedence: 7
```

`relativeTo` is a key from `liturgicalMainFeasts` (e.g. `EASTER`, `ADVENT`, `SACRED_HEART`, `CORPUS_DOMINI`). `shift` is the number of days after that anchor. Useful for feasts tied to the moveable cycle.

### Suppressing a feast from a parent level

```yaml
feasts:
  france_joan_of_arc_virgin:
    suppress: true
```

No `month`, `day`, or `precedence` needed. When the ancestor chain reaches this entry, `removeFeastFromCalendar` is called, undoing what a parent level declared. Useful when a national feast does not apply in a particular diocese.

## The `move:` section

Moves a feast that already exists in the calendar (typically from `common_feasts.yaml`) to a different date within the liturgical year for this location.

```yaml
move:
  joseph_of_calasanz_priest:
    month: 8
    day: 26
    precedence: 12
```

The key must match an existing feast key. The feast is relocated to the given date within the liturgical year's bounds. This is used when a conflict with another feast requires a local adjustment.

## Feast origin tracking

Every feast added by a location call records the `frenchName` of that location as its origin (`feastOrigins` on the day). This lets the consumer app display "France" or "diocèse de Lyon" next to a proper feast.

`frenchName` and `frenchLocative` should be self-contained and descriptive. For countries, the bare name suffices (`France`, `en France`). For dioceses, cities, and churches, include the geographic type to avoid ambiguity (`diocèse de Lyon`, `dans le diocèse de Lyon`).

## `epiphanyDate` and `ascensionDate`

These are not feast entries — they control calendar structure for the whole location. They are resolved by walking the ancestor chain from most specific to root and taking the first non-null value found.

| field | values | meaning |
|---|---|---|
| `epiphanyDate` | `day` | January 6, fixed |
| | `sunday` | First Sunday after January 1 |
| `ascensionDate` | `thursday` | 39 days after Easter (traditional) |
| | `sunday` | Moved to the following Sunday |

## Geography priority

When building the location tree (`buildLocationTree`), nodes are sorted by priority within each level. Priority is used for display ordering only, not for feast application order (which is always ancestor → descendant).

| geography | priority |
|---|---|
| continent, community | 1 |
| country | 2 |
| diocese | 3 |
| city, church | 4 |

## Adding a new location

1. Create `assets/locations/my-location.yaml` with at minimum `language`, `geography`, `frenchName`, and `parent` (unless it is a root).
2. Add feasts under `feasts:` and/or relocations under `move:`.
3. Pass the location identifier to `getCalendar()` — the system picks it up automatically from the flat map loaded by `LiturgyData`.
