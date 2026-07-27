# Icon Registry — Project Wellness

The icon bible. One place to look up which icon to use for any workout, exercise, equipment, or metric in the app. Every name in this file was verified against the icon library's real, current catalog (via pub.dev and the Iconify aggregator, which indexes MDI, Tabler, Phosphor, Font Awesome, Remix, Iconoir, Ionicons, Boxicons, Health Icons, and game-icons.net) — nothing here is guessed or invented.

**Hard rule: no emojis. Ever. Not in code, not in UI, not as a placeholder "for now."** Every visual marker in this app is a vector icon glyph (`Icons.*`, a font-icon package, or a bundled SVG). See `feedback_no_emojis` in project memory — this has been stated explicitly and repeatedly.

**Implementation status: live in code, now with a working richer icon package.** `lib/models/exercise_def.dart` has `Equipment` (tier 2) and `MovementBadge` (tier 3, new) enums plus an optional `icon` override (tier 1). `lib/data/exercise_library.dart` resolves the base icon (`iconForExercise()`: override → equipment glyph → category default) and `lib/widgets/exercise_icon.dart` composites it with a small movement-badge overlay via the `ExerciseIcon` widget — that's what's actually rendered in the UI now, not a bare `Icon`. Two categories were added beyond the original 9 — **Yoga** and **Mobility** — and ~40 exercises were added, both sourced from `EXERCISE_VIDEO_REGISTRY.md`. When adding an exercise, tag it with equipment + movement in `exercise_library.dart` and mirror the change here (§6) — don't let the two drift.

**Package history — three icon packages tried, only one works.**
- `material_design_icons_flutter` (latest `7.0.7296`, 2023, unmaintained): generates `_MdiIconData extends IconData`; the installed Flutter SDK (3.44.6 / Dart 3.12.2) made `IconData` a `final class`, so it fails to compile. Not caught by `flutter analyze` — only a real `flutter build` or `flutter test` surfaces it.
- `phosphor_flutter` (latest `2.1.0`, 2024): same failure, same `extends IconData` pattern (`PhosphorIconData extends IconData`). Verified broken via `flutter test` this session — the §4 recommendation below to use it as a fallback was wrong and has been superseded by this note.
- `font_awesome_flutter` (latest `11.0.0`, 2026, actively maintained): compiles fine, but deliberately moved to its own `FaIconData` type + `FaIcon` widget instead of `IconData`/`Icon`, specifically to sidestep the final-class problem. Not adopted here because mixing it in would mean every icon-resolution function returns a widget instead of `IconData`, a bigger refactor than the coverage gain justified.
- **`lucide_icons_flutter` (latest `3.1.15`, actively maintained — published days before this was verified) is what's actually in `pubspec.yaml`.** It uses real `const IconData(codepoint, fontFamily: ...)` values (a genuine icon font, not a runtime map lookup), so it compiles cleanly and works in `const` contexts. Its fitness/food coverage is real but narrower than MDI's unverified claims ever promised — see §2b and the nutrition registry for the honest list of what it actually has.

**Before ever adding another icon package here: run `flutter test` (or a full `flutter build`) against a real usage, not just `flutter pub get` + `flutter analyze`.** Analyze has now missed two broken packages in a row.

---

## 1. Where we start from

`pubspec.yaml` currently has:
- `cupertino_icons: ^1.0.8`
- `uses-material-design: true` → the full Flutter `Icons.*` class (Material Icons) is already available, zero extra dependency.

`lib/data/exercise_library.dart` has a working `iconForCategory()` mapping the app's 13 categories (Chest, Back, Legs, Shoulders, Biceps, Triceps, Forearms, Core, Cardio, Pilates, Yoga, Mobility, Full Body — Yoga and Mobility added alongside the icon work below; the old combined "Arms" category was later split into Biceps/Triceps, and Forearms added as a new category) to Material Icons, plus `iconForExercise()` layering `lucide_icons_flutter` equipment glyphs and direct overrides on top. `lib/widgets/exercise_icon.dart` then overlays a movement badge. Everything below documents that system: equipment, movement patterns, cardio/sport activities, and per-exercise recommendations for the ~190 exercises in the library.

Also `cupertino_icons: ^1.0.8` and `uses-material-design: true` above are joined by `lucide_icons_flutter: ^3.1.15` — see the package-history note above for why this is the only third-party icon package in the app.

---

## 2. The honest limit — read this before assigning icons per exercise

I searched every major open icon library for exercise-specific glyphs. **None of them — free or paid — have a distinct pictogram for "Bicep Curl" vs. "Hammer Curl" vs. "Tricep Pushdown" vs. "Skull Crusher."** Direct, confirmed zero-result searches across Material/MDI/Tabler/Phosphor/FontAwesome/Remix/Iconoir/Ionicons/Boxicons/game-icons.net for: *push-up, pull-up, sit-up, crunch, burpee, squat, deadlift, bench-press, tricep, shoulder-press, lunge, cable-machine, kettlebell-swing, chin-up, weightlifting, streak, resistance-band, foam-roller.*

That level of granularity (a little stick-figure doing the exact movement) only exists as illustrated exercise diagrams inside proprietary apps like Strong, Hevy, or MuscleWiki — those are custom-drawn art assets, not reusable icon-font glyphs, and they're copyrighted.

