# K06 · 2a BUILD LOGIC (iteration 2)

## CONTRACT CHANGES

None. No state/event shape changed this iteration — the two fixes are
internal to `PipRepositoryImpl`, and the bloc's public contract
(`PipCareRequested` / `PipWardrobeBuyRequested` / `PipWardrobeEquipRequested`,
`PipState` {status, nest, actionError, actionNonce}, `kPipNotEnoughCoins`,
`pipStageName`, `PipNest.growthFraction`) is exactly as iteration 1 left
it. The UI builder needs no changes.

## FIXES_1 items in this layer — both fixed, proofs un-skipped

- **K06-BUG-1 (major) — rapid care taps lost charges.** `_care` was a
  read-modify-write (SELECT, then `coins: kid.coins - cost`); two
  overlapping taps both read 120 and both wrote 115. Now one conditional
  statement: `UPDATE children SET coins = coins - ?,
  happiness = min(happiness + 1, 5) WHERE id = ? AND coins >= ?`
  (drift `customUpdate`, notifies `children` watchers). Zero changed rows
  = unknown child or insufficient coins: silent no-op, never negative.
  Single-tap behaviour is byte-identical (feed 5 / bath 3 / play free,
  happiness +1 clamped 0..5).
- **K06-BUG-2 (major) — concurrent wardrobe buys overspent.** Affordability
  was checked outside the transaction and the write used the stale read
  (Wellies 40 + Crown 120 both landed from 120 coins). Now one transaction:
  re-read the tile, deduct conditionally
  (`UPDATE children SET coins = coins - ? WHERE id = ? AND coins >= ?`,
  0 rows = cannot afford, no-op), then claim the tile only while still
  unowned (`owned = false` in the WHERE); a lost same-item race refunds the
  deduction inside the same transaction, so a double tap charges exactly
  once. The bloc's `state.nest` pre-check stays as the fast toast path, but
  correctness no longer depends on it.
- Proofs un-skipped in `k06_bugs_test.dart` (BUG-1, BUG-2 only — both pass,
  verified with `--run-skipped`). BUG-3/4/5/6 stay skipped: views/widgets,
  the parallel UI builder's layer.

## FIXES_1 items NOT in this layer (left for the UI builder)

- BUG-3 heading apostrophe, BUG-4 nest art box, BUG-5 care-button heights,
  BUG-6/D1 invisible dashed border, ORCHESTRATOR_NOTES item 1 — all
  `presentation/views|widgets`, untouched here.
- ORCHESTRATOR_NOTES items 2 (glyphs) and 3 (seed prices): shared-asset /
  shared-seed concerns, already filed as `SHARED_REQUEST.md` §5/§6 by the
  test stage; the screen renders whatever the DB holds and hard-codes
  nothing. Nothing to change in this layer.

## Files changed

- `app/lib/features/pip/data/pip_repository_impl.dart`: atomic `_care`
  and atomic `buyItem` (+ claim/refund), as above. Nothing else in the
  file changed; `watchNest`/ordering/names/costs from iteration 1 intact.
- `app/test/features/pip/pip_repository_test.dart`: new `atomic writes`
  group — 5 concurrent feeds land at 95 (not 115), concurrent
  wellies+crown buys leave scarf + sunhat + exactly one purchase with a
  non-negative balance, concurrent same-item buys charge exactly once (80).
- `app/test/features/pip/k06_bugs_test.dart`: removed `skip: true` from
  the K06-BUG-1 and K06-BUG-2 proofs only.

## Verification (logic-stage scope — no full-app test, no simulator)

- `dart format` on touched dirs → clean.
- `flutter analyze lib/features/pip test/features/pip/pip_repository_test.dart
  test/features/pip/k06_bugs_test.dart test/features/pip/pip_bloc_test.dart`
  → No issues found.
- `flutter test --timeout 120s test/features/pip/pip_repository_test.dart
  test/features/pip/pip_bloc_test.dart` → All tests passed (36).
- `flutter test --timeout 120s test/features/pip/k06_bugs_test.dart
  test/features/pip/pip_bloc_actions_test.dart` → All tests passed
  (38 green, 4 skipped — the 4 remaining skips are BUG-3..6, view layer).
- `--run-skipped --plain-name K06-BUG-1` → passed; `--plain-name K06-BUG-2`
  → passed.
- Shared regression `repositories_test.dart` “pip care, wardrobe and look”
  → passed.
- No `google_fonts`, no `DateTime.now()`, no new ids, no `core/` or `app/`
  edits, no views/widgets edits, no simulator.

## LEFT FOR NEXT ITERATION

- Nothing unfinished in the logic layer. UI builder owns BUG-3/4/5/6 + D1.

VERDICT: PASS
