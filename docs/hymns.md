# Hymn Management

## Overview

Hymns follow the same pipeline as all other office elements: **Ferial → Common → Proper**. Each layer can enrich or replace the previous one.

---

## Data Sources

### `assets/hymns/000_list.yaml`
Index of hymn lists keyed by season. Structure:
```yaml
hymn_list:
  advent: [code1, code2, ...]
  christmas: [...]
  after_epiphany: [...]
  lent: [...]
  passion: [...]   # Lent weeks 5+ and Holy Week
  easter: [...]
  ot: [...]

tierce_hymn_list:  # hymns specific to Terce
  ordinary: [...]
  lent: [...]
  easter: [...]

sexte_hymn_list:   # same for Sext
none_hymn_list:    # same for None
```

This file is loaded once per session and cached in memory (`hymns_management.dart`).

### `assets/hymns/*.yaml`
Individual files containing the full text of each hymn, indexed by code (e.g. `alleluia-pascal.yaml`).

### Ferial / Proper / Common YAMLs
Any celebration file can define a `hymn:` list directly in its office section.

---

## Resolution Pipeline (Lauds, Vespers, Office of Readings)

### 1. Ferial layer (`ferial_*_resolution.dart`)

The ferial resolver loads the day's YAML, then **appends** (without overwriting) the seasonal hymns from `000_list.yaml`:

```dart
final seasonHymns = await getHymnsForSeason("advent", dataLoader);
ferialMorning.hymn = [...?ferialMorning.hymn, ...seasonHymns];
```

The day-specific hymn from the YAML (if any) stays **first in the list**.

Season → key mapping:

| Liturgical season          | `000_list.yaml` key |
|----------------------------|---------------------|
| Ordinary time              | `ot`                |
| Advent                     | `advent`            |
| Christmas / before Epiphany| `christmas`         |
| After Epiphany             | `after_epiphany`    |
| Lent (weeks 1–4)           | `lent`              |
| Lent (weeks 5+)            | `passion`           |
| Holy Week                  | `passion`           |
| Easter time                | `easter`            |

### 2. Common layer (`loadMorningHierarchicalCommon` etc.)

If the celebration has a selected common, it is loaded (hierarchically, see the README) and overlaid on the ferial layer, according to precedence:

- **Solemnities and Feasts** (precedence ≤ 9): `overlayWith` — every field the common defines replaces the ferial one, `hymn` included.
- **Memorials** (precedence > 9): `overlayWithCommon` — selective overlay that leaves the psalmody alone; `hymn` is replaced if the common defines one.

### 3. Proper layer

The celebration's proper YAML is loaded by `morningExtract` (or the vespers/readings equivalent) and always applied with `overlayWith`, whatever the precedence: its `hymn` field, if defined, replaces the current one.

### 4. Special case: Holy Week (Lauds and Office of Readings)

In `morning_export.dart` and `readings_export.dart`, if `hymn` is still `null` after all overlays and the celebration is a Holy Week day (`holyWeekCodes`), Passion hymns are injected:
```dart
if (morningOffice.hymn == null &&
    holyWeekCodes.contains(celebrationContext.celebrationCode)) {
  morningOffice.hymn =
      await getHymnsForSeason("passion", celebrationContext.dataLoader);
}
```

### 5. Hydration

At this point `hymn` only contains codes (`HymnEntry.code`). `resolveOfficeContent()` (`lib/tools/resolve_office_content.dart`) then loads each text from `assets/hymns/*.yaml` through `HymnsLibrary` (cached), and stores it in `HymnEntry.hymnData`. The same mechanism, with another folder, resolves the Mass sequences and solemn blessings.

---

## Middle of the Day (Terce, Sext, None)

Middle of the day hymns do not go through the ferial/common/proper pipeline. They are determined solely by the liturgical season, via three dedicated lists in `000_list.yaml`:

```dart
getTierceHymns(liturgicalTime, dataLoader)  // tierce_hymn_list
getSexteHymns(liturgicalTime, dataLoader)   // sexte_hymn_list
getNoneHymns(liturgicalTime, dataLoader)    // none_hymn_list
```

Season → key mapping (`liturgicalTime` → list key): `lent`/`holyweek` → `"lent"` | `paschaloctave`/`paschaltime` → `"easter"` | everything else → `"ordinary"`.

---

## Flow Summary

```
000_list.yaml (cached)
      │
      ▼
ferial_*_resolution  →  day-specific YAML hymn + seasonal hymns
      │
      ▼
      + common (overlay if defined)
      │
      ▼
      + proper (overlay if defined)
      │
      ▼
morning/vespers/readings_export  →  merge by precedence (+ Holy Week fallback)
      │
      ▼
resolveOfficeContent  →  full texts loaded
```
