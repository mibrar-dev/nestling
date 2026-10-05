# K11 · Badges — stage 2 build, INTEGRATE (iteration 4)

Merge of the two parallel builders for feature `badges`. Sources:
`2a_build_logic.md` (logic chunk, iteration 4) + `2b_build_ui.md` (UI chunk,
iteration 4), plan in `1_plan.md`, mandatory items in
`ORCHESTRATOR_NOTES.md` (07:33 ribbon group opacity). There is no
`FIXES_3.md` for this screen, so the fix list is assembled from the loop
artifacts: `6_bugs.md` (iteration 3: no new bugs), `4_review.md`,
`3_test.md`, `ORCHESTRATOR_NOTES.md` 07:33.

## Summary of 2a (logic chunk — domain / data / bloc, iteration 4)

- No lib edits, no contract changes. Fix list had no logic-layer items;
  review's `_switchMap` note remains explicit hardening-only ("fix if ever
  touched", identical to the K08 shared pattern) — NOT touched.
- Re-verification only: scoped analyze clean; repository + bloc files
  38/38 pass unmodified.

## Summary of 2b (UI chunk — views / widgets, iteration 4)

- **Ribbon group opacity fixed (`badge_grid_cell.dart`,
  orchestrator-mandatory 07:33):** `lockedMedalSvg` now wraps the ribbon in
  `<g opacity=".4"><path fill="#6E6A8A" stroke="#1E1B3A" …/></g>` with NO
  opacity on the `<path>`. Browser composites the element as one group layer;
  per-paint path opacity composited fill and stroke separately and darkened
  the stroke's inner band (app (130,128,148) vs design (165,164,176)).
- **Tests:** `badges_view_test.dart` 42 → 44 — group-form string pin plus two
  new raster tests (light + dark) proving fill ≈ grey-at-40 % over the tile
  and stroke ≈ ink-at-40 % over the tile surface.
- **NOT touched:** `badges_view.dart`, `happy_week_card.dart`;
  domain/data/bloc.

## Integration fix (this stage — one, minimal)

- The merged tree failed 2 tests: `k11_bugs_test.dart` `K11-ART locked
  medals in light/dark` (line 246). That guard encoded the OLD per-paint
  formula `_over(_ink, 0.4, fillComposite)` with the comment "the stroke
  paints over the fill at full alpha, then the whole ribbon at 40 %" — stale
  since 2b's mandatory group-opacity fix. True group compositing hides the
  fill under the opaque stroke inside the layer, so the stroke centre is
  ink-at-40 % over the tile SURFACE (`_over(_ink, 0.4, tokens.surface)` =
  (165,164,176) in light, exactly the design sample and the note's ±3
  target). 2b flagged this handoff explicitly and already pins the corrected
  composites in its own view-level raster tests.
- Fix (smallest change, `app/test/features/badges/k11_bugs_test.dart` only):
  expectation base `fillComposite` → `tokens.surface`, comment updated to the
  group-compositing math, reason string updated. No product-code change, no
  redesign. The fill/ring/disc/glyph asserts in that guard are untouched.

## FIXES items

### Done (verified on the merged tree)

- ORCHESTRATOR_NOTES 07:33 ribbon group opacity — local `<g>` fix + 2 new
  raster guards (2b) + stale K11-ART guard updated to group math (this
  stage); feature + full suite green.
- ORCHESTRATOR_NOTES 06:55 locked-medal art, K11-BUG-1 (widget clamp),
  K11-BUG-2 (no hard-coded `'maya'`) — fixed and verified in iteration 2,
  still green (`6_bugs.md` iteration 3: no new bugs).
- Review findings 1 (ctor syntax), 2 (= K11-BUG-1 clamp), 4 (stale error on
  loading) — fixed in iteration 2; `_switchMap` hardening-only note left as
  is per its own guidance.
- `SHARED_REQUEST.md` seed item — closed, landed as
  `shared/k11_badges_seed`; no `TODO(K11)` under the feature.

### Left (not integration issues)

- Nothing. The orchestrator's ordered zoomed-crop check (Bins out, design vs
  app, both themes; inner band (165,164,176) ±3 in light) belongs to stage 5
  with the simulator — this stage supplies the corrected pixels.

## Orchestrator rules re-checked on the merged tree

- `grep google_fonts|GoogleFonts` over `lib/features/badges` +
  `test/features/badges` → comment mentions only, zero call sites/imports.
  `grep DateTime.now()` over `lib/features/badges` → zero hits.
- Tokens only (locked-medal hexes are illustration art, same category as the
  shared files' hard-coded hexes; all chrome still uses tokens); `KidScope`
  shared sky+meadow; `NestBalancedText` on the `.kid-title`; children/badges
  in DB insertion order; counts from the database; no `clock`/`newId` misuse;
  no simulator booted by this stage; no `flutter clean`; `analysis_options`
  untouched; no `pkill`/`killall`.
- Files modified under `app/` are only
  `app/lib/features/badges/presentation/widgets/badge_grid_cell.dart`,
  `app/test/features/badges/badges_view_test.dart` (2b) and
  `app/test/features/badges/k11_bugs_test.dart` (this stage's one-line-class
  guard fix) — all RULES §1. The `docs/screens/K11/.brief_*`,
  `2a_build_logic.md`, `2b_build_ui.md` modifications are the parallel
  builders' own notes, committed by the loop.

## Command tails (verbatim)

```
$ dart format .   (in app/)
Formatted 678 files (0 changed) in 2.52 seconds.

$ flutter analyze   (in app/)
Analyzing app...
No issues found! (ran in 3.0s)

$ flutter test --timeout 120s test/features/badges/
00:03 +170: All tests passed!

$ flutter test --timeout 120s   (full suite)
03:23 +5212 ~16: All tests passed!
```

Feature suite: **170 passed, 0 failed.** Full suite: **5212 passed, ~16
skipped, 0 failed.** `dart format` clean, `flutter analyze` → No issues
found. Pre-fix the merged tree showed exactly the 2 stale K11-ART stroke
guards failing (light + dark); post-fix everything is green — no mismatched
BLoC states/events, no import or rename conflicts, no other failing test
caused by the merge.

VERDICT: PASS
