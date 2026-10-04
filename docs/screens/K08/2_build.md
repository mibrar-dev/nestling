# K08 · Reward shop — stage 2 integrate (iteration 2)

Job: merge the two parallel builders, make the combined result compile and
pass. No redesign; smallest change per breakage.

Iteration 1's blocker is **still open**. `main` was merged into this branch
(`031089c Merge branch 'main' into screen/K08`), but that merge did **not**
include the fix for `SHARED_REQUEST.md` §2 — both assertions are still present
verbatim at `kid_home_view_test.dart:2001` and `:2059`. So this stage's job
reduced to verifying the merged tree and re-confirming the blocker with fresh
numbers.

## Summary of 2a (logic) — iteration 2

`2a_build_logic.md`: **CONTRACT CHANGES: None** again, and explicitly
`requestReward(childId, rewardId)` keeps its `Future<void>` signature with the
five events / state shape from iteration 1 — which is why 2b needed no
signature change. Landed:

- **K08-BUG-1 fixed (FIXES_1 item 1, major, money integrity)** in
  `data/kid_shop_repository_impl.dart`: `requestReward` now makes payment a
  *precondition* of an `approved` row, inside the single transaction, mirroring
  P14's `approveRedemption` check-before-write. needsOk → `requested` unchanged;
  instant → the child row is read inside the transaction and only when the
  balance covers the price is the row written `approved` *and* the coins
  deducted together. A short balance (or a missing child row) yields `requested`,
  so no unpaid `approved` row can survive. The old write-first + silently
  no-op `_spendCoins` is gone, replaced by one `_insertRedemption` helper.
- `kid_shop_repository_test.dart` +1 regression test (`an instant reward beyond
  the balance is left requested (K08-BUG-1)`) plus a `makeInstant` helper; the
  file is now 17 tests. 2a's logic slice is 34 bloc + 17 repository = 51 tests.

2a documented one accepted behaviour note (not a signature change): an instant
reward requested when the balance no longer covers it now lands as `requested`,
and since the bloc toasts from the `needsOk` flag captured at tap time, that
raced edge can read "enjoy" for a row that is really `requested`. 2a judged the
money invariant to be what matters and accepted it as negligible. I agree —
it is a one-frame double-tap race on a toasting string, and the row status and
coins are correct. Left alone, not re-litigated here.

## Summary of 2b (UI) — iteration 2

`2b_build_ui.md`: views/widgets only; no `domain`/`data`/`bloc` file touched.
It absorbed the four UI-owned FIXES_1 items:

- **K08-BUG-2 (major) fixed** — `_ShopGrid`'s odd trailing filler was
  `const Spacer()`, which *is* an `Expanded` and was already inside an
  `Expanded`, so any 1/3/5-reward family threw `Incorrect use of
  ParentDataWidget` and no grid laid out at all. Now `const SizedBox.shrink()`,
  the inert filler `1_plan.md` §(a) had specified.
- **K08-BUG-3 (minor) fixed** — the card price is now announced as `"50 coins"`
  via `Semantics(label: …, container: true, excludeSemantics: true)`, mirroring
  `NestCoinPill`. `container: true` is load-bearing: without it the label merges
  into the card node and a screen reader reads one long run.
- **UI-check deviations 1 + 2 (major) fixed** — `shop_reward_icons.dart` is now a
  thin forwarder to the shared `rewardIconFor(key, audience: NestAudience.kid)`,
  which carries the exact `.k8-art` drawings: `cake`→`rewardCake` (was
  `chefHat`), `coffee`→`rewardCoffee` (was the sit-down `cafe` mug),
  `film`→`rewardFilm`, `moon`→`rewardMoon`, `plate`→`rewardPlate`, `tv`→`rewardTv`.
  This is the switch `ORCHESTRATOR_NOTES.md` (15:08) asked for, now that main
  has it; P14 keeps its parent branch so nothing there changed.
- **deviation 4 (café card taller)** — no change, correctly: DATA OVER MOCKS.

One finding from 2b worth carrying forward, because it is a *test* bug that was
masking real results: `k08_bugs_test.dart`'s K08-BUG-3 proof had never actually
run. It pumped `NestlingApp` without `setUpTestScope()`, so GetIt had no
`AppModeController`, the tree never built, and every finder in that file
returned "0 widgets" for a reason unrelated to what it was testing — which is
also why two "Sorted" proofs in `6_bugs.md` had looked green. 2b fixed it in its
own file. That is why iteration 1 saw 53 K08 tests and iteration 2 sees 143.

## FIXES

### Done

