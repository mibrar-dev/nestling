# P07 Paywall — build report (Stage 2 integration, iteration 4)

Integrator report over the two parallel builder chunks of iteration 4.
Sources: `docs/screens/P07/2a_build_logic.md` (logic), `2b_build_ui.md` (UI),
`1_plan.md`, `FIXES_3.md`, `ORCHESTRATOR_NOTES.md` (incl. its iteration-4
update), `SHARED_REQUEST.md`.

## Summary of 2a (logic chunk)

No CONTRACT CHANGES and no file edits — FIXES_3 contains no logic-layer
items. The layer was re-verified as-is and needed nothing:

- `domain/paywall_repository.dart` — `readSubscription()` with the
  `watchSubscription().first` default (unchanged).
- `data/paywall_repository_impl.dart` — one-shot SELECT override, `_upsert`
  writes, HTML-exact plan copy (unchanged).
- `presentation/bloc/paywall_bloc.dart` — trial/restore actions, the
  P07-BUG-12 active-subscription guard (fail-open, emits
  `success(request: restore)`), double-tap `working` guard,
  `copyWith(clearError:)` (unchanged).
- `paywall_bloc_test.dart` — 30 tests including stage 3's one-shot-budget
  test for `readSubscription`.

2a explicitly confirmed P07-BUG-13 is a view-layer defect
(`_LegalLink` paragraph geometry) and that un-skipping it from the logic
side would only turn the suite red — correctly left to 2b.

## Summary of 2b (UI chunk)

One view edit, one proof un-skipped:

- `presentation/views/paywall_view.dart` — `_LegalLink`'s inner `Padding`
  gained symmetric vertical insets `(NestDevice.tapParent - 18) / 2` (13).
  Root cause: iteration 3 removed the expanding `Center` (which stacked the
  legal row into five lines) and with it the vertical centring; the
  `ConstrainedBox`'s 44 px min-height forced the `RenderParagraph` to 44 px
  tall and a paragraph paints its line at the box top, leaving every link
  13 px above the centred `·` separators. The inset maths
  (`centre − half the 18 px line`) also holds at 1.3 × text scale, where
  centre-of-text stays half the box.
- `p07_bugs_test.dart` — `[P07-BUG-13] the legal links share the separators'
  baseline` un-skipped and green.
- 5_ui iteration-3 deviation 2 (separators ~10 px below the link baseline)
  resolved as a consequence: both glyph families now centre in the same
  44 px band and share one baseline.
- ORCHESTRATOR_NOTES iteration-4 update: item 1 (benefit-4 wrap) needed no
  code change — the merged `fd92d95` budget set `NestType` letterSpacing to
  0, restoring HTML-matched advance widths, and the new light/dark shots
  render `Co-parent sharing, so James sees the same` on one line with the
  plan card's tag fully above the CTA. Item 2 (same 44 px centred box for
  separators) is covered by the BUG-13 centring; the powered box stays 44 px
  because the `Wrap` run height is unchanged. Item 3 (title orphan "days")
  accepted, no hard break inserted.
- Verified on device (`ui/app_light_4.png`, `app_dark_4.png`): legal row on
  one run with `·` on the link baseline, benefit 4 on one line, plan card and
  tag above the CTA, bottom edge running to the physical edge in both themes.
  `compare.py` mean diff: light 2.56%, dark 2.48% (iteration 3: 5.48% /
  5.28%).

## Integration work done here

None required. 2a declared no contract change, so 2b's view code still
consumes the iteration-3 bloc/repository seams unchanged. No BLoC
state/event mismatch, import break or renamed member appeared in the merge.
The only worktree deltas at integration time were the two 2b edits above
plus its untracked device shots, which the loop commits.

## FIXES_3 items — done

- **P07-BUG-13 (major: legal-link labels top-aligned, 13 px off)** — fixed
  screen-locally by the vertical-centring inset; proof un-skipped and green.
- **5_ui deviation 2 (separators below the link baseline)** — resolved by
  the same fix (one shared 44 px band for both glyph families).
- **5_ui deviation 1 (benefit-4 wrap → plan tag clipped)** — resolved by the
  merged shared budget `fd92d95` (`NestType` letterSpacing 0), which 2b
  confirmed on new light/dark shots: benefit 4 on one line, plan tag fully
  visible above the CTA panel. No screen change, and deliberately no text
  shrink or copy edit.
- **ORCHESTRATOR_NOTES iteration-4 update** — items 1 and 2 satisfied as
  above, item 3 (title orphan) accepted minor, no hard break added.
- **Iteration-1/2 bugs 1–12** — proofs remain un-skipped and green.

## FIXES_3 items — LEFT (shared code, out of RULES §1 scope)

- **P07-BUG-8 (major):** the 14-day trial never expires — nothing in
  `app/lib` writes `subscription_status = 'expired'`, so the router guard
  (`app_session.dart` + `app/launch.dart`; `SHARED_REQUEST.md` §1) stays
  dead code. P07-BUG-10's screen half already landed, so no close trap will
  appear when this does.
- **P07-BUG-9 (minor):** kid-mode + onboarding-incomplete deep link to
  `/paywall` lands on `/welcome` instead of `/parental-gate` (guard order in
  `app/lib/app/router.dart`; `SHARED_REQUEST.md` §2).

Their two proofs are the suite's only remaining skips.

## Orchestrator rules re-checked at integration

- ORCHESTRATOR_NOTES 1 still holds on both paths: trial →
  `startTrialNow()` + `completeOnboarding()` → `/today`; restore →
  `setSubscription('active')` + `completeOnboarding()` → `/today`.
- LETTER SPACING (main `fd92d95`): no tracking is added at any call site in
  this feature; the `NestType` default of 0 is relied on, which is what fixed
  the benefit-4 wrap.
- FONTS: grep for `google_fonts`/`GoogleFonts` in the feature's `lib/` and
  `test/` is clean; no `pip_stage_*.svg`; COPY unchanged and still pinned
  character-by-character; BOTTOM EDGE and ALIGNMENT still covered by the
  painted-pixel, gutter and BUG-13 baseline tests.

## Analyze / test tails

```
$ dart format .
Formatted 370 files (0 changed) in 1.14 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 5.5s)

$ flutter test
00:48 +801 ~2: All tests passed!
```

Per-file feature runs:

```
test/features/paywall/p07_bugs_test.dart:      +18 ~2  All tests passed!
test/features/paywall/paywall_bloc_test.dart:  +30     All tests passed!
test/features/paywall/paywall_view_test.dart:  +59     All tests passed!
test/features/paywall/ (whole dir):            +107 ~2 All tests passed!
```

The 2 skips are `[P07-BUG-8]` and `[P07-BUG-9]` (shared code). No scratch or
probe files remain in `app/` (stage 3's iteration-3 `probe_iter3.dart`
noted in `FIXES_3` is gone; `flutter analyze` is clean app-wide).

## Verdict basis

Stage 2 integration requires `dart format` clean, `flutter analyze` printing
`No issues found!`, and the full suite passing. All three hold: 370 files
formatted with 0 changes, no analyzer issues, and 801 tests passing with
only the two documented shared-code skips left.

VERDICT: PASS
