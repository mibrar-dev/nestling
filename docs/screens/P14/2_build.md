# P14 · Rewards manager — Stage 2 integrate (iteration 1)

Owner: integrator. Inputs: `docs/screens/P14/2a_build_logic.md` (logic),
`docs/screens/P14/2b_build_ui.md` (UI). Output: the two halves combined into one
compiling, analyse-clean, fully-passing feature.

**Outcome: no code change was required.** 2a declared *CONTRACT CHANGES — None*
and 2b coded the view/widgets against the plan §2 signatures verbatim, so the
merge seam needed no repair. The seam was verified by inspection plus the full
suite; the verification evidence is below rather than a claim.

## 1. Summary of the two halves

**2a — logic** (`domain/**` untouched, `data/**` untouched, `bloc/**` edited, 21
tests). Added the four write events to `rewards_event.dart`
(`RewardsNeedsOkChanged`, `RewardsCreateRequested`, `RewardsUpdateRequested`,
`RewardsDeleteRequested`) and their handlers to `rewards_bloc.dart`. Every
handler awaits the repository and emits **nothing on success** — the existing
`emit.forEach(_repository.watchItems(), …)` subscription delivers the new list
after each write — and emits `failure` + message on error behind an
`emit.isDone` guard. `RewardsLoadRequested` / `RewardsStatus` /
`RewardsState(items, errorMessage)` unchanged. `RewardsCreateRequested` builds
`Reward(id: '', …, detail: '{price} coins')`; the impl stamps `reward-{ms}`.
Tests: `rewards_bloc_test.dart` (13) + `rewards_repository_test.dart` (8),
both through a real in-memory Drift DB (`setUpTestScope`).

**2b — UI** (`presentation/views/**` + `presentation/widgets/**` rewritten,
12 tests). Replaced the AppBar/ListTile placeholder with the real screen
(status bar, compact nav, intro, card list, `+ New reward`, plus loading /
empty / failure surfaces), deleted the unreferenced
`rewards_placeholder_card.dart`, and added `p14_reward_card.dart` (the `.rw`
card + `.editbtn`), `p14_reward_editor_sheet.dart` (in-feature bottom sheet)
and `p14_reward_meta.dart` (icon/tint map, verbatim `aria-label` maps, all copy).
Tests: `rewards_view_test.dart` (8) + `reward_card_widget_test.dart` (4).

Combined feature tree (`app/lib/features/rewards/`): 3 new widget files, 1 new
view, 2 edited bloc files, 1 deleted placeholder, 4 test files (33 tests).

## 2. Integration audit across the seam

Nothing was left implicit. Checked, with the result:

| seam concern | check | result |
|---|---|---|
| event names/signatures used by the view match the bloc | every `bloc.add(...)` in `rewards_view.dart` / `p14_reward_editor_sheet.dart` resolves to a real handler | 4/4 match plan §2 verbatim |
| state cases handled | `RewardsStatus` switch is exhaustive over `initial/loading/loaded/failure` | exhaustive, no fall-through |
| deleted `rewards_placeholder_card.dart` | `grep -rn rewards_placeholder_card app/` | **zero** references left (no dangling import) |
| domain/data/DI/route files | untouched by either half; `analyze` clean across them | still per plan; `/rewards` intact |
| **update cannot silently drop entity fields** | `RewardEditorSheet._submit()` rebuilds a `Reward` from scratch and `RewardsUpdateRequested` forwards it wholesale to `updateReward` — so any field not copied would be wiped on save | `Reward` has exactly 6 fields (id, title, detail, icon, coinPrice, needsOk) and the sheet copies all 6 (`id: existing?.id`, `icon: existing?.icon`) → **no field loss** |
| create path consistency | sheet sends `icon: 'gift'`; bloc rebuilds `detail: '{price} coins'` | consistent with the sheet's own `'$_price coins'`; `'gift'` is not in the seed map so it hits the documented plan §1 fallback (`NestIcons.gift` + neutral tile), not a missing icon |
| copy vs HTML source | character-by-character against `P14-rewards.html` lines 13–21 | `Reward shop`, intro with em dash U+2014, `+ New reward` (ASCII `+`), `Needs my OK`, and both shortened `aria-label`s (`Edit Stay up later`, `Edit Trip to the park cafe` — ASCII "cafe") match the source |
| owner-rule compliance in the merged tree | `grep` for `google_fonts`/`GoogleFonts`, `// ignore`, `letterSpacing`, `TODO(P14)` | **none present** |
| accessibility action rule (RULES §8) | `_EditButton` wraps `Semantics(button:, enabled:, label:, onTap: onTap)` with `onTap:` passed **on the Semantics node**; the inner `Ink` icon is `ExcludeSemantics` | compliant; every other control is a design-system component that already exposes `SemanticsAction.tap` |
| merged-file rule (RULES §1) | `git status --porcelain -- app/lib/core app/lib/app tools/` | **empty** — shared code untouched; all changes inside `features/rewards/**` + `test/features/rewards/**` |

