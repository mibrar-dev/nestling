# K08 · Reward shop — stage 2b build UI (iteration 3)

Scope as briefed: `app/lib/features/kid_shop/presentation/views/**` and
`presentation/widgets/**`, plus the view/widget tests in
`app/test/features/kid_shop/` (`reward_shop_view_test.dart`).
No `domain/`, `data/`, `bloc/` or shared file was touched. No simulator was
booted, installed on or driven; no whole-app `flutter test`; no
`flutter clean`; `analysis_options.yaml` untouched.

## Summary

The iteration-2 build was already at the design's geometry (iteration-2 `5_ui`
measured every band 0–6 at Δ0 and PASSed the ±2 px rule), so this iteration is
one **behavioural UI fix** plus a **contract re-sync**, not a redesign. No
pixel of layout, colour, radius or copy moved: the only change to the card is
two `Semantics(container: true)` wrappers, which do not lay out.

## Fixed — K08-BUG-5 (FIXES_2 "From 3_test.md" item 2, minor, accessibility)

**"Every reward name merges into one announcement."** With the price made its
own node in iteration 2 (K08-BUG-3's fix), `.k8-n` was the last part of a card
without a semantics boundary, so the grid `Column` absorbed all six names (plus
the café's note) into a single run: a screen-reader user heard the whole shop
as one item and could not tie a name to its own "50 coins" or its own
"Get …" button.

Fix (`shop_reward_card.dart`), mirroring the fix the price already documents:

- the `.k8-n` name is wrapped in `Semantics(container: true)`, so it announces
  as its own node with the same copy and the same rect;
- the `.k8-note` gets the same wrapper. The note is the name's **sibling**, so
  without its own boundary it would simply have moved into the stray grid-level
  node the six names used to share — the merge would still exist, one level up.
  It now reads as its own short node ("30 more to go") between the price and
  the (absent) action, which is exactly the order the card reads in.

Neither wrapper is interactive, so no `SemanticsAction.tap` is owed on them
(the ACCESSIBILITY-ACTIONS rule only binds controls); `container: true` without
`excludeSemantics: true`, so the Text's own label is what gets announced — no
label is duplicated and no visual copy changed.

Rejected alternatives, for the record:

- `MergeSemantics` per card — it would make the card's node
  `"Trip to the park café\n30 more to go"`, which breaks the exact-label proof
  and merges reading with content;
- wrapping the whole card — same problem, and it would swallow the price and
  button nodes K08-BUG-3 just bought;
- `excludeSemantics` on the name — silently drops the one string that carries
  the card's meaning, which is the opposite of the fix.

## Contract re-sync (2a, iteration 3)

`2a_build_logic.md` CONTRACT CHANGES: `KidShopRepository.requestReward` now
returns `Future<String?>` — `'approved'` / `'requested'` / `null` — so the toast
can be honest (K08-BUG-4). **BLoC events and state shapes are unchanged**, so
no view code needed to move: the view still dispatches
`KidShopRewardRequested(item.id)` and toasts `state.notice` on `noticeSeq`.

2a touched one file of mine to keep the tree compiling:
`reward_shop_view_test.dart`'s `_FakeKidShopRepository` (the `Future<String?>`
signature + a `_servedItems` getter so the fake reports the same status the real
repository would). I kept it — it is correct, minimal and documented by 2a — and
added my test alongside it; the 2b view suite passes unmodified against it.

## Tests

`reward_shop_view_test.dart` 67 → **68**: new
`every reward name is its own announcement (K08-BUG-5)`, kept in the file the UI
layer owns so the rule has a proof here as well as in the test stage's
`shop_reward_a11y_test.dart` (two files, one rule, no duplication of intent).
It asserts each of the six DB titles is its own label, that the note is its own
node, and that no reachable label contains two titles.

The three K08-BUG-5 proofs in `shop_reward_a11y_test.dart` (owned by the test
stage) now **pass** — I only changed the widget, not that file.

## Verification (no simulator, no whole-app run)

```
dart format lib/features/kid_shop test/features/kid_shop
  Formatted 15 files (0 changed)

flutter analyze lib/features/kid_shop test/features/kid_shop
  No issues found! (ran in 3.0s)

flutter test --timeout 120s test/features/kid_shop/reward_shop_view_test.dart
                                                  test/features/kid_shop/reward_shop_widget_geometry_test.dart
  00:04 +91: All tests passed!

flutter test --timeout 120s test/features/kid_shop/shop_reward_a11y_test.dart
  00:01 +7: All tests passed!          (3 of them the K08-BUG-5 proofs)

flutter test --timeout 120s test/features/kid_shop/     (feature sweep, read-only)
  00:03 +166: All tests passed!        (bloc 35, repository 18, view 68,
                                         geometry 24, icons 7, a11y 7, bugs 7)
```

The whole K08 feature is green, including 2a's K08-BUG-4 proof, which was the
feature's last failing test. The 24 geometry assertions are the regression
proof that the semantics wrappers moved nothing: every card top, column width,
56 disc, 20 price row, 56 button and the 20 px gutters measure exactly as
before.

Rule audit: no `google_fonts` / `GoogleFonts` (the only grep hit in the feature
is the test header saying so), no `DateTime.now()` (clock stays on
`appNowUtc()`), no id minted in the view, no `Wrap`/`Row` chip rows on this
screen, `NestBalancedText` still on the `.kid-title` heading, reward icons still
forward to `rewardIconFor(audience: NestAudience.kid)`, copy untouched
(character-for-character against `K08-shop.html`), no bare colour or size
literal introduced — the wrappers add no values at all.

## LEFT FOR NEXT ITERATION

1. **`NestKidButtonColor.muted` for the "Save up!" button** — the one item of
   `ORCHESTRATOR_NOTES.md` UPDATE (17:10) that is still code-blocked. I checked
   the tree: neither `main` nor `shared/shared_batch8` has it yet
   (`enum NestKidButtonColor { leaf, coin, sky, peach, lilac, white }` on both),
   so the documented fallback (`NestKidButtonColor.white` + `onPressed: null`,
   `1_plan.md` §g / `SHARED_REQUEST.md` §1) stands. When the batch merges this
   is one prop on `shop_reward_card.dart`; it is invisible in the UI shots today
   because the card is below the fold at scroll 0.
2. **Not mine, still open** — `SHARED_REQUEST.md` §2: the two
   `test/features/kid_home/kid_home_view_test.dart` lines that assert the
   foundation placeholder copy `K08 Reward shop`. Out of RULES §1 for this
   worktree; needs one orchestrator edit.
3. **Next `5_ui`**: re-shoot light + dark. Nothing in this iteration moves a
   pixel, but 2a's toast copy and the shared glyphs are new since the last
   compare, so bands 4–7 should be re-measured as planned.

VERDICT: PASS