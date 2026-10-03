# K03 Kid home — Stage 3 (TEST), iteration 8

Scope: `kid_home` / `/kid-home`, kid mode. Tests in
`app/test/features/kid_home/` (`kid_home_view_test.dart`,
`kid_home_bloc_test.dart`, `k03_bugs_test.dart`, `kid_home_geometry_test.dart`).
Per RULES §1 this stage only touched `app/test/features/kid_home/**` and
`docs/screens/K03/**` — **no screen code was patched, no bug was found, so
nothing needed recording as a defect**.

**No simulator was booted, installed on or captured** (SIMULATORS rule: only the
UI-check stage may, and only `BC440E48-…`).

## Verification run (in `app/`, this iteration)

- `dart format --set-exit-if-changed .` → **381 files, 0 changed**.
- `flutter analyze` → **No issues found!** (`analysis_options.yaml` untouched, no
  new suppressions).
- `flutter test` (whole app) → **exit 0, `+1369`** — 1369 pass, **0 skip,
  0 fail**.
- `flutter test test/features/kid_home/` → **exit 0, `+162`** — 162 pass,
  **0 skip, 0 fail**.

The suite's **last parked proofs are now live and green**, so the K03 folder has
no skipped tests at all (iteration 7: 143 pass / 6 skip / 1 fail).

| File | Iteration 7 | Now |
| --- | --- | --- |
| `kid_home_view_test.dart` | 71 | **77** (+4, all pass) |
| `kid_home_bloc_test.dart` | 27 (+1 failing proof) | **31** (+2, all pass) |
| `k03_bugs_test.dart` | 45 (2 parked) | **53**, all pass |
| `kid_home_geometry_test.dart` | 1 (parked) | **1**, passing |

## What iteration 8 delivered (the surface under test)

**The shared pet-slot fix landed** (`shared/pet_stage_explicit`, main
`45b693a` / `797221c`), which is what SHARED_REQUEST #13 asked for:

1. **`NestPetStage` explicit mode composes the scene inside the REAL parent
   box** — centred, scaled down, never off-centre or clipped — and
   `PipNestFallback` grew `nestHeight` + `visibleNestWidth`
   (`visibleNestRatio` = 202/240). K03 now passes
   `nestWidth: 236, nestHeight: 156, fixedPipHeight: 152` and
   `_kStageToHearts = 10.75` (`kid_home_view.dart:76-93`, `nestWidth:` at `:739`).
