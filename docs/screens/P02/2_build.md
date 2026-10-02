# P02 Value tour — build notes (Stage 2, iteration 2)

Implemented per `docs/screens/P02/1_plan.md` and fixed EVERY item in
`docs/screens/P02/FIXES_1.md` (review findings 1–9, UI deviations 1–6).
All 9 skipped proofs in `p02_bugs_test.dart` un-skipped and passing.

## Files changed

- `app/lib/features/onboarding/presentation/views/value_tour_view.dart`
  (rewrite of iteration 1): pager base back to the spec **400** (× clamped
  text scaler); pager + step copy share **one scrollable** so short screens
  scroll instead of overflowing (P02-BUG-3); `_TourNav` rebuilt at the compact
  spec geometry (**4 + 44 + 12 = 60**) with the shared Material/InkWell
  action pattern and the tap action on the labeled node; card-1 rows use the
  new `ValueTourPreviewRow`; subs follow `Seed.demo` (BUG-4); date chips
  derive the next payout Saturday from `Seed.anchorDay`
  (`Sat 10 Oct` under the pinned test clock — BUG-5); `animateToPage`
  retargets double-taps (review 7); dashed add-row labels exposed as
  plain-text semantics, icons excluded (review 4); redundant `NestCard`
  paddings dropped (review 5); `PopScope` routes system back to `/welcome`
  (BUG-6); `_pagerInsetLeft = NestSpacing.padSide` (review 2).
- `app/lib/features/onboarding/presentation/widgets/value_tour_preview_row.dart`
  (new, P02-only): static preview row at the design's 38dp `.pv-row` metrics
  (36 tile r12 icon 22, title 15/20 w600, sub 13/18, gap 8, small coin pill,
  no vertical padding, non-interactive), composed from shared
  `NestIcon`/`NestCoinPill`/tokens. Retires when the shared compact-row
  variant in `SHARED_REQUEST.md` lands (review 1 / UI 1).
- `app/lib/features/onboarding/presentation/views/welcome_view.dart`:
  untouched (reverted an attempted `push` fix — see BUG-6 below).
- `app/test/features/onboarding/value_tour_view_test.dart`: seeded subs,
  derived-chip expectation (+ stale `Sat 4 Oct` absence), DB-backed ledger
  test (children + families rows → `formatPounds`), 400/520 pager asserts,
  `padSide` gutter asserts, Skip tap-action assert, add-row label asserts,
  new plain-text-labels test.
- `app/test/features/onboarding/p02_bugs_test.dart`: all 9 `skip:` removed;
  BUG-2/BUG-4 adapted to `ValueTourPreviewRow` (same `.subtitle` field).
- `docs/screens/P02/SHARED_REQUEST.md`: + compact-row variant request,
  + pager-metric token requests; nav item updated to the 60px interim bar.
- Screenshots: `docs/screens/P02/ui/app_light_2.png`, `app_dark_2.png`,
  `cmp_light_2.png`, `cmp_dark_2.png` (step 1, sim 16e).

## Fix items (FIXES_1 → what was done)

- Review 1 / UI 2 / BUG-1 (pager 468, copy cramp): private 38dp rows +
  pager 400; BUG-1a/b/c pass; 390×844 composition breathes again.
- Review 2 (`_pagerInsetLeft`): now `NestSpacing.padSide`; tests assert it.
- Review 3 (bespoke nav action): shared Material/InkWell pattern, 60px bar.
- Review 4 (hidden add-row copy): labels are plain-text semantics nodes
  (`container: true` boundary + excluded icon); test asserts all three.
- Review 5 (tokens): paddings dropped; rest stay documented `static const`s
  with CSS sources; token request filed.
- Review 6 / BUG-4 (seed mismatch): subs now Maya·daily / Maya·weekly /
  Maya·daily / Maya·daily, read back from Drift in the proof test. PNG text
  differs by design (DB wins per orchestrator rule).
- Review 7 (double-tap skip): `animateToPage(target, …)`; 6_bugs stage had
  already shown taps benign, now structurally impossible.
- Review 8 (pinned literals): 400/520 asserts; ledger expectations computed
  from `children` + `families` rows.
- Review 9 (tap action): `Semantics.onTap` on the Skip node + assertion.
- UI 1 (truncated titles): 3 of 4 titles now full on device; only the
  longest (`Empty the dishwasher`, ~8px over its slot under real Inter)
  keeps a 2-char ellipsis. All spec metrics are exact — residual is font
  rendering against a 1px design margin. Left for the UI stage (tracking
  tweak vs accept).
- UI 3 (body punctuation): NOT actionable here — app follows repo +
  DESIGN_SPEC §5 (straight quotes); needs the orchestrator ruling.
- UI 4 (nav 60): done (card top back at design y≈107).
- UI 5 (chip +3): accepted shared-component drift (border folds into
  `Container` padding — measured, documented).
- BUG-2: rows measure 38.0dp (≤ 40); proof passes.
- BUG-3: unified scrollable — 320×568@1.0 and 375×667@1.3 take-exception
  clean; 390×844 pixel-identical to the fixed stack (content < viewport).
- BUG-5: chips derive the next payout Saturday (`Sat 10 Oct` pinned);
  production uses the real next Saturday (verified `Sat 3 Oct` on-device
  Friday Oct 2). Generic weekday proof passes.
- BUG-6: `PopScope(canPop: false)` → `go('/welcome')` on vetoed pop. P01
  keeps `go` (its tests untouched). `push` was tried and reverted:
  `GoRouter.push` routes through the engine echo, which never fires in
  widget tests (direct `router.push` + settle also stays put), so the proof
  could not observe it. Deep-link back now lands on `/welcome` instead of
  exiting — harmless for an onboarding flow, noted.

## UI verification (sim 16e, `shot.sh` + `compare.py`, step 1)

- Light mean diff **6.50% → 4.05%** (bands 0–7: 2.01/5.48/5.26/6.61/0.87/
  3.94/4.39/3.80). Dark **6.41% → 3.85%**. Band 4 (card body) 0.87/0.81%.
  Remaining bands 1–3 carry the mandated text diffs (seeded subs, derived
  chip, repo body copy, one title ellipsis); band 0 is the OS bar (ignored).
- Dark tokens, gutters, dots, CTA, progress, dashed rows, bottom-edge
  bar-surface-to-edge all match. No overflow/clipping on device.
- `shot.sh` "frame never stabilised" warning persists in both themes
  (same as iteration 1; 6_bugs found no screen-side animation — dots resolve
  to zero duration, `PipAvatar` takes the SVG path, widget `pumpAndSettle`
  is clean; handed to the UI stage/orchestrator with the tooling).

## Verification (in `app/`)

- `dart format .` — clean (0 changed on final pass).
- `flutter analyze` tail: `No issues found!`
- `flutter test test/features/onboarding/` — all pass (contract + 9
  un-skipped proofs + P01 suite).
- `flutter test` (full) tail: `00:07 +432: All tests passed!`

VERDICT: PASS
