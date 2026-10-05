# K11 · Badges — stage 6 bug hunt (iteration 3)

Adversarial pass over `/badges` (feature `badges`, kid mode) on the
iteration-3 tree. The only product change this iteration is the locked-medal
art in `badge_grid_cell.dart` (`ORCHESTRATOR_NOTES.md` 06:55). Result:
**no new bugs** — the art renders exactly the design's colours in both
themes, and the iteration-1 fixes remain verified. No major bug exists, so
the stage verdict is PASS.

No file under `app/lib/` was touched by this stage. Only
`app/test/features/badges/k11_bugs_test.dart` and this file changed.

## Bugs — status

### K11-BUG-1 — `happyDays` was never clamped to the seven drawn days — FIXED (iteration 2)

- **Severity (when open):** minor. **Repro (when open):** store `happyDays 8`
  for Maya → “8 happy days” under seven dots.
- **Fix:** `HappyWeekCard` clamps to 0..7 for the dots and the why-line;
  the repository still reports the stored value verbatim.
- **Regression guard:** `K11-BUG-1 happyDays 8 clamps to the seven drawn
  days` — passing.

### K11-BUG-2 — no active child fell back to the hard-coded `'maya'` — FIXED (iteration 2)

- **Severity (when open):** minor. **Repro (when open):** Zoe-only family,
  `activeChildId` null → “No shiny ones yet…” instead of Zoe's shelf.
- **Fix:** `BadgesRepositoryImpl` resolves the child from the roster
  (persisted id → first child in creation order → no child = empty shelf).
- **Regression guard:** `K11-BUG-2 a non-Maya family with no active child
  shows Zoe` — passing.

## Iteration 3 — locked-medal art, verified (no bug)

The mandatory item: the locked medal's dashed ring is INK, the ribbon's
`opacity=".4"` applies to fill **and** 3 px stroke together, and dark mode
matches the dark design PNG.

**Design measurement (independent, PIL over the design PNGs; Bins out medal,
light + dark):**

| Element | Light PNG | Dark PNG | App (`lockedMedalSvg`) |
|---|---|---|---|
| Dashed ring core | `(30,27,58)` = `#1E1B3A` | `(30,27,58)` = `#1E1B3A` | `stroke="#1E1B3A"`, 3 px, dasharray `5 4` |
| Disc fill | `(243,238,229)` = `#F3EEE5` | `(243,238,229)` = `#F3EEE5` | `fill="#F3EEE5"` (the medal stays light in dark — this is what “light ring” in the note describes) |
| Ribbon fill | 40 % `#6E6A8A` over the tile | 40 % over the dark tile | `fill="#6E6A8A"` + element `opacity=".4"` |
| Ribbon stroke | 40 % ink over the fill | 40 % ink over the fill | `stroke="#1E1B3A"` + element `opacity=".4"` |
| Glyph | `(110,106,138)` = `#6E6A8A` | same | per-id glyph stroke `#6E6A8A` |

**Raster proof (kept as a regression guard):** `K11-ART locked medals in
light|dark` pumps each of the five still-to-do ids, rasterizes the tile and
asserts the exact composites at the medal's known coordinates —
`Color.alphaBlend` expectations from the tokens, so a dropped element opacity
or a wrong ring colour fails. It also counts glyph-coloured pixels inside the
disc for every id (>50 at 3×), which catches a malformed path that parses and
paints nothing. The stage-3 `badges_locked_art_test.dart` pins the same
contract at the SVG-string level.

**Known limitation (documented in `1_plan.md`, not a new bug):** if one of
the five still-to-do ids is ever *earned*, the tile gets the solid ink border
and “Got it!” but keeps its locked medal drawing (no colourful variant exists
for those ids in the design). Each id still renders its own medal, never the
rosette.

**Observation (not a bug, for the review stage):** the corrected locked
markup lives as inline SVG strings with fixed illustration colours inside
`badge_grid_cell.dart`, and the five shared `badge_*` asset files still paint
the ring `#6E6A8A`, so K11 no longer uses those five assets. If the design
system should own the corrected art (assets under `app/assets/**` are shared),
that is a SHARED_REQUEST for the orchestrator, not a screen bug.

## Other hunt areas

Unchanged since iteration 2 and still covered by the green suite (168 tests):
child-resolution matrix (0/1/6 children, deleted active child, creation
order), empty-family live recovery, switch-burst stale-emission race,
double-tap Back/lock, 320 px × 1.3 overflow at 3 widths × 2 scales × 2
themes, restart persistence, nine-id art, a11y actions. Timezone/BST and
money rounding remain N/A on K11 (no clock reads, no £/coins).

## Verification

```
dart format test/features/badges/k11_bugs_test.dart          → clean
flutter analyze test/features/badges/k11_bugs_test.dart      → No issues found!
flutter test --timeout 120s test/features/badges/k11_bugs_test.dart
  → +4: All tests passed!    (2 fix guards + 2 raster art guards)
flutter test --timeout 120s --concurrency=1 test/features/badges
  → +168: All tests passed!  (feature suite, 0 failed)
```

No simulator was booted, no `flutter clean`, no global kills (only my own
orphaned test PIDs), no files outside
`app/test/features/badges/k11_bugs_test.dart` and `docs/screens/K11/6_bugs.md`
were touched by this stage.

VERDICT: PASS
