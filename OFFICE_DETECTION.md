# Office Detection System

This document explains the architecture of the office detection system used to identify possible liturgical celebrations for a given date.

## Overview

The system uses a **common detection function** (`detectCelebrations`) that handles all the shared logic, combined with **specialized wrappers** for each office type (Morning, Readings, Vespers, etc.).

```
┌─────────────────────────────────────────────────────────────────────┐
│                        office_detection.dart                         │
│                                                                      │
│  ┌──────────────────────┐    ┌─────────────────────────────────┐   │
│  │ CelebrationYamlData  │    │     DetectedCelebration         │   │
│  │  - title             │    │  - mapKey                       │   │
│  │  - subtitle          │    │  - celebrationName              │   │
│  │  - description       │    │  - celebrationCode              │   │
│  │  - color             │    │  - ferialCode                   │   │
│  │  - commons           │    │  - commonList                   │   │
│  └──────────────────────┘    │  - liturgicalTime               │   │
│                              │  - breviaryWeek                 │   │
│  ┌──────────────────────┐    │  - precedence                   │   │
│  │ parseCelebrationYaml │    │  - liturgicalColor              │   │
│  │   (YAML → Data)      │    │  - isCelebrable                 │   │
│  └──────────────────────┘    │  - celebrationDescription       │   │
│                              └─────────────────────────────────┘   │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                    detectCelebrations()                        │ │
│  │                                                                │ │
│  │   1. Get day content from Calendar                             │ │
│  │   2. Build list of all celebrations (feastList + default)      │ │
│  │   3. Sort by precedence                                        │ │
│  │   4. Load YAML files in parallel (Future.wait)                 │ │
│  │   5. Parse and build DetectedCelebration list                  │ │
│  │                                                                │ │
│  │   Returns: List<DetectedCelebration>                           │ │
│  └────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

## Architecture: Function + Wrappers

```
                              ┌─────────────────────────┐
                              │   detectCelebrations    │
                              │   (common function)     │
                              │                         │
                              │ • Calendar lookup       │
                              │ • Sorting by precedence │
                              │ • Parallel YAML loading │
                              │ • YAML parsing          │
                              └───────────┬─────────────┘
                                          │
                                          │  List<DetectedCelebration>
                                          │
     ┌────────────┬────────────┬──────────┼──────────┬────────────┐
     │            │            │          │          │            │
     ▼            ▼            ▼          ▼          ▼            ▼
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│ morning  │ │ readings │ │middleOf  │ │ vespers  │ │ compline │
│Detection │ │Detection │ │  Day     │ │Detection │ │Detection │
│(wrapper) │ │(wrapper) │ │Detection │ │(wrapper) │ │(wrapper) │
│          │ │          │ │(wrapper) │ │          │ │          │
│ Simple   │ │+ Te Deum │ │ Simple   │ │+ I Vêpres│ │+ Eve     │
│conversion│ │          │ │conversion│ │(tomorrow)│ │+ dayOfWk │
└────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘
     │            │            │            │            │
     ▼            ▼            ▼            ▼            ▼
  Morning     Readings    MiddleOfDay   Vespers     Compline
 Definition  Definition   Definition  Definition  Definition
```

## Wrapper Details

### Morning Detection (`morning_detection_v2.dart`)

Simple wrapper that converts `DetectedCelebration` to `MorningDefinition`.

```dart
Future<Map<String, MorningDefinition>> morningDetection(...) async {
  final celebrations = await detectCelebrations(calendar, date, dataLoader);
  // Simple conversion to MorningDefinition
  return { for (var c in celebrations) c.mapKey: MorningDefinition(...) };
}
```

### Readings Detection (`readings_detection_v2.dart`)

Adds Te Deum computation logic:

```dart
bool _computeTeDeum(int precedence, DateTime date, String liturgicalTime) {
  // Te Deum if:
  // - Feast or Solemnity (precedence < 6)
  // - OR Sunday (except during Lent)
  return precedence < 6 || (isSunday && !isLent);
}
```

```
┌─────────────────────┐
│ DetectedCelebration │
│   precedence: 3     │───────► Te Deum = true (Solemnity)
└─────────────────────┘

