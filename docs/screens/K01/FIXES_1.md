# Fix list after iteration 1

## From 3_test.md
# K01 · Who's playing? — Stage 3 (TEST, iteration 1)

Route `/who-is-playing` · feature `kid_home` · branch `screen/K01`.
No production code edited: every finding below is recorded, not patched
(RULES §1 keeps this stage inside `app/test/features/kid_home/**` and
`docs/screens/K01/**`).

## 0. Baseline hygiene first

`screen/K01` was three commits behind `main`, and the K03 tests in the same
directory were red on the stale tree (20 failures in `kid_home_view_test.dart`,
8 in `k03_bugs_test.dart`). `git merge main` cleared every one of them — they
were the `shared/test_clock` casualties `main` had already fixed, not K01
regressions. After the merge the whole `kid_home` directory is green
(204 tests). Recording it so the next stage does not re-investigate.

## 1. Tests added (78 new, all in `app/test/features/kid_home/`)

| File | Tests | What it owns |
|---|---|---|
| `k01_copy_parity_test.dart` | 13 (11 green, **2 red — BUG-A**) | Copy is READ from `design/html-source/screens/K01-profile-picker.html` and compared byte-for-byte; the design CSS numbers the geometry tests transcribe; the shared type scale; `letterSpacing == 0`; no money/coins/dates |
| `k01_copy_fit_test.dart` | 7 green | Copy FIT at the app's **real** bundled Nunito/Inter metrics, 320/390/430 × 1.0/1.3 |
| `k01_profile_picker_matrix_test.dart` | 46 green | 320/390/430 × light/dark × scale 1.0/1.3; 20 px gutters + alignment; tap targets; semantics labels + real effects; every tap's route; loading / failure / empty; dark tokens; bottom edge (painted pixels) |
| `k01_bloc_paths_test.dart` | 12 green | The bloc paths the shared `kid_home_bloc_test.dart` K01 group did not cover |

Existing K01 coverage re-run and still green: `k01_profile_picker_view_test.dart`
(13), `k01_profile_picker_geometry_test.dart` (4), `kid_home_bloc_test.dart` K01
group (7), `kid_home_repository_test.dart` (2).

### 1.1 Bloc paths newly covered (`k01_bloc_paths_test.dart`)

`KidHomeProfilesRequested` before any load · repeated profile requests do not
stack a subscription · a profiles listen failure with nothing on screen becomes
`failure` · a mid-session roster error RELEASES the subscription so the retry
really reloads (2 subs) · `KidHomeLoadRequested` publishes `loading` exactly
once, then `loaded` · a reload while live is ignored (1 home + 1 roster sub) ·
a roster push keeps status/child/items · a roster push does NOT consume a
pending selection · the selection one-shot IS consumed by the next **home**
emission · `props` include `profiles` + `selectedProfileId` · an empty roster
is a loaded state, not a failure · every K01 field the tile reads survives the
bloc round-trip.

### 1.2 Widget paths newly covered (`k01_profile_picker_matrix_test.dart`)

- 320/390/430 × light/dark × text scale 1.0/1.3 — all six strings present,
  `takeException()` null, **20 px gutters on both edges**, equal-width tiles,
  16 px gap, shared top/bottom edges, lock on the same right edge as the
  cards, and no paragraph escaping the gutters.
- Compact metrics at 320 (tile 132, avatar 64, Pip 80) and the design metrics
  at 390/430 (avatar 96, Pip 112).
- **Tap targets**: every tile and the lock ≥ `NestDevice.tapKid` (56) at all
  three widths; the failure card's `NestKidButton` ≥ 56.
- **Every tap navigates**: Maya → `/kid-pin`, Leo → `/kid-home` (route read
  from `pinHash` in the DB, never assumed), lock → `/parental-gate`, pop
  returns to `/who-is-playing`, and a **rejected** `setActiveChild` shows
  `Hmm, that did not work. Try again.` and does NOT navigate.
- **Accessibility**: the lock is `isButton` + `SemanticsAction.tap` and its
  action opens the gate; each tile's action navigates AND writes
  `app_state.activeChildId`; the tile node's label is exactly
  `Maya, Age 7–9`; the pets are announced as `isImage` with the design's alt
  text and are not second buttons; the title/sub/caption advertise no tap.
- **States**: loading (spinner + lock, no tiles) at all three widths;
  failure (Pip + copy + retry) with a working semantics retry; empty roster
  under `Seed.empty` in light AND dark.
- **Dark mode is branch-free**: tile fill/border and pet tints come from
  `NestColors.dark`; sky top and meadow are painted-pixel-checked.
- **Bottom edge (owner rule)**: no `NestBottomCta` on this screen,
  `NestHomeIndicator` reserves 0, and the meadow is pixel-identical at
  (8/195/382, 838/843) with a 34 px OS bottom inset, light and dark.
- `NestStatusBar` reserves height only — no mock `9:41` glyph in the app.

## 2. BUGS FOUND (not patched)

