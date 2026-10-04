# K08 · Reward shop — stage 2a build logic (iteration 2)

## CONTRACT CHANGES

None. `requestReward(childId, rewardId)` keeps its `Future<void>` signature
and the five BLoC events / state shape from iteration 1 are untouched, so
the UI builder codes against the plan unchanged.

One behaviour note for the UI builder (not a signature change): an instant
reward requested when the balance no longer covers it now lands as
`requested` (a grown-up decides) instead of `approved`-unpaid. The bloc
toasts from the item's `needsOk` flag captured at tap time, so in that
raced edge the toast may read “enjoy” for a row that is actually
`requested` — accepted as negligible; the money invariant is what the
proofs pin.

## Files changed (logic layer only — no views/widgets touched)

- `app/lib/features/kid_shop/data/kid_shop_repository_impl.dart`:
  **K08-BUG-1 fixed** (FIXES_1 item 1, my layer). `requestReward` now makes
  payment a precondition of the `approved` row, inside the single
  transaction, mirroring P14's `approveRedemption` check-before-write:
  needsOk → `requested` (unchanged); instant → child row read **inside**
  the transaction, and only when the balance covers the price is the row
  written `approved` **and** the coins deducted together. When the balance
  is short (two individually-affordable cards tapped in one frame, second
  lands after the first spent the coins) — or the child row is gone — the
  row is written `requested` instead, so no unpaid `approved` row survives.
  The old write-first + silently-no-op `_spendCoins` is deleted (replaced
  by one `_insertRedemption` helper; no triplicated insert body).
- `app/test/features/kid_shop/kid_shop_repository_test.dart`: new
  regression test `an instant reward beyond the balance is left requested
  (K08-BUG-1)` — baking (100, approved, 120→20) then screen-as-instant
  (50, uncovered) → `requested`, coins stay 20 — plus a `makeInstant`
  helper. File is now 17 tests.
- No other logic file touched: domain contract, `watchActiveShop`,
  `watchShop` legacy entry, BLoC events/state all already match the plan.

FIXES_1 items **not** mine (left for the UI builder — views/widgets are
out of my scope): K08-BUG-2 (`reward_shop_view.dart:354` `Spacer` →
`SizedBox.shrink`) and K08-BUG-3 (`shop_reward_card.dart` price
`Semantics(label: '$price coins')`). Their 4 proofs still fail, as
expected, and I did not touch those files or their tests.

## Verification (no simulator — 5_ui only; no whole-app run — integrator)

- `flutter analyze lib/features/kid_shop test/features/kid_shop` → No
  issues found.
- `flutter test --timeout 120s test/features/kid_shop/
  kid_shop_bloc_test.dart test/features/kid_shop/kid_shop_repository_test.dart`
  → All 51 tests passed (34 bloc + 17 repository).
- `flutter test --timeout 120s test/features/kid_shop/k08_bugs_test.dart
  --plain-name K08-BUG-1` → All 3 passed (repository proof, one-frame
  two-card widget proof, needs-OK sibling regression). Full bugs file:
  +3 −4, the 4 failures being exactly the BUG-2/BUG-3 proofs owned by the
  UI builder.
- `flutter test --timeout 120s test/core/data/repositories_test.dart` →
  All 22 passed (legacy `watchShop` entry unaffected).
- No `DateTime.now` (clock via `appNowUtc`), no `google_fonts`, no new ids
  minted, no `flutter clean`, no simulator, no `analysis_options` change.

## LEFT FOR NEXT ITERATION

- UI builder: K08-BUG-2 and K08-BUG-3 fixes (their files, their proofs).
- Integrator: whole-app suite (the `kid_home_view_test.dart` placeholder-copy
  blocker in SHARED_REQUEST.md is still open) and the `5_ui` screenshots.

VERDICT: PASS
