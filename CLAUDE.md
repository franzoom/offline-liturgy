#CLAUDE.md - Context for Claude Code

<System_context>
  - project: Dart package `offline_liturgy` v2.2.0 — builds a universal Catholic liturgical calendar and resolves all Divine Office content (Morning, Vespers, Readings, Compline, MiddleOfDay)
  - main goal: provide a package for an interface app (Flutter consumer via rootBundle DataLoader)
  - dart SDK: ^3.4.1 | deps: yaml ^3.1.1 | dev: test ^1.31.0, lints ^6.1.0
</System_context>

<Critical_notes>
  ## Easter algorithm — DO NOT TOUCH
  `easter(int year)` in `lib/calendar_management/common_calendar_definitions.dart` uses Meeus/Jones/Butcher algorithm.
  50+ mobile dates derive from it (Ascension, Pentecost, Annunciation transfer, etc.).

  ## Feast priority system (precedence 1–13)
  - 1–3: Solemnities | 4–5: Feasts | 6–9: Obligatory memorials | 10–11: Optional memorials | 12: Commemorations | 13: Ferial days
  - RULE: ferial days (precedence 13) sort BEFORE optional memorials (12) via effectivePrecedence() → 11.5
  - During Avent/Lent/Octaves: memorials 10–11 demoted to 12 via `downgradeMemorialsDuringPrivilegedTimes()`

  ## Feast date transfers
  Mobile-date transfers are computed at date-calculation time in `common_calendar_definitions.dart`,
  not via post-hoc calendar moves. Each function returns the correct date directly:
  - `annunciation()`: transferred if Holy Week or Paschal Octave
  - `saintJoseph()`: transferred if Holy Week
  - `saintJohnTheBaptist()`: shifted if conflicts with Sacred Heart
  - `saintPieterAndPaul()`: shifted if conflicts with Sacred Heart

  Location YAML files may also declare a `move:` section to relocate any feast already
  in the calendar to a different fixed date. This uses `Calendar.moveItemToDate()`,
  which is prefix-agnostic: `roman/`, local, or parent-location feasts can all be moved.

  ## Two liturgical years always built
  `getCalendar()` always builds year N + year N+1 to avoid boundary issues.

  ## DataLoader abstraction
  `FileSystemDataLoader` for CLI/Dart. Flutter consumer must provide its own `DataLoader` using rootBundle.
</Critical_notes>

<Commands>
  dart run test/calendar_output.dart   # generates test/calendar_output.txt (calendar for Lyon, year 2026)
  dart analyze                          # static analysis
  dart format lib/ test/               # format code
  dart pub get                          # install deps
</Commands>

<File_map>
  lib/
    offline_liturgy.dart               # package entry point (exports)
    classes/
      calendar_class.dart              # Calendar + DayContent + FeastDates + F (short alias)
      office_elements_class.dart       # CelebrationContext + all content structs (Psalm, HymnEntry, Reading, Intercession, etc.)
      morning_class.dart               # Morning class with overlayWith() and overlayWithCommon()
      vespers_class.dart               # Vespers class (vespers1=eve / vespers2=day)
      readings_class.dart              # Readings class with year A/B/C patristic support
      compline_class.dart              # Compline class with marialHymnRef
      middle_of_day_class.dart         # MiddleOfDay class (tierce/sexte/none structure)
      location_class.dart              # Location + LocationFeast + LocationGeography + LocationNode + buildLocationTree()
      mass_class.dart                  # Mass structures (MassAntiphon, MassReading, MassGospel, etc.)
    calendar_management/
      common_calendar_definitions.dart # Mobile date calculations: easter(), advent(), epiphany(), createLiturgicalDays()
      main_calendar_fill.dart          # getCalendar() + calendarFill() — fills 2 liturgical years
      location_loader.dart             # LiturgyData (loads common_feasts.yaml + all locations/*.yaml) + buildLocationTree()
    offices/
      office_detection.dart            # detectCelebrations() — central, sorts celebrations by precedence
      morning/                         # morning_detection / morning_extract / ferial_morning_resolution / morning_export
      vespers/                         # vespers_detection / vespers_extract / ferial_vespers_resolution / vespers_export
      readings/                        # readings_detection / readings_extract / ferial_readings_resolution
      compline/                        # compline_detection / compline_extract
      middle_of_day/                   # middle_of_day_detection / ferial_middle_of_day_resolution
      masses/                          # mass structures
    tools/
      data_loader.dart                 # abstract DataLoader + FileSystemDataLoader
      date_tools.dart                  # DateNavigation extension (shift, isSunday, isSameDayAs) + ferialDayCheck() + liturgicalYear() + ferialNameResolution()
      constants.dart                   # file path constants + privilegedTimes set
      extract_week_and_day.dart        # extractWeekAndDay('ot_3_5', season) → [3, 5]
      hymns_management.dart            # getHymnsForSeason(season, dataLoader)
      resolve_office_content.dart      # resolves full office content + short readings
      hierarchical_common_loader.dart  # buildHierarchicalCommon() + loadMorningHierarchicalCommon() etc.
      paschal_antiphon.dart            # post-Easter antiphon management
    assets/ (lib/assets/)
      psalms_library.dart              # getPsalm(key, dataLoader) — loads PSALM_N / OT_N / NT_N
      hymns_library.dart               # getHymn(key, dataLoader)
      gradual_psalms.dart              # mid-day gradual psalms
      french_liturgy_labels.dart       # liturgicalTimeLabels, daysOfWeek maps in French
      usual_texts.dart                 # recurring texts (Te Deum, blessings)
      middle_of_day_antiphons.dart     # mid-day specific antiphons

  assets/ (data files)
    calendar_data/
      common_feasts.yaml               # 200+ universal Roman feasts with month/day/precedence
      ferial_days/                     # ot_N_D.yaml / advent_N_D.yaml / lent_N_D.yaml / easter_N_D.yaml (season_week_day)
      special_days/                    # nativity, holy_thursday, holy_friday, easter, pentecost, advent_17–24, christmas_26–31, etc.
      commons/                         # hierarchical commons: apostles / martyrs / martyrs_male / martyrs_male_priest + seasonal variants (_advent, _lent, _easter)
      complines/                       # compline by weekday + seasonal variants
      sanctoral/                       # individual saint YAML files
    locations/                         # continent → country → diocese → city → church hierarchy YAML files
    hymns/                             # ~60 YAML hymn files (French)
    psalms/                            # PSALM_1–150 + OT_1–43 + NT_1–12 YAML files + hebrew-greek/ (gradual psalms)
    mass_missal/                       # Mass text files

  scripts/                             # Python migration/conversion utilities (maintenance only, not for runtime)
  test/
    calendar_output.dart               # integration test: builds Lyon 2026 calendar → test/calendar_output.txt
