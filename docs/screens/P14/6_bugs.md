# P14 · Rewards manager — Stage 6 adversarial bug hunt (iteration 2)

Route `/rewards` · feature `rewards` · parent mode · design
`design/html-source/screens/P14-rewards.html` + light/dark PNGs
(1170×2532 ÷3). This stage changed **nothing** in `app/lib/**`; it extended
`app/test/features/rewards/p14_bugs_test.dart` and this report.

Gates on the iteration-2 build (`5502cf6`, main merged through `c20a7c9` —
`shared/rewards_seed_order` included):

* `flutter test` on the nine stable feature test files →
  **+89 passed, 3 skipped, 0 failed** (the three skips are the new open-bug
  proofs B06–B08).
* `flutter test test/features/rewards/p14_bugs_test.dart --run-skipped` →
  B06, B07 and B08 fail exactly as designed; the other 20 tests (the five
  iteration-1 proofs, now unskipped, plus the clean guards) pass.
* `flutter analyze` / `dart format` on the bug file → clean.
* No simulator was booted, installed on, screenshotted or driven.
* `ORCHESTRATOR_NOTES.md` (12:27, 12:35) verified in the code: the repository
  serves `watchRewardsInCreationOrder`, the seed ships
  `Baking together needsOk: false`, the toggle state is DB-driven, and the
  order/toggle proofs below pin all of it.

## Iteration-1 bugs — all fixed, proofs live and green

| id | was | fix (iteration-2 build) | proof (unskipped, green) |
|---|---|---|---|
| P14-B01 | major — iOS keyboard covered Save/Cancel/Delete | feature-local `showRewardEditorSheet` + `viewInsets` padding and a keyboard-aware form cap/scroll in `RewardEditorSheet` (`SHARED_REQUEST.md` filed for the shared helper) | `[P14-B01] the keyboard must not cover the editor sheet controls` |
| P14-B02 | minor — empty/failure surfaces top-aligned | `_RewardsCenteredScroll` (`LayoutBuilder` + `SingleChildScrollView` + `minHeight` + `Center`) | `[P14-B02] …` (both tests) |
| P14-B03 | minor — failed sheet write lost the input | write-result channel (`Completer` on all four events) + awaited `_submit`, inline danger caption, `_saving` guard | `[P14-B03] a sheet write failure keeps the sheet open with an inline error` |
| P14-B04 | minor, latent — delete orphaned redemptions | `deleteReward` removes the reward and its redemption rows in one transaction | `[P14-B04] deleting a reward with a pending request orphans the request` |
| P14-B05 | major — price order instead of creation order | `watchItems()` → `watchRewardsInCreationOrder`; seed order + Baking OFF from `shared/rewards_seed_order` | `[P14-B05] rewards are listed in creation order, not price order` |

Net effect: rows render `30 min screen time → Pick Friday film → Stay up 15 min
later → Baking together (toggle OFF) → Trip to the park café → Choose dinner`,
exactly the owner-rule/design order, all values DB-driven.

## Open bugs (iteration 2)

| id | severity | one-liner | failing test (skip-marked) |
|---|---|---|---|
| P14-B06 | minor | A stream error **after** the first emission is swallowed — the stale list stays with no error surface and no `Try again` | `[P14-B06] a stream error after data still offers the failure surface` |
| P14-B07 | minor | The inline write-error caption is not a live region — screen readers never hear the failure | `[P14-B07] the inline write-error caption is announced to screen readers` |
| P14-B08 | minor | The sheet's chrome reservation ignores the 44 px close button (and text-scale growth), so the sheet overflows when the keyboard caps the form | `[P14-B08] the sheet must not overflow when the keyboard caps the form` |

### P14-B06 — minor — a stream error after data is silently swallowed

**Repro.** Mock `watchItems` emits one reward, then errors while staying open.
The card stays on screen, `Try again` never appears, and `Something went
wrong` never appears: the parent is left with a stale list whose stream is
dead (later writes would not be reflected).

**Measured** (`--run-skipped`): `Expected: exactly one matching candidate …
p14_try_again`, `Actual: Found 0 widgets`.

**Root cause.** `RewardsView`'s `failure` branch short-circuits on
`state.items.isNotEmpty` and renders `_RewardsLoaded`. That shortcut was meant
for failed *action* writes, but writes no longer emit `failure` (iteration-2
contract), so the only way to reach it is a stream error after data — exactly
the case it then hides. `_onLoadRequested` keeps `items` in the failure state.

**Suggested fix.** Show `_RewardsCenteredScroll(child: _RewardsFailure())` for
every `failure` (drop the `items.isNotEmpty` branch — the reason it existed is
gone), or track whether the failure came from the stream and only keep the
list for non-stream errors. A `Try again` re-subscribes either way.

### P14-B07 — minor — the inline error caption is silent to screen readers

**Repro.** A save write fails → the danger caption appears above Save; a
VoiceOver/TalkBack user gets no announcement of the failure.