### BUG-A (major, new) — the title apostrophe is not the design's

**File:** `app/lib/features/kid_home/presentation/views/profile_picker_view.dart:210`
— `'Who’s playing?',` uses **U+2019** (right single quotation mark).

**Design truth:** `design/html-source/screens/K01-profile-picker.html:42`
holds a raw ASCII apostrophe (byte `0x27`):

```
3c 68 31 … 57 68 6f 27 73 …  →  <h1 class="kid-title k1-title">Who's playing?</h1>
```

and both design PNGs render the STRAIGHT tick (verified by reading a 4×
crop of `design/screens/light/K01-profile-picker.png` around the title: a
solid slanted rectangle, not a comma-shaped `’`).

**Why this is a defect, not a house convention** — this is the cross-stage
question `6_bugs.md` asked me to settle. The convention in this repo is *not*
"always U+2019"; it is "the app matches its own HTML source":

| Screen | HTML source | App copy |
|---|---|---|
| P02, P03, P04, P07, K11 | `&rsquo;` (curly) | U+2019 ✔ |
| P01, P08, P13, P15, **K03**, K06, K07, K10 | literal `'` (straight) | ASCII `'` |
| **K01** | literal `'` (straight) | **U+2019 ✘** |

An AST scan of `app/lib/features/**` finds U+2019 in exactly four shipped
strings — P03 `create_account_view.dart:110`, P04
`privacy_consent_view.dart:72,192,195`, P07 `paywall_view.dart:431,595`, P02
`value_tour_view.dart:346,403,498` — every one of which is on a screen whose
HTML uses `&rsquo;`. K01's `profile_picker_view.dart:210` is the ONLY
exception in the app. The same feature's K03 already ships the straight form
(`kid_home_view.dart:332`, `"Who's playing?"`), and K03's own stage-3 harness
note records "the design source uses a **straight** apostrophe".

The COPY rule is explicit — "compare copy character-by-character with the
HTML source" — and the HTML source is the only byte-level oracle for which
apostrophe the designer drew. `1_plan.md` §0 asserted U+2019 without citing
the source; stages 4 and 5 deferred to that plan instead of re-reading it,
which is how the wrong glyph shipped.

**Repro (two red tests, deliberately left red):**

```
flutter test test/features/kid_home/k01_copy_parity_test.dart \
  --plain-name "the title matches the source byte for byte"
# Expected: exactly one matching candidate
#   Actual: Found 0 widgets with text "Who's playing?"
#     Which: means none were found but one was expected

flutter test test/features/kid_home/k01_copy_parity_test.dart \
  --plain-name "no drawn string carries a curly apostrophe"
# Expected: false
#   Actual: <true>
# “Who’s playing?” has a curly apostrophe; K01’s source is straight
```

Both flip green the moment the one character changes to `"Who's playing?"`.
No test edit is needed.

**Fix in view code (for the build stage, one character):**
`profile_picker_view.dart:210` → `"Who's playing?",`

**Follow-on test edits the fixes stage must make** (these currently pin the
wrong glyph):
- `k01_copy_parity_test.dart` — nothing; it already asserts the source.
- `k01_profile_picker_view_test.dart:128,295,302` (`find.text('Who’s playing?')`).
- `k01_bugs_test.dart:302,412,420-422,522` (`copy matches the plan's
  typographic characters exactly` explicitly asserts `contains('’')` is true
  and `contains("'")` is false — the inverse of the design).
- `k01_profile_picker_matrix_test.dart` `_title` (mine) and
  `k01_copy_fit_test.dart` `_copy`.

**Orchestrator decision needed (one line, then both stages align):** the COPY
rule and the HTML source say straight. Recommend ruling straight, because a
per-screen entity (`&rsquo;` vs `'`) is what the design system actually uses —
if the intent were "always curly", the fix belongs in the design source, not
in 5 test files.

### BUG-B (major, corroborating stages 4/6, not new) — Try again cannot recover

`KidHomeLoadRequested` only restarts the home stream when `_homeSub == null`
(`kid_home_bloc.dart:52`); a profiles-only failure therefore leaves the state
at `failure` forever, because `copyWithProfiles`
(`kid_home_state.dart:166`) never restores `loaded`. Filed by stage 4
(finding 1) and stage 6 (K01-BUG-5). My tests cover both halves without
colliding: `k01_profile_picker_matrix_test.dart` proves the *working* failure
path (fake where the home stream itself fails — Try again recovers), and
`k01_bloc_paths_test.dart` proves `copyWithProfiles` keeps the status
unchanged, which is precisely the defect.

### BUG-C (major, corroborating stage 6 K01-BUG-3) — a tile dies after back

The `selectedProfileId` one-shot only clears on a home emission
(`copyWithLoaded`). Tapping a tile, returning to the picker and tapping the
SAME tile emits an `==`-equal state, the bloc drops it and nothing happens —
no navigation, no feedback. My `each tile is a labelled button…` /
`Maya’s tile pushes the PIN route` tests prove the healthy half (the one-shot
is consumed, so a fresh selection navigates); stage 6's
`K01-BUG-3: tapping the same tile after back does nothing` is the red half.

