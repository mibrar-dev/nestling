# K11 · Badges — stage 6 bug hunt (iteration 4)

Adversarial pass over `/badges` (feature `badges`, kid mode) on the
iteration-4 tree. The only product change this iteration is the mandatory
07:33 nit: the locked ribbon's 40 % opacity must composite as a **group**
(`<g opacity=".4">`), not per paint on the `<path>`. Result: **fix verified,
no new bugs**. No major bug exists, so the stage verdict is PASS.

No file under `app/lib/` was touched by this stage. The iteration-4 build
already corrected the raster guard's stroke expectation together with the fix
(committed in the build checkpoint); this stage verified it and changed only
this file.

## Bugs — status

### K11-BUG-1 — `happyDays` was never clamped to the seven drawn days — FIXED (iteration 2)

- **Severity (when open):** minor. **Repro (when open):** store `happyDays 8`
  for Maya → “8 happy days” under seven dots.
- **Fix:** `HappyWeekCard` clamps to 0..7 for the dots and the why-line.
- **Regression guard:** `K11-BUG-1 happyDays 8 clamps to the seven drawn
  days` — passing.

### K11-BUG-2 — no active child fell back to the hard-coded `'maya'` — FIXED (iteration 2)

- **Severity (when open):** minor. **Repro (when open):** Zoe-only family,
  `activeChildId` null → “No shiny ones yet…” instead of Zoe's shelf.
- **Fix:** `BadgesRepositoryImpl` resolves the child from the roster
  (persisted id → first child in creation order → no child = empty shelf).
- **Regression guard:** `K11-BUG-2 a non-Maya family with no active child
  shows Zoe` — passing.

### K11-BUG-3 — locked ribbon composited its 40 % opacity per paint — FIXED (iteration 4)

- **Severity (when open):** minor (colour band mismatch on the five locked
  medals; the stroke's inner band was too dark, e.g. `(130,128,148)` where
  the design shows `(165,164,176)`).
- **Where:** `badge_grid_cell.dart` `lockedMedalSvg` — the iteration-3 build
  put `opacity=".4"` on the ribbon `<path>`; flutter_svg applies that per
  paint, so the stroke composited over the already-40 % fill instead of the
  browser's group layer (`ORCHESTRATOR_NOTES.md` 07:33).
- **Fix (iteration 4):** wrap the ribbon in `<g opacity=".4"><path …/></g>`
  with no opacity on the path, so fill and stroke are rendered together and
  the group is composited once at 40 %.
- **Verified (independent raster probe, 3×):** after the fix the stroke band
  samples `(164,163,175)` in light and `(30,27,50)` in dark versus the design
  PNG's `(165,164,176)` / `(31,28,51)` (within 1 due to raster rounding); the
  fill samples `(196,195,207)` / `(62,59,83)` versus `(197,195,208)` /
  `(63,59,83)`.
- **Regression guard:** `K11-ART locked medals in light|dark` (all five
  still-to-do ids) now asserts the group composite
  (`Color.alphaBlend(ink, 0.4, tile surface)`). Note: the iteration-3 version
  of this guard had encoded the per-paint composite as its expectation, i.e.
  it pinned the bug instead of the design — the expectation is corrected and
  now fails if the markup ever regresses to a path-level opacity.

## Iteration 4 — checked, no new bug

- The `<g opacity=".4">` wrapper renders with true group semantics in
  flutter_svg 2.3 (proven by the raster guard and the independent probe).
- The glyph and the dashed ring stay outside the group: ring `#1E1B3A`,
  disc `#F3EEE5`, glyph `#6E6A8A`, unchanged in both themes.
- The stage-3 string checks (`badges_locked_art_test.dart`) still match the
  markup (the group still contains `opacity=".4"` and the ink-ring path).
- Everything else is unchanged since iterations 1–3 and still covered by the
  green suite: child resolution (0/1/6 children, deleted active child,
  creation order), empty-family live recovery, switch-burst race, double-tap
  Back/lock, 320 px × 1.3 overflow matrix, restart persistence, a11y.
  Timezone/BST and money rounding remain N/A on K11 (no clock, no £).

## Verification

```
dart format test/features/badges/k11_bugs_test.dart          → clean
flutter analyze test/features/badges/k11_bugs_test.dart      → No issues found!
flutter test --timeout 120s test/features/badges/k11_bugs_test.dart
  → +4: All tests passed!    (2 fix guards + 2 raster art guards)
flutter test --timeout 120s --concurrency=1 test/features/badges
  → +170: All tests passed!  (feature suite, 0 failed)
```

No simulator was booted, no `flutter clean`, no global kills (only my own
orphaned test PIDs); this stage changed only `docs/screens/K11/6_bugs.md` and
left every `app/` file as the build committed it.

VERDICT: PASS
