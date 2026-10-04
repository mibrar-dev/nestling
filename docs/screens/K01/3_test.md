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

VERDICT: FAIL