## 3. False positive, already retracted by stage 6

`k01_bugs_test.dart:517` `copy is never ellipsized at 320 px + 1.3 text scale`
was red when this stage ran, but it is **not** a bug: that probe did not load
the bundled faces, so `flutter test`'s metric-less placeholder font (every glyph
one em wide) makes "Who's playing?" ≈2× too wide and trips
`didExceedMaxLines`.

`k01_copy_fit_test.dart` is the same probe done correctly — it loads
Inter + Nunito in `setUpAll`, exactly like `k01_profile_picker_geometry_test.dart`
documents — and it is **green at every width and scale**:

```
320/390/430 @1.0 and @1.3 — no string is ellipsized or clipped
title 34/44, sub 26/34, caption 40/52, name 32/42, age 20/26
```

Stage 6 has since replaced that probe with a real-font version in its own file,
so nothing is outstanding — kept here because the red was visible in the
shared suite while these stages overlapped, and the next reader will see it in
the history.

## 4. Independent diagnosis of D1/D2 (feeds `ORCHESTRATOR_NOTES.md`)

`5_ui.md` measured tiles +16.6 px and the caption +34 px low, with the
title/sub/lock exact. Measured in a widget test with the bundled fonts at
390×844 (`viewPadding` 0), design values read from the PNG ink rows ÷3:

| Element | Design | App | Δ |
|---|---|---|---|
| title line box | 123…157 | 123…157 | 0 |
| sub line box | 173…199 | 173…199 | 0 |
| tiles | 289.0…648.7 (h 360) | 305.5…665.5 (h 360) | **+16.5** |
| caption box | ≈739…779 | 772…812 | **+33** |
| lock | 314…370 × 47…103 | 314…370 × 47…103 | 0 |
| gutters | 20 / 370 | 20 / 370 | 0 |

**Cause, arithmetically exact:** the design's `.scroll` is
`844 − 47 (--status-h) − 60 (.k1-top) − 34 (--home-h) = 703` px tall; the app's
body is `844 − 47 − 60 − 0 = 737` px because `NestHomeIndicator` reserves
nothing in the running app (the deliberate P01 BUG-2 decision). The tiles band
is `flex: 1` and CENTRES, so 34 px of extra leftover space splits into 17 px
above and below → tiles +17.0 (measured +16.5; the 0.5 is the design PNG's
anti-alias edge). The caption sits below the band, so it takes the whole
+34. Both numbers reproduce exactly.

So D1/D2 are one fix, and it is not "re-centre `.k1-mid`": give the picker the
design's 34 px bottom reserve (e.g. reserve `NestDevice.homeH` — or
`viewPadding.bottom` on device — under the caption) so the centred band lands
where the design puts it. Not a finding of this stage; recorded so the build
stage does not re-derive it.

## 5. Results

```
flutter analyze                       → No issues found!
dart format (4 new files)             → 0 changed after formatting
flutter test test/features/kid_home/  → 210 green (kid_home incl. stage 6), 0 red
flutter test (whole app)              → +2824 ~8 -3
```

Whole-app `-3`:

| Failure | Owner |
|---|---|
| `k01_copy_parity_test.dart` × 2 | **mine** — BUG-A, deliberately red |
| `quests/quest_library_a11y_actions_test.dart` — "a chip tap really filters the idea list" | another screen's file; **passes in isolation**, so it is a pre-existing full-suite concurrency flake, not K01 |

`test/features/kid_home/` is fully green: stage 6 finished `k01_bugs_test.dart`
while this stage ran (13 green + 7 `skip:` for its open bugs), and its
320 px + 1.3 "copy renders in full" probe now loads the bundled faces — so the
§3 false positive is already retracted on their side.

Per file, as run:

| File | Result |
|---|---|
| `k01_copy_parity_test.dart` | **+11 −2** (both red = BUG-A) |
| `k01_copy_fit_test.dart` | +7 |
| `k01_profile_picker_matrix_test.dart` | +46 |
| `k01_bloc_paths_test.dart` | +12 |
| `k01_profile_picker_view_test.dart` | +13 |
| `k01_profile_picker_geometry_test.dart` | +4 |
| `kid_home_bloc_test.dart` | +38 |
| `kid_home_repository_test.dart` / `kid_home_geometry_test.dart` / `kid_home_view_test.dart` / `k03_bugs_test.dart` | green after `git merge main` |

## 6. Known reds that are NOT mine

- **`k01_copy_parity_test.dart` × 2** — BUG-A above. Deliberately red: the
  test states the design contract and turns green on the one-character fix.
- `k01_bugs_test.dart` finished green (its own reproducers are `skip:`-marked
  against open bug ids, per its header). Nothing for me to report there.