┌─────────────────────┐
│ DetectedCelebration │
│   precedence: 13    │───────► Te Deum = false (weekday)
│   date: Wednesday   │
└─────────────────────┘

┌─────────────────────┐
│ DetectedCelebration │
│   precedence: 13    │───────► Te Deum = true (Sunday, not Lent)
│   date: Sunday      │
│   time: Ordinary    │
└─────────────────────┘
```

### Middle of Day Detection (`middle_of_day_detection_v2.dart`)

Simple wrapper that converts `DetectedCelebration` to `MiddleOfDayDefinition`.

The Middle of Day office (Tierce, Sexte, None) uses the same celebrations as other offices. The `MiddleOfDay` class contains:

```
┌─────────────────────────────────────────┐
│            MiddleOfDay                  │
├─────────────────────────────────────────┤
│ celebration: Celebration?               │
│ psalmody: List<PsalmEntry>?  ──────────►│ Common to all 3 hours
├─────────────────────────────────────────┤
│ tierce: HourOffice?          ──────────►│ antiphon, reading, responsory
│ sexte: HourOffice?           ──────────►│ antiphon, reading, responsory
│ none: HourOffice?            ──────────►│ antiphon, reading, responsory
├─────────────────────────────────────────┤
│ oration: List<String>?                  │
└─────────────────────────────────────────┘
```

### Vespers Detection (`vespers_detection_v2.dart`)

Handles **First Vespers** (I Vêpres) logic by looking at tomorrow's celebrations:

```
         Today (date)                    Tomorrow (date + 1)
    ┌─────────────────────┐          ┌─────────────────────┐
    │  detectCelebrations │          │  detectCelebrations │
    │     (II Vêpres)     │          │                     │
    └──────────┬──────────┘          └──────────┬──────────┘
               │                                │
               │                                │ Filter: precedence ≤ 5
               │                                │ (Solemnities, Feasts of the Lord)
               │                                ▼
               │                     ┌─────────────────────┐
               │                     │ I Vêpres candidates │
               │                     └──────────┬──────────┘
               │                                │
               └────────────┬───────────────────┘
                            │
                            ▼
                  ┌─────────────────────┐
                  │   Merge & Sort      │
                  │   by precedence     │
                  └─────────────────────┘
                            │
                            ▼
              Map<String, VespersDefinition>
              ┌─────────────────────────────┐
              │ "Férie du 24 déc."          │ ← II Vêpres, isCelebrable: false
              │ "I Vêpres: Nativité"        │ ← I Vêpres, isCelebrable: true
              └─────────────────────────────┘
```

### Compline Detection (`compline_detection_v2.dart`)

Complines are special - they depend on the **day of the week** (for psalm selection) and handle **Eve Complines** like First Vespers.

```
┌─────────────────────────────────────────────────────────────┐
│              Compline-specific logic                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  dayOfWeek ────────────► Determines which psalms to use     │
│  • monday, tuesday...    (stored in Dart files, not YAML)   │
│  • sunday for solemnities                                   │
│  • saturday for eve                                         │
│                                                             │
│  celebrationType ──────► Determines variations              │
│  • 'normal': regular weekday                                │
│  • 'solemnity': uses Sunday psalms                          │
│  • 'solemnityeve': uses Saturday psalms                     │
│  • 'holy_thursday', etc.: special cases                     │
│                                                             │
│  isEveCompline ────────► Like isFirstVespers                │
│  • Looks at tomorrow for solemnities/Sundays                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

```
       Today                         Tomorrow
  detectCelebrations            detectCelebrations
         │                              │
         │                              │ Filter: precedence ≤ 4
         │                              │         OR Sunday
         ▼                              ▼
  ┌─────────────┐              ┌─────────────────┐
  │ Today's     │              │ Eve Complines   │
  │ Complines   │              │ candidates      │
  └──────┬──────┘              └────────┬────────┘
         │                              │
         └──────────┬───────────────────┘
                    │
                    ▼
       Map<String, ComplineDefinition>
       ┌───────────────────────────────────────┐
       │ "Complies du lundi"                   │ ← isEveCompline: false
       │ "Complies de la veille de Noël"       │ ← isEveCompline: true
       └───────────────────────────────────────┘
```

