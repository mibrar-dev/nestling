# P07 Paywall — build report (Stage 2 integration, iteration 3)

Integrator report over the two parallel builder chunks of iteration 3.
Sources: `docs/screens/P07/2a_build_logic.md` (logic),
`2b_build_ui.md` (UI), `1_plan.md`, `FIXES_2.md`, `ORCHESTRATOR_NOTES.md`,
`SHARED_REQUEST.md`.

## Summary of 2a (logic chunk)

One additive repository method, no event/state shape change:

- `domain/paywall_repository.dart` — added
  `readSubscription(): Future<SubscriptionStatus>` (one-shot read) with a
  `watchSubscription().first` default, so every existing fake keeps
  compiling.
- `data/paywall_repository_impl.dart` — overrode `readSubscription()` with a
  direct SELECT. 2a probe-verified that awaiting a fresh Drift watch stream
  inside a widget test never resolves, so the BUG-12 guard cannot use the
  watch stream.
- `presentation/bloc/paywall_bloc.dart` — P07-BUG-12 guard in
  `_onTrialStarted`: when `readSubscription()` reports `active`, skip
  `startTrial()` and emit `success(request: restore)` so the view takes its
  restore branch instead of downgrading a paying family to `trial`. Read
  errors fail open to the legacy trial path; the `working` double-tap guard
  is unchanged.
- Tests: `paywall_bloc_test.dart` grew to 29 (fake gained
  `subscription`/`failSubscription` + `readSubscription()`; four new tests for
  the active-guard, fail-open and the three seeds). `p07_bugs_test.dart` and
  `paywall_view_test.dart` each received the one-line `readSubscription`
  stub their fakes need to compile, delegating to the watch stream (never
  read by those fakes, so byte-identical legacy behaviour).

## Summary of 2b (UI chunk)

- `presentation/views/paywall_view.dart` — `_LegalLink` lost the expanding
  inner `Center` (it made each link a full-width `Wrap` run, stacking the
  legal row into five lines) and its label text is `maxLines: 1` /
  `softWrap: false`; the two `·` separators became
  `ExcludeSemantics(Text('·', …, softWrap: false))` (P07-BUG-11). The nav
  now wraps its row in a `ListenableBuilder` on `AppSession` and omits the
  close tile and its 44 px balance spacer while `session.trialExpired`
  (P07-BUG-10) — with the trial expired the router bounces every non-paywall
  location back, so a close control could never work.
- `paywall_view_test.dart` — a legal-row geometry regression test (no
  expanding `Center` in the link subtree) plus a structural plan-card
  presence assertion; the stage-3 `[P07-BUG-10]` proof rewritten to the
  fixed contract and un-skipped.
- `p07_bugs_test.dart` — `[P07-BUG-10]` rewritten to the same contract,
  `[P07-BUG-11]` and `[P07-BUG-12]` un-skipped.
- 2b verified on a real device (`ui/app_light_3.png`, read back directly):
  legal row on one run, compact panel, CTA at ~646, bottom edge still the
  bar's own surface, `compare.py` mean diff 11.43% → 5.48%.

## Integration work done here

None required. The two halves landed with matching public names
(`readSubscription()`, `PaywallAction`, `PaywallRequest`, the view's
`success(request: restore)` branch), so there were no BLoC state/event
mismatches, import breaks or renamed members to reconcile. `dart format`
reports 0 changed and the analyzer is clean as-is.

The only worktree delta at integration time was 2b's in-flight
`paywall_view_test.dart` (the legal-row test), which is committed by the
loop; nothing in it needed adjustment.

## FIXES_2 items — done

- **UI deviations 1/2/3 (5_ui: stacked legal row, oversized CTA panel,
  benefit 4 + plan card hidden behind it)** — root-caused to the expanding
  `Center` in `_LegalLink`; fixed screen-locally. One run now fits at 390 dp
  and the panel compacts to the design geometry.
- **P07-BUG-10 (major: close trap on the expired-trial paywall)** — fixed
  screen-locally by omitting the dead close affordance while
  `trialExpired`; both proofs rewritten to that contract and un-skipped.
- **P07-BUG-11 (announced `·` separators)** — `ExcludeSemantics` on both;
  proof un-skipped.
- **P07-BUG-12 (Start free trial downgrades an active subscriber)** — fixed
  in the bloc action path; proof un-skipped.
- **Iteration-1 bugs 1–7** — proofs stay un-skipped and green.
- **UI deviation 4 (title orphan "days")** — accepted and documented by 2b:
  the HTML's `text-wrap: balance` has no Flutter equivalent, a hard `\n`
  would break the exact-copy `find.text` pins, and the block height is
  unchanged. Not a screen defect.
- **Benefit 4 wrapping on device** — accepted font-metric drift between the
  bundled Inter build and the HTML mock's; the copy string is pinned
  verbatim, so it is not fixable from the UI layer.

## FIXES_2 items — LEFT (shared code, out of RULES §1 scope)

- **P07-BUG-8 (major):** the 14-day trial never expires — nothing in
  `app/lib` writes `subscription_status = 'expired'`, so the router guard is
  dead code. Owner `core/data/app_session.dart` (+ `app/launch.dart`);
  `SHARED_REQUEST.md` §1.
- **P07-BUG-9 (minor):** kid-mode + onboarding-incomplete deep link to
  `/paywall` lands on `/welcome` instead of `/parental-gate`. Owner
  `app/lib/router.dart`; `SHARED_REQUEST.md` §2.

Their two proof tests are the only remaining skips in the suite. They do not
block the screen, its handoff or a green run. Note that BUG-10's fix is the
screen half of the pair the bug hunt asked to land together: the close trap
can no longer occur when the shared expiry fix arrives.

## Orchestrator rules re-checked at integration

- ORCHESTRATOR_NOTES 1 holds on both paths: trial →
  `startTrialNow()` + `completeOnboarding()` → `/today`; restore →
  `setSubscription('active')` + `completeOnboarding()` → `/today`.
- COPY unchanged and still character-pinned; FONTS: grep for
  `google_fonts`/`GoogleFonts` in the feature's `lib/` and `test/` is clean;
  no `pip_stage_*.svg` anywhere; BOTTOM EDGE and ALIGNMENT still pinned by
  the painted-pixel and gutter tests, re-confirmed green.

## Analyze / test tails

```
$ dart format .
Formatted 369 files (0 changed) in 1.10 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 4.9s)

$ flutter test
00:22 +765 ~2: All tests passed!
```

Per-file feature runs:

```
test/features/paywall/p07_bugs_test.dart:      +17 ~2  All tests passed!
test/features/paywall/paywall_bloc_test.dart:  +29     All tests passed!
test/features/paywall/paywall_view_test.dart:  +55     All tests passed!
test/features/paywall/ (whole dir):            +101 ~2 All tests passed!
```

The 2 skips are `[P07-BUG-8]` and `[P07-BUG-9]` (shared code).

## Verdict basis

Stage 2 integration requires `dart format` clean, `flutter analyze` printing
`No issues found!`, and the full suite passing. All three hold: 369 files
formatted with 0 changes, no analyzer issues, 765 tests passing with only
the two documented shared-code skips left.

VERDICT: PASS