- `quest_library_a11y_actions_test.dart` × 1 — whole-suite flake in another
  feature's file, green in isolation.

## 7. Harness notes for the next stages

- **Load the bundled fonts for any metric assertion.** Without them
  `flutter test` uses a one-em-per-glyph placeholder and every width/scale
  measurement is fiction (this produced one false bug report and would have
  produced two more). Font-sensitive probes live in
  `k01_copy_fit_test.dart` / `k01_profile_picker_geometry_test.dart` for that
  reason — the geometry file's header already says so.
- **Never await a Drift future directly inside `testWidgets`.** It deadlocks
  under the fake clock (I lost 10 minutes to one). Use
  `await tester.runAsync(() => repo.watchProfiles().first)`.
- **`tester.pageBack()` does not work on `/kid-home`** (K03's own chrome has
  no back button). Pop the Navigator directly:
  `tester.state<NavigatorState>(find.byType(Navigator).first).pop()`.
- A tile's name/age/pip semantics **merge into the tile button node**, so
  `getSemantics(find.text('Maya'))` returns the *button*. Assert "no tap
  action" only on nodes outside a control (title/sub/caption); assert the
  tile's label and `isButton` instead. The pets are `isImage` nodes that
  inherit the tile's tap — correct, not phantom buttons.
- Bottom-edge pixel probes must sample where no glyph is painted: the caption
  occupies y 772…812, so `y = 800` at `x = 195` reads ink, not meadow. Sample
  `y ∈ {838, 843}`. Allow ±1 per channel: an 8-bit capture of an sRGB gradient
  lands a unit either side of the rounded token.
- `SemanticsFlag.hasFlag` is deprecated in this SDK; use
  `data.flagsCollection.isButton` / `.isImage`.
- `testWidgets(skip:)` takes a **bool** in this SDK (only `test()` takes a
  reason string), which is why stage 6's header promises reason-carrying
  `skip:` markers the file cannot express.
- **Concurrency note:** stages 4, 5 and 6 ran in this worktree at the same
  time as stage 3 (their files appeared mid-run; `k01_bugs_test.dart` was
  being written while I measured, and it now ends green). I touched only my
  four new files and never `k01_bugs_test.dart`, `k03_bugs_test.dart` or
  `kid_home_view_test.dart`, but stage 6 recorded my matrix file as "mid-write
  WIP" — it is finished and green now.

## 8. Verdict basis

`flutter analyze` is clean and `dart format` is clean, but this stage found a
real defect in the screen (BUG-A, plus corroboration of BUG-B/BUG-C) and it is
recorded rather than patched, as the brief requires. Two of my tests are
intentionally red to pin it. Stage 3 cannot pass.


## From 4_review.md
# K01 · Who's playing? — Stage 4 QA code review (iteration 1)

Reviewed `git diff main...HEAD` for screen K01. Scope checked:
feature-first layering (entity → abstract repo → impl → bloc → view),
RULES.md §1 edit surface, design-system reuse (no hard-coded
colours/sizes/fonts), DESIGN_SPEC §5 K01 copy, accessibility, performance,
error handling, Children's Code. Analyzer clean (`No issues found!`),
all 57 K01-owned tests pass.

## Findings

1. **major** — the failure card's *Try again* cannot recover from a
   profiles-stream failure. `profile_picker_view.dart` dispatches
   `KidHomeLoadRequested`, but `KidHomeBloc._onLoadRequested`
   (app/lib/features/kid_home/presentation/bloc/kid_home_bloc.dart:47-67)
   only re-subscribes and emits `loading` when `_homeSub == null`. In the
   failing case the home subscription is still live, so no loading state
   and no home restart happen; `_ensureProfilesSub()` restarts the
   profiles stream, and `_onProfilesReceived`
   (kid_home_bloc.dart:92-97) emits `copyWithProfiles`, which by design
   never touches `status`. If the failure card was shown because the
   profiles stream errored while `state.child == null` (K01 entry with no
   active child — `watchHome()` emits `KidHomeData(child: null)` when
   `activeChildId` is null, kid_home_repository_impl.dart:43-45), the
   state stays `KidHomeStatus.failure` forever: the watch stream has
   already delivered its value and will not re-emit without a DB write,
   and the only write path (`setActiveChild`) is unreachable behind the
   failure card. The comment at kid_home_bloc.dart:99-105 says a healthy
   emission restores `loaded` "via `copyWithLoaded`", but that requires
   a home-stream emission that is not guaranteed. **Fix:** in
   `_onProfilesReceived` restore the loaded state when the failure was
   caused by the profiles roster, e.g.
   `emit(state.copyWithProfiles(event.profiles).copyWith(status:
   state.status == KidHomeStatus.failure ? KidHomeStatus.loaded :
   state.status))`, and/or have Try again restart the profiles stream
   with an explicit `loading` emit. Add a regression test that drives
   profiles-failure → Try again → profiles-recovery and asserts
   `KidHomeStatus.loaded` without a new home emission.