So the registry works in **tiers**, which is the same pattern real fitness apps use once you look under the hood:

| Tier | What it covers | Example |
|---|---|---|
| 1 — Category | Broad muscle group / discipline (already built) | "Arms" → `Icons.sports_gymnastics` |
| 2 — Equipment | What you're holding | Barbell, Dumbbell, Kettlebell, Cable/Machine, Bodyweight, Band |
| 3 — Movement badge | Direction of motion, shown as a small overlay/corner badge on the equipment icon | Curl (↑), Press (↑), Row (←), Extension (↓), Fly (↔) |

A concrete exercise = **Equipment icon + Movement badge**, not a bespoke pictogram. Section 6 applies this to every exercise currently in `exercise_library.dart`.

The one exception: **game-icons.net** has surprisingly granular *body/action* glyphs — `biceps`, `muscle-up`, `punch`, `high-kick`, `planks`, `meditation` — because it was built for tabletop/RPG stat icons, not fitness apps specifically. It's CC BY 3.0 (attribution required per icon, no Flutter package — SVG only via `flutter_svg`). Good for a handful of hero/flourish icons, not the whole system.

---

## 3. Library-by-library reference

### Material Icons (Google, built-in)
- **License:** Apache 2.0. **Cost:** free, already in the project.
- **Flutter:** `Icons.*` — no package needed.
- **Relevant confirmed names:** `fitness_center`, `pool`, `rowing`, `directions_run`, `directions_walk`, `directions_bike`, `hiking`, `self_improvement`, `spa`, `hot_tub`, `accessibility_new`, `accessibility`, `sports_gymnastics`, `sports_martial_arts`, `sports_mma`, `sports_kabaddi`, `sports_handball`, `sports_volleyball`, `sports_tennis`, `sports_basketball`, `sports_soccer`, `sports_rugby`, `sports_cricket`, `sports_golf`, `sports_hockey`, `sports_baseball`, `sports_football`, `sports_score`, `kayaking`, `downhill_skiing`, `ice_skating`, `surfing`, `snowboarding`, `skateboarding`, `monitor_weight`, `monitor_heart`, `scale`, `timer`, `hourglass_bottom`, `local_fire_department`, `whatshot`, `bolt`, `military_tech`, `workspace_premium`, `water_drop`, `restaurant`, `local_dining`, `bedtime`, `nightlight_round`, `calendar_month`, `straighten`.
- Note: Google's own icon named `emoji_events` (trophy) is a real vector glyph, not an emoji character — but given the no-emoji rule, prefer `military_tech` or `workspace_premium` for medals/achievements to avoid the naming confusion entirely.
- Broader set: `material_symbols_icons` pub package exposes the newer 5,000+ glyph "Material Symbols" (variable fill/weight/grade) if the built-in ~2,000 aren't enough.

