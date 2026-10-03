# P07 Paywall — test report (Stage 3, iteration 2)

## Summary

The screen now exists. Iteration 1's 63-test contract suite turned red against
a placeholder; after the iteration-2 build (`paywall_view.dart` is 808 lines,
the bloc has the trial/restore events and `PaywallAction`/`PaywallRequest`,
the repository upserts and its copy matches the HTML) **the whole suite is
green**, and this iteration added 8 further tests for the paths the build
introduced.

**One real bug was found and recorded, not patched** (stage 3 may not edit the
screen): on the expired-trial paywall the close button is a no-op — P07-BUG-10.
Per the stage brief, `VERDICT: PASS` requires all tests passing *and* no bugs
found, so this iteration is a FAIL with a green suite.

| Run | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed .` | 367 files, 0 changed |
| `flutter analyze` (the 3 committed paywall test files) | **No issues found!** |
| `flutter test test/features/paywall/paywall_bloc_test.dart` | **+25** all passed |
| `flutter test test/features/paywall/paywall_view_test.dart` | **+53 ~1** all passed |
| `flutter test test/features/paywall/p07_bugs_test.dart` (stage 6) | **+14 ~2** all passed |
| `flutter test` (whole app) | **+742 ~3: All tests passed!** |

The 3 skips are all recorded defects with proof tests, by stage convention
(`6_bugs.md`: skipped while the defect is open, unskipped when fixed):
`[P07-BUG-8]` and `[P07-BUG-9]` (shared code, filed in
`docs/screens/P07/SHARED_REQUEST.md`) and `[P07-BUG-10]` (this stage, below).

## Tests added this iteration (all in `paywall_view_test.dart`)

The action events (`PaywallTrialStarted` / `PaywallRestoreRequested`,
`PaywallAction`, `PaywallRequest`, `copyWith(clearError:)`) landed with the
build, so the follow-up deferred in iteration 1 is now covered by
`paywall_bloc_test.dart`'s `PaywallBloc trial and restore actions` group
(working → success, failure + message per request, `startTrial` vs `activate`
delegation). Those tests were verified green, not rewritten. The 8 tests below
are new:

| Test | What it pins |
|---|---|
| `the hero scales down at 320dp` / `390dp` / `430dp` | the hero's fixed 350×148 frame scales as `min(w/350, 1)`: Pip's slot is 96px at 320, 120px at 390 and 430 (never upscaled), and the scene stays inside the 20px gutters |
| `Restore purchases never starts a trial` | the restore handoff writes `active` only — `trial_start` must still be `null`, proving `startTrialNow()` did not run on that path |
| `a failed trial toasts in place and stays on /paywall` | action failure: toast with the reason, no navigation, no `app_state` write, and the same CTA still works on retry (then `/today`, `onboarding_complete`, `trial_start` set) |
| `the CTA is disabled and spinning while the trial is in flight` | `working`: `NestButton.onPressed == null`, `loading == true`, `Restore purchases` loses its tap action, and a second tap never starts a second trial (one tap → one `startTrial()`) |
| `a restore request never shows the trial spinner` | `loading` belongs to the trial pill only — a restore never claims a trial is running |
| `an expired trial sends /today to the paywall` | the `trialExpired` guard (router.dart:90-93) with `subscription_status = 'expired'`: `/today` redirects to `/paywall` and the paywall renders — the only reachable shape of that guard today |
| `[P07-BUG-10] close escapes the expired-trial paywall` | **skipped proof** for the bug below |
| `tapping the plan card changes nothing` (strengthened) | scrolls the card into view first (the old tap never hit it and emitted a hit-test warning), then taps it and asserts the plan stays `selected: true` and nothing navigated |

Supporting changes to the test file only: the fake repository gained
`failTrial` and a `trialGate` `Completer` (to hold the screen in `working`), and
`_useFakePaywallBloc()` re-registers the DI `PaywallBloc` factory so the *whole
app* — router, session, navigation — can be driven by a failing or hanging
repository. `_pumpPaywall` gained a `route` parameter for the guard test.

## Bugs found

### P07-BUG-10 — major (latent today, trap once P07-BUG-8 lands) — the close button cannot leave the expired-trial paywall

**Where:** `app/lib/features/paywall/presentation/views/paywall_view.dart:27-34`

```dart
void _onBack(BuildContext context) {
  if (!context.mounted) return;
  if (context.canPop()) {
    context.pop();                       // ← line 30
  } else {
    context.go(PocketMoneyRoutePaths.setup);
  }
}
```

With the router's expired-trial guard (`app/lib/app/router.dart:90-93`,
`onboarded && session.trialExpired && location != '/paywall' → '/paywall'`),
`/today` is *redirected* to `/paywall`. A GoRouter redirect replaces the target
but leaves `/today` on the navigation history, so `context.canPop()` is **true**
here — unlike the onboarding case the `else` branch was written for. Tapping X
therefore pops to `/today`, the guard immediately redirects back to `/paywall`,
and the screen is a trap: the parent can never dismiss the paywall. Only
starting a trial or restoring purchases gets them out.

**Repro:**
```
cd app
flutter test test/features/paywall/paywall_view_test.dart \
  --run-skipped --plain-name 'P07-BUG-10'
