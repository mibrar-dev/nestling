# shared/unique_ids — report

## Files changed

- `app/lib/core/data/ids.dart` (new): `newId(String prefix)` →
  `'$prefix-<uuid v4>'` from `Random.secure()` 128-bit (v4 version/variant
  bits). Clock-independent by construction. No `uuid` package added
  (task allows crypto-random; avoids a new dependency).
- `app/lib/features/rewards/data/rewards_repository_impl.dart`:
  `createReward` stamps `newId('reward')` instead of
  `'reward-${clock.now()…millisecondsSinceEpoch}'`; dropped the now-unused
  `package:clock/clock.dart` import.
- `app/lib/features/family/data/family_repository_impl.dart`: `addChild`
  stamps `newId('child')`, `inviteCoParent` stamps `newId('coparent')`
  instead of clock-ms ids; dropped the now-unused
  `package:clock/clock.dart` import (kept `app_clock.dart` for `createdAt`).
- `docs/screens/RULES.md` (§4): added
  "Ids are newId(prefix) (uuid); never derive ids from the clock."
- `app/test/core/data/unique_ids_test.dart` (new): see tests below.

## What / why

P09 BUG-P09-14: ids derived from the pinnable app clock
(`'q-${appNowUtc().millisecondsSinceEpoch}'`) collide whenever two inserts
share a millisecond — always under the pinned test clock, and in production
on fast double-tap/restart. Drift then throws UNIQUE and the raw SQL error
reaches the toast. Same pattern existed on main for rewards (`reward-…`),
children (`child-…`) and co-parents (`coparent-…`). All three now use the
shared crypto-random `newId`. P09's own `quest_editor_view.dart:543` is on
the unmerged P09 branch and intentionally untouched — P09 adopts `newId`
itself.

## Tests added (`app/test/core/data/unique_ids_test.dart`)

- `newId returns 10k distinct values`
- `newId keeps the prefix and uuid shape`
- `pinned clock back-to-back creates: two rewards in a row succeed with
  distinct ids`
- `pinned clock back-to-back creates: two children in a row succeed with
  distinct ids`
- `pinned clock back-to-back creates: two co-parents in a row succeed with
  distinct ids`

## Raw-exception-text audit (DO 3, report-only — no redesign)

With clock ids gone, insert UNIQUE collisions should no longer fire. Where
a raw error could still reach the user, mapped against existing parent-safe
copy:

- `family_bloc.dart` `_onRemoveChildRequested` / `_onChildSelected` set
  `errorMessage = error.toString()` → toasted via `showNestToast` in
  `child_profile_view.dart` (loaded state). Raw text would surface on
  failure. `addChild` already maps to parent-safe
  `'Something went wrong — try again'`.
- `p14_reward_meta.dart` `RewardCopy.saveError/deleteError` interpolate
  `$error` into the inline caption above Save/Delete (raw text visible).
  Parent-safe `RewardCopy.actionFailed` exists for the Needs-OK flip.
- Load-path `onError: error.toString()` in `rewards_bloc`, `family_bloc`,
  `quests_bloc` feeds the full-screen failure bodies (not toasts).
- No presentation/bloc copy was changed here (out of scope for this task).

## Follow-up screens must do

- P09: adopt `newId('q')` at `quest_editor_view.dart:543` on its own branch.
- P14: refresh the two stale `reward-{ms}` comments
  (`rewards_event.dart:38`, `p14_reward_editor_sheet.dart:76`); consider
  mapping `saveError`/`deleteError` to parent-safe copy.
- P05/P15: `family_repository_impl.dart:41` `DateTime.now()` anchor fallback
  (noted in P09 6_bugs.md observations) is still a CLOCK-rule violation for
  that loop; untouched here.

## Verification

- `cd app && dart format .` → 0 changed (clean)
- `flutter analyze` → No issues found!
- `flutter test` → All tests passed! (+2913 ~2, incl. 5 new above)

VERDICT: PASS