2. **minor** — `KidHomeState.copyWithProfiles`
   (app/lib/features/kid_home/presentation/bloc/kid_home_state.dart:166)
   carries a stale `errorMessage` through a recovered profiles stream;
   clearing it alongside the status restore in finding 1 keeps the state
   honest for the toast/retry UI that reads `errorMessage`.

3. **minor** — Try again on the K01 failure card shows no spinner when
   the home subscription is still live (the `loading` emit is inside the
   `_homeSub == null` guard, kid_home_bloc.dart:50), so the tapped
   failure card just sits there until the next emission. Folded into the
   finding 1 fix.

## Non-findings (checked, OK)

- No navigation in the bloc; tile tap goes through
  `selectedProfileId` → `BlocListener` → `context.push` with
  `{'childId': id}` extra, matching the K02 contract.
- CHILD ORDER respected: `watchProfiles` in DB creation order, no sort.
- PIP rule respected: per-child `PipAvatar(style/skin/accessory/stage)`
  from the DB row; no `pip_stage_*.svg` in the picker.
- Copy matches the design; the one U+2019 vs ASCII deviation in the HTML
  fixture is a pre-agreed convention (all Dart screens use U+2019).
- No hard-coded colours/sizes/fonts; typography, radii, spacing,
  shadows, tints all from tokens; `NestBalancedText` used for the
  `.kid-title`; no `letterSpacing` additions; no `google_fonts`.
- Bottom-edge rule: no bottom bar on this screen, meadow runs to the
  edge — consistent with the design.
- Lock button → `/parental-gate`, guarded `_busy`; tiles and lock expose
  `SemanticsAction.tap` and tests perform the tap action.
- No `DateTime.now()` in K01 code; no analytics/ads/child-data leakage
  in kid mode; new tests pinned via `test/flutter_test_config.dart`.
- `KidChild.ageBand` added additively; all copyWith/withCompletion*
  constructors carry `profiles`/`selectedProfileId` through.
- The stale `DateTime.now()` hits in K03/today code and the branch
  being behind main are process items, not findings.


## From 5_ui.md
# K01 · Who's playing? — Stage 5 (UI CHECK, iteration 1)

Route `/who-is-playing` · mode kid · seed demo · child maya · simulator BC440E48-B3A3-43BC-971B-0EF5DB621874 (390×844).
No code edited in this stage.

## Captures

- `bash tools/screens/shot.sh "$PWD/app" /who-is-playing "$PWD/docs/screens/K01/ui/app_light_1.png" BC440E48-B3A3-43BC-971B-0EF5DB621874 light demo kid maya` → `docs/screens/K01/ui/app_light_1.png`
- Same with `dark` → `docs/screens/K01/ui/app_dark_1.png`
- `python3 tools/screens/compare.py design/screens/light/K01-profile-picker.png docs/screens/K01/ui/app_light_1.png docs/screens/K01/ui/cmp_light_1.png`
- `python3 tools/screens/compare.py design/screens/dark/K01-profile-picker.png docs/screens/K01/ui/app_dark_1.png docs/screens/K01/ui/cmp_dark_1.png`
- Compare images READ (not attached): `docs/screens/K01/ui/cmp_light_1.png`, `docs/screens/K01/ui/cmp_dark_1.png`.

## Mean diff + bands

Light: mean diff 6.10%

```
band  y-range    diff%
  0      0-105    1.78%
  1    105-211    2.02%
  2    211-316    6.27%
  3    316-422    3.67%
  4    422-527    7.02%
  5    527-633   10.23%
  6    633-738   10.86%
  7    738-844    6.94%
```

Dark: mean diff 5.62%

```
band  y-range    diff%
  0      0-105    1.77%
  1    105-211    2.02%
  2    211-316    5.77%
  3    316-422    3.60%
  4    422-527    6.69%
  5    527-633    9.75%
  6    633-738    9.06%
  7    738-844    6.29%
```

Bands 5–6 carry the tile-bottom + caption + meadow drift in both themes.

## Measured positions (logical px, ÷3; design vs app)

| Element | Design light | App light | Design dark | App dark | ±2 px? |
|---|---|---|---|---|---|
| Title "Who's playing?" top (first dark/light row, x 60–330) | 129 | 129 | 129 | 129 | PASS |
| Sub "Tap your face to start" top | 190 | 190 | 190 | 190 | PASS |
| Lock button (first control): white rect, x=342 vertical | 48.0–101.7, border x 333–350 | 48.0–101.7, border x 333–350 | same | same | PASS |
| Left tile top border (x=30) | 297.7 | 314.3 (+16.6) | 297.7 | 314.3 (+16.6) | FAIL |
| Left tile bottom border (x=30) | 640.0 | 656.3 (+16.3) | 640.0 | 656.3 (+16.3) | FAIL |
| Right tile top (white start, x=216) | 299 | 315 (+16) | — (same code path) | — | FAIL |
| Tile left/right edges at y=400 | 21 / 185 / 204 / 368 | 21 / 185 / 204 / 368 | 21 / 185 / 204 / 368 | 21 / 185 / 204 / 368 | PASS |
| Caption first text row (x=195 gap) | 747.0 | 781.0 (+34) | 742-equiv | 781-equiv | FAIL |
| Meadow top at left gutter (x=30) | 646 | 752 (+106) | 646 | 751 (+105) | FAIL |

