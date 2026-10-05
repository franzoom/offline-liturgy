# Liturgical Calendar — Special Days & Code Structure

## 1. General Principle: Ferial Codes

Every day in the calendar receives a `defaultCelebrationTitle` (the ferial code). This code follows the pattern:

```
{season}_{week}_{day}
```

- `season`: `ot`, `advent`, `lent`, `easter`, `christmas`
- `week`: integer starting at 1 (counted from the beginning of the season)
- `day`: day-of-week offset within the week, starting at 0 (Sunday) through 6 (Saturday)

Examples: `ot_3_5`, `advent_2_3`, `lent_1_0`

This code determines which YAML file is loaded from `assets/calendar_data/ferial_days/`.

### Breviary Week Cycle

The breviary rotates on a 4-week cycle independently of the liturgical season. The formula is:

```dart
breviaryWeek = (totalDaysFromSeasonStart ~/ 7) % 4 + 1
```

---

## 2. Ordinary Time

Ordinary Time runs in two segments: after the Baptism of the Lord until Ash Wednesday, and after Pentecost until Christ the King.

The day code is: `ot_{week}_{date.weekday % 7}`

The day index uses `date.weekday % 7` (Monday=1, …, Saturday=6, Sunday=0).

**File loading (Ordinary Time):**
- Base: `ferial_days/ot_{(week-1)%4 + 1}_{day}.yaml` (4-week cycle)
- Overlay (weeks > 4): `ferial_days/ot_{week}_{day}.yaml` adds specific content on top

**Ordinary Time after Pentecost** starts at the week that aligns with the 34-week total. The starting week is calculated backward from Christ the King:

```dart
ordinaryTimeDays = (32 - weeksLeft) * 7 + 1
```

This ensures the last week of Ordinary Time is always week 34, regardless of the year.

---

## 3. Advent

### Standard Advent (weeks 1–3 until Dec 16 included)

Code: `advent_{week}_{day}` — loaded directly from `ferial_days/advent_{week}_{day}.yaml`.

Sundays have precedence 2; ferial days have precedence 13.

### Special Advent (Dec 17–24)

From December 17, each day has its own proper texts that take priority over the weekly ferial content. The code format changes:

```
advent-{dateDay}_{week}_{day}
e.g. advent-17_3_5
```

The dash signals a special day. Resolution is a **two-layer load**:

1. **Base**: `ferial_days/advent_{week}_{day}.yaml` (weekly ferial content)
2. **Proper**: `ferial_days/advent_{dateDay}.yaml` (content specific to that calendar date)

The proper is overlaid on the base via `overlayWith()`.

**Exception for Sundays (day=0):** only the `evangelicAntiphon` from the proper is applied (not a full overlay), because the Sunday office has its own structure.

**Note on week 3:** the breviary takes the psalm antiphons of Dec 17–23 falling in week 3 from week 4, while the psalms stay those of week 3. The resolvers do not apply this rule themselves: these antiphons have to be in the dated `advent_{dateDay}.yaml` files.

Precedence of these days: 9 (raised from 13 for standard ferial days).

---

## 4. Christmas Time

Christmas Time is the most complex season. It covers five distinct sub-periods.

### 4a. Christmas Day (Dec 25)

- Code: `roman/nativity`
- Liturgical time: `nativity`
- Breviary week: 1

### 4b. Christmas Octave (Dec 26–31)

- Liturgical time: `christmasoctave`
- Code: `christmas_{dateDay}` (e.g. `christmas_26`, `christmas_27`, …)
- Precedence: 7 for Dec 26–28, 9 for Dec 29–31
- **Exception**: the Holy Family day gets code `roman/holy_family_sunday` (or `roman/holy_family_week` when there is no Sunday in the octave and it falls on Dec 30) with precedence 5.
- Content: base `commons/christmas.yaml` + proper `ferial_days/christmas_{dateDay}.yaml`.
- Breviary week: 4 before Holy Family, 1 from Holy Family onward.

### 4c. January 1 — Mary, Mother of God

- Code: `roman/mary_mother_of_god`
- Liturgical time: `christmas`
- Precedence: 2 (Solemnity)
- Breviary week: 1

### 4d. January 2 to the Eve of Epiphany