</File_map>

<Key_classes>
  ## Calendar / DayContent
  Calendar.addItemToDay(date, prec, key, {knownCodes})    — add/update feast; returns stored key; if knownCodes provided and key absent from index, preserves existing qualified key and only updates precedence
  Calendar.addItemRelatedToFeast(date, shift, prec, key, {knownCodes}) — add at date+shift days; returns stored key
  Calendar.addFeastsToCalendar(feasts, year, mainFeasts)  — bulk add from a FeastDates map
  Calendar.moveItemToDate(feastName, newDate, precedence) — move feast, prefix-agnostic, returns resolved key
  Calendar.downgradeMemorialsDuringPrivilegedTimes()      — called after fill
  DayContent: {liturgicalYear, liturgicalTime, precedence, liturgicalColor, breviaryWeek, feastList: Map<int,List<String>>, feastOrigins}

  ## CelebrationContext (central context for all office resolution)
  Fields: celebrationType, celebrationCode, date, liturgicalTime, breviaryWeek, precedence, teDeum, commonList, liturgicalColor, dataLoader, celebrationOrigin
  Getters: selectedCommon, isFirstVespers, isSecondVespers

  ## Location
  Location.applyToCalendar(calendar, year, mainFeasts)   — applies local feasts
  LocationFeast: {key, month, day, precedence, relativeTo, shift}
  buildLocationTree(locations) → List<LocationNode>       — immutable hierarchy

  ## LiturgyData
  LiturgyData.load()                        — file system (CLI)
  LiturgyData.loadFromDataLoader(loader)    — Flutter
  .locationData: Map<String, Location>
  .locationTree: List<LocationNode>
  .knownCodes: Set<String>                  — all qualified codes present in index.json; passed to addItemToDay for key-preservation logic

  ## Ferial day codes
  Format: `season_week_day`  e.g. `ot_3_5` (ordinary time, week 3, day 5)
  Seasons: ot | advent | christmas | lent | easter
  extractWeekAndDay(code, season) → [week, day]
</Key_classes>

<Liturgical_data_model>
  ## Liturgical seasons (liturgicalTime values)
  advent | nativity | christmasoctave | christmas | lent | holyweek | paschaloctave | easter | ot

  ## Liturgical years
  liturgicalYear(year) → 'A' | 'B' | 'C'  (year % 3 logic)
  Affects: patristic readings (A/B/C), evangelic antiphons

  ## Hierarchical commons resolution
  Common "martyrs_male_priest" + season "lent" → loads sequentially:
  martyrs → martyrs_lent → martyrs_male → martyrs_male_lent → martyrs_male_priest → martyrs_male_priest_lent
  (parallel load, sequential overlay — specific overrides general)

  ## Epiphany / Ascension modes (per location YAML)
  epiphanyDate: 'day' (Jan 6 fixed) | 'sunday' (1st Sunday after Jan 1)
  ascensionDate: 'sunday' (moved to Sunday) | null (Thursday, 39 days after Easter)
</Liturgical_data_model>

<Code_style>
  - language: English for comments and identifiers
  - naming: camelCase for variables and functions, PascalCase for classes
  - format: dart format (not Prettier — Prettier is JS only)
  - prefer 3 separate blocks over a boolean flag inside one loop
</Code_style>
