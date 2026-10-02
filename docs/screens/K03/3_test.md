# K03 Kid home — Stage 3 (TEST), iteration 5

Scope: `kid_home` / `/kid-home`, kid mode. Tests live in
`app/test/features/kid_home/` (`kid_home_bloc_test.dart`,
`kid_home_view_test.dart`, `k03_bugs_test.dart`). Per RULES §1 this stage only
touched `app/test/features/kid_home/**` and `docs/screens/K03/**` — no screen
code was patched.

## Verification run (in `app/`, this iteration)

- `dart format --set-exit-if-changed .` → clean (no file reformatted).
- `flutter analyze` → **No issues found!** (`analysis_options.yaml` untouched,
  no ignores).
- `flutter test` (whole app) → **exit 0, `+593 ~1`** — 593 pass, 1 skip,
  0 fail.
- `flutter test test/features/kid_home/` → **exit 0, `+114 ~1`** — 114 pass,
  1 skip (the shared K03-BUG-7 proof, see below), 0 fail.

Per file (`flutter test <file>`, compact reporter):

| File | At the start of iteration 5 | Now |
| --- | --- | --- |
| `kid_home_view_test.dart` | 47 | **56** (+9) |
| `kid_home_bloc_test.dart` | 20 | **20** (1 existing test extended) |
| `k03_bugs_test.dart` | 38 + 1 skip | **38** + 1 skip |
| **K03 folder total** | **105 pass + 1 skip** | **114 pass + 1 skip** |

All +9 are this iteration's additions; the bug-proof file was untouched by this
stage (its K03-BUG-11 proof arrived with the iteration-5 build).

## What the iteration-5 build changed (the surface under test)

Main merged a design-system migration and the build adopted it, so the
behaviour under test moved in four places. Each is now pinned by a test:

1. **Shared components instead of local forks** — the pet slot is now
   `NestPetStage(pip: PipAvatar(...), speech: …)` (`kid_home_view.dart:687`),
   the hearts are the shared two-tone `NestHeart` (`:463`), and the local
   speech-bubble/heart/tail painters are gone.
2. **Grown-ups lock in every kid state** (review finding 11) —
   `kid_home_view.dart:205` (loading), `:249` (failure), `:330` (no active
   child), `:433` (loaded), all rendering `_GateLockButton` (`:666`).
3. **Pet-stage semantics carry the growth stage** (review finding 12) —
   `semanticLabel: 'Pip the ${_pipStageName(stage)}, stage $stage of 4'`
   (`kid_home_view.dart:697`, name table at `:79`).
4. **State/bloc hygiene** — `copyWithLoaded` no longer carries a stale
   `errorMessage` (`kid_home_state.dart:108`), and `_onLoadRequested` evicts
   celebration entries for quests that vanished from the list
   (`kid_home_bloc.dart:45`, the K03-BUG-11 fix).

## Tests added (iteration 5)

### `kid_home_view_test.dart` — new group `K03 layout invariants`

