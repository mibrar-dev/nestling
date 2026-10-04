# K08 · Reward shop — stage 2a build logic (iteration 3)

## CONTRACT CHANGES

One, required by FIXES_2 (K08-BUG-4): `KidShopRepository.requestReward`
now returns the status it actually wrote — `Future<String?>`:
`'approved'` when the reward was granted and paid for, `'requested'` when
it waits for a grown-up, `null` for unknown ids (no-op, unchanged).
BLoC events and state shapes are UNCHANGED; the view still toasts
`state.notice` on `noticeSeq` — only the copy selection moved (from the
tap-time `needsOk` flag to the written status).

**For the UI builder:** `app/test/features/kid_shop/
reward_shop_view_test.dart` was the only out-of-layer file touched, and
only its `_FakeKidShopRepository` (lines 93–154): the signature follows
the new contract and the fake reports the same status the real repository
would for the served items (`needsOk` → `'requested'`, instant →
`'approved'`, unknown → `null` via a shared `_servedItems` getter). No
test body, no view, no widget was changed — your 67 view tests pass
unmodified against it (verified below). Revert/adjust freely if your half
needs a different fake behaviour; the bloc contract above is what matters.

## Files changed

- `app/lib/features/kid_shop/domain/kid_shop_repository.dart`: `requestReward`
  returns `Future<String?>` with the written-status contract documented.
  Source-compatible for callers that ignore the result (the shared
  `test/core/data/repositories_test.dart` needed no edit — verified green).
- `app/lib/features/kid_shop/data/kid_shop_repository_impl.dart`: the three
  write paths return their status (`'requested'` needsOk / uncovered /
  missing child, `'approved'` + deduction otherwise); unknown id returns
  `null`. Transaction body unchanged otherwise.
- `app/lib/features/kid_shop/presentation/bloc/kid_shop_bloc.dart`
  (K08-BUG-4 fixed): `_onRewardRequested` chooses the toast from the
  written status — `'approved'` → `It’s yours — enjoy!`, anything written
  as `'requested'` → `Mum will give it a thumbs-up soon.` A throw or a
  `null` (reward vanished mid-flight; unreachable behind the guard) keeps
  the existing `Hmm, that did not work. Try again.` Guards (unknown /
  unaffordable / duplicate / pre-load) and `requestingIds` semantics
  unchanged.
- `app/test/features/kid_shop/kid_shop_bloc_test.dart` (34→35): the fake
  implements the new signature with a per-id `writtenStatus` override
  (default `'requested'`); new test `a raced instant request left requested
  toasts thumbs-up (K08-BUG-4)`; the enjoy-copy test now pins
  `writtenStatus['r-baking'] = 'approved'`.
- `app/test/features/kid_shop/kid_shop_repository_test.dart` (18 tests):
  return-value assertions added to the four write tests (`requested` /
  `approved` / `requested`-when-uncovered / `requested`-no-row / `null`
  unknown).
- `app/test/features/kid_shop/reward_shop_view_test.dart`: fake-only
  update described under CONTRACT CHANGES (UI builder's file; flagged,
  minimal, verified).

Not mine, not touched: K08-BUG-5 (`shop_reward_card.dart` name semantics —
UI builder is actively editing that file in this worktree) and the
`kid_home_view_test.dart` SHARED_REQUEST blocker (another feature).

## Verification (no simulator — 5_ui only; no whole-app run — integrator)

- `flutter analyze lib/features/kid_shop test/features/kid_shop` → No
  issues found.
- `flutter test --timeout 120s` (own files): bloc 35 + repository 18 → All
  53 passed.
- `... k08_bugs_test.dart` → All 7 passed, including the previously failing
  K08-BUG-4 proof (`a reward left awaiting approval is not announced as
  "yours"`); no `skip:` marker anywhere in the feature's tests.
- Regression sweep for the contract change: `reward_shop_view_test.dart`
  → 67 passed; icons + a11y + geometry + shared `repositories_test.dart`
  → 60 passed.
- No `DateTime.now` (clock via `appNowUtc`), no `google_fonts`, no new ids,
  no `flutter clean`, no simulator, no `analysis_options` change.

## LEFT FOR NEXT ITERATION

- UI builder: K08-BUG-5 fix (your file, your proofs).
- Integrator: whole-app suite + `5_ui` re-shoot (glyph + toast changes).

VERDICT: PASS
