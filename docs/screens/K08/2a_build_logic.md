# K08 · Reward shop — stage 2a build logic (iteration 1)

## CONTRACT CHANGES

None. Event/state/repository names match `1_plan.md` §(b) exactly
(`KidShopLoadRequested`, `KidShopDataReceived(KidShopData)`,
`KidShopStreamFailed`, `KidShopRewardRequested(rewardId)`,
`KidShopNoticeShown`; state `{status, childId, coins, items,
requestingIds, notice, noticeSeq, errorMessage}`; repository
`watchActiveShop()` + `requestReward`). The UI builder can code against the
plan unchanged.

## Files changed (logic layer only — no views/widgets touched)

- `app/lib/features/kid_shop/domain/entities/kid_shop_data.dart` (new):
  `KidShopData {childId, coins, items}` value object per plan §(b).
- `app/lib/features/kid_shop/domain/kid_shop_repository.dart`: contract is
  now `watchActiveShop()` + `requestReward`. Deleted the superseded
  `getItems`/`watchItems`/`watchShop` (price-order `watchRewards` — wrong
  order for K08); verified zero other callers before deleting. Existing
  `RewardShopView` uses only `state.status`/`items`/`errorMessage`, which are
  preserved, so the parallel UI build is unaffected.
- `app/lib/features/kid_shop/data/kid_shop_repository_impl.dart`:
  `watchActiveShop()` = `watchAppState()` → `activeChildId ?? 'maya'` →
  `combineLatest2(watchRewardsInCreationOrder, watchChild)` → items in
  CREATION order with `affordable = coins >= coinPrice`. Outer/inner fan-out
  uses a feature-local `_switchMap` (same semantics as the `kid_home`
  helper — `asyncExpand` would stall on child switches since watch streams
  never close; kept local to avoid a cross-feature import and any shared
  edit). `requestReward`/`_spendCoins` unchanged (needsOk → `requested`,
  coins untouched; else `approved` + deduct; unknown id no-op).
- `app/lib/features/kid_shop/presentation/bloc/kid_shop_event.dart`: the
  five plan events with guard/ownership docs.
- `app/lib/features/kid_shop/presentation/bloc/kid_shop_state.dart`: plan
  state plus `copyWithLoaded` (clears stale load error, preserves
  `requestingIds`/`notice*`), `copyWithRequestStarted/Finished`
  (spinner + one-shot notice with `noticeSeq+1`), `copyWithNoticeCleared`.
- `app/lib/features/kid_shop/presentation/bloc/kid_shop_bloc.dart`:
  guarded manual subscription (K03-BUG-15 precedent — `await emit.forEach`
  would hang and deadlock tap events; the old handler had this latent bug
  and was rewritten, not extended). `RewardRequested` ignores
  not-loaded / unknown / unaffordable / duplicate; success notice is
  `needsOk ? 'Mum will give it a thumbs-up soon.' : 'It’s yours — enjoy!'`
  (curly ’ U+2019, em dash U+2014), failure notice is
  `'Hmm, that did not work. Try again.'` with `noticeSeq+1`.
- `app/test/features/kid_shop/kid_shop_bloc_test.dart` (new, 15 tests):
  loaded emits Maya 120 + 6 items in creation order with only `r-cafe`
  unaffordable; needsOk → thumbs-up, instant → enjoy, repo write asserted as
  `(maya, rewardId)`; unaffordable/unknown/duplicate/pre-load ignored;
  stream error → failure → retry reloads; second load while live ignored
  (`watches == 1`); notice clear keeps `noticeSeq`; state value semantics.
- `app/test/features/kid_shop/kid_shop_repository_test.dart` (new, 7
  tests): in-memory Drift + `Seed.demo` — creation order, affordable flags,
  `{price} coins` detail, active-child switch (Leo 45, nothing affordable),
  needsOk → `requested` + coins unchanged, instant → `approved` + 120→20,
  unknown id no-op.

DI/routes untouched (constructor signatures unchanged; route still adds
`KidShopLoadRequested`). No shared files touched. No `DateTime.now`, no
`google_fonts`, no simulator use.

## Verification

- `flutter analyze lib/features/kid_shop test/features/kid_shop` → No
  issues found.
- `flutter test --timeout 120s test/features/kid_shop/` (2 files) → All
  22 tests passed.
- Whole-app `flutter test` and simulator runs left to the integrator per
  stage scope.

## Plan items done (§b + §f logic parts)

State/events/repository/bloc per §(b); bloc + repository tests per §(f).
View tests, geometry, semantics-tap and screenshots belong to the UI
builder / integrator.

## LEFT FOR NEXT ITERATION

Nothing in the logic layer. If the UI builder needs anything beyond the
plan contract (e.g. a derived `footerCoins` string), it goes through the
integrator as a contract amendment.

VERDICT: PASS
