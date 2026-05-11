# Morning Prayer API — How It Works

This document describes the two-step API for resolving the Morning Prayer (Lauds) office, and generalizes to all other offices. The same pattern applies to Vespers, Readings, Compline, and Midday Prayer.

---

## Overview

```
Step 1: morningDetection()  →  Map<String, CelebrationContext>
                                         │
                          (user selects a celebration)
                                         │
Step 2: morningExport()     →  Morning
```

The consumer calls **detection** first to get the list of possible celebrations for a day, then passes the chosen one (adjusted with user preferences) to **export** to get the fully resolved office text.

---

## Prerequisites

Before calling either step, two objects must be ready:

### 1. `LiturgyData` — loaded once at startup

```dart
// CLI / Dart standalone
final data = await LiturgyData.load();

// Flutter (using rootBundle)
final data = await LiturgyData.loadFromDataLoader(FlutterDataLoader());
```

This loads all universal feasts and location definitions. It is heavy and must be cached.

### 2. `Calendar` — built (and cached) per date + region

```dart
final calendar = getCalendar(
  Calendar(),
  DateTime(2026, 3, 25),  // any date in the target liturgical year
  'lyon',                  // location ID — must match a file in assets/locations/
  data,
);
```

`getCalendar()` covers approximately two liturgical years. Cache it and only recompute when the date falls outside the covered range or the region changes.

### 3. `DataLoader` — passed to every API call

```dart
final dataLoader = FlutterDataLoader();  // or FileSystemDataLoader()
```

---

## Step 1 — Detection

```dart
Future<Map<String, CelebrationContext>> morningDetection(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
)
```

### What it does

Inspects the calendar for `date` and returns all liturgically valid celebrations for that day, sorted by precedence (most solemn first).

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `calendar` | `Calendar` | Pre-built calendar covering the date |
| `date` | `DateTime` | The day to query |
| `dataLoader` | `DataLoader` | Asset loader for the runtime environment |

### Return value

`Map<String, CelebrationContext>` — keyed by the celebration's display title.

Each entry is a `CelebrationContext` with these fields relevant for display and selection:

| Field | Type | Description |
|---|---|---|
| `celebrationTitle` | `String?` | Display name (e.g. "Annonciation du Seigneur") |
| `celebrationGlobalName` | `String?` | Full name with subtitle |
| `celebrationCode` | `String` | Internal code (used in Step 2) |
| `precedence` | `int?` | Priority level 1–13 (lower = more solemn) |
| `liturgicalColor` | `String?` | `white`, `violet`, `red`, `green`, `rose` |
| `liturgicalTime` | `String?` | Season: `advent`, `lent`, `easter`, `ot`, etc. |
| `breviaryWeek` | `int?` | Psalter week 1–4 |
| `isCelebrable` | `bool` | Whether this celebration can be chosen |
| `commonList` | `List<String>?` | Available commons (codes) |
| `commonTitles` | `Map<String, String>` | Code → display title for each common |
| `celebrationOrigin` | `String?` | Location name that added this feast; `null` = Roman calendar |

### Sorting and `isCelebrable`

The map is ordered by effective precedence. When a solemnity or feast (precedence ≤ 7) is present, only celebrations at that level have `isCelebrable = true`. On ordinary days, all entries are celebrable.

The consumer should filter on `isCelebrable` before displaying choices:

```dart
final celebrable = morningMap.entries
    .where((e) => e.value.isCelebrable)
    .toList();
```

---

## Step 2 — Export

```dart
Future<Morning> morningExport(CelebrationContext celebrationContext)
```

### What it does

Resolves the full office content for the selected celebration:
1. Loads the ferial (weekday) base layer for the season and week
2. Loads and overlays the common texts (hierarchically, from general to specific)
3. Loads and overlays the proper texts (special day or sanctoral YAML)
4. Applies seasonal rules (Gloria hymn, Lenten restrictions, paschal alleluia)
5. Hydrates psalms and hymns with their full text content
6. Filters the evangelic antiphon to the current liturgical year (A/B/C)
7. Assigns the Benedictus canticle

### Preparing the context before calling export

The `CelebrationContext` returned by detection should not be passed directly. Use `copyWith()` to apply user choices:

```dart
final selectedContext = morningMap.entries
    .firstWhere((e) => e.value.isCelebrable)
    .value;

final celebrationContext = selectedContext.copyWith(
  // Pass the selected common, or an empty list if none
  commonList: selectedCommon != null ? [selectedCommon] : [],
  // Whether to render imprecatory psalm verses (bracketed sections)
  showImprecatoryVerses: false,
  // Optional: override precedence (e.g. user chooses to treat a memorial as a feast)
  precedence: selectedContext.precedence,
);

final morning = await morningExport(celebrationContext);
```

### Commons selection