Tile height matches (design 342.3 vs app 342.0); the whole tiles band is shifted down, not resized.

## Element-by-element

- Presence/order: title, sub, 2 tiles (Maya then Leo, CHILD ORDER ok), lock, caption, meadow — all present, correct order. No overflow, clipping, or ellipsis faults at 390 px.
- Copy (visual): "Who's playing?" / "Tap your face to start" / "Maya" / "Age 7–9" / "Leo" / "Age 4–6" / "Grown-ups: tap the lock to get back to your dashboard." all match. Note: HTML source uses ASCII `'` in the title (`K01-profile-picker.html:42`) while the app renders U+2019 per `1_plan.md` §0 and house convention (P02/P03/P04/P07 all ship U+2019); ages use `&ndash;` (U+2013) in both. Not counted as a defect.
- Alignment/gutters: tile outer edges identical (21/185/204/368), 20 px side gutters, lock at x 314–370 — PASS. Tiles are aligned to each other; the band itself is displaced.
- Sizes: tile width/gap/border-3/radius-32, lock 56×56 r18, avatar s96 look, pet circle 132 look — widths match at y=400; vertical shift corrupts chord-width spot checks but shapes match visually.
- Colours: tile border ink (30,27,58) both; dark tile border near-white both; sky gradient within ~5 units (design (224,239,255) vs app (219,238,255) at y250 — gradient-stop variance, negligible). Meadow bottom differs: design (204,237,192, hill-front tint) vs app (191,232,176, flat hill-back) — see D3.
- Radii/shadows: r-xl tiles, 56-lock r18, kid shadow under tiles visible in both — PASS.
- Icons: lock padlock glyph matches; no v1 `pip_stage_*.svg` used — PASS.
- Bottom edge (OWNER RULE): no bottom bar on this screen; meadow runs to the physical edge in both app shots, no strip under a bar — PASS.
- Status bar / home pill: design 9:41 vs sim clock, design home pill vs sim no pill — ignored per STATUS BAR rule (OS-drawn). Not findings.
- Dark mode: same geometry shift as light; dark tokens flip correctly (tile surface dark, border near-white, pet tints dark). Same fails as light.

## Deviations (design value → app value + fix)

1. D1 — Tiles band ~16.5 px too low. Design tile top 297.7 → app 314.3; bottom 640.0 → 656.3 (light and dark identical). Title/sub/lock are exact, so the extra space is between the sub and the tiles band. Violates the ±2 px rule and the UI VERDICT RULE (uniform shift = FAIL). Fix: reduce the space above the tiles band / re-centre `.k1-mid` so tile tops land at 297–299 (feature dir: `profile_picker_view.dart` tiles-band layout; see `2b` layout-notes deviation — fixed header/footer vs plan `Expanded`-in-scroll).
2. D2 — Caption ~34 px too low (consequence of D1 plus band weighting). Design caption top 747 → app 781. Fix: with D1 corrected, re-pin caption so its first row lands at 747 (light) with the 16 px band→caption gap and 32 px bottom pad per plan.
3. D3 — Meadow hill geometry wrong (shared `KidScope`, not fixable in feature dir). Design: two-tone hills rising behind the tiles (meadow top at gutter y 646; centre hill-back crest high). App: single flat hill below the tiles (meadow top at gutter y 752, +106). The tiles overlap the meadow in the design but sit fully on blue in the app. Fix: shared — reshape `KidScope` meadow to the 136 px two-hill SVG (`hill-back` + `hill-front` overlay); file `SHARED_REQUEST.md` if the loop requires it.
4. D4 — Meadow bottom colour is hill-back only (consequence of D3). Design bottom (204,237,192, hill-front `color-mix` bake per SPACING §9.14) → app (191,232,176). Fix: with D3, restore the lighter hill-front overlay colour.
5. D5 — Leo Pip artwork differs (INTENTIONAL, not a defect — PIP orchestrator rule overrides the design). Design shows yellow hatchling with eggshell for Leo; app correctly renders the child's OWN Pip via `PipAvatar` (Bolt·sky·stage 2, blue). Maya (Mochi·sunny·stage 3, yellow) matches. No fix; noted so the heat-map red on Leo's pet circle is not mistaken for a regression.
6. D6 — Sky gradient tint differs by ~5 units at mid-screen (design (224,239,255) vs app (219,238,255)). Below designer-reject threshold; noted only. No fix.

Bands 2–6 red is accounted for by D1–D4; bands 0–1 (≈2%) is status-bar-glyph + anti-alias noise only.


