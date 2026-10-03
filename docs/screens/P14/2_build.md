# P14 · Rewards manager — Stage 2 integrate (iteration 2)

Owner: integrator. Inputs: `docs/screens/P14/2a_build_logic.md` (logic),
`2b_build_ui.md` (UI), plus the mandatory `ORCHESTRATOR_NOTES.md` and
`FIXES_1.md` (stage 4 review → stage 6 bugs → this rebuild).

**Gates: `dart format` 0 changed · `flutter analyze` → No issues found ·
`flutter test` → +1870: All tests passed (1870 ran, 0 failed, 0 skipped).**
One integration-hygiene fix was applied (2 `// ignore:` comments removed);
everything else was already coherent.

## 0. ORCHESTRATOR_NOTES.md — mandatory items verified in THIS worktree

The notes file appeared this iteration and every item is mandatory, so each was
checked against the code and the shared branch, not against the builders' prose:

| mandatory item | verified how | result |
|---|---|---|
| List in **CREATION order**, never price order | `RewardsRepositoryImpl.watchItems()` serves `_db.watchRewardsInCreationOrder(Seed.familyId)`; `grep` finds **no** price sort left anywhere in the feature (only `coinPrice` *column writes*) | DONE (2a) |
| Shared seed/DB work present (`shared/rewards_seed_order`) | `app_database.dart` has `watchRewardsInCreationOrder` (line 556) and the `rewards.created_at` + `created_at_tz` migration (v4→v5, line 351/419) | present on this branch |
| "Baking together" `needsOk: false`, as in the design | `seed.dart:524` → `await reward('r-baking', …, needsOk: false);` | present on this branch |
| Do not hard-code the toggle state; it comes from `needsOk` | the card reads `reward.needsOk`; the tests assert DB-driven `rewardNeedsOk` | compliant |
| (12:35) use `AppDatabase.watchRewardsInCreationOrder` | wired, see row 1 | DONE |

