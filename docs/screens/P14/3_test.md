# P14 · Rewards manager — Stage 3 tests (iteration 1)

Route `/rewards` · feature `rewards` · parent mode. Test-only stage: nothing in
`app/lib/**` or `tools/**` was touched (`git status --porcelain -- app/lib
tools/` empty). Everything lives in `app/test/features/rewards/`.

## Gates

```
$ dart format .
Formatted 426 files (0 changed) in 1.02 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.4s)

$ flutter test
00:37 +1665 ~7: All tests passed!
```

Per-file (feature dir only):

```
rewards_bloc_test            +13     rewards_states_test      +7
rewards_repository_test       +8     rewards_responsive_test  +9
rewards_view_test             +8     rewards_a11y_test       +12
reward_card_widget_test       +4     rewards_order_test       +2 ~1
p14_bugs_test (stage 6)    +9 ~6
```

72 passed / 0 failed / 7 skipped in the feature dir; 1665 across the app. The
skips are the open-bug proofs (6 from `6_bugs.md`, plus mine below), each
re-provable with `--run-skipped`. No new `google_fonts` import, no
`analysis_options` change, no weakened lint.

## Files

* **`p14_test_support.dart`** (new, harness) — `pumpRewardsApp(tester,
  width/height/textScale/theme/seedDemo/prepare)`, `loadBundledFonts()`,
  `rewardRows/rewardRow/rewardNeedsOk`, `rewardIdsInAppOrder`,
  `tappableSemanticsNodes`, `visibleTrackRect`, and the seeded id + label maps.
* **`rewards_a11y_test.dart`** (new, 12) — the RULES §8 contract.
* **`rewards_states_test.dart`** (new, 7) — loading / failure / empty / copy /
  token surfaces.
* **`rewards_responsive_test.dart`** (new, 9) — 320/390/430 × scale 1.0/1.3 ×
  light/dark.
* **`rewards_order_test.dart`** (new, 2 + 1 skip) — the ORCHESTRATOR_NOTES
  12:27 creation-order ruling.
* **`rewards_bloc_test.dart`**, **`rewards_repository_test.dart`**,
  **`rewards_view_test.dart`** — rewritten order/toggle assertions.

## Coverage against the brief

| requirement | where |
|---|---|
| bloc_test for every event/state path | `rewards_bloc_test.dart` — all five events, `initial/loading/loaded/failure`, four throwing-write paths, stream error + retry |
| light + dark | `rewards_states_test.dart` (tokens per theme), `rewards_responsive_test.dart` (every width × scale in both) |
| widths 320/390/430 | `rewards_responsive_test.dart`; sheets re-checked at all three |
| text scale 1.0 and 1.3 | same, via `platformDispatcher.textScaleFactorTestValue` (the app clamps to 1.0–1.3) |
| empty / loading / error | `rewards_states_test.dart` (loading via a never-emitting stream, failure via a throwing one, empty via `Seed.empty` and via deleting every row) |
| every tap navigates to the right route | `rewards_a11y_test.dart` — Back by tap **and** by `performAction`, asserted with `pushedPath`/`currentPath`, never view text |
| semantics labels on icon buttons | `rewards_a11y_test.dart` — all 14 control labels resolved, each exactly one node with `SemanticsAction.tap` |
| tap targets ≥ 44 (parent) | `rewards_a11y_test.dart` — Back, 6 toggles, 6 edits, New reward, and all seven sheet controls measured |
| in-memory Drift + `Seed.demo`/`empty` | `setUpTestScope` everywhere; `Seed.demo` default, `Seed.empty` / row deletion for the empty cases |

Beyond the list, `performAction(tap)` is asserted to change **real** state, not
just to exist: a switch writes its Drift row, edit opens the prefilled sheet,
`+ New reward` opens a blank one, Back pops the route.

## ORCHESTRATOR_NOTES (12:27 + 12:35) — mandatory items

1. **List in creation order, not price.** Split in two, deliberately:
   * *green* — `rewards_order_test.dart`: the rendered card ids equal
     `repository.watchItems()` ids exactly. That is what the screen owns: it
     must not re-sort. It fails if the view ever adds `.sort()` or reverses.
   * *skipped* — `[P14-ORDER] the rendered list is in Seed.demo creation
     order`. **This one fails today**, which is the point:
     `--run-skipped` gives `at location [1] is 'r-bedtime' instead of
     'r-film'`, i.e. price 60 before price 80. Same finding as stage 6's
     P14-B05; `watchRewardsInCreationOrder` is not in this snapshot (not an
     ancestor). Remove the skip after the next main merge.