## From 6_bugs.md
# K01 · Who's playing? — Stage 6 bug hunt (iteration 1)

Adversarial pass over `/who-is-playing` (feature `kid_home`, mode kid) on the
merged base (`7e46483`, main merged). Every proof lives in
`app/test/features/kid_home/k01_bugs_test.dart` and is backed by the real
in-memory Drift database (Seed.demo), the real repository, or a
feature-local fake for failure paths. No screen code was changed.

Verification commands:

```
flutter test test/features/kid_home/k01_bugs_test.dart
  → +13 ~7: All tests passed!      (7 proofs parked with skip: true)

flutter test --run-skipped test/features/kid_home/k01_bugs_test.dart
  → 7 failures, one per open bug below
```

| # | Severity | Status | Area |
|---|---|---|---|
| K01-BUG-1 | major | open | 3+ children collapse the tile row |
| K01-BUG-2 | major | open | two-finger tile burst navigates twice |
| K01-BUG-3 | major | open | a tile is dead after returning from a route |
| K01-BUG-4 | minor | open | empty nickname → unlabelled tile |
| K01-BUG-5 | major | open | Try again cannot recover from a profiles failure |

Also already tracked by the other stages (referenced, not re-proved here):
5_ui D1 (tiles band 16.5 px low) and D2 (caption 34 px low) — the
orchestrator notes say to fix both in the next build; D3/D4 (meadow) are the
shared `kid_meadow` work, not a K01 finding.

---

## K01-BUG-1 — major — 3+ children collapse the tile row

`_PickerLoaded` lays every profile out in ONE fixed `Row` of `Expanded`
cards (`profile_picker_view.dart:252-270`). Two children give the design's
167 px tiles; each extra child shrinks every tile without floor or scroll,
past the point where the compact metrics fit.

**Repro (widget test, 390×844, Seed.demo + inserted children):**

- +1 child (Nina) → tiles `[106, 106, 106]` px (design 167, compact minimum
  132); the 96 px pet disc is clamped to 86×96 — an ellipse, not a circle.
- +2 children (4 total) → tiles 75.5 px; the 64 px avatar disc renders
  49.5×64.
- +4 children (6 total) → tiles `[45 × 6]` px; 20 px padding leaves 25 px
  of content for a 64 px avatar and an 80 px Pip.

**Failing tests:**

- `K01-BUG-1 — 3+ children collapse the tile row a third child shrinks every tile below the compact minimum`
- `... at 4+ children the pet disc/avatar stop being circles`
- `... six children leave 45 px slivers (design tile: 167)`

**Suggested fix:** make the tiles band scroll horizontally (or wrap) when
`profiles.length > 2`, keeping the design tile width (167 at 390) and the
20 px gutters; never let a tile shrink below the compact minimum (132).
The 1–2 child layout stays as designed.

## K01-BUG-2 — major — two-finger tile burst navigates twice

Each tile has its own `_busy` latch (`profile_tile.dart:36-43`), so a touch
on Maya does not block a simultaneous touch on Leo. Both
`KidHomeProfileSelected` events write `app_state` and both one-shot
emissions reach the picker's `BlocListener`, which pushes `/kid-pin` and
`/kid-home` on top of each other. The last DB write wins the active child,
and one back press lands on the other child's screen.

**Repro (widget test):** pointer 7 down on Maya + pointer 8 down on Leo,
both up in the same burst (before any frame). After settling: top route
`/kid-home`, `activeChildId == 'leo'`, and `K02 Kid PIN` is present in the
widget tree (`skipOffstage: false`) beneath it — two navigations for one
gesture burst.

**Failing test:** `K01-BUG-2: tapping Maya then Leo stacks two kid routes`.

**Suggested fix:** single-flight the picker navigation — a screen-level
latch set before `context.push` and cleared when the pushed route pops, or
`IgnorePointer` over the tiles while a selection is pending, or ignore
`KidHomeProfileSelected` in the bloc while `selectedProfileId` is
unconsumed. (Related observation, not a finding: because the first push
installs within the first tap's dispatch, a *sequential* second tap already
lands on the newly pushed route — e.g. a PIN keypad key. A one-frame
guard before navigating would remove that too.)

## K01-BUG-3 — major — a tile is dead after returning from a kid route

`selectedProfileId` is a one-shot that only clears on the next home-stream
emission (`copyWithLoaded`, `kid_home_state.dart:150-160`). After
`setActiveChild`, the clear emission races *ahead* of the selection emit
(Drift re-notifies `app_state`, the handler then emits `copyWithSelection`),
so the one-shot stays set. A second tap on the same child then emits an
`==`-equal state, the bloc drops it (Equatable), and nothing happens — no
navigation, no toast.

**Repro (widget test, Seed.demo where `activeChildId` is already `maya`):**
tap Maya → `/kid-pin`; back to the picker (`selectedProfileId == 'maya'`,
asserted); tap Maya again → the path stays `/who-is-playing` forever. The
same flow breaks after a Leo visit to `/kid-home`.

