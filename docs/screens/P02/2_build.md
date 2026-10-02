# P02 Value tour — build notes (Stage 2, iteration 3)

Implemented per `docs/screens/P02/1_plan.md`, the mandatory
`docs/screens/P02/ORCHESTRATOR_NOTES.md` (marketing illustration: design
copy wins — the one exception to data-over-mocks), and every item in
`docs/screens/P02/FIXES_2.md`. All 4 skipped proofs un-skipped and passing;
zero `skip:` markers remain in `app/test/features/onboarding/`.

## Files changed

- `app/lib/features/onboarding/presentation/widgets/value_tour_preview_row.dart`:
  title now renders inside `FittedBox(scaleDown, centerLeft)` — lays out
  unbounded and paints scaled to its slot (same pattern as the head chips),
  so the design's names are full at 390dp under any font rendering
  (ORCHESTRATOR_NOTES 3, P02-BUG-7). Subtitle unchanged (fits at design
  width; ellipsis remains the small-screen backstop).
- `app/lib/features/onboarding/presentation/views/value_tour_view.dart`:
  card-1 subs restored to the design constants (Maya·weekly, Leo·once,
  Maya·daily, Maya·weekly); date chips restored to static `Sat 4 Oct`
  (`_payoutChipLabel` + `Seed`/`london_time` imports deleted); step-1 body
  and all three card heads use the design punctuation verbatim (curly quotes
  + em dash, U+2019 apostrophes). Nothing else touched (pager 400, unified
  scrollable, 60px nav, PopScope, semantics all carry over).
- `app/lib/features/onboarding/data/onboarding_repository_impl.dart`: step-1
  `detail` mirrors the design string, so loaded copy matches the view's
  pre-load copy character by character (BUG-9; allowed data-layer edit).
- `app/test/features/onboarding/value_tour_view_test.dart`: design body,
  heads, subs, static chip (already updated); no changes needed this round.
- `app/test/features/onboarding/onboarding_bloc_test.dart`: step-detail
  expectations already carry the design punctuation (already updated).
- `app/test/features/onboarding/p02_bugs_test.dart`: `skip:` removed from
  P02-BUG-7, P02-BUG-8a, P02-BUG-8b, P02-BUG-9 (were already edited to the
  notes-correct expectations).
- `docs/screens/P02/SHARED_REQUEST.md`: item 2 (compact-row variant)
  withdrawn — the private row + `FittedBox` title solves P02 permanently
  with shared primitives, so no shared change is needed for this screen.
- Screenshots: `ui/app_light_3.png`, `ui/app_dark_3.png`, `ui/cmp_light_3.png`,
  `ui/cmp_dark_3.png` (step 1, sim 16e, fresh seed).

## Fix items (FIXES_2 → what was done)

- BUG-7 (titles truncate): `FittedBox(scaleDown)` title slot — widget proof
  (intrinsic ≤ laid-out for all four) passes, and the device screenshot
  shows `Empty the dishwasher` in full. At 390dp the scale is ~0.96
  (sub-perceptual); available width, never clipping, decides. The notes'
  320dp×1.3 wrap wish is noted but not implemented: inside the spec-fixed
  400dp card there is no room for 2-line 1.3× titles, and BUG-7's proof
  as written requires the scale-to-fit behavior; extreme sizes stay
  exception-free with complete (scaled) titles.
- BUG-8 (design copy): subs + both chips restored to the HTML constants;
  derivation deleted. BUG-4/BUG-5 stay void per the notes.
- BUG-9 (punctuation): view + repo impl + bloc/contract/bug tests all carry
  the curly body and U+2019 heads verbatim (checked against the HTML:
  card-2 `·` and all other card copy already matched).
- UI 1 (row-1 ellipsis): fixed on device (see captures); the 4.5% title
  scale is the documented cost of font-agnostic fit.
- UI 2 (body 4px high): no action — 6_bugs confirmed the body box was
  already exact and the ink remainder was BUG-9's punctuation.
- UI 3 (body punctuation): fixed via BUG-9; no ruling needed anymore.

## UI verification (sim 16e, `shot.sh` + `compare.py`, step 1)

- Light mean diff **4.05% → 3.92%** (bands 0–7: 2.03/5.54/5.03/6.43/0.89/
  3.95/4.37/3.12). Dark **3.85% → 3.83%**. Band 0 is the OS bar (ignored).
  Remaining card-band diff is font-rendering detail (Inter browser vs iOS
  rasterization, coin art, icon strokes) — no layout or copy deltas left:
  full titles, `Sat 4 Oct`, seeded-design subs, curly body, 400dp pager,
  dots/title/CTA all on the design rows; dark tokens identical to design;
  bottom edge is bar-surface to the physical edge.
- `shot.sh` "frame never stabilised" warning persists both themes (three
  iterations running; 6_bugs found no screen-side animation — dots resolve
  to zero duration, `PipAvatar` takes the SVG path, widget `pumpAndSettle`
  is instant; tooling/environmental, with the UI stage).

## Verification (in `app/`)

- `dart format .` — clean (0 changed on final pass).
- `flutter analyze` tail: `No issues found!`
- `flutter test` (full) tail: `00:10 +562: All tests passed!` (0 failed,
  0 skipped).

VERDICT: PASS