2. **The speech bubble matches `.speech`** (SHARED_REQUEST #15): max-width 260,
   radius 18, 3 px ink border, 8×14 padding, no fixed line height (SHARED_REQUEST
   #15's "46 px instead of ≈44").
3. **K03-BUG-15 fixed in the bloc** (`kid_home_bloc.dart:41` — `if (_homeSub != null) return;` — with new events
   `KidHomeDataReceived` / `KidHomeStreamFailed`): `_onLoadRequested` keeps the
   live subscription in `_homeSub` and early-returns while it is live; the
   subscription is released on error and on close.
4. Every parked proof was un-skipped by the build and passes.

## Tests added (this stage)

### `kid_home_view_test.dart`

1. **`the scene fills the real content box at 320/390/430px`** (3 tests) — the
   new shared contract, as distinct from the centring proof: the fallback's
   `stageW` equals the *actual* content box (280/350/390), the slot box keeps
   the 20 px gutters, the nest and the Pip sit on the slot axis (±1), and
   neither is clipped left or right. This is what the nominal
   `stageW = nestW / 0.62 = 419 px` could never do.
2. **`the speech bubble matches .speech`** — measured as shapes, not just text:
   the body's fill is `surface`, radius 18, a 3 px `ink` border, padding
   `8 / 14`, width ≤ 260 (`.speech` max-width), the label 16 px w800 with
   tracking 0, and the tail hanging below the body.

### `kid_home_bloc_test.dart`

3. **`a retry after a stream failure opens a fresh subscription`** — the guard
   must not wedge the failure card: load fails → `KidHomeStreamFailed` →
   `failure` + `errorMessage`; "Try again" then opens a **second** subscription
   (counter 1 → 2) and returns to `loaded` with Maya's data. Without the
   release-on-error the retry would be silently ignored.
4. **`a child switch on the live stream needs no reload`** — `pushChild(Leo)`
   alone updates the state (the live `watchHome()` follows `app_state`), and the
   load event the router re-dispatches after the K01 picker returns is ignored
   (still one subscription) without stranding the screen on the old child.

## Results

Targeted runs for the three defects this screen was carrying:

| Proof | Result | Evidence |
| --- | --- | --- |
| `K03-BUG-13` (pet slot centring/clipping, 320/390/430) | **+3, all pass** | nest centre == slot centre at every width (160/195/215); nothing clipped (the old values were +69.7/+34.7/+14.7 px off-axis with a 59.7 px clip at 320) |
| `K03-BUG-14` (pet block height) | **+1, all pass** | block ≈ 236 px, the design's `.k3-pet` (was 276) |
| `K03-BUG-15` (retry stacking subscriptions) | **+2, all pass** | child-row and items subscriptions stay at 1 across three load dispatches (was 3) |
| `kid_home_geometry_test.dart` (real Inter/Nunito) | **+1, all pass** | nest centre 195 ±1, nest box 236 (±2 → 198 visible), Pip centre 195, hearts centre 448 ±2, first card top 559 ±2 |

Everything else stayed green without edits: the layout matrix (light + dark ×
320/390/430 × text scale 1.0/1.3), the PERIODS ruling, the bottom-edge and
alignment owner rules, navigation for every tap target, icon-button semantics,
tap targets (≥ 44 parent / ≥ 56 kid), the PipAvatar mandate per child, the
completion/celebration state machine, and the shapes group (chip pill, card
tile + tint, 56 px check).

## Bugs found

**None.** No test failed, no exception surfaced, and nothing in the screen or
the shared components misbehaved under this stage's probes. Everything this
suite could previously only park is now covered by live, passing assertions.

Closed since iteration 7 (all fixed upstream, all proven here):
`K03-BUG-13`, `K03-BUG-14`, `K03-BUG-15`, SHARED_REQUEST #13 (pet-slot explicit
mode) and #15 (`.speech` bubble). Review findings 1, 3, 4, 5, 8, 13, 14 and the
iteration-6 finding 6 are closed.

## Owner rules re-checked

- **BOTTOM EDGE:** the K03-BUG-10 proofs (light + dark, 34 px inset emulated)
  pass — the dock surface runs to the physical edge and the meadow ends at the
  dock's top border in both themes, with no coloured strip under the bar or
  around the home indicator.
- **ALIGNMENT:** 20 px gutters and shared card/bar/dock edges pass, and the pet
  slot is now **on the axis at every width** — the misalignment this report
  carried in iterations 6 and 7 is gone (K03-BUG-13). Dock labels still cannot
  wrap (`wrapLabel: false`), so the three buttons keep equal heights at 320,
  390 and 430 and at 1.0/1.3 text scale.

## Rule coverage

| Rule | Status on K03 |
| --- | --- |
| PIP | Mandated `PipAvatar` for the active child in every state (loaded, empty, failure); no v1 `pip_stage_*.svg` anywhere in the feature |
| BOTTOM EDGE / ALIGNMENT | Proven by tests (above) |
| PERIODS + DATA OVER MOCKS | Counts come from the DB ("4 done today", "4 of 6 done"); daily/weekly/once + new-period proofs green |
| COPY | Re-verified character-by-character against the HTML source (0 curly / 4 straight apostrophes there; the app matches; en dash in the seed quest title; middle dot in the detail chip) |
| FONTS | No `google_fonts` / `GoogleFonts` in the feature or its tests; `flutter analyze` clean |
| LETTER SPACING | Every rendered K03 string asserts `letterSpacing == 0` (including the balanced heading and the bubble) |
| CHIP ROWS (`NestChipWrap`) | Not applicable: K03's chips are the non-interactive `KidStatusChip`; there is no interactive `NestChip` row on this screen |
| UI CHECK MEASURES SHAPES | Extended this iteration with the bubble (radius/border/padding/max-width) and the scene box per width; chip pill, card tile + tint, check button and dock labels are all measured as background/border rects |
| BALANCED HEADINGS | The only `.kid-title` heading ("Today's quests") renders through `NestBalancedText`, and nothing else does |
| CHILD ORDER | No child list on this screen; pinned at the repository level (K03-BUG-12 → `['Maya','Leo']`) |
| TRIAL | No test writes `subscription_status`; the demo seed is an active subscriber |
| SIMULATORS | None booted by this stage |

## Harness notes (carry forward)

- Direct Drift work inside `testWidgets` must run inside `tester.runAsync`;
  bottom insets are emulated with `tester.view.padding` / `viewPadding` at 3×
  physical px; never `pumpAndSettle` while a loading spinner is on screen;
  card assertions after a celebration need `tester.pageBack()`.
- Seed the DB **before** pumping: a Drift write performed in `runAsync` after
  the app is pumped does not repaint the screen in the fake-async harness, so
  tests that change children/quests write first and pump the route fresh. The
  live-stream behaviour itself is covered at the bloc level with the fake
  repository instead (`a child switch on the live stream needs no reload`).
- The rest of the suite runs on `flutter_test`'s fallback font, which is wider
  than Nunito: the section title wraps to two lines (so the section→progress gap
  is asserted as `>= 16`), and the speech bubble wraps inside its 260 px
  max-width (so its *height* is not asserted there). Real-font geometry lives
  in `kid_home_geometry_test.dart`, which loads the bundled faces in isolation.

VERDICT: PASS
