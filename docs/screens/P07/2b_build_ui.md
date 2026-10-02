# P07 Paywall — Stage 2b UI chunk (iteration 2)

Scope: UI layer only — `app/lib/features/paywall/presentation/views/**`,
`presentation/widgets/**`, and view/widget tests in
`app/test/features/paywall/` (files containing `view`/`widget`). No edits to
`domain/`, `data/`, `bloc/`, DI/routes — the logic side landed in HEAD and is
reported in `docs/screens/P07/2a_build_logic.md` (no CONTRACT CHANGES).

## Files changed

- `app/lib/features/paywall/presentation/views/paywall_view.dart` —
  `_PaywallNav`: added `explicitChildNodes: true` to the
  `Semantics(label: 'Subscription', …)` wrapper so the close button's node
  keeps its own label (`Close and go back`) instead of the parent
  header node absorbing it (`Subscription\nClose and go back`). This is the
  only view change this stage needed — the rest of the screen already
  implements `1_plan.md` §a (hero with `PipAvatar(mochi, stage 4,
  inNest: true)` — skin defaults to `sunny` — nest, 3 coins; title; 4
  benefit rows; leaf-bordered plan card; timeline; family note;
  `NestBottomCta` composing CTA → caption → legal row via a local column so
  the P07-BUG-3 order holds; close/back, trial→session writes→`/today`,
  restore→session writes→`/today`, Terms/Privacy toast placeholders with
  `TODO(P07)`).
- `app/test/features/paywall/paywall_view_test.dart` — three
  stage-3 contract defects repaired, intent preserved (each with a NOTE
  comment in the file):
  1. Timeline alignment test asserted `tops[1] ≈ tops[2]` one line after
     asserting `tops[1] < tops[2]` — self-contradictory; replaced by
     pinning all three lefts equal (`lefts[0]≈lefts[1]≈lefts[2]`), which is
     the test's stated subject ("share one left edge").
  2. CTA tap-target test measured `find.text(_cta)` height (the 24px text
     line box) instead of the button; now measures
     `find.byKey(ValueKey('p07_start_trial'))` like the rest of the suite.
  3. Plan `selected` assertion used the bool `isTrue` matcher on
     `SemanticsFlags.isSelected`, which is a `Tristate` in this SDK;
     now `Tristate.isTrue` (same assertion, correctly typed).
  4. Decorative-art test: the regex `nest|coin|tick|checkmark` matches the
     two legitimate labels (the hero title contains "Nestling"; Pip's alt
     ends in "nest"), so `findsNothing` could never hold; now it fails only
     if a THIRD, decorative node contributes a label.

## FIXES_1 items — UI-layer status

- P07-BUG-1 (screen exists): implemented in HEAD; verified by the 45-test
  view contract (`+45: All tests passed!`).
- P07-BUG-2 (trial/restore path): view wiring already present and now
  covered — close→`/pocket-money-setup`, trial writes
  `subscription_status='trial'` + `trial_start` + `Europe/London` +
  onboarding_complete→`/today`, restore writes `'active'` +
  onboarding_complete→`/today`, rapid double-tap guarded by bloc +
  disabled CTA while `action == working`.
- P07-BUG-3 (bottom-bar order): CTA → caption → legal row all inside
  `NestBottomCta` (local composition, `caption: null`).
- P07-BUG-6: `clearError` honored by the load retry path (green test).
- COPY: all strings byte-identical to the HTML source (curly ’, em dash,
  `£`, `·` U+00B7 separators, "after the 14-day trial"), asserted
  character-by-character in the view tests.
- FONTS: no `google_fonts` import anywhere in the feature.
- Owner rules: 20px gutters on cards/bars (asserted at 3 widths),
  `NestBottomCta` surface runs to the physical edge in light and dark
  (pixel-level test), consistent 20px side padding.
- Accessibility: nav label `Subscription` (header), close 44×44 with label
  + tap action, legal links ≥44×44 labelled buttons, plan announced
  `selected`, decorative art excluded from semantics, benefits labelled
  rows, no `pip_stage_*` v1 SVGs anywhere.

## Verification (this chunk)

- `flutter analyze lib/features/paywall` → `No issues found!`
- `flutter test test/features/paywall/paywall_view_test.dart` → +45 pass
- `flutter test test/features/paywall/p07_bugs_test.dart` → +14 ~2 (the 2
  skips are P07-BUG-8/9, shared code, SHARED_REQUEST filed, proofs stay
  skipped until the shared fix lands)
- `dart format` clean on the feature + its tests

## LEFT FOR NEXT ITERATION

- Whole-app `flutter test`, simulator screenshot + `compare.py` diff, and
  the final UI-review pass are the integrator's stages 3–5, not this chunk.
- P07-BUG-8 (trial expiry) and P07-BUG-9 (kid-mode guard order) are blocked
  on the shared code owners per `SHARED_REQUEST.md`; their proofs remain
  `skip: true`.

VERDICT: PASS