**Failing test:** `K01-BUG-3: tapping the same tile after back does nothing`
(the test asserts the mechanism first: `bloc.state.selectedProfileId` is
still `'maya'` instead of null).

**Suggested fix:** consume the selection instead of relying on a stream
emission — e.g. a `selectionNonce` that increments per selection (the view
navigates on nonce change), or a "selection handled" event the view
dispatches in the listener, or clear `selectedProfileId` after the push.
Keep navigation out of the bloc (existing contract).

## K01-BUG-4 — minor — empty nickname makes an unlabelled tile

`ProfileTile` builds its semantics label from the raw nickname
(`profile_tile.dart:53-57`); `''` yields an empty accessible name. The
avatar falls back to `'?'`, the label does not. P05's form blocks empty
names, but the DB/entity allow the row (edit paths, imports, future code).

**Repro:** insert `children(id: 'noname', nickname: '')`, pump the picker,
read the tile's semantics — `label == ''`.

**Failing test:** `a child with an empty nickname still has a usable label`.

**Suggested fix:** fall back to a stable label (e.g. `Kid`) when the
nickname is blank, and/or enforce non-blank nicknames at the DB/validation
layer.

## K01-BUG-5 — major — Try again cannot recover from a profiles-only failure

(Also stage-4 review finding 1.) The failure card can be shown when
`watchProfiles` errors while the home stream is healthy (it emits
`KidHomeData(child: null)` then stays quiet). `KidHomeLoadRequested` only
restarts the home stream when `_homeSub == null` (`kid_home_bloc.dart:52`)
and `copyWithProfiles` never touches `status` (`kid_home_state.dart:166`),
so a successful profiles retry leaves `KidHomeStatus.failure` forever — the
only write path (`setActiveChild`) is behind the failure card.

**Repro (fake repo):** `watchHome` yields `KidHomeData(child: null)`;
`watchProfiles` errors once, then yields Maya. Pump → failure card. Tap
Try again → the roster recovers but the card stays.

**Failing test:** `K01-BUG-5: Try again cannot recover from a profiles
failure`.

**Suggested fix:** in `_onProfilesReceived`, restore `loaded` when a
healthy roster arrives after a failure (and clear `errorMessage`); and/or
make Try again emit `loading` and restart the profiles stream when the home
subscription is still live.

---

## Checked clean (probes that pass and stay in the suite)

- **0 children** (`Seed.empty`): title, empty-roster message, lock, no
  tiles, no exception.
- **1 child**: single tile fills the 20 px gutters without overflow.
- **Long UK name** (`Maximilian-Alexander`) at 320 px + 1.3 scale: no
  exception, ellipsized inside the tile.
- **Empty age band**: line omitted, both tiles keep the same height/rhythm.
- **Money/timezone**: no `£`, coin count or date anywhere on the screen
  (probe), so £0.00/£999.99/9999-coin and BST rounding cases cannot occur
  here.
- **Rapid same-tile double tap**: one route (tile latch works).
- **Rapid lock double tap**: one gate route (`_busy` latch held over the
  awaited push).
- **Deep links**: `/who-is-playing` renders in kid and parent mode.
- **Restart persistence**: `setActiveChild` survives a file-backed DB
  reopen.
- **Copy**: U+2019 in the title, en dashes in `Age 7–9` / `Age 4–6`,
  ASCII hyphen in `Grown-ups` — per plan §0 and the house convention.
- **Semantics**: Maya's tile, Leo's tile and the lock all expose
  `SemanticsAction.tap`.
- **Dark mode**: all 16 token pairs used on the screen (sky top/bottom,
  meadow, surface, pet tints, avatar inks, light + dark) are ≥ 4.5:1.
- **320 px + 1.3 text scale** (real bundled fonts): title, sub and caption
  render in full; the balanced title box does not collapse.

## Cross-stage notes (not new bugs)

- **U+2019 vs ASCII apostrophe.** `k01_copy_parity_test.dart` (stage 3)
  asserts the title must be ASCII `Who's playing?` to match the HTML
  fixture, while `1_plan.md` §0, the view test, and P02/P03/P04/P07 all
  ship U+2019 and stage 5 explicitly ruled the U+2019 rendering not a
  defect. The two tests cannot both pass; this needs one orchestrator
  ruling (the UI stage and the shipped convention favour U+2019).
- **D1/D2 (layout).** Tiles band +16.5 px and caption +34 px versus the
  design are already in `5_ui.md` and `ORCHESTRATOR_NOTES.md` (fix in the
  next build). Not re-proved here.
- **D3/D4 (meadow hills).** Shared `kid_meadow` work per
  `ORCHESTRATOR_NOTES.md` — deliberately not reported as K01 bugs.
- **WIP files.** `k01_profile_picker_matrix_test.dart` was mid-write by the
  concurrently running stage 3 during this pass (analyzer errors there are
  that stage's in-flight work, not K01's).