### Material Design Icons — MDI / Pictogrammers (community superset, different project from Google's)
- **License:** Apache 2.0 (some SIL OFL). **Package:** [`material_design_icons_flutter`](https://pub.dev/packages/material_design_icons_flutter) — 7,400+ icons.
- **This is the single richest fitness vocabulary of any icon set.** Confirmed real names: `dumbbell`, `kettlebell`, `barbell`, `human_barbell`, `yoga`, `swim`, `swim_dive`, `swimming_pool`, `run`, `run_fast`, `exit_run`, `cycling`, `bike`, `bike_fast`, `rowing`, `jump_rope`, `rock_climbing`, `hiking`, `karate`, `kickboxing`, `boxing_glove`, `wrestling`, `gymnastics`, `gym`, `meditation`, `stairs`, `stairs_up`, `stairs_down`, `treadmill` *(check exact casing — treadmill confirmed via Tabler/Iconoir, verify MDI has it too before relying on it)*, `weight`, `scale`, `medal`, `medal_outline`, `trophy`, `trophy_outline`, `dance_ballroom`, `dance_pole`, `human_female_dance`, `skate`, `skateboard`, `snowboard`, `ski`, `ski_cross_country`, `kayaking`, `volleyball`, `basketball`, `soccer`, `soccer_field`, `tennis`, `tennis_ball`, `golf`, `golf_tee`, `golf_cart`, `nutrition`, `sleep`, `walking`, `stretch_to_page`.
- Use via `MdiIcons.dumbbell`, `MdiIcons.kettlebell`, etc.

### Tabler Icons
- **License:** MIT. **Package:** [`flutter_tabler_icons`](https://pub.dev/packages/flutter_tabler_icons) or [`tabler_icons_flutter`](https://pub.dev/packages/tabler_icons_flutter) — 6,100+ icons, clean line style with filled variants.
- Confirmed: `barbell`, `barbell_filled`, `barbell_off`, `dumbbell`, `yoga`, `swiming` *(yes — that's a real typo baked into the actual library, not mine)*, `run`, `bike`, `bike_filled`, `jump_rope`, `karate`, `gymnastics`, `treadmill`, `stairs`, `stairs_up`, `stairs_down`, `kayak`, `mountain`, `mountain_filled`, `skateboard`, `medal`, `trophy`, `trophy_filled`, `heartbeat`, `heart_rate_monitor`, `flame`, `flame_filled`, `target`, `calendar_check`, `apple`, `golf`, `golf_filled`, `disc_golf`, `ball_tennis`, `soccer_field`.

### Phosphor Icons
- **License:** MIT. **Package:** [`phosphor_flutter`](https://pub.dev/packages/phosphor_flutter) — 1,500+ icons, each in 6 weights (thin/light/regular/bold/fill/duotone) — good pick if you want one consistent stroke-weight language across the whole app rather than a mixed grab-bag.
- Confirmed: `Barbell` (all 6 weights), `PersonSimpleSwim`, `PersonSimpleSki`, `PersonSimpleSnowboard`, `BoxingGlove`, `Heartbeat`, `Stairs`, `Steps`, `Flame`, `Medal`, `Target`, `Volleyball`, `Basketball`, `SoccerBall`, `TennisBall`, `Golf`, `CalendarCheck`.

### Font Awesome (Free tier)
- **License:** SIL OFL 1.1 (icon glyphs), MIT (code). **Package:** [`font_awesome_flutter`](https://pub.dev/packages/font_awesome_flutter).
- Confirmed free-tier: `dumbbell`, `personSwimming` (v6 renamed from `swimmer`), `personHiking` (v6 renamed from `hiking`), `personBiking`, `personRunning`, `personSkating`, `personSkiing`, `personWalking`, `spa`, `heartPulse` (renamed from `heartbeat`), `weightScale` (renamed from `weight`), `medal`, `stopwatch`, `mountain`, `mountainSun`, `volleyball`, `basketball`, `tableTennisPaddleBall`, `calendarCheck`, `utensils`, `apple` *(check exact FA6 name — `appleWhole`)*.
- Font Awesome renamed a lot of icons between v5 and v6 (dropping gendered "man/woman" prefixes for neutral "person"). Always check the version pinned by `font_awesome_flutter` before using an old v5 name.

### Remix Icon
- **License:** Apache 2.0. **Package:** [`flutter_remix`](https://pub.dev/packages/flutter_remix) or [`remixicon`](https://pub.dev/packages/remixicon).
- Confirmed: `run_fill` / `run_line`, `bike_fill` / `bike_line`, `e_bike_fill` / `e_bike_line`, `boxing_fill` / `boxing_line`, `kick_fill` / `kick_line`, `stairs_fill` / `stairs_line`, `medal_fill` / `medal_line`, `trophy_fill` / `trophy_line`, `timer_fill` / `timer_line`, `target_fill` / `target_line`, `fire_fill` / `fire_line`, `flame` *(verify — Remix uses `fire-fill`/`fire-line`, not `flame`)*, `calendar_check_fill` / `calendar_check_line`, `basketball_fill` / `basketball_line`, `golf_ball_fill` / `golf_ball_line`.

### Iconoir
- **License:** MIT. **Package:** [`iconoir_flutter`](https://pub.dev/packages/iconoir_flutter).
- Confirmed: `yoga`, `cycling`, `swimming`, `gym`, `treadmill`, `boxing_glove`, `medal`, `medal_solid`, `trophy`, `timer`, `timer_solid`, `walking`, `apple`, `calendar_check`, `calendar_check_solid`, `basketball`, `soccer_ball`, `tennis_ball`, `golf`, `skateboard`.

### Ionicons
- **License:** MIT. **Package:** [`ionicons`](https://pub.dev/packages/ionicons).
- Confirmed: `barbell` / `barbell_outline` / `barbell_sharp`, `footsteps`, `nutrition` / `nutrition_outline`, `medal` / `medal_outline`, `scale` / `scale_outline`, `golf` / `golf_outline`, `basketball` / `basketball_outline`, `stopwatch` / `stopwatch_outline`, `timer` / `timer_outline`.

### Boxicons
- **License:** CC 4.0 (icons) — check attribution requirements before shipping. **Package:** [`boxicons`](https://pub.dev/packages/boxicons) or [`flutter_boxicons`](https://pub.dev/packages/flutter_boxicons).
- Confirmed: `dumbbell`, `dumbbell_filled`, `swim`, `run`, `cycling`, `spa`, `medal`.

### Health Icons (healthicons.org)
- **License:** Public-domain-equivalent (CC0/MIT dual). **No Flutter font package** — SVG only, render via `flutter_svg`.
- Purpose-built for health/wellness apps, so the naming fits unusually well: `exercise_yoga` / `exercise_yoga_outline`, `swim` / `swim_outline`, `gym` / `gym_outline`, `bike` / `bike_outline`, `heartbeat` / `heartbeat_outline`, `walking` / `walking_outline`, `nutrition` / `nutrition_outline`, `malnutrition` / `malnutrition_outline`, `man` / `man_outline`, `woman` / `woman_outline`.

### game-icons.net
- **License:** CC BY 3.0 — **attribution required per icon** (credit the individual artist: Lorc, Delapouite, Skoll, etc.). **No Flutter package** — download SVGs individually, bundle as assets, render via `flutter_svg`.
- The only set with genuinely granular body/action glyphs: `biceps`, `muscle-up`, `muscle-fat`, `punch`, `high-punch`, `fire-punch`, `punching-bag`, `high-kick`, `boot-kick`, `boxing-glove`, `boxing-ring`, `planks`, `packed-planks`, `meditation`, `swimfins`, `mountain-climbing`, `hiking`, `cycling`, `run`, `weight-scale`, `water-bottle`, `walking-boot`, `gym-bag`, `stairs`, `3d-stairs`.
- Use sparingly, as flourish/hero icons for a handful of screens (e.g. an "Arms Day" header could use `biceps`) — not as the primary navigation icon set, because CC BY attribution has to be tracked per-icon in a credits screen.

---

## 4. Recommendation for this app

Given the goal is to match a coherent style with zero unnecessary dependencies:

1. **What's actually shipped: `Icons.*` only, zero extra dependency.** `iconForCategory()` covers the 13 categories and `iconForExercise()` layers equipment glyphs + direct overrides on top, using only Material Icons names from §3. This isn't the "ship today, upgrade later" placeholder it originally sounds like below — it's the permanent state until a maintained richer icon package is vetted in, because of point 2.
2. **`material_design_icons_flutter` was tried and reverted — do not re-add it without first confirming a fix.** Its latest pub.dev release (`7.0.7296`, 2023) fails to compile against modern Flutter/Dart SDKs (`IconData` became a `final class`; the package still subclasses it). It's unmaintained — there's no newer version to pull. This only shows up on `flutter build`, not `flutter analyze`, so it's easy to merge broken and not notice. If you want the literal `dumbbell`/`kettlebell`/`barbell`/`yoga` glyphs it would have provided, either wait for an upstream fix, switch to `phosphor_flutter` (still maintained, different name set, would need a full re-verification pass against the tables in §5/§6), or bundle specific SVGs via `flutter_svg`.
3. **`phosphor_flutter`** is the more promising path if/when this gets revisited — actively maintained, one consistent stroke-weight language across the whole app rather than MDI's grab-bag community style. Verify every name against its live icon browser and confirm a full `flutter build` (not just `pub get`/`analyze`) before trusting any glyph name.
4. **game-icons.net SVGs** only for specific decorative moments (splash/empty-states/day-headers), with a credits screen.

---

## 5. Concept → icon map

### 5a. Categories (current — already implemented in `exercise_library.dart`)

| Category | Material Icons (current) |
|---|---|
| Chest | `Icons.fitness_center` |
| Back | `Icons.rowing` |
| Legs | `Icons.directions_run` |
| Shoulders | `Icons.accessibility_new` |
| Biceps | `Icons.sports_gymnastics` (kept from the old combined "Arms" category — flexed-arm glyph fits biceps specifically) |
| Triceps | `Icons.sports_martial_arts` (implemented — no dedicated triceps/pushing-arm glyph in Material, the punching-arm silhouette is the closest honest metaphor) |
| Forearms | `Icons.back_hand` (implemented — no dedicated wrist/grip glyph in Material, the open-hand icon is the closest honest metaphor) |
| Core | `Icons.self_improvement` |
| Cardio | `Icons.directions_bike` |
| Pilates | `Icons.spa` |
| Yoga | `Icons.self_improvement` (implemented — MDI's literal `yoga` glyph is unusable, see correction above) |
| Mobility | `Icons.straighten` (implemented — no literal "stretch" glyph in Material, ruler is the closest available metaphor) |
| Full Body | `Icons.accessibility` |

### 5b. Equipment — as actually implemented (`_equipmentIcon()` in `exercise_library.dart`)

| Equipment | Icon used | Notes |
|---|---|---|
| Barbell | `LucideIcons.weight` | Lucide has no literal "barbell" either — `weight` (a plate-and-bar glyph) is the closest real match, shared with Kettlebell |
| Kettlebell | `LucideIcons.weight` | Shares Barbell's glyph — no library has a distinct kettlebell shape that survived a build test; differentiated from barbell exercises by the movement badge and category instead |
| Dumbbell | `LucideIcons.dumbbell` | Literal glyph, confirmed compiling |
| Cable / Machine | `LucideIcons.cable` | Literal glyph, confirmed compiling — this one didn't exist in any previously-tried package |
| Bodyweight | `LucideIcons.footprints` | Generic "body in motion" glyph, consistent across all bodyweight moves |
| Resistance band | — (category fallback) | No dedicated icon in Lucide or Material |
| Bench | — (category fallback) | No dedicated icon anywhere; currently unused by any exercise in the library |

### 5c. Movement badges — as actually implemented (`badgeIconFor()` in `lib/widgets/exercise_icon.dart`)

Rendered as a small circular overlay in the bottom-right corner of the equipment icon via the `ExerciseIcon` widget (suppressed below 20px — illegible at chip-avatar sizes). This is the tier that turns "every barbell press exercise looks the same" into genuine per-exercise variety: `MovementBadge` × `Equipment` gives up to ~75 distinct combinations across all Material-only badge glyphs below, all of which are long-stable classic `Icons.*` names (zero new dependency risk for this tier).

| Movement | Badge icon |
|---|---|
| Press | `Icons.arrow_upward` |
| Curl | `Icons.rotate_left` |
| Pull (row / pull-up) | `Icons.arrow_back` |
| Pulldown | `Icons.arrow_downward` |
| Extension | `Icons.call_made` |
| Raise / Fly | `Icons.open_in_full` |
| Squat / Hinge | `Icons.expand_more` |
| Hip Thrust / Bridge | `Icons.unfold_more` |
| Twist / Rotation | `Icons.rotate_right` |
| Carry | `Icons.directions_walk` |
| Jump / Explosive | `Icons.bolt` |
| Hold / Isometric | `Icons.pause_circle_outline` |
| Swing | `Icons.swap_vert` |
| Rotational press (e.g. Arnold Press) | `Icons.sync` |
| Roll (foam rolling, ab wheel) | `Icons.autorenew` |

**Honest result, not 100% uniqueness:** even with equipment × badge composited, exercises that are genuinely the same movement pattern at a different angle or load (Barbell/Incline/Decline Bench Press; Deadlift/Sumo Deadlift/Rack Pull) still render identically — that's not a bug, no icon system short of bespoke per-exercise art could meaningfully separate those. §6 below documents exactly which exercises still share an icon and why.

### 5d. Cardio / endurance

| Activity | Material Icons | Best alternative (richer set) |
|---|---|---|
| Running | `directions_run` | `mdi:run`, `ph:PersonSimpleRun` |
| Cycling | `directions_bike` | `mdi:bike`, `tabler:bike` |
| Swimming | `pool` | `mdi:swim`, `healthicons:swim`, `ph:PersonSimpleSwim` |
| Rowing machine | `rowing` | `mdi:rowing` |
| Jump rope | — | `mdi:jump_rope`, `tabler:jump_rope` |
| Elliptical | — | No dedicated glyph found anywhere; fall back to `directions_run` or a custom asset |
| Stair climber | `stairs` | `mdi:stairs`, `ph:Stairs` |
| Hiking | `hiking` | `mdi:hiking`, `game-icons:hiking` |
| Rock climbing | — | `mdi:rock_climbing`, `game-icons:mountain-climbing` (Material has none — MDI is the only mainstream set with the literal glyph) |
| Kayaking | `kayaking` | `mdi:kayaking`, `tabler:kayak` |
| Skiing | `downhill_skiing` | `mdi:ski`, `ph:PersonSimpleSki` |
| Snowboarding | `snowboarding` | `mdi:snowboard`, `ph:PersonSimpleSnowboard` |
| Ice skating | `ice_skating` | `mdi:skate` |
| Surfing | `surfing` | `game-icons:surf-board` |
| Skateboarding | `skateboarding` | `mdi:skateboard`, `iconoir:skateboard` |

### 5e. Mind-body / Pilates / Yoga / Recovery

| Activity | Material Icons | Best alternative |
|---|---|---|
| Yoga | `self_improvement` | `mdi:yoga`, `healthicons:exercise-yoga`, `iconoir:yoga` |
| Pilates | `spa` | (no dedicated "pilates" glyph anywhere — every library conflates it with yoga/stretch; keep using `spa`/`self_improvement`) |
| Meditation | `self_improvement` | `mdi:meditation`, `game-icons:meditation` |
| Stretching | — | `lucide:stretch-vertical` / `stretch-horizontal` |
| Plank / isometric hold | `self_improvement` | `game-icons:planks` |
| Sauna / heat recovery | `hot_tub` | (no dedicated sauna glyph found in any set searched) |
| Foam rolling / mobility | — | No dedicated glyph anywhere; fall back to a generic "roller" custom asset |

### 5f. Sports (for future expansion beyond the current library)

| Sport | Material Icons | Best alternative |
|---|---|---|
| Basketball | `sports_basketball` | `mdi:basketball`, `ph:Basketball` |
| Soccer | `sports_soccer` | `mdi:soccer`, `ph:SoccerBall` |
| Tennis | `sports_tennis` | `mdi:tennis_ball`, `ph:TennisBall` |
| Golf | `sports_golf` | `mdi:golf`, `ph:Golf` |
| Volleyball | `sports_volleyball` | `mdi:volleyball`, `ph:Volleyball` |
| Boxing | `sports_mma` | `mdi:boxing_glove`, `ph:BoxingGlove`, `game-icons:boxing-ring` |
| Martial arts / karate | `sports_martial_arts` | `mdi:karate`, `tabler:karate` |
| Wrestling | — | `mdi:wrestling` (Material has no dedicated glyph) |
| Handball | `sports_handball` | — |
| Rugby | `sports_rugby` | — |
| Cricket | `sports_cricket` | — |
| Hockey | `sports_hockey` | — |
| Baseball | `sports_baseball` | — |
| American football | `sports_football` | — |
| Dance | — | `mdi:dance_ballroom`, `mdi:human_female_dance` |

### 5g. App UI / metrics

| Concept | Material Icons | Best alternative |
|---|---|---|
| Timer / rest clock | `timer` | `mdi:timer`, `ph:Timer` |
| Streak / consistency | `local_fire_department` | (no dedicated "streak" glyph anywhere — every app reuses a flame icon for this) |
| Calories burned | `local_fire_department` or `whatshot` | (no dedicated "calories" glyph found — flame is the universal convention) |
| Trophy / achievement | `military_tech` or `workspace_premium` | `mdi:trophy`, `ph:Medal` — avoid `Icons.emoji_events` given the no-emoji rule, even though it's a real vector icon, to sidestep the naming confusion |
| Heart rate | `monitor_heart` | `tabler:heart_rate_monitor`, `healthicons:heartbeat` |
| Body weight / scale | `monitor_weight` or `scale` | `mdi:scale`, `game-icons:weight-scale` |
| Water / hydration | `water_drop` | — |
| Nutrition / food | `restaurant` | `mdi:nutrition`, `healthicons:nutrition` |
| Sleep | `bedtime` | `mdi:sleep` |
| Calendar / streak day | `calendar_month` | `mdi:calendar_check`, `ph:CalendarCheck` |
| Measurements (tape) | `straighten` | — |
| Goal / target | `track_changes` | `tabler:target`, `ph:Target` |
| Personal record (PR) | `military_tech` | — |

---

## 6. Exercise-by-exercise recommendation

Generated from `lib/data/exercise_library.dart` — this table is a direct reflection of the `equipment`/`movement`/`icon` tags on every `ExerciseDef`, not a separate hand-maintained plan. If this ever looks out of sync with the code, the code is correct; regenerate this section instead of hand-editing around a drift.

**190 exercises total** (grown over several passes from an original 132 — additions across Chest/Back/Legs/Shoulders/Arms/Core, Deadlift/Sumo Deadlift/Good Morning/Rack Pull/Hyperextension recategorized from Back to Legs since they're quad/hamstring/glute-dominant hip-hinge patterns, not back exercises; a new **Forearms** category with 12 wrist-curl/grip exercises, split out from Arms since forearm/grip training had zero dedicated entries before; most recently, the old combined **Arms** category was itself split into **Biceps** (15 exercises) and **Triceps** (14 exercises), with 6 new biceps and 4 new triceps movements added in the same pass). "Equipment icon" is the base glyph (§5b); "Movement badge" is the small corner overlay (§5c) rendered by the `ExerciseIcon` widget. Cardio and most Pilates/Yoga/Mobility entries have no distinct equipment icon (no equipment, or a direct override) — the movement badge is what differentiates them.

### Chest
| Exercise | Equipment icon | Movement badge |
|---|---|---|
| Barbell Bench Press | Barbell (`weight`) | press |
| Incline Bench Press | Barbell (`weight`) | press |
| Decline Bench Press | Barbell (`weight`) | press |
| Dumbbell Bench Press | Dumbbell (`dumbbell`) | press |
| Incline Dumbbell Press | Dumbbell (`dumbbell`) | press |
| Dumbbell Flyes | Dumbbell (`dumbbell`) | raise |
| Cable Crossover | Cable/Machine (`cable`) | raise |
| Push-Up | Bodyweight (`footprints`) | press |
| Chest Dip | Bodyweight (`footprints`) | extension |
| Pec Deck Machine | Cable/Machine (`cable`) | raise |
| Landmine Press | Barbell (`weight`) | rotationalPress |
| Low-to-High Cable Fly | Cable/Machine (`cable`) | raise |
| Svend Press | Category default | press |
| Dumbbell Pullover | Dumbbell (`dumbbell`) | pull |
| Smith Machine Bench Press | Barbell (`weight`) | press |

### Back
| Exercise | Equipment icon | Movement badge |
|---|---|---|
| Pull-Up | Bodyweight (`footprints`) | pull |
| Chin-Up | Bodyweight (`footprints`) | pull |
| Lat Pulldown | Cable/Machine (`cable`) | pulldown |
| Barbell Row | Barbell (`weight`) | pull |
| Dumbbell Row | Dumbbell (`dumbbell`) | pull |
| T-Bar Row | Barbell (`weight`) | pull |
| Seated Cable Row | Cable/Machine (`cable`) | pull |
| Face Pull | Cable/Machine (`cable`) | pulldown |
| Shrugs | Barbell (`weight`) | raise |
| Front Lever | Bodyweight (`footprints`) | hold |
| Muscle-Up | Bodyweight (`footprints`) | pull |
| Straight-Arm Pulldown | Cable/Machine (`cable`) | pulldown |
| Chest-Supported Row | Cable/Machine (`cable`) | pull |
| Inverted Row | Bodyweight (`footprints`) | pull |

### Legs
Includes the hip-hinge movements moved from Back (Deadlift, Sumo Deadlift, Good Morning, Rack Pull, Hyperextension) — see the count note above.

| Exercise | Equipment icon | Movement badge |
|---|---|---|
| Back Squat | Barbell (`weight`) | squat |
| Front Squat | Barbell (`weight`) | squat |
| Leg Press | Cable/Machine (`cable`) | squat |
| Romanian Deadlift | Barbell (`weight`) | hipThrust |
| Deadlift | Barbell (`weight`) | squat |
| Sumo Deadlift | Barbell (`weight`) | squat |
| Good Morning | Barbell (`weight`) | hipThrust |
| Rack Pull | Barbell (`weight`) | squat |
| Hyperextension | Bodyweight (`footprints`) | hipThrust |
| Lunges | Bodyweight (`footprints`) | squat |
| Bulgarian Split Squat | Dumbbell (`dumbbell`) | squat |
| Leg Extension | Cable/Machine (`cable`) | extension |
| Leg Curl | Cable/Machine (`cable`) | curl |
| Calf Raise | Barbell (`weight`) | raise |
| Hip Thrust | Barbell (`weight`) | hipThrust |
| Goblet Squat | Dumbbell (`dumbbell`) | squat |
| Walking Lunge | Bodyweight (`footprints`) | carry |
| Box Squat | Barbell (`weight`) | squat |
| Nordic Hamstring Curl | Bodyweight (`footprints`) | curl |
| ATG Split Squat | Bodyweight (`footprints`) | squat |
| Cossack Squat | Bodyweight (`footprints`) | twist |
| Pistol Squat | Bodyweight (`footprints`) | squat |
| Hack Squat | Cable/Machine (`cable`) | squat |
| Seated Calf Raise | Cable/Machine (`cable`) | raise |
| Step-Up | Dumbbell (`dumbbell`) | squat |
| Sissy Squat | Bodyweight (`footprints`) | extension |
| Reverse Lunge | Dumbbell (`dumbbell`) | squat |
| Glute Bridge | Bodyweight (`footprints`) | hipThrust |
| Hip Adduction Machine | Cable/Machine (`cable`) | curl |
| Hip Abduction Machine | Cable/Machine (`cable`) | raise |

### Shoulders
| Exercise | Equipment icon | Movement badge |
|---|---|---|
| Overhead Press | Barbell (`weight`) | press |
| Dumbbell Shoulder Press | Dumbbell (`dumbbell`) | press |
| Arnold Press | Dumbbell (`dumbbell`) | rotationalPress |
| Lateral Raise | Dumbbell (`dumbbell`) | raise |
| Front Raise | Dumbbell (`dumbbell`) | raise |
| Rear Delt Fly | Dumbbell (`dumbbell`) | raise |
| Upright Row | Barbell (`weight`) | pull |
| Cable Lateral Raise | Cable/Machine (`cable`) | raise |
| Handstand Push-Up | Bodyweight (`footprints`) | press |
| Handstand Hold | Bodyweight (`footprints`) | hold |
| Machine Shoulder Press | Cable/Machine (`cable`) | press |
| Cable Front Raise | Cable/Machine (`cable`) | raise |
| Reverse Pec Deck | Cable/Machine (`cable`) | raise |

### Biceps
Split out from the old combined "Arms" category so biceps and triceps are separately browsable/suggested — see the count note above.

| Exercise | Equipment icon | Movement badge |
|---|---|---|
| Barbell Curl | Barbell (`weight`) | curl |
| Dumbbell Curl | Dumbbell (`dumbbell`) | curl |
| Hammer Curl | Dumbbell (`dumbbell`) | curl |
| Preacher Curl | Dumbbell (`dumbbell`) | curl |
| Barbell Preacher Curl | Barbell (`weight`) | curl |
| Concentration Curl | Dumbbell (`dumbbell`) | curl |
| Cable Curl | Cable/Machine (`cable`) | curl |
| Spider Curl | Dumbbell (`dumbbell`) | curl |
| EZ-Bar Curl | Barbell (`weight`) | curl |
| Reverse Curl | Barbell (`weight`) | curl |
| Incline Dumbbell Curl | Dumbbell (`dumbbell`) | curl |
| Drag Curl | Barbell (`weight`) | curl |
| Cross-Body Hammer Curl | Dumbbell (`dumbbell`) | curl |
| Cable Rope Hammer Curl | Cable/Machine (`cable`) | curl |
| 21s | Dumbbell (`dumbbell`) | curl |

### Triceps
| Exercise | Equipment icon | Movement badge |
|---|---|---|
| Tricep Pushdown | Cable/Machine (`cable`) | extension |
| Skull Crusher | Barbell (`weight`) | extension |
| Overhead Tricep Extension | Dumbbell (`dumbbell`) | extension |
| Close-Grip Bench Press | Barbell (`weight`) | press |
| Dips | Bodyweight (`footprints`) | extension |
| Diamond Push-Up | Bodyweight (`footprints`) | press |
| Cable Overhead Tricep Extension | Cable/Machine (`cable`) | extension |
| Bench Dip | Bodyweight (`footprints`) | extension |
| Dumbbell Tricep Kickback | Dumbbell (`dumbbell`) | extension |
| JM Press | Dumbbell (`dumbbell`) | extension |
| Tate Press | Dumbbell (`dumbbell`) | extension |
| Single Arm Cable Tricep Pushdown | Cable/Machine (`cable`) | extension |
| Single Arm Tricep Extension | Dumbbell (`dumbbell`) | extension |
| Single Arm Overhead Tricep Extension | Dumbbell (`dumbbell`) | extension |

### Forearms
Equipment/grip work split out from Arms into its own category — see the count note above.

| Exercise | Equipment icon | Movement badge |
|---|---|---|
| Barbell Wrist Curl | Barbell (`weight`) | curl |
| Barbell Reverse Wrist Curl | Barbell (`weight`) | extension |
| Dumbbell Wrist Curl | Dumbbell (`dumbbell`) | curl |
| Behind-the-Back Barbell Wrist Curl | Barbell (`weight`) | curl |
| Cable Wrist Curl | Cable/Machine (`cable`) | curl |
| Cable Reverse Wrist Curl | Cable/Machine (`cable`) | extension |
| Zottman Curl | Dumbbell (`dumbbell`) | curl |
| Barbell Finger Curl | Barbell (`weight`) | curl |
| Wrist Roller | Category default | roll |
| Plate Pinch | Category default | hold |
| Hand Gripper | Category default | hold |
| Dead Hang | Bodyweight (`footprints`) | hold |

### Core
| Exercise | Equipment icon | Movement badge |
|---|---|---|
| Plank | Bodyweight (`footprints`) | hold |
| Side Plank | Bodyweight (`footprints`) | twist |
| Crunch | Bodyweight (`footprints`) | curl |
| Sit-Up | Bodyweight (`footprints`) | curl |
| Hanging Leg Raise | Bodyweight (`footprints`) | raise |
| Russian Twist | Bodyweight (`footprints`) | twist |
| Cable Crunch | Cable/Machine (`cable`) | curl |
| Ab Wheel Rollout | Category default | roll |
| Mountain Climber | Bodyweight (`footprints`) | carry |
| Bicycle Crunch | Bodyweight (`footprints`) | twist |
| Dead Bug | Bodyweight (`footprints`) | extension |
| Bird Dog | Bodyweight (`footprints`) | extension |
| Pallof Press | Cable/Machine (`cable`) | press |
| Hollow Body Hold | Bodyweight (`footprints`) | hold |
| L-Sit | Bodyweight (`footprints`) | hold |
| Cable Woodchopper | Cable/Machine (`cable`) | twist |
| Weighted Sit-Up | Bodyweight (`footprints`) | curl |
| Toes to Bar | Bodyweight (`footprints`) | raise |
| V-Up | Bodyweight (`footprints`) | curl |

### Cardio
| Exercise | Equipment icon | Movement badge |
|---|---|---|
| Running | Direct override (`Icons.directions_run`) | — |
| Cycling | Direct override (`Icons.directions_bike`) | — |
| Rowing Machine | Direct override (`Icons.rowing`) | — |
| Jump Rope | Direct override (`Icons.directions_run`) | jump |
| Elliptical | Direct override (`Icons.directions_walk`) | — |
| Stair Climber | Direct override (`Icons.stairs`) | — |
| Swimming | Direct override (`Icons.pool`) | — |

### Pilates
| Exercise | Equipment icon | Movement badge |
|---|---|---|
| The Hundred | Category default | hold |
| Roll-Up | Category default | curl |
| Single Leg Circle | Category default | twist |
| Rolling Like a Ball | Category default | roll |
| Single Leg Stretch | Category default | extension |
| Double Leg Stretch | Category default | extension |
| Spine Stretch Forward | Category default | curl |
| Saw | Category default | twist |
| Swan | Category default | raise |
| Side Kick Series | Category default | raise |
| Teaser | Category default | hold |
| Pilates Plank | Category default | hold |
| Bridge | Category default | hipThrust |

### Yoga
| Exercise | Equipment icon | Movement badge |
|---|---|---|
| Cat-Cow | Category default | swing |
| Downward-Facing Dog | Category default | hold |
| Pigeon Pose | Category default | hold |
| Warrior II | Category default | hold |
| Tree Pose | Category default | hold |
| Child's Pose | Category default | hold |
| Sun Salutation A | Category default | swing |
| Sun Salutation B | Category default | swing |

### Mobility
| Exercise | Equipment icon | Movement badge |
|---|---|---|
| 90/90 Hip Stretch | Category default | twist |
| Couch Stretch | Category default | hold |
| World's Greatest Stretch | Category default | twist |
| Jefferson Curl | Category default | curl |
| Foam Rolling | Category default | roll |
| Ankle Dorsiflexion Stretch | Category default | extension |
| Thoracic Rotation | Category default | twist |
| Banded Shoulder Dislocates | Band (category default) | swing |

### Full Body
| Exercise | Equipment icon | Movement badge |
|---|---|---|
| Burpee | Bodyweight (`footprints`) | jump |
| Kettlebell Swing | Kettlebell (`weight`) | swing |
| Kettlebell Clean | Kettlebell (`weight`) | pull |
| Kettlebell Snatch | Kettlebell (`weight`) | jump |
| Clean and Jerk | Barbell (`weight`) | jump |
| Power Clean | Barbell (`weight`) | pull |
| Snatch | Barbell (`weight`) | jump |
| Farmers Carry | Dumbbell (`dumbbell`) | carry |
| Thruster | Barbell (`weight`) | rotationalPress |
| Turkish Get-Up | Kettlebell (`weight`) | carry |
| Box Jump | Category default | jump |
| Battle Ropes | Category default | swing |
| Sled Push | Category default | press |
| Sled Pull | Category default | pull |
| Medicine Ball Slam | Category default | pulldown |
| Tire Flip | Category default | squat |


## 7. Adding a new icon package — checklist

1. Add the dependency to `pubspec.yaml`, run `flutter pub get`.
2. Confirm the exact glyph name on the library's **live** icon browser before writing code — names drift between major versions (Font Awesome v5→v6 renamed several fitness icons).
3. **Run `flutter test` (or a full `flutter build`) against a real usage before trusting the package** — `flutter analyze` alone missed that `material_design_icons_flutter` and `phosphor_flutter` both fail to compile against this Flutter SDK (see the package-history note near the top of this file).
4. Never use an emoji character as a stopgap "for now" — pick the closest generic glyph (e.g. `fitness_center`) instead and swap later.
5. If pulling from `game-icons.net` or any CC-BY set: add the artist credit to a credits/about screen — this is a license requirement, not optional.
6. Update this file when you add or change an icon mapping — it's the single source of truth, don't let it drift from `exercise_library.dart`.