1. **`SHARED_REQUEST.md` §2 — consolidated and escalated.** 2b had appended a
   second, partly duplicated copy of the blocker section, so the file now carries
   one authoritative section with iteration-2 evidence: 3765 pass / ~4 skip /
   2 fail, K08-owned tests 53 → 143 and all green, and a count of the seven
   stage reports that have now re-confirmed the same two failures. The proposed
   two-line fix is unchanged (`pushedPath(tester) == '/reward-shop'`).

No code fix was needed this iteration. Analyze is clean on the merged tree, the
two halves still meet with **no member mismatches** (no renamed state field, no
missing event, no import clash), and nothing in the merge broke a previously
green K08 test.

### Left (not mine to fix)

2. **Two failing tests, both in another feature's directory — BLOCKER, 2nd
   iteration.** `test/features/kid_home/kid_home_view_test.dart` asserts the
   *foundation placeholder's* copy `K08 Reward shop` (the old
   `AppBar(title: Text('K08 Reward shop'))`) to prove the dock navigated:
   line 2001 (`dock Shop opens /reward-shop`) and lines 2059/2077 (the table row
   in `every dock button exposes a tap action and routes`).

   The real build renders the design's heading `Reward shop`, so the marker is
   gone. Re-verified after the `main` merge: both lines are byte-identical to
   iteration 1, so the merge did not silently resolve them.

   I again declined to paper over it in the view. The only in-tree ways to
   satisfy `find.text` are to render wrong copy (direct COPY-rule violation — the
   HTML says `Reward shop`) or to bury it in a non-`Offstage` node, which a
   screen reader would then announce on a real screen. Both trade a correct
   screen for a stale test; the test is what should change. This is recorded with
   the reason in `SHARED_REQUEST.md` §2 so a future stage does not re-litigate it.

   Out of scope per RULES §1 (`test/features/kid_home/**` is kid_home's).

## Verification

`dart format .` (from `app/`):

```
Formatted 580 files (0 changed) in 2.62 seconds.
```

`flutter analyze` (from `app/`, whole repo, no ignores, nothing weakened):

```
Analyzing app...
No issues found! (ran in 9.3s)
```

`flutter test --timeout 120s` (whole suite, unbuffered run — the iteration-1
lesson about piping through `tail`):

```
01:39 +3765 ~4 -2: Some tests failed.

Failing tests:
  .../test/features/kid_home/kid_home_view_test.dart: K03 accessibility actions (VoiceOver/TalkBack) every dock button exposes a tap action and routes
  .../test/features/kid_home/kid_home_view_test.dart: K03 navigation dock Shop opens /reward-shop
```

3765 passed, ~4 skipped, **2 failed** — both the item-2 blocker. Isolated
confirmation of everything K08 owns:

- `flutter test --timeout 120s test/features/kid_shop/` → `00:03 +143: All
  tests passed!` (bloc 34, repository 17, view 67, geometry 18, bugs 7), **zero
  skips** — the `skip:` grep across the feature's tests hits only its own
  comment saying there is no skip marker.
- `2a` re-verified the shared file my iteration-1 fix touches:
  `flutter test --timeout 120s test/core/data/repositories_test.dart` → 22/22,
  i.e. the `watchShop` legacy entry survives iteration 2's data-layer rewrite.

The ~4 skips in the whole-suite count are pre-existing and live in
`kid_home` (`k01_profile_picker_matrix_test.dart`), not K08.

Rule audit on the merged result: no `google_fonts`/`GoogleFonts` and no
`DateTime.now()` in `lib/features/kid_shop` or `test/features/kid_shop` (the
one grep hit is a comment saying so); clock via `appNowUtc()`; no ids minted in
the view; both `ORCHESTRATOR_NOTES.md` items honoured — reward icons switched to
the shared `rewardIconFor(audience: kid)` once main had it, café title left to
the DB; no `flutter clean`; no simulator booted, installed on or screenshotted
(5_ui's alone, and only E7D5555E-378A-49DF-AAEE-16677AF4B9DB); no
`analysis_options` change; nothing skipped to get a pass; no file outside RULES
§1 touched except `docs/screens/K08/**`.

## Left for next iteration

1. **Blocker, and the only thing keeping K08 red:** land the `SHARED_REQUEST.md`
   §2 two-line fix to `test/features/kid_home/kid_home_view_test.dart`. This is
   the second iteration reporting it; it needs one action from the orchestrator,
   since the K08 worktree cannot reach that file.
2. `5_ui` re-check: the glyph fix changes three art discs (`cake`, `coffee`,
   `plate`) and the K08-BUG-3 semantics wrapper; re-shoot light + dark and
   re-run `compare.py`, expecting bands 4–6 to drop, and re-measure the
   `.k8-get.off` button in row 3.
3. Swap the `Save up!` colourway when a `NestKidButton` off-colourway lands
   (`SHARED_REQUEST.md` §1, non-blocking).

VERDICT: FAIL