## Example: December 24th Evening

```
Date: December 24, 2024

Today's celebrations:
├── Férie du 24 décembre (precedence: 13)

Tomorrow's celebrations:
├── Nativité du Seigneur (precedence: 2, Solemnity)

vespersDetection() returns:
┌─────────────────────────────────────────────────────────────┐
│ Key                           │ isFirstVespers │ isCelebrable │
├───────────────────────────────┼────────────────┼──────────────┤
│ "I Vêpres: Nativité..."       │ true           │ true         │
│ "Férie du 24 décembre"        │ false          │ false        │
└─────────────────────────────────────────────────────────────┘
```

## Parallel YAML Loading

The `detectCelebrations` function uses `Future.wait` for efficient parallel loading:

```
Non-ferial celebrations: [A, B, C, D]

Phase 1: Try special_days/ in parallel
┌─────────────────────────────────────────────┐
│  Future.wait([                              │
│    loadYaml('special_days/A.yaml'),  ──────►│ "content"
│    loadYaml('special_days/B.yaml'),  ──────►│ ""  (empty)
│    loadYaml('special_days/C.yaml'),  ──────►│ "content"
│    loadYaml('special_days/D.yaml'),  ──────►│ ""  (empty)
│  ])                                         │
└─────────────────────────────────────────────┘

Phase 2: Try sanctoral/ for empty results
┌─────────────────────────────────────────────┐
│  Future.wait([                              │
│    loadYaml('sanctoral/B.yaml'),     ──────►│ "content"
│    loadYaml('sanctoral/D.yaml'),     ──────►│ "content"
│  ])                                         │
└─────────────────────────────────────────────┘

Result: All 4 files loaded with only 2 parallel batches
(instead of up to 8 sequential calls)
```

## File Structure

```
lib/
├── offices/
│   ├── office_detection.dart               # Common detection function
│   ├── morning/
│   │   ├── morning_detection.dart          # Original (legacy)
│   │   └── morning_detection_v2.dart       # New wrapper
│   ├── readings/
│   │   ├── readings_detection.dart         # Original (legacy)
│   │   └── readings_detection_v2.dart      # New wrapper + Te Deum
│   ├── middle_of_day/
│   │   └── middle_of_day_detection_v2.dart # New wrapper
│   ├── vespers/
│   │   └── vespers_detection_v2.dart       # New wrapper + I Vêpres
│   └── compline/
│       ├── compline_detection.dart         # Original (legacy)
│       └── compline_detection_v2.dart      # New wrapper + Eve + dayOfWeek
└── classes/
    ├── morning_class.dart                  # Morning + MorningDefinition
    ├── readings_class.dart                 # Readings + ReadingsDefinition
    ├── middle_of_day_class.dart            # MiddleOfDay + MiddleOfDayDefinition
    ├── vespers_class.dart                  # Vespers + VespersDefinition
    └── compline_class.dart                 # Compline + ComplineDefinition
```

## Adding a New Office Type

To add detection for a new office (e.g., Compline):

1. **Create the Definition class** in the appropriate `*_class.dart` file
2. **Create a wrapper** in `offices/<office>/<office>_detection_v2.dart`:

```dart
import '../office_detection.dart';

Future<Map<String, YourOfficeDefinition>> yourOfficeDetection(
  Calendar calendar,
  DateTime date,
  DataLoader dataLoader,
) async {
  // 1. Call the common function
  final celebrations = await detectCelebrations(calendar, date, dataLoader);

  // 2. Add any office-specific logic here

  // 3. Convert to your Definition type
  return { for (var c in celebrations) c.mapKey: YourOfficeDefinition(...) };
}
```

## Benefits of This Architecture

| Aspect | Before | After |
|--------|--------|-------|
| Code duplication | ~150 lines per office | ~30 lines per wrapper |
| YAML loading | Sequential (slow) | Parallel with Future.wait |
| Error handling | Scattered | Centralized in parseCelebrationYaml |
| Adding new office | Copy-paste entire function | Small wrapper only |
| Testing | Test each function separately | Test detectCelebrations once |