Net effect on the baseline: rows now render 50 → 80 → 60 → 100 → 150 → 90
(the design's five, then `Choose dinner` below the fold) with Baking's toggle
**off** — the design's own state, previously overridden by the old seed.

## 1. Summary of the two halves

**2a — logic** (`bloc/**` + `data/rewards_repository_impl.dart`, 26 tests).
* **Contract change (additive):** all four write events gained an optional
  `Completer<void>? result`. Success → `result.complete()`; failure →
  `result.completeError(error)`; the channel is excluded from Equatable
  `props`. The write-failure `failure` emit was **removed**, so a failed write
  can no longer replace the loaded list with a full-screen error (review
  finding 1 / P14-B03 root cause). The stream's own error remains the only
  source of `failure` — the `Try again` path.
* `watchItems()` → `watchRewardsInCreationOrder` (P14-B05).
* `deleteReward` now removes the reward **and** its `reward_redemptions` rows
  in one transaction (P14-B04; app-wide FKs are off, so the old version
  orphaned redemption rows).
* Un-skipped `[P14-ORDER]`, `[P14-B04]`, `[P14-B05]`; rewrote the bloc failure
  group around the channel.

**2b — UI** (`views/**` + `widgets/**`, view/widget/state tests).
* `_submit()`/`_delete()` are `async`, await the channel, keep the sheet open
  with a `danger` inline caption on error, and guard against a double write
  with `_saving` (review 1.3–1.4, P14-B03).
* `_RewardsCenteredScroll` (`LayoutBuilder` + `SingleChildScrollView` +
  `minHeight` + `Center`) centres the empty and failure surfaces in the
  viewport (review 4 / P14-B02) and `_RewardsScroll` no longer appends the
  16 px trailing spacer (review 3).
* Full-screen failure renders static `RewardCopy.loadError` only; the raw
  exception stays technical (review 2).
* P14-B01 keyboard fix: feature-local `showRewardEditorSheet` (no `constraints`
  cap) + the sheet pads by `viewInsetsOf(context).bottom` and caps/scrolls its
  own form. `SHARED_REQUEST.md` filed for the shared helper. The resting
  (no-keyboard) layout is unchanged.
* Copy moved to `RewardCopy`, `SizedBox(6)` → `NestSpacing.gap6`,
  `44.0` → `NestDevice.tapParent`, `reward!` force-unwrap removed (review 5–6).
* Un-skipped B01/B02/B03; updated the failure-state assertions.

## 2. Integration audit across the seam

| concern | check | result |
|---|---|---|
| the new `result:` contract is actually used, not just declared | `grep -rn "result:"` → **4** call sites (`RewardsNeedsOkChanged`, create, update, delete), all in `rewards_view.dart` | wired |
| **no orphan channel** (a `completeError` with no listener is an unhandled async error that would fail the suite) | every site either `return result.future` (`saveReward`, `deleteReward`) or `await`s it in a `try` (`_changeNeedsOk`, sheet `_submit`/`_delete`) — 4 channels, 4 consumers | consistent |
| sheet callback types match the view's new async helpers | `onSave: Future<void> Function(Reward)`, `onDelete: Future<void> Function()`; view passes `saveReward(…)` / `deleteReward(…)`, with `existing == null ? () async {} : …` replacing the force-unwrap | types line up |
| bloc ↔ view on failure semantics | writes no longer emit `failure`; `_RewardsFailure` is now only reachable from the stream error, which is what its static copy and `Try again` assume | coherent |
| parallel edits to one file (`p14_bugs_test.dart` — **both** builders touched it) | `grep -rn "skip:" test/features/rewards/` → **none**; all five proofs `P14-B01…B05` present | last-writer did not lose the other's un-skips |
| tests pinned to the new seed/order | bloc + repository tests pin creation order `[r-screen, r-film, r-bedtime, r-baking, r-cafe, r-dinner]` and the seeded `needsOk` map | DB-driven, nothing hard-coded |
| copy vs HTML source | `RewardCopy` intro (em dash U+2014), `+ New reward` (ASCII `+`), `Needs my OK`, `Reward shop`, `é` in `café` unchanged from the source; new sheet strings are clearly marked as having no design reference | compliant |
| owner-rule greps | no `google_fonts`/`GoogleFonts`, no `letterSpacing`, no `TODO(P14)`, no `skip:` | clean |
| scope (RULES §1) | `git status --porcelain -- app/lib/core app/lib/app tools/` → **empty** | shared code untouched; all work inside `features/rewards/**` + `test/features/rewards/**` |

## 3. FIXES

### Done (this stage)

- **Removed both `// ignore: unawaited_futures` comments in
  `test/features/rewards/rewards_a11y_test.dart`** (lines 232, 264). RULES §7
  requires `flutter analyze` with **no ignores**, and iteration 1 had zero —
  these two arrived with the test stage's a11y file this iteration. The
  futures genuinely must not be awaited (they complete on the later pop, which
  the code comments already say), so the fix is the repo's own convention, not
  a behaviour change: `unawaited(GoRouter.of(context).push('/rewards'))` plus
  `import 'dart:async' show unawaited;`. `p14_bugs_test.dart:396` in this same
  feature already uses `unawaited(...)`, so this also removes the outlier.
  Behaviour is unchanged: 1870 tests still pass, P14's 84 still pass.
  (Not touched on purpose: `app/test/app/router_push_test.dart` carries the same
  pattern but is shared test code owned by another loop.)

Nothing else needed fixing: no mismatched BLoC states/events, no import
breakage, no renamed members, no test broken by the merge of the two halves.
Both halves' work landed intact, including the one file they edited
concurrently.

### Left / open (carried forward — no code change here)

1. **Stage 5 must re-measure the list against the new creation order.** The
   *layout* did not move (intro y, card pitch 138, the same x rects), but the
   visible row sequence and Baking's toggle state now differ from iteration 1
   because the data changed, not the layout.
2. **`SHARED_REQUEST.md` (bottom-sheet keyboard inset)** — when the shared
   `showNestBottomSheet` is fixed, delete `showRewardEditorSheet` and return to
   it. Not blocking; P14 ships the feature-local copy.
3. **Shared a11y wart** noted in `rewards_a11y_test.dart`: design-system
   controls built as `Semantics(label:, onTap:) > InkWell` expose the inner
   `InkWell` as a second unnamed node. Pre-existing in `core/`, not P14.
4. **`Reward.detail`** still carried but unused by P14 (price shows in the coin
   pill), per plan §2 — left alone.
5. **Sheet restyle is unverified against a render** (2b item 2): the resting
   sheet now reserves 107 px of chrome for its own cap; a stage-5 sheet
   screenshot 16–23 px different from iteration 1 is that reservation, not list
   drift.

## 4. Verification tails (final state, `app/`)

```
$ dart format .
Formatted 434 files (0 changed) in 1.25 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.1s)

$ flutter test            # full app
00:47 +1869: .../test/features/onboarding/value_tour_view_test.dart: P02 value tour — owner rule: alignment card content shares one inner left edge
00:47 +1870: All tests passed!

$ flutter test test/features/rewards/
00:04 +84: All tests passed!
```

P14's 84 feature tests: 0 failed, 0 skipped — all five stage-6 bug proofs
(B01–B05) live and green. The `WARNING (drift): … created the database class
AppDatabase multiple times` lines in the raw output are pre-existing noise from
other features' parallel in-memory databases (present on `main` and in every
other screen's suite); they are warnings, not failures, and are filtered from
the tails above.

No simulator was booted, installed on, screenshotted or driven at any point in
this stage.

VERDICT: PASS