## 3. FIXES

### Done
- **None required.** No integration breakage was present: no mismatched BLoC
  states/events, no import errors, no renamed members, no test broken by the
  merge. Both halves were written against the same contract, so the combined
  result compiled, analysed and tested green on the first run of this stage and
  stayed green on the final confirmation run.
- Verified rather than assumed that 2b's file deletion did not orphan 2a's
  imports, and that 2a's bloc did not lose 2b's view-facing API (the four
  events, `RewardCopy`, `RewardCard`, `openRewardEditor`).

### Left / open (carried to the next iteration — no code change here)

1. **Inline error caption in the editor sheet (plan §4).** Still open, and it is
   a **contract** question, not a view bug: 2a reported *CONTRACT CHANGES —
   None* and the plan §2 signatures have no per-write result channel, so a sheet
   write failure cannot be reported back into the sheet. Today the sheet
   dismisses on Save and the failure surfaces as the list's `failure` state.
   Surfacing it inline needs one of: (a) the write events return a `Future` /
   emit a result the sheet awaits, or (b) the sheet takes an `errorText`
   driven by a `BlocListener`. Both change `bloc/**`, which 2a owns — this
   stage deliberately does not touch it. **Orchestrator call needed.**
2. **Keyboard robustness of the sheet body** (2b item 2): plain
   `Column(mainAxisSize: min)`, ~560 px against a 776 px cap; needs scroll
   protection if a real keyboard shrinks it. `NestBottomSheet` passes unbounded
   height, so a bare `SingleChildScrollView` is not the fix. Not reproducible in
   the widget tests; untouched here.
3. **Light/dark render comparison** (`shot.sh` + `compare.py`) is stage 5's
   job — no simulator was booted, installed on or driven at any point in this
   stage.
4. **`Reward.detail`** still carried but unused by P14 (per plan §2) — left
   alone.

## 4. Verification tails (final state, `app/`)

```
$ dart format .
Formatted 420 files (0 changed) in 1.10 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.1s)

$ flutter test
00:36 +1624: .../test/features/onboarding/value_tour_view_test.dart: P02 value tour — owner rule: alignment dark 430dp: 20px gutters on every edge
00:36 +1625: .../test/features/onboarding/value_tour_view_test.dart: P02 value tour — owner rule: alignment card content shares one inner left edge
00:36 +1626: All tests passed!
```

Per-file breakdown of the 33 feature tests (all green, nothing lost in the
merge — 2a's 21 and 2b's 12 both present):

```
rewards_bloc_test:        +13: All tests passed!
rewards_repository_test:   +8: All tests passed!
rewards_view_test:         +8: All tests passed!
reward_card_widget_test:   +4: All tests passed!
```

The `WARNING (drift): … created the database class AppDatabase multiple times`
lines in the raw `flutter test` output are pre-existing noise from other
features' parallel in-memory databases (they appear on `main` and on every
other screen's suite); they are warnings, not failures, and are filtered out of
the tail above. 1626 tests ran, 0 failed, 0 skipped.

VERDICT: PASS