```
→ `Expected: not '/paywall' / Actual: '/paywall'`.

Device-equivalent: onboard a family, let the trial lapse, open `/today` (the
app redirects to the paywall), press the X — nothing happens, forever.

**Severity and reachability:** latent today, because nothing in `app/lib` ever
writes `subscription_status = 'expired'` (P07-BUG-8, shared, filed in
`SHARED_REQUEST.md`). The moment that shared fix lands, this becomes a
blocker for the expired-trial user. Flagged here so the two are fixed
together.

**Suggested fix (build stage — not applied by stage 3):** make the target
explicit rather than history-dependent, e.g. pop only when the popped route is
actually dismissible, or `context.go(PocketMoneyRoutePaths.setup)` whenever the
session reports `trialExpired` (the `else` branch already lands somewhere
legal). A test that asserts *which* destination an expired-trial parent should
see is a product decision for the orchestrator; the proof test only requires
"X leaves the paywall".

## Carried over from iteration 1 (all now green, nothing outstanding)

- The screen surface: hero, `PipAvatar(mochi, sunny, stage 4, inNest)` on the
  120px slot, h1, 4 benefits, plan card, timeline, family note,
  `NestBottomCta` + caption + legal row.
- Copy character-by-character against `P07-paywall.html`, including the caption
  article “the” (P07-BUG-3) and the plan tag (P07-BUG-5) — the build fixed both
  at the repository source.
- Light + dark, 320/390/430, text scale 1.0 and 1.3, no overflow.
- 20px gutters on cards, scroll and bar; the bottom edge reaching the physical
  screen edge with the bar's own surface (painted-pixel proof, both themes,
  including a 34px home-indicator inset).
- Semantics labels on every control, ≥44dp parent targets, no kid controls.
- `initial` / `loading` / `loaded` / `failure` + Retry, and an empty plan list
  that is never an empty state.
- ORCHESTRATOR_NOTES 1: trial → `startTrialNow()` + `completeOnboarding()` →
  `/today`; restore → `active` + `completeOnboarding()` → `/today`; close →
  `/pocket-money-setup`.
- Identical screen under `Seed.demo` / `empty` / `fresh`, with no seeded child
  names leaking (DATA OVER MOCKS).

## Notes for the next stage

1. **Open shared findings.** `[P07-BUG-8]` (the trial never expires) and
   `[P07-BUG-9]` (kid-mode guard order) live in `core/` and `app/` — filed in
   `docs/screens/P07/SHARED_REQUEST.md`, out of this worktree's edit scope.
   Their proofs stay skipped until the orchestrator lands them; P07-BUG-10
   becomes reachable at that moment.
2. **`google_fonts` is gone** and none of this feature's `lib/` or `test/` files
   import it or call `GoogleFonts.*` (verified by grep).
3. **Concurrent scratch file.** While this stage ran, the Stage 6 (bugs) agent
   created `app/test/features/paywall/probe_scratch.dart` (its own header says
   it is temporary and deleted before that report lands). It is not
   auto-collected by `flutter test` (no `_test` suffix), so the suite above is
   unaffected; it does currently produce 13 `flutter analyze` infos, all inside
   that one file. Nothing else in the repo has analyze issues. Not deleted here
   — it is another stage's in-flight work.

## Verdict basis

All tests pass (`+742 ~3`), `dart format` is clean and the three committed
paywall test files analyze clean. But stage 3 may only pass when **no bugs are
found**, and P07-BUG-10 is a real defect in the screen's back navigation,
recorded above with a proof test and a repro. The build stage should fix it
(with P07-BUG-8 in mind) and unskip `[P07-BUG-10]`.

VERDICT: FAIL