**Measured** (`--run-skipped`): the caption node's
`flagsCollection.isLiveRegion` is `false` (`Expected: true`, `Actual:
<false>`).

**Root cause.** `RewardEditorSheet` renders the caption as a plain `Text`.
The design-system error pattern (`NestTextField.errorText`) wraps it in
`Semantics(liveRegion: true, label: …, child: ExcludeSemantics(...))`.

**Suggested fix.** Mirror the `NestTextField` error-row semantics: wrap the
caption in `Semantics(liveRegion: true, label: _errorText!, child:
ExcludeSemantics(child: Text(...)))` so it is announced exactly once.

### P14-B08 — minor — the sheet overflows when the keyboard caps the form

**Repro.** `/rewards` → `+ New reward` → focus `Name` with a full iOS
keyboard: 390×844 at 1.3 text scale with a 336 px keyboard (incl. the
predictive row) reports `A RenderFlex overflowed by 13 pixels on the bottom`;
375×667 (SE 2/3) overflows at both 1.0 (260 px keyboard) and 1.3; 360×640 too.
At 1.0/390×844 with a 300 px keyboard there is no overflow.

**Measured matrix** (Save stays above the keyboard in every case — this is a
layout-hygiene defect, not a lost-control one):

| device | scale | keyboard | overflow | Save bottom vs keyboard top |
|---|---|---|---|---|
| 390×844 | 1.0 | 300 | no | 434 vs 544 |
| 390×844 | 1.3 | 300 | no | 434 vs 544 |
| 390×844 | 1.3 | 336 | **13 px** | 411 vs 508 |
| 375×667 | 1.0 | 260 | **yes** | 389 vs 407 |
| 375×667 | 1.3 | 260 | **yes** | 411 vs 407 |
| 360×640 | 1.3 | 260 | **yes** | 411 vs 380 |

**Root cause.** `RewardEditorSheet.build` reserves
`chrome = s2 + gap5 + s3 + fontSize*height + s2 + homeH + s4` for
`NestBottomSheet`'s own chrome, but the actual title row is `max(text line,
44 px close button)` tall and grows with the text scaler — 20 px more than the
reservation. `available` is therefore 20 px too generous, and once the
keyboard caps the form the `NestBottomSheet` Column is 13–20 px over its
budget. (The overflowed band is the sheet's own bottom padding, which is why
no control is lost.)

**Suggested fix.** Compute the reservation from the real title row —
`math.max(titleLineHeight, NestDevice.tapParent)` and include the text
scaler (`MediaQuery.textScalerOf(context).scale(fontSize)`), or measure the
sheet chrome with a `LayoutBuilder`/`GlobalKey` instead of a constant sum.

## Verified clean — iteration-2 guards (all green)

* **A failed toggle** (`setNeedsOk` throws): `Hmm, that did not work. Try
  again.` toast appears and the switch keeps the DB value — no full-screen
  error, no lying state.
* **A failed save then a retry**: the sheet stays open with the typed name and
  the caption; the second Save succeeds and closes it (2 write attempts).
* **Save is guarded while a write is in flight**: a slow write plus a second
  tap performs exactly one create.
* **Delete cascade scope**: deleting `Trip to the park café` removes only its
  redemption row; `r-baking:requested` remains.
* **Edit keeps position; create lands last**: renaming the 4th reward keeps it
  4th; a new reward is appended (7 rows, last).
* **Seeded Baking toggle is OFF** (design state, `shared/rewards_seed_order`)
  while other rows are ON; flipping the DB row flips the view.
* The iteration-1 clean guards (kid-mode gate, Back pop, restart persistence,
  rapid double taps, 9999 coins + long name at 320×1.3, a11y tap actions,
  empty-state create, dark mode at 1.3) all still pass.

## Notes, not bugs

* **Confirmed Delete has no in-flight guard** (unlike Save's `_saving`): a
  rapid double tap on the confirmed Delete sends two delete events. Both are
  idempotent (the second matches 0 rows), the first pop wins, and no state or
  DB inconsistency results — recorded, not filed.
* **Raw error detail** is appended to the inline caption
  (`Could not save the reward: Bad state: disk full`). Friendly sentence first;
  the technical tail matches the build's stated contract.
* **`SHARED_REQUEST.md`** (bottom-sheet keyboard inset) still open; when the
  shared helper learns `viewInsets`, `showRewardEditorSheet` can be deleted.
* **Shared a11y wart** (design-system controls exposing the inner `InkWell` as
  a second unnamed node) is pre-existing in `core/`, not P14.
* **`Reward.detail`** remains carried but unused by P14 (plan §2).

## Verdict rationale

All five iteration-1 defects (two major) are fixed with live, unskipped
proofs. Iteration 2 found three new defects, all **minor** and each with a
failing proof: a swallowed stream error, an unannounced error caption, and a
13–20 px sheet overflow in a small-screen + keyboard + 1.3-scale combination
(no control becomes unreachable). No major bug is open, so the stage passes
with the three minors filed for a later iteration.

VERDICT: PASS
