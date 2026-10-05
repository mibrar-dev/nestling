# K05 Quest complete — 3 TEST (iteration 2)

Feature `kid_home`, route `/quest-complete` (`KidHomeRoutePaths.complete`),
kid mode. Per-test timeout `120s` throughout; no simulator was booted,
installed on, or driven (only `5_ui` may use one).

Iteration 1 never wrote this file, so this pass did both: it established the
baseline against the tests the build stages had left, then closed the matrix
gaps that the stage prompt requires and the existing files did not cover.

## Baseline on arrival

Everything the build/review/bugs stages wrote already existed and passed — the
iteration-1 work was real, so this stage extended rather than rewrote it:

```
flutter analyze lib/features/kid_home test/features/kid_home  → No issues found!
flutter test --timeout 120s test/features/kid_home/           → +609 ~3 (3 pre-existing K03 skips)
flutter test --timeout 120s test/features/kid_home/quest_complete_view_test.dart
                                              quest_complete_geometry_test.dart → +31
```

## Tests added

One new file, `app/test/features/kid_home/quest_complete_matrix_test.dart`
(38 tests). It exists because the stage prompt's matrix — light + dark, widths
320/390/430, text scale 1.0 and 1.3, tap targets ≥ 56 kid — was only *partly*
covered, and the two real holes were invisible to every existing test.

