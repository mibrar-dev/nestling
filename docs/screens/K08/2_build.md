# K08 · Reward shop — stage 2 integrate (iteration 1)

Job: merge the two parallel builders, then make the combined result compile and
pass. No redesign; smallest change per breakage.

## Summary of 2a (logic)

`2a_build_logic.md` reported **CONTRACT CHANGES: None** — the BLoC/repository
names match `1_plan.md` §(b) exactly, so 2b could code against the plan
unchanged. Landed:

- `domain/entities/kid_shop_data.dart` (new) — `KidShopData {childId, coins, items}`.
- `domain/kid_shop_repository.dart` — contract reduced to `watchActiveShop()` +
  `requestReward`; the superseded `getItems`/`watchItems`/`watchShop` were deleted
  after verifying no other callers.
- `data/kid_shop_repository_impl.dart` — `watchActiveShop()` =
  `watchAppState()` → `activeChildId ?? 'maya'` → `combineLatest2(watchRewardsInCreationOrder,
  watchChild)` → items in **creation** order (not price order) with
  `affordable = coins >= coinPrice`. Feature-local `_switchMap` for the
  never-closing inner streams (same semantics as the `kid_home` helper;
  `asyncExpand` would stall on a child switch).
- The five plan events/state fields, a **rewritten** load handler with a guarded
  manual subscription (K03-BUG-15 precedent — the old `await emit.forEach` was a
  latent deadlock, so it was replaced rather than extended), and the
  `copyWith*` helpers including `noticeSeq` so two identical toasts stay distinct.
- 22 tests: `kid_shop_bloc_test.dart` (15) + `kid_shop_repository_test.dart` (7).

## Summary of 2b (UI)

`2b_build_ui.md` — views/widgets only, no domain/data/bloc file touched:

- `views/reward_shop_view.dart` rewritten from the placeholder: one `KidScope`,
  transparent `Scaffold`, `.k8-top` back/lock row, `BlocListener` on `noticeSeq`
  → `showNestToast`, loading/failure/empty/loaded bodies, `.scroll.k8-scroll`
  column.
- `widgets/shop_reward_card.dart` + `widgets/shop_reward_icons.dart` (new);
  `kid_shop_placeholder_card.dart` deleted as dead.
- 31 tests: `reward_shop_view_test.dart` (20) + `reward_shop_widget_geometry_test.dart` (11).
- Two geometry findings recorded for `5_ui`: the card's bottom padding is 4
  (`--s1`), not the CSS 10, because `NestKidButton` carries its 6 px shadow room
  inside its box; and `IntrinsicHeight` + `stretch` reproduces the CSS grid's
  row stretch for the café note card.

The two halves met with **no member mismatches** — no renamed state field, no
missing event, no import clash, no BLoC-state disagreement. Nothing had to be
reconciled in the presentation layer.

## FIXES

### Done

1. **`flutter analyze` — 5 issues, all one root cause.** `test/core/data/repositories_test.dart:270`
   called `shop.watchShop('maya')`, which 2a deleted from the repository
   (`undefined_method`), which cascaded into two `inference_failure_on_untyped_parameter`
   warnings and two `avoid_dynamic_calls` infos on the two `firstWhere` lines.
   2a's note was that it "verified zero other callers" — true inside `lib/`, but
   the shared foundation test is a caller.

   **Fix:** restored `watchShop` on the feature-owned implementation only. The
   interface stays exactly as `1_plan.md` §(b) specifies (no contract churn), and
   `app/test/core/**` was not touched — RULES §1 forbids it. Rather than
   resurrect the old duplicate body, the shared inner stream was extracted as
   `_shopFor(childId)` and both entry points use it, so there is one mapping and
   `watchShop` cannot drift from `watchActiveShop`. One side effect worth
   noting: `watchShop` now returns **creation** order rather than the old price
   order; the shared test only asserts length + affordability, so it passes
   (`repositories_test.dart` → 22/22 green).

2. **Stale buffered test run.** My first full run piped through `tail`, so output
   only appeared at exit; I killed it to get progress and that kill corrupted the
   tail (`PathNotFoundException` on the temp listener dir, "Cannot close sink").
   Those errors were mine, not the code's. Re-ran clean and unbuffered — the
   numbers below are from the clean run. No code was touched in response to them.

### Left (not mine to fix)

3. **Two failing tests, both in another feature's directory — BLOCKER.**
   `test/features/kid_home/kid_home_view_test.dart` asserts the *foundation
   placeholder's* copy `K08 Reward shop` (the old
   `AppBar(title: Text('K08 Reward shop'))`) to prove the dock navigated:
   line 2001 (`dock Shop opens /reward-shop`) and lines 2059/2077 (the table
   row in `every dock button exposes a tap action and routes`).

   The real build correctly renders the design's heading `Reward shop`, so the
   marker is gone. I did **not** paper over it in the view: the only ways to
   satisfy `find.text` are to render wrong copy (direct COPY-rule violation) or
   bury it in an `Opacity(0)` node, which a screen reader would then announce on
   a real screen (`find.text` skips only `Offstage`). Both trade a correct
   screen for a stale test.

   Filed in `SHARED_REQUEST.md` with a 2-line fix, using the idiom that same
   file already established at lines 1982-1983 ("Route assertion, not placeholder
   copy"): `pushedPath(tester) == '/reward-shop'` (the shared helper in
   `test/test_scope.dart:78`). The table test already asserts the route correctly
   at line 2076, so line 2077 is redundant. K06/K09 keep their assertions — those
   screens are still placeholders.

   Out of scope per RULES §1 (`test/features/kid_home/**` is kid_home's).

## Verification

`dart format .` (from `app/`):

```
Formatted 555 files (0 changed) in 1.83 seconds.
```

`flutter analyze` (from `app/`, whole repo, no ignores, nothing weakened):

```
Analyzing app...
No issues found! (ran in 2.9s)
```

`flutter test --timeout 120s` (whole suite, clean unbuffered run):

```
01:21 +3444 ~4 -2: Some tests failed.

Failing tests:
  .../test/features/kid_home/kid_home_view_test.dart: K03 accessibility actions (VoiceOver/TalkBack) every dock button exposes a tap action and routes
  .../test/features/kid_home/kid_home_view_test.dart: K03 navigation dock Shop opens /reward-shop
```

3444 passed, ~4 skipped (expected skips), **2 failed** — both the item-3 blocker
above. Isolated confirmation of the rest:

- `flutter test --timeout 120s test/features/kid_shop/` → `00:02 +53: All tests passed!`
  (2a's 22 + 2b's 31, all green after the `_shopFor` extraction).
- `flutter test --timeout 120s test/core/data/repositories_test.dart` →
  `00:02 +22: All tests passed!` (the shared file FIXES-1 repaired).
- Failure detail for the two, for the record:
  `Expected: exactly one matching candidate / Actual: _TextWidgetFinder:<Found 0 widgets with text "K08 Reward shop": []>`.

Rule audit on the merged result: no `google_fonts`/`GoogleFonts` and no
`DateTime.now()` anywhere in `lib/features/kid_shop` or `test/features/kid_shop`
(the one grep hit is a comment in `reward_shop_view_test.dart` saying so); clock
via `appNowUtc()`; no ids minted in the view; no `flutter clean`; no simulator
booted, installed on or screenshotted (that is `5_ui`'s, and only
E7D5555E-378A-49DF-AAEE-16677AF4B9DB); no `analysis_options` change; no file
outside RULES §1 touched except the one documented repository edit in
FIXES-1 (feature-owned) and `docs/screens/K08/**`.

## Left for next iteration

1. **Blocker:** land the SHARED_REQUEST fix to
   `test/features/kid_home/kid_home_view_test.dart` (2 lines), then re-run the
   full suite for a green result. This is the only thing standing between K08
   and a clean `flutter test`.
2. `5_ui`: `tools/screens/shot.sh` for `/reward-shop` in light + dark (kid mode,
   `CHILD=maya`, `SEED=demo`, `DISABLE_ANIMATIONS=1`) + `compare.py` against both
   design PNGs; check the band drift against 2b's geometry table, especially grid
   rows 2 and 3 which are below the fold in the PNG.
3. Swap the `Save up!` colourway when the `NestKidButton` request lands
   (non-blocking, documented deviation until then).

VERDICT: FAIL