1. **`blocks stack in order with the specified gaps`** — pins the layout
   contract that is deterministic in the test font: pet → hearts → section →
   progress → cards order; the scroll viewport's bottom equals the dock's top
   (content scrolls behind the bar, never under it); hearts → section = 16
   (`NestSpacing.s4`, the heart is a fixed 26 px slot); progress → first card
   = 16 (meadow-panel column spacing); card → card = 12 (`NestSpacing.s3`; the
   card's 6 px kid-shadow reserve sits inside its own rect).
   The section → progress gap is deliberately **not** asserted: the section
   title is the only block whose height depends on glyph metrics (it wraps to
   two lines in the test font), so an exact value would be a font fact, not a
   layout fact. It is asserted as `>= 16` instead.
2. **`the pet slot carries the design speech bubble`** — the shared
   `NestPetStage` receives `speech: "Let's do some quests!"` and a `PipAvatar`
   in its `pip:` slot (no v1 art re-introduced through the new component).

### `kid_home_view_test.dart` — new group `K03 grown-ups lock (every kid state)`

3. **`loaded home: the lock opens the parental gate`** — pin for the existing
   behaviour in the loaded state (semantics label `Grown-ups` → `/parental-gate`).
4. **`no active child: the lock still opens the parental gate`** — `Seed.empty`
   + `AppSession.refresh()`, taps the lock and lands on the gate. This is the
   build's new lock (review finding 11); the empty state still offers the
   picker as its primary action.
5. **`failure state: the lock still opens the parental gate`** — fake
   repository with `failLoad: true`, taps the lock from the failure card.
6. **`loading state: the lock is reachable and opens the gate`** — hanging
   repository: the spinner state keeps a tappable lock (this state is never
   pumped to settle, because the progress indicator animates forever).

### `kid_home_view_test.dart` — extended group `K03 Pip (orchestrator mandate)`

7. **`the pet slot announces the child stage, not a generic label`** — the
   merged semantics node for Maya contains `Pip the Fledgling, stage 3 of 4`
   (never a bare "mascot").
8. **`the stage name follows the active child (Leo is a hatchling)`** — same
   assertion with the active child switched to Leo: `Pip the Hatchling, stage
   2 of 4`.
9. **`hearts mirror happiness and clamp to 0..5`** — Maya (happiness 4) renders
   5 `NestHeart`s, 4 filled + 1 outline; happiness 0 fills nothing (Pip is
   never framed negatively) and happiness 9 clamps to five. This pins the
   mapping in the new shared heart component against `child.happiness.clamp(0, 5)`
   (`kid_home_view.dart:374`).

### `kid_home_bloc_test.dart` — extended existing test

10. **`failure is followed by a successful retry load`** now also verifies
    `state.errorMessage == null` after the healthy stream emission, pinning the
    review-finding-5 fix (a load error no longer sticks to a loaded screen).

## Results

Every test above passes. Targeted proof runs for the findings this build was
supposed to close:

- `flutter test --plain-name "K03-BUG-11"` → **+1, All tests passed!** — the
  silent no-op completion no longer leaves the check latched (2 recorded calls,
  celebration for the right tap).
- `flutter test --plain-name "K03-BUG-10"` → **+2, All tests passed!** — the
  dock surface reaches the physical bottom edge in **light and dark** (owner
  BOTTOM EDGE rule), with the bottom inset emulated at `viewPadding`/`padding`
  scale (3× physical px).
- `flutter test --plain-name "K03-BUG-10 dark"` — included above.

Carried-forward coverage that still passes unchanged: the layout matrix (light
+ dark × 320/390/430 × text scale 1.0/1.3), the PERIODS ruling (daily / weekly
/ once / fresh completion inside a new period, anchored to
`countsForCurrentPeriod`), the bottom-edge + alignment proofs (20 px gutters,
shared edges, equal-width dock buttons, 20 px safe-area for the home
indicator), every navigation target, icon-button semantics, tap targets
(≥ 44 parent, ≥ 56 kid), the PipAvatar mandate per child, and the completion /
celebration state machine in the bloc suite (20 tests).

## Bugs found

**None in the K03 screen this iteration.** The nine new tests and the whole
existing suite pass without a single screen patch.

Closed by this iteration's build, now proven green:

- `K03-BUG-11` — a silent no-op `completeQuest` left the quest check latched
  and the bloc's pending-celebration entry lingering. Fixed in
  `kid_home_bloc.dart:45` (evict entries whose quest vanished) plus the
  token reset in the card's busy latch.
- `K03-BUG-10` — the dock surface did not cover the OS bottom inset
  (`kid_home_view.dart:547-558`: the surface `Container` now wraps
  `SafeArea(top: false)`).
- Review findings 5, 11, 12 (cleared `errorMessage`; lock in every kid state;
  stage-aware pet-stage alt text).

Still open, **shared** (outside `app/lib/features/kid_home/**`, therefore
filed as SHARED_REQUEST #5 rather than counted as a K03 defect):

- **K03-BUG-7** — the documented
  `--dart-define=DISABLE_ANIMATIONS=1` does not disable motion. Repro:
  `cd app && flutter test test/features/kid_home/k03_bugs_test.dart --dart-define=DISABLE_ANIMATIONS=1 --plain-name "K03-BUG-7"`
  → fails with
  `bool.fromEnvironment only understands "true"; with "1" the still-frame path is skipped and Rive Pip`
  (`app/lib/core/data/env_flags.dart` reads the flag with
  `bool.fromEnvironment`, which only accepts `true`/`false`, and the harness
  passes `1`). Fix belongs to `core/data` + `app/`. Its proof therefore stays
  conditionally skipped in the normal run (`skip: !const bool.hasEnvironment('DISABLE_ANIMATIONS')`),
  which is the single skip in the suite. Side effect: UI captures warn "frame
  never stabilised".

## Harness notes (so the next iteration does not re-derive them)

- **Seed before you pump.** The bloc holds a real live subscription
  (`_onLoadRequested` → `emit.forEach(combineLatest2(watchActiveChild, watchItems))`),
  but inside the fake-async harness a Drift write performed in
  `tester.runAsync` after the app is pumped does **not** repaint the screen:
  probe evidence — the bloc stayed on Maya (`items=6`) after writing
  `app_state.activeChildId = 'leo'`, even after `pumpAndSettle()`, and a
  *freshly created* `watchActiveChild()` emitted no event at all within 60 ms
  of real time. (`quest_completions` writes do propagate — the PERIODS tests
  rely on it.) This is a scheduling artefact of the harness, not a screen
  defect: in the app the child is always set *before* navigating to
  `/kid-home` (K01 picker → `kid_home_routes.dart` dispatches
  `KidHomeLoadRequested` on entry). Every test that changes children/quests
  therefore writes the DB first and pumps the route fresh.
- **Font-dependent geometry stays a capture measurement.** Measured block tops
  on a 390×844 light surface: zero insets → hearts 462, section 504, progress
  592–598, first card 624–630, dock 739; with emulated device insets
  (59 top / 34 bottom) → hearts 474, section 516, progress 610, first card
  642, dock 705. The orchestrator's absolute band targets (ORCHESTRATOR_NOTES
  QA of `cmp_light_4`: hearts ≈443, section ≈490, progress ≈520, card ≈560,
  dock ≈720) are design/capture rows for one device + inset combination, so
  they remain the UI stage's `compare.py` job; the new layout test pins only
  the inset-independent contract. Note the residual delta the UI stage should
  re-measure after this build: the pet block is still the tallest contributor
  above the hearts row.
- Dock-button *heights* are still not compared in the alignment tests: the
  fallback test font wraps "My jar" (80 vs 72 px) — a font artifact.
- `google_fonts` logs "unable to load font …" noise in every pumped test; it is
  harmless (the tests run on the fallback font) and is not a finding.

VERDICT: PASS
