# P14 · Rewards manager — Stage 2 integrate (iteration 3)

Owner: integrator. Inputs: `docs/screens/P14/2a_build_logic.md` (logic),
`2b_build_ui.md` (UI), the mandatory `ORCHESTRATOR_NOTES.md`, and
`FIXES_2.md` (B06/B07/B08 + stage-4 review findings).

**Gates: `dart format` 0 changed · `flutter analyze` → No issues found ·
`flutter test` → +2233 ~1: All tests passed. P14's own suite: +103, 0 failed,
0 skipped.** No code change was required — again.

## 0. ORCHESTRATOR_NOTES.md — every mandatory item re-verified in this worktree

| mandatory item | evidence | held? |
|---|---|---|
| List in **CREATION order**, never price | `rewards_repository_impl.dart:26` → `watchRewardsInCreationOrder(Seed.familyId)`; `grep orderBy|ORDER BY|coin_price` over the feature → **no hits** | yes |
| Baking `needsOk: false` | `seed.dart:524` | yes |
| Toggle state from the DB, never hard-coded | card reads `reward.needsOk`; `rewards_order_test.dart` runs both the screen layer and the seed insertion sequence live | yes |
| (12:35) use the shared creation-order query | wired (row 1) | yes |

## 1. Summary of the two halves

**2a — logic** (one lib file: `rewards_bloc.dart`; `rewards_bloc_test.dart`).
* **CONTRACT CHANGES: None** — no event/state/DI/route shape moved, so every
  existing call site compiles and behaves identically except the fixed defect.
* P14-B06 logic half: the `watchItems()` stream is now piped through
  `_closeOnError` (the `TodayBloc`/`PocketMoneyBloc` house pattern) — the
  first stream error is forwarded *and then the subscription closes*, so
  `emit.forEach` completes and cancels. Without it a stream error after data
  left a dead subscription alive and every `Try again` stacked another one.
* New test `a stream error after data keeps the rows and Try again recovers`
  with a `_DieAfterDataRepository`: loading → loaded(1) → failure (rows
  retained, `stream died`) → loading → loaded(1), asserting `watches == 2` —
  one recovery subscription, no stacked leak.

**2b — UI** (`views/**` + `widgets/**` + view/widget/state tests).
* **P14-B06 view half**: the `failure` branch drops the `items.isNotEmpty`
  short-circuit and always renders `_RewardsCenteredScroll(_RewardsFailure())`,
  so a dead stream always offers `Try again`. Added a stronger proof in
  `rewards_view_test.dart` (row on screen → stream dies → `Try again` present,
  card gone, copy shown, and `Try again` really re-subscribes).
* **P14-B07**: the inline write-error caption is now
  `Semantics(liveRegion: true, label: …, child: ExcludeSemantics(child: Text))`
  — announced once (the `NestTextField` error-row pattern).
* **P14-B08**: the hand-derived chrome arithmetic is **gone**; the sheet body is
  a loose `Flexible` + `SingleChildScrollView`, so the form is handed exactly
  the height the grabber/title left over, measured by the layout engine at any
  text scale — nothing left to drift from `NestBottomSheet`.
* Review finding 2 (duplicate announcement): the sheet's visible `Needs my OK`
  twin is now `ExcludeSemantics`; the switch keeps the label, `toggled`,
  `enabled` and its tap action, so the row announces once.
* Layout deliberately untouched: title, intro, card geometry, gutters and the
  `+ New reward` button already measure Δ0; this round was behaviour, not
  layout.

## 2. Integration audit across the seam

This round's real risk was **B06's two halves being individually correct but
mutually incompatible**, so the cross-half contract got the most attention:

| concern | check | result |
|---|---|---|
| 2b's unconditional failure surface is only safe because of 2a's contract | 2b's reasoning needs "writes never emit `failure`"; verified in the bloc that `_onNeedsOkChanged` completes the `result` channel instead of emitting, and that the **only** `failure` emit left is the stream's own `onError` in `_onLoadRequested` | holds — the branch is reachable only by a stream error |
| 2a's `Try again` can actually re-subscribe | `_closeOnError` closes the subscription *after* forwarding, so the handler completes; with bloc's concurrent default a retry would otherwise stack a second subscription on a dead one | fixed at the root; `watches == 2` proves one clean recovery |
| the `result` channel still has no orphan (an unheard `completeError` would fail the suite) | 4 channels created, 4 consumers — `_changeNeedsOk` awaits in a `try`, `saveReward`/`deleteReward` return the future the sheet awaits | consistent |
| B08's layout change did not move the resting sheet | the "no keyboard → sheet 422→794, Save 682→734" proof still passes (loose `Flexible` shrink-wraps) | no drift |
| B07's `Semantics` node vs the ACCESSIBILITY rule | the caption is non-interactive text with `liveRegion` + `label` + `ExcludeSemantics` on the `Text` child only — no control is wrapped, so no `onTap:` is owed | compliant |
| duplicate-announcement fix kept one activatable node | the a11y "one activatable node per label" proof still passes | holds |
| **the skip count went UP vs iteration 2** (0 → 1) | traced it: the single `~1` is `test/features/pocket_money/p12_bugs_test.dart` (P12-BUG-05) — **another feature's file**, not P14. `grep skip:` over `test/features/rewards/` → none | not ours, not a P14 regression |
| rule greps | no `skip:`, no `// ignore`, no `google_fonts`/`GoogleFonts`, no `letterSpacing` in the feature | clean |
| scope (RULES §1) | `git status --porcelain -- app/lib/core app/lib/app tools/` → **empty** | shared code untouched; all work inside `features/rewards/**` + `test/features/rewards/**` |

## 3. FIXES

### Done (this stage)
- **None required.** No mismatched BLoC states/events, no import breakage, no
  renamed members, no test broken by the merge of the two halves, and no
  lint-suppression left in the feature's tests (the two
  `// ignore: unawaited_futures` this file's iteration 2 removed stayed gone —
  verified, not assumed).
- Both halves' proof sets survived intact, including the files 2b and 2a
  edited concurrently (`p14_bugs_test.dart`, `rewards_bloc_test.dart`,
  `rewards_view_test.dart`): all of B01–B08 and `ORDER` are live and green,
  and the feature's skip count is **0**.

### Left / open (carried forward — no code change here)

1. **Review finding 1 — the raw exception in the sheet caption.** 2b
   deliberately did **not** resolve it, and neither did I: stage 4 wants
   `Could not save the reward. Please try again.` while stage 6 read the
   technical tail as the build's stated contract, and the `[P14-B07]` proof
   locates the caption with `find.textContaining('disk full')`. Two stages
   cannot both be right, and the judgement call belongs in a spec, not in a
   test quietly relaxed. **Needs an orchestrator ruling** — (a) drop `$error`
   and re-point the locator, or (b) keep the tail and close the finding.
2. **Stage 5 re-measure** — the layout did not move but the visible data did
   (`Baking together` renders **off**, `Choose dinner` sits below the fold).
   Report title y, intro y and each card top, design vs app.
3. **`SHARED_REQUEST.md` still open** — the shared `showNestBottomSheet`
   `viewInsets` hole (P14 keeps a correct feature-local opener until it lands)
   and `NestIconButton.shape` (the 44×44 radius-12 `.editbtn`).
4. **Pre-existing token observation, not changed here:** the 40×40 icon tile
   (`p14_reward_card.dart:61-62`) and the `Colors.transparent` modal barrier
   (`rewards_view.dart:280`, matching the shared `showNestBottomSheet`
   precedent) are design-derived values with numeric test assertions, not
   integration breakages — left alone rather than redesigned.
5. `Reward.detail` still carried but unused by P14 (per plan §2).

## 4. Verification tails (final state, `app/`)

```
$ dart format .
Formatted 470 files (0 changed) in 1.26 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.3s)

$ flutter test                        # full app
00:50 +2233 ~1: All tests passed!

$ flutter test test/features/rewards/ # P14 only
00:04 +103: All tests passed!
```

The one `~1` (skipped) is `test/features/pocket_money/p12_bugs_test.dart`
(P12-BUG-05) — another feature's file, outside this worktree's scope and not
caused by P14. P14's 103 tests: 0 failed, 0 skipped. The
`WARNING (drift): … created the database class AppDatabase multiple times`
lines are pre-existing noise from other features' parallel in-memory
databases (present on `main` and in every other screen's suite) — warnings,
not failures — and are filtered from the tails above.

No simulator was booted, installed on, screenshotted or driven at any point in
this stage.

VERDICT: PASS