**What was already covered (not duplicated):** design-rect geometry at 390/1.0
light (`quest_complete_geometry_test.dart`, 3 tests), the celebration/copy/
semantics/states/rebuild-scope suite (`quest_complete_view_test.dart`, 31
tests), and the adversarial bug hunt incl. 320/1.3 no-throw (`k05_bugs_test.dart`,
19 tests). The bloc/repo layer is already pinned by
`kid_home_bloc_test.dart` (K05's `pipTotalCoins` mapping + `copyWithLoaded`) and
`kid_home_repository_test.dart` (DB truth, growth helpers); K05 adds no BLoC
event or state, so there was no new event/state path to cover.

### 1. `the device matrix` — 320/390/430 × light/dark × 1.0/1.3 (36 tests)

12 cells × 3 assertions each:

- **`nothing overflows and the gutters hold`** — the hero, coin pill and CTA
  render; the growth card is scrolled into view first (below the fold at
  320/1.3); `tester.takeException()` is null (catches RenderFlex overflow and
  unbounded constraints); the card and CTA keep the 20 px side gutters at
  **every** width (`card.right == width - 20`); the burst plate scales rather
  than overflowing.
- **`the bar surface reaches the physical edge`** — the owner BOTTOM EDGE rule,
  verified on the **painted raster**, not just rects. See §Bugs below for why
  the rect version was not enough.
- **`both controls meet the 56 px kid floor`** — `NestSpacing.tapKid` (56) is
  asserted as a *floor* on the lock (w+h) and the CTA (w+h), and the lock keeps
  its `Grown-ups` semantic label in all 12 cells.

**The 430 px hole was real.** No K05 test had ever pumped 430 at any scale or
in any theme — the widest supported device had zero coverage.

### 2. `dark layout is the light layout` (2 tests)

The design ships a dark PNG whose painted rects are identical to the light one.
`every painted rect is identical in both themes` measures 9 surfaces (lock,
Pip, hero, pill, bubble, card, progress, CTA, bar) in both themes and asserts
exact rect equality — so dark may flip **tokens only**, never padding, border
width or spacing. This closes the gap that dark was previously only checked for
*not throwing* at 320/1.3 plus the bar bottom edge.

`the dark tokens really are different from the light ones` guards the test above
from being vacuously true: it proves `surface`/`lilacTint`/`ink` actually differ
between themes, and that each theme's ink is the high-contrast partner of its
own ground (dark ink vs dark surface, light ink vs light surface). Without it, a
theme that failed to apply at all would make the rect comparison prove nothing.

## Bugs found

**No bug in the screen was found by this stage's tests.** All 38 pass against
the real screen; I patched nothing. What the pass *did* find is a defect in the
**existing test suite** — a false-negative class for an owner rule — which is
recorded here because it is exactly the kind of thing this stage must not paper
over.

### K05-TEST-1 (minor, test-only) — the bottom-edge rule had no painted-pixel proof

`quest_complete_geometry_test.dart:227-231` and
`quest_complete_view_test.dart:549-571` both assert the bar bottom edge by
measuring the bar `Container`'s **rect** (`barSurface.bottom == 844`) and
checking its `BoxDecoration.color == tokens.surface`. That proves the surface
BOX reaches the edge. It does **not** prove the surface is what is *painted*
there.

**Repro (verified by probe, then reverted).** In
`quest_complete_view.dart`, add one line inside the bar's `Column`, after the
`NestKidButton`:

```dart
Container(height: NestDevice.homeH, color: tokens.leaf),  // 34 px meadow strip
```

Result — a 34 px green strip under the button, the exact violation the owner
rule forbids:

- `quest_complete_geometry_test.dart` → **FAILS** (`barSurface.height` 89 → 123),
  but only because the strip changed the bar's HEIGHT. It never looked at
  colour.
- `quest_complete_view_test.dart`, `k05_bugs_test.dart` → **pass**.
- A strip sized to keep the height constant (i.e. taken from the bar's own
  padding instead of added) leaves **every** existing assertion green, because
  the rect and the `BoxDecoration.color` are both still `surface`.

The new pixel probe fails in all 12 cells. Fix landed in the new file only; no
screen code changed.

A weaker widget-tree variant was tried first (walk `DecoratedBox`es overlapping
the bottom band) and **rejected**: the band's full-screen background boxes always
overlap it, so the check produced false positives until I measured the actual
raster. Sample rows are derived from a measured pixel dump, not guessed:
`y 834…838` is the CTA's own 6 px shadow room (legitimately not the surface), the
painted button ends at 834, the widget box at 840, and the bar's own 3 px ink
top border is skipped — the covered region is `y 840…844` plus both outer
columns across the full bar height. Pattern copied from the existing meadow probe
in `kid_home_geometry_test.dart:103-153`.

## Non-tautology verification (probes run, then reverted)

No test here is trusted just because it is green:

- **Gutter probe** — `ListView` padding `padSide + 6` → the matrix fails on
  `card left gutter` in every cell. Restored (`git diff lib/` empty).
- **Bottom-edge probe** — the 34 px leaf strip above → matrix fails 12/12 on the
  owner-rule reason; and the pre-existing geometry/view/bugs files stay green
  except for the incidental height change. Restored.
- **Dark-layout probe** — not mutated, but guarded structurally by the
  token-difference test (see §2).
- First draft of the bottom-edge test used a literal-token finder like the one
  review finding 6 flagged; it resolves both surfaces from the live
  `NestTokens` extension instead, so a token change fails loudly.

## Hygiene

- `flutter analyze lib test` → **No issues found!** (8 lints in my first draft —
  `prefer_int_literals`, `unnecessary_string_interpolations`,
  `avoid_redundant_argument_values` — all fixed; zero ignores added, no
  `analysis_options` change).
- `dart format --output=none --set-exit-if-changed` → clean.
- No `google_fonts` / `GoogleFonts` / `DateTime.now()` in the new file
  (grep → 0). No ids minted. Bundled Nunito/Inter loaded in `setUpAll` so
  metrics match a device run. Every pumped app ends with `disposeApp`.
- **Zero `lib/` edits** by this stage (verified: `git status --short lib/` empty).
  One added file, inside RULES §1 (`app/test/features/<feature>/**`).

## Results (final, against the tree as it stands)

```
flutter test --timeout 120s test/features/kid_home/quest_complete_matrix_test.dart → +38  All tests passed!
flutter test --timeout 120s test/features/kid_home/                               → +651 ~5  All tests passed!
flutter test --timeout 120s test/                                                → +4382 ~12 All tests passed!
flutter analyze lib test                                                         → No issues found!
```

The 12 skips are the bug proofs parked by other stages (K01 ×1, K03 ×2, K05 ×2)
and are not this stage's. A concurrent stage-6 agent was editing
`k05_bugs_test.dart` and scratch files in this worktree during the run (per the
orchestrator's process rule, not a finding); the final runs above are against its
finished state, and none of its K05 findings are attributed to this stage.

VERDICT: PASS