2. **Baking's `needsOk` false + "do not hard-code the toggle state".** Every
   order/toggle assertion in the four pre-existing test files was rewritten
   to read the database instead of a literal — the old `'all needsOk isTrue'`
   and `needsOk: false` fixtures would have failed the moment the seed
   correction landed. New pin: `rewards_order_test.dart`'s "the toggle state of
   each row is its database value" (switch state == `rewardNeedsOk(id)`, per
   row) and `rewards_states_test.dart`'s track-colour check.
3. **`watchRewardsInCreationOrder`** — not yet on this branch; nothing to call.
   The green order test is written against the repository interface, so it
   passes unchanged once the repository switches.

## Findings

### Confirmed from this stage (test-side, no screen change needed)

**F1 — widget tests must load the bundled families, or overflow assertions lie.**
`reward_card_widget_test.dart` noted this for card geometry; it bites harder
than that. Without `FontLoader`, the fallback font renders the sheet's
stepper row **19 px too wide** at 320×568 × scale 1.3, and its body **16 px too
tall** — a `RenderFlex` overflow that does not exist on device:

```
no fonts    320×568 ×1.3 → "A RenderFlex overflowed by 19 pixels on the right",
                            "A RenderFlex overflowed by 16 pixels on the bottom"
with fonts  320×568 ×1.3 → 0 exceptions
             390/430×568 ×1.3, 320×844 ×1.0/1.3 → 0 exceptions
```

Every new widget test file calls `setUpAll(loadBundledFonts)`. This also means
the earlier "keyboard robustness of the sheet" open item from `2b`/`2_build`
is **not** reproducible once fonts are loaded: at 320×568 × 1.3 the sheet lays
out cleanly. (The keyboard issue is a different, still-real bug — see B1.)

### Bugs confirmed in the screen (already filed by stage 6, re-proved here)

Measured from the test side; no code changed, per the stage rule.

**B1 / P14-B01 (major) — the keyboard covers the sheet's controls.**
`showNestBottomSheet` never reads `MediaQuery.viewInsets`. With a 300 px inset
at 390×844:

```
Save   y 682 → 734   keyboard top 544   → 190 px behind
Cancel y 742 → 794   keyboard top 544   → 250 px behind
sheet  y 422 → 794   (unchanged by the inset)
```

Shared `nest_bottom_sheet.dart` — `grep -rn viewInsets lib/` returns nothing
app-wide. iOS-only (Android resizes the window). Needs a `SHARED_REQUEST` or a
feature-local `AnimatedPadding` + scrollable body.

**B2 / P14-B02 (minor) — empty and failure surfaces are top-aligned.**
Empty state renders y 107 → 481, centre **294.0** vs the scroll viewport centre
**475.5** — 181.5 px off, pinned under the nav bar. Same `_RewardsScroll`
`ListView` root cause for the failure surface.

**B3 / P14-B05 (major) — price order, not creation order.** See
ORCHESTRATOR_NOTES §1; proven by my skipped `[P14-ORDER]` test.

### Shared-component observation (not a P14 defect)

Every design-system control built as `Semantics(label:, onTap:) > InkWell`
also exposes the inner `InkWell` as a **second, unnamed** semantics node —
measured on `/rewards`: 28 tappable nodes, **14 unnamed** (6 switches at
59×44, 6 edit buttons + Back at 44×44, `+ New reward` at 350×52; `actions`
= `tap`, none carry `isButton`). `/today` shows the same pattern (3 unnamed),
so it is systemic, not P14. Each control is still correctly operable — the
labelled node has the tap action and `performAction` drives the real behaviour,
which my tests assert — so this is a shared `SHARED_REQUEST` candidate, not a
stage-3 blocker. `_EditButton` in `p14_reward_card.dart` follows the same
shared idiom deliberately (its `onTap:` **is** on the `Semantics` node, so
RULES §8 holds).

## Notes for the next iteration

* Two harmless `tap()` "would not hit test" warnings come from
  `p14_bugs_test.dart` (stage 6) at 320-wide + B01/B03 scenarios; every P14
  file I added is warning-free.
* `_RewardsScroll` appends a trailing `SizedBox(s4)` after its single child,
  so the empty/failure surfaces carry 16 px of dead space at the bottom on top
  of the B2 centring problem. Harmless, but fold it in when B2 is fixed.
* A blank sheet's `Save` is disabled until the first frame after typing —
  `enterText` alone does not re-enable it, so tests must `pumpAndSettle()`
  between typing and tapping. Bit me once here; recorded in the harness.
* After a write, `await pumpAndSettle()` is **not** enough to see the new card
  in the tree: the Drift write is real async. `await rewardRows()` first, then
  `pumpAndSettle()`. Without it the empty-state create test read a stale tree
  and looked like a bug.
* `tester.runAsync` is required for `RewardsRepository.watchItems().first`
  inside a widget test — a Drift stream never delivers under the fake clock,
  and a bare await deadlocks to the 10-minute timeout.

VERDICT: FAIL