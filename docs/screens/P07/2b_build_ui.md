# P07 Paywall — Stage 2b UI chunk (iteration 3)

Scope: UI layer only — `app/lib/features/paywall/presentation/views/**`,
`presentation/widgets/**`, and view/widget tests in
`app/test/features/paywall/`. No edits to `domain/`, `data/`, bloc,
DI/routes (the parallel 2a chunk landed its `readSubscription()` +
BUG-12 active-guard in HEAD with no contract changes to the view).

## FIXES_2 items — UI-side resolution

1. **Legal row stacked vertically (5_ui deviation 1/2/3)** — root cause
   was two expanding boxes in `_LegalLink`: the inner `Center` behind the
   `InkWell` put each item at run-width, and a bare soft-wrapped `Text`
   for the `·` separator made it a full-width run item as well. Fix:
   `_LegalLink` now is `ConstrainedBox(44) > Material > InkWell > Padding
   > ExcludeSemantics(Text(label, maxLines: 1, softWrap: false))`; the
   separators are `ExcludeSemantics(Text('·', maxLines: 1,
   softWrap: false))`. Verified on a real device via `tools/screens/
   shot.sh` + read-back of the shot (`docs/screens/P07/ui/
   app_light_3.png`): all three links + both separators fit one centred
   run, the bottom panel is compact (CTA button at the design's ~646), and
   bands 4–6 of `compare.py` dropped from ~14–29% to ~2.5–10%. A
   regression test pins "no `Center` anywhere in the link subtree".
2. **P07-BUG-10 (expired-trial paywall close trap)** — the router makes
   every destination bounce, so a working X is impossible; the screen now
   omits the close tile and its 44px balance spacer while
   `GetIt.instance<AppSession>().trialExpired` (`ListenableBuilder` on
   `AppSession`, so the bar rebuilds on session changes). Both proofs
   (mine and stage 6's) were updated to this contract and un-skipped. The
   trial CTA + restore remain as the gate's exits. Product call on a
   permanent redirect/exemption belongs to the orchestrator.
3. **P07-BUG-11 (announced separators)** — both `·` separators are
   `ExcludeSemantics`; the skipped proof is un-skipped and green.
4. **P07-BUG-12 (active downgrade)** — fixed on the logic chunk
   (`PaywallBloc._onTrialStarted` emits `success(request: restore)`
   without `startTrial()` when already `active`); the view's restore
   branch then no-ops the active write + completes onboarding → `/today`.
   Proof un-skipped and green; the view needed no change for this one
   (it already takes the bloc's `success(request: restore)` down the
   restore branch).

## Accepted, documented as-is (stage-5 deviation 4)

Title wraps orphan-style (`...14` / `days`) — the HTML wants
`text-wrap: balance`, which Flutter's text engine has no equivalent for,
and a hard `\n` would break the exact-copy `find.text` pins. No layout
shift (same two-line block height); accepted.

Also note: benefit 4 wraps to two lines on the device because the bundled
Inter metrics render that line 2–3 em-spaces wider than the
HTML-mock's — accepted font-metric drift, not fixable from the UI layer (the copy string is pinned verbatim).

## Files changed

- `app/lib/features/paywall/presentation/views/paywall_view.dart` —
  `_LegalLink` chain without `Center`, `maxLines: 1`/`softWrap: false` on
  link text; dot separators in `ExcludeSemantics(...softWrap:false)`; nav
  now `ListenableBuilder` dropping `_close` tile + spacer while
  `session.trialExpired` (BUG-10).
- `app/test/features/paywall/paywall_view_test.dart` — new
  "legal row" geometry test (no expanding `Center` in link subtree +
  plan card still in the tree); stage-3 `[P07-BUG-10]` proof rewritten to
  the fixed contract (no dead close control on the expired gate; CTA +
  restore remain) and un-skipped.
- `app/test/features/paywall/p07_bugs_test.dart` — `[P07-BUG-10]` proof
  rewritten to the same contract, `[P07-BUG-11]` and `[P07-BUG-12]`
  proofs un-skipped. The edited proofs only assert the screen/bloc behaviour the fix promises; BUG-8/9 skips remain (shared code).

## Verification (this chunk)

- `flutter analyze lib/features/paywall` → `No issues found!`
- `flutter test test/features/paywall/paywall_view_test.dart` → +55 pass
- `flutter test test/features/paywall/p07_bugs_test.dart` → +17 ~2
- `dart format` clean.
- Real-device shot (`app_light_3.png`, read back directly): legal row on
  one line, compact panel compact, CTA at ~646, no page-coloured strip
  below the bar (Bottom-edge owner rule re-confirmed visually), and
  `compare.py` mean diff dropped from 11.43% to 5.48% with the CTA/bands
  4–6 no longer flagged as major mismatches.

## LEFT FOR NEXT ITERATION

- Dark-device shot + compare for iteration 3 is stage 5's pass.
- Real-device wrap of benefit 4 / title orphan documented above; not
  fixable from the UI layer (font metrics / text-engine balance) or by
  splitting the copy string (contract pins the exact string) — flag for
  the orchestrator to either accept or relax the comparison band.
- `[P07-BUG-8]` / `[P07-BUG-9]` remain open in shared code
  (`SHARED_REQUEST.md`), can't land here.

VERDICT: PASS