If `commonList` is non-empty and the celebration is not a ferial day (`celebrationCode != ferialCode`), the user may choose which common to apply. The `commonTitles` map provides the display label for each common code.

Default behavior: use `commonList.first` automatically.

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `celebrationContext` | `CelebrationContext` | Context from Step 1, adjusted with `copyWith()` |

Key fields read by `morningExport`:

| Field | Used for |
|---|---|
| `celebrationCode` | Identifies which proper YAML to load |
| `ferialCode` | Identifies which ferial base YAML to load |
| `selectedCommon` (= `commonList.first`) | Which common hierarchy to load |
| `precedence` | Determines merge strategy (full replacement vs overlay) |
| `liturgicalTime` | Seasonal adjustments (Gloria, alleluia, etc.) |
| `date` | Liturgical year A/B/C for evangelic antiphon |
| `dataLoader` | Asset loading |
| `showImprecatoryVerses` | Whether bracketed psalm verses are included |

### Return value: `Morning`

```dart
class Morning {
  Invitatory?            invitatory;        // Opening psalm + antiphon
  List<HymnEntry>?       hymn;              // Hymn(s) — hymnData is populated
  List<PsalmEntry>?      psalmody;          // Psalms — psalmData is populated
  Reading?               reading;           // Short biblical reading
  String?                responsory;        // Responsory text
  Map<String, String>?   evangelicAntiphon; // Benedictus antiphon; keys: 'antiphon', 'A', 'B', 'C'
  Psalm?                 evangelicCanticle; // Benedictus (always populated)
  Intercession?          intercession;      // Intercessions text
  List<String>?          oration;           // Concluding prayer
}
```

Psalms and hymns are **fully hydrated**: `psalmEntry.psalmData` and `hymnEntry.hymnData` contain the complete text, ready to display.

The `evangelicAntiphon` map after export contains at most two keys: `'antiphon'` (the common antiphon) and the current year (`'A'`, `'B'`, or `'C'`). Use `'antiphon'` as the default when the year-specific one is absent.

---

## Complete Example

```dart
// --- One-time setup ---
final data = await LiturgyData.loadFromDataLoader(FlutterDataLoader());
final dataLoader = FlutterDataLoader();

// --- Per date+region (cache this) ---
final calendar = getCalendar(Calendar(), date, 'lyon', data);

// --- Step 1: detect ---
final Map<String, CelebrationContext> morningMap =
    await morningDetection(calendar, date, dataLoader);

// Filter celebrable options
final options = morningMap.entries
    .where((e) => e.value.isCelebrable)
    .toList();

// Auto-select most solemn (first in map)
final selected = options.first.value;

// Let user pick a common if available
final common = selected.commonList?.isNotEmpty == true
    ? selected.commonList!.first
    : null;

// --- Step 2: export ---
final context = selected.copyWith(
  commonList: common != null ? [common] : [],
  showImprecatoryVerses: false,
);

final Morning morning = await morningExport(context);

// --- Consume ---
print(morning.reading?.biblicalReference);   // e.g. "Is 2, 2-5"
print(morning.reading?.content);             // full reading text
for (final entry in morning.psalmody ?? []) {
  print(entry.psalm);                        // e.g. "PSALM_63"
  print(entry.psalmData?.content);           // full psalm text
  print(entry.antiphon?.first);              // antiphon text
}
print(morning.evangelicAntiphon?['antiphon']); // Benedictus antiphon
print(morning.evangelicCanticle?.content);     // Benedictus text
```

---

## Same Pattern for Other Offices

All offices follow the identical two-step pattern:

| Office | Detection | Export |
|---|---|---|
| Morning Prayer (Lauds) | `morningDetection()` | `morningExport()` |
| Vespers | `vespersDetection()` | `vespersExport()` |
| Office of Readings | `readingsDetection()` | `readingsExport()` |
| Compline | `complineDetection()` | `complineExport()` |
| Midday Prayer | `middleOfDayDetection()` | `middleOfDayExport()` |

Detection always returns `Map<String, CelebrationContext>`. Export always takes a `CelebrationContext` and returns the office-specific class (`Vespers`, `Readings`, `Compline`, `MiddleOfDay`).

**Exception — Compline:** detection returns `Map<String, ComplineDefinition>` (not `CelebrationContext`) and does not use a ferial base layer. The `ComplineDefinition` is passed directly to `complineExport()`.

---

## Key Rules to Remember

- Always filter by `isCelebrable` before showing options to the user.
- Always call `copyWith()` before passing to export — never mutate the detected context directly.
- `commonList` in `copyWith()` should contain **exactly one** element (the chosen common), or be empty.
- The `Calendar` covers ~2 years; check `getDayContent(date) != null` before deciding to recompute.
- `LiturgyData` is loaded once; `DataLoader` and `Calendar` can be reused across offices for the same day.