- Liturgical time: `christmas`
- Code: `christmas-{dateDay}_{week}_{dayOffset}` (e.g. `christmas-3_1_2`)
  - `dateDay`: calendar day (2, 3, 4, 5…)
  - `week`: week number counted from Holy Family
  - `dayOffset`: `christmasFerialDays % 7`

Resolution is a **two-layer load**:

1. **Base**: `ferial_days/christmas_{week}_{dayOffset}.yaml`
2. **Proper**: `ferial_days/christmas-ferial_before_epiphany_{dateDay}.yaml`

The proper is overlaid on the base. Only `christmas_1_*` files are used (and rarely `christmas_2_*` if Holy Family fell as early as Dec 26). Files `christmas_3_*` and `christmas_4_*` are **never reached**.

### 4e. Epiphany

- Code: `roman/epiphany`
- Date: January 6 (fixed) or the first Sunday on or after January 2 (moveable), depending on the location's `epiphanyDate` field (`day` or `sunday` — see `location_geography.md`).
- Precedence: 3
- Breviary week: 2 if Epiphany is on Jan 6 or earlier; 1 if Epiphany is after Jan 6 (in the moveable mode, the Baptism of the Lord immediately follows the next day as a Monday, resetting the breviary week).

### 4f. Epiphany+1 to the Baptism of the Lord

- Liturgical time: `christmas`
- Code: `christmas_2_{date.weekday % 7}`
- File loaded: `ferial_days/christmas_2_{date.weekday}.yaml`
- Hymn season: `after_epiphany`

### 4g. Baptism of the Lord

- Code: `roman/baptism_of_the_lord_sunday`, or `roman/baptism_of_the_lord_week` when it falls on a Monday
- Date: Sunday after Epiphany (or Monday if Epiphany falls on Jan 7–8)
- Liturgical time: `christmas` (it closes Christmas Time; Ordinary Time starts the next day)
- Precedence: 5
- Breviary week: 1

---

## 5. Ascension and the Days Before It

Ascension is normally on Thursday, 39 days after Easter.

Some dioceses transfer Ascension to the following Sunday (42 days after Easter). This is configured per location via the `ascensionDate: sunday` field in the location YAML file (resolved by walking the ancestor chain — see `location_geography.md`). Internally this resolves to the boolean `ascensionOnSunday` used by `calendarFill()`.

### Impact on ferial codes (Sunday Ascension only)

When Ascension is moved to Sunday, the last days before it (Wednesday–Saturday of the 6th week, days 38–41 counted from Easter Sunday) receive a modified code:

```
easter_{week}_{day}_before_ascension
```

This suffix (`_before_ascension`) signals that these days liturgically "anticipate" the Ascension and must load specific content (different antiphons, readings etc.) rather than standard Paschal Time ferial content.

When Ascension is on Thursday (default), no suffix is added and these days use the standard `easter_{week}_{day}` code.

### Days after Ascension until Pentecost

After Ascension (whether Thursday or Sunday), the remaining days until Pentecost continue with the standard `easter_{week}_{day}` code. There is no special suffix for the post-Ascension days.

---

## Summary Table

| Period | Code format | Files loaded |
|---|---|---|
| Ordinary Time | `ot_{W}_{D}` | `ferial_days/ot_{(W-1)%4+1}_{D}.yaml` + overlay `ot_{W}_{D}.yaml` if W>4 |
| Advent (standard) | `advent_{W}_{D}` | `ferial_days/advent_{W}_{D}.yaml` |
| Advent (Dec 17–24) | `advent-{date}_{W}_{D}` | base `advent_{W}_{D}` + proper `advent_{date}` |
| Christmas Octave | `christmas_{dateDay}` | base `commons/christmas.yaml` + proper `ferial_days/christmas_{dateDay}.yaml` |
| Jan 2 – Epiphany eve | `christmas-{date}_{W}_{D}` | base `christmas_{W}_{D}` + proper `christmas-ferial_before_epiphany_{date}` |
| Post-Epiphany | `christmas_2_{N}` | `ferial_days/christmas_2_{weekday}.yaml` |
| Lent | `lent_{W}_{D}` | `ferial_days/lent_{W}_{D}.yaml` |
| Easter (`paschaloctave`, then `paschaltime`) | `easter_{W}_{D}` | `ferial_days/easter_{W}_{D}.yaml` |
| Pre-Ascension (Sunday mode) | `easter_6_{D}_before_ascension` | specific ferial content for those 4 days (`D` = 3–6) |
