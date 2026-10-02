# P07 Paywall — build report (Stage 2 integration, iteration 2)

Two builders worked in parallel on the P07 paywall; this file is the
integrator's report over the combined result. Sources:
`docs/screens/P07/2a_build_logic.md` (logic), `2b_build_ui.md` (UI),
`1_plan.md`, `FIXES_1.md`, `ORCHESTRATOR_NOTES.md`, `SHARED_REQUEST.md`.

## Summary of 2a (logic chunk)

No CONTRACT CHANGES; the logic layer was already in HEAD and was verified,
not rewritten.

- `presentation/bloc/paywall_event.dart` — `PaywallLoadRequested`,
  `PaywallTrialStarted`, `PaywallRestoreRequested` (`1_plan.md` §b names).
- `presentation/bloc/paywall_state.dart` — `status` +
  `action: PaywallAction{idle, working, success, failure}` +
  `request: PaywallRequest{none, trial, restore}` discriminator (trial must
  not call `startTrialNow()` on the restore path) + `copyWith(clearError:)`.
- `presentation/bloc/paywall_bloc.dart` — `_onTrialStarted` → `startTrial()`
  → success/failure, `_onRestoreRequested` → `activate()` →
  success/failure, both with a `if (state.action == working) return;`
  double-tap guard.
- `data/paywall_repository_impl.dart` — `_upsert` mirroring
  `AppSession._write` (P01 BUG-4 class), and the single annual plan whose
  `detail` carries the design copy: sub without a stray full stop, caption
  with the article "the", tag included, em-dash separators.
- `test/features/paywall/paywall_bloc_test.dart` — 25 tests (status machine,
  live/empty/error streams, action transitions with the discriminator,
  repository under demo/empty/fresh).

One documented deviation, kept: the view resolves `AppSession` through
`GetIt.instance<AppSession>()`, not `context.read<AppSession>()` — it is
registered in GetIt (`app/lib/app/di.dart`) but is not a Provider ancestor
(`app/lib/app/app.dart`). Read-only; no shared edit needed.

## Summary of 2b (UI chunk)

- `presentation/views/paywall_view.dart` — the full `1_plan.md` §a screen:
  `_PaywallNav` (compact bar, 44×44 surface-2 close tile, label
  `Subscription`), `_PaywallHero` (350×148 frame with P01's
  LayoutBuilder scale-down pattern; lilac-tint circle 170 at (90,−5), nest
  150 at (100,41), `PipAvatar(style: mochi, stage: 4, inNest: true)` 120 at
  (115,20), three coins at the design positions/rotations with `--sh-1`),
  `_PaywallTitle` (h1, centred, maxLines 3), `_BenefitList` (4 rows, 24px
  leaf-tint tick + Inter 15/24), `_PlanCard` (`NestCard` geometry + local 2px
  leaf border + selected radio + title/sub/tag, `selected: true` announced),
  `_TimelineCard` (margin-top 48, three steps, 24px dots, 2px connectors),
  `_FamilyNote`, and `_PaywallCta` inside `NestBottomCta` composing
  CTA → caption → legal row through a local column (`caption: null`), which
  is how P07-BUG-3's order holds without re-implementing the bar surface.
  Scroll body is `SingleChildScrollView` + `Column` (the sliver delegate's
  `IndexedSemantics` wrapper hijacked descendant labels in widget tests and
  built lazily, hiding below-fold copy). Close → `/pocket-money-setup`;
  trial/restore → session writes → `/today` via `BlocListener`; Terms and
  Privacy answer in place with a toast behind `TODO(P07)`.
  The chunk's one view change: `explicitChildNodes: true` on the nav's
  `Semantics` wrapper.
- `test/features/paywall/paywall_view_test.dart` — four stage-3 contract
  defects repaired with intent preserved, each with a NOTE comment in the
  file (self-contradictory `tops[1] ≈ tops[2]`; CTA tap target measured on
  `find.text` instead of the button key; `Tristate.isSelected` compared with
  the bool `isTrue` matcher; decorative-art regex that legitimately matches
  the hero title and Pip's alt).

## Integration work done here

The combined result needed one cleanup, no redesign:

1. **Deleted `app/test/features/paywall/zz_debug_test.dart`** (leftover
   semantics-dump helper committed in `fdc4238` "P07: wip before sync"). It
   duplicated the 2b stage's diagnosis work and read the deprecated
   `tester.binding.pipelineOwner`, which `flutter analyze` flags
   (`deprecated_member_use`). 2b's report explicitly listed it as its own
   debug helper, so removing it is not a redesign.
2. `dart format .` → `0 changed`; no import, BLoC state/event or member
   mismatches remained between the halves — 2a and 2b agreed on every
   public name, so there was nothing to reconcile.

## FIXES_1 items — done

- **P07-BUG-1** (screen exists): implemented; 45-test view contract green.
- **P07-BUG-2** (trial/restore path, ORCHESTRATOR_NOTES 1 mandatory):
  events + action/request state + session writes + `/today` navigation;
  verified by reading `app_state` after a tap (`trial` + `trial_start` +
  `Europe/London` + onboarding complete; restore writes `active` and is
  never downgraded), plus the rapid double-tap guard.
- **P07-BUG-3** (bottom-bar order): CTA → caption → legal row inside
  `NestBottomCta`.
- **P07-BUG-4** (caption "the"): fixed at the data source.
- **P07-BUG-5** (sub punctuation + tag data source): fixed; the tag is
  reachable from the data layer.
- **P07-BUG-6** (stale error survives retry): `clearError` path.
- **P07-BUG-7** (UPDATE-only writes): `_upsert`.
- **P07-BUG-1/2/3/4/5/6/7** proofs un-skipped in
  `p07_bugs_test.dart` and passing.
- COPY, FONTS, PIP, ALIGNMENT, BOTTOM EDGE: asserted by the suite
  (character-by-character copy, no `google_fonts` anywhere in the feature,
  `PipAvatar` v2 and no `pip_stage_*.svg`, 20px gutters at 320/390/430,
  bottom-edge painted-pixel check in light and dark).

## FIXES_1 items — LEFT (documented, not screen-local)

- **P07-BUG-8** (major, shared): the 14-day trial never expires — nothing in
  `app/lib` writes `subscription_status = 'expired'`, so the router guard is
  dead code. Owner: `core/data/app_session.dart` (+ `app/launch.dart`).
- **P07-BUG-9** (minor, shared): kid-mode + onboarding-incomplete deep link
  to `/paywall` ends on `/welcome` instead of the parental gate. Owner:
  `app/lib/router.dart` (guard order).

Both are filed in `docs/screens/P07/SHARED_REQUEST.md`; their proof tests
remain `skip: true` (the only 2 skips in the suite) until the shared fix
lands. Neither blocks the P07 screen, its handoff or the green suite.

## Analyze / test tails

```
$ dart format .
Formatted 367 files (0 changed) in 0.76 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 2.8s)

$ flutter test
00:15 +734 ~2: All tests passed!
```

Per-file feature runs:

```
test/features/paywall/p07_bugs_test.dart:    +14 ~2  All tests passed!
test/features/paywall/paywall_bloc_test.dart: +25    All tests passed!
test/features/paywall/paywall_view_test.dart: +45    All tests passed!
test/features/paywall/ (whole dir):           +84 ~2  All tests passed!
```

## Verdict basis

Stage 2 integration requires `dart format` clean, `flutter analyze` printing
`No issues found!`, and the full suite passing. All three hold: 367 files
formatted with 0 changes, no analyzer issues, and 734 tests pass with only
the two documented shared-code skips remaining.

VERDICT: PASS
