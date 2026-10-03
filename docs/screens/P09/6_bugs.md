# P09 — stage 6 · FIND BUGS (iteration 4)

Tree: `8022be3` (“P09: checkpoint after build (iteration 4)”, batch-5
integration complete) + the proof below. No screen code was changed — the
brief forbids fixing here.

Adversarial area sweep (iteration 4): the twelve earlier proofs re-run, then
new probes over the iteration-4 changes (Stack-overlaid toggle, uniform card
padding, boundary-jump stepper, `quest*` icons, parent-safe save-failure
copy) and the usual edge set — 0 / 1 / 6 children, emoji-leading and long UK
names, £0.00 / £999.99 / 9999 coins, rapid double taps, back navigation and
deep links, Drift restart persistence, the parent/kid guard, dark-mode
contrast, 320 dp × text scale 1.3, async gaps, Europe/London wall-clock
storage and integer-pence money.

All proofs live in `app/test/features/quests/p09_bugs_test.dart`. The one
iteration-4 proof is `skip: true` so the suite stays green; run it with
`--run-skipped`. Every probe in the “attacks that hold” group runs unskipped.

## Earlier findings — all FIXED, proofs unskipped and green

| id | what was wrong | fix | proof |
|---|---|---|---|
| BUG-P09-1 | payout helper hard-coded 1p/coin | streams `watchCoinValuePencePerCoin()` | green |
| BUG-P09-2 | double-tap Save created the quest twice | `_saving` guard + pill disabled | green |
| BUG-P09-3 | non-picker icon showed no selected tile | aliases cover every seeded key | green |
| BUG-P09-4 | out-of-range coins unreachable | bounds widen to the stored value | green |
| BUG-P09-5 | removed child left an orphaned assignee | roster-unknown falls back to `Anyone` | green |
| BUG-P09-6 | out-of-range reward silently clamped | Save blocked + live-region caption | green |
| BUG-P09-7 | alias tile tap rewrote the stored key | selected tile’s tap is inert | green |
| BUG-P09-8 | emoji nickname threw a UTF-16 paint error | `_initial` takes the first grapheme | green |
| BUG-P09-9 | card 68 / track 307,618.5 after batch 5 | uniform padding + no Transform | green (2 tests) |
| BUG-P09-10 | 59×44 hit slop clipped by the 40-high row | Stack-overlaid `Positioned` toggle | green (3 tests) |
| BUG-P09-11 | 9999 needed 9899 taps to repair | first step jumps to the boundary | green |
| BUG-P09-12 | legacy glyphs on four tiles | `questBed/questDishes/questHoover/questBins` | green |

**Iteration-4 verification of the fixes** (all measured at HEAD):

* approval card `20/600/350/72`, due card top `684`, track
  `303/620.5/51/31` — the design rects exactly (BUG-P09-9 proofs);
* the toggle’s tap target is now the full design `::before` 59×44:
  edges 614.5 / 657.5 / 299.5 / 357.5 flip; 0.5 px outside
  (613.5 / 658.5 / 298.5 / 358.5) misses; corners flip (scratch map,
  BUG-P09-10 proofs);
* `−` on 9999 → `100` and `+` on 0 → `1` in one tap; caption clears, Save
  enables (BUG-P09-11 proof);
* tiles draw `assets/icons/ic_quest_*.svg` (BUG-P09-12 proof).

## Summary — iteration 4

| id | severity | one-liner | failing test |
|---|---|---|---|
| BUG-P09-13 | minor | the parent-safe save-failure copy (review finding 4) is dead in debug builds: the repository’s coin-range guard asserts first (`AssertionError`), which the bloc’s `_editorError` does not map, so the raw `Failed assertion: … Quest coins must be 1..100, got 9999` text reaches the toast | `BUG-P09-13 — the parent-safe save copy is dead in debug` › `the real range guard leaks the raw assert text into the toast` |

---

## BUG-P09-13 — minor — the parent-safe save copy is dead in debug

**Where:** `QuestsBloc._editorError` (`quests_bloc.dart:117-124`) —
`if (error is ArgumentError)` — against
`QuestsRepositoryImpl._checkCoins` (`quests_repository_impl.dart:97-105`),
which **asserts first** and only then throws `ArgumentError`.

**Why it is wrong:** review finding 4 asked that a programmer error never
reach the parent verbatim; the bloc maps `ArgumentError` to
`QuestsBloc.saveFailedMessage` and logs the detail. But under
`flutter test` / debug builds asserts are enabled, so the guard’s actual
error type is `AssertionError` — the mapping misses and `error.toString()`
(the raw `Failed assertion: …` text, including the repository file path and
line) becomes `editorError`, which the listener shows in the toast. In
release the assert is stripped, the `ArgumentError` path runs, and the copy
is parent-safe — so the two build modes disagree, and every test that mocks
the guard (throwing `ArgumentError`) passes while the real guard leaks.
Reachability: the clamped editor never sends an out-of-range value, so this
is a latent defensive-path defect today; it becomes user-visible the moment
any caller bypasses the editor’s clamp.

**Repro:** with the real repository (no mock), dispatch
`QuestsCreateRequested` for a 9999-coin quest; `bloc.state.editorError` is
the raw assertion string, not `QuestsBloc.saveFailedMessage`:

```
Expected: 'Could not save the quest. Try again.'
  Actual: '\'…quests_repository_impl.dart\': Failed assertion: line 99 pos 7:
           \'coins >= minCoins && coins <= maxCoins\':
           Quest coins must be 1..100, got 9999'
```

**Suggested fix:** map both error types —
`if (error is ArgumentError || error is AssertionError)` — or drop the
assert and keep the `throw` as the single guard (then debug and release both
surface `ArgumentError`); either keeps the states/bloc suites’ intent and
makes the two build modes behave the same.

---

## Observations (not filed as bugs)

* **Post-repair stepper re-entry.** After the one-tap repair (9999 → 100,
  0 → 1) the widened `_coinFloor`/`_coinCeiling` still include the stored
  value, so `+` walks back to 101 (caption and Save block return) and `−`
  walks back to 0. This is the BUG-P09-4 “every value between the stored
  value and the design range stays reachable” contract, it is recoverable in
  one tap, and nothing is written while out of range — recorded here because
  the two requirements interact; not filed.
* **Tree-wide suite and the calendar rollover.** The whole-app run at this
  tree reports 35 failures, all in other features: kid_home (28, e.g.
  `Found 0 widgets with text "4 of 6 done"`), approvals (4), today (2) and a
  core `family_time_test` `.single`. The seed is pinned to Sat 3 Oct 2026 by
  `test/flutter_test_config.dart`, but the real clock rolled to Sun 4 Oct
  during the session, so period-dependent counts in those features fall
  outside the current day. The quests feature is unaffected
  (`flutter test test/features/quests` is fully green). Environment/process
  item, not a P09 finding.

## Attacks that hold (probes, unskipped — 13 tests)

- **Rapid double taps:** double-tap `Delete quest` → one confirm modal;
  double-tap `Due by` → one option sheet; double-tap `Cancel`, a due-sheet
  row and `Keep it` never pop a second route; double-tap **Save** is guarded.
- **Restart persistence:** save → dispose the app → new `NestlingApp` over
  the same Drift DB → the quest is on the library’s Active tab.
- **Parent/kid guard:** kid mode + `/quest-editor` (plain and with `?id=`)
  lands on `/parental-gate`.
- **320 dp × text scale 1.3**, new and edit mode: no overflow/exception.
- **One-child family:** the new quest defaults to that child.
- **Six children with long names** at 320 × 1.3: pills wrap in creation
  order, `Anyone` last.
- **Dark mode:** the Save pill’s `--surface` on `--leaf` keeps ≥ 4.5:1.
- **Back navigation:** a quest pushed from Today (`?questId=`) → Cancel
  returns to `/today`.
- **Zone/BST:** with the family moved to `Asia/Dubai`, the due time is still
  the wall-clock `17:00`.
- **A11y actions:** due-sheet rows and delete-confirm buttons expose
  `SemanticsAction.tap`; `performAction(tap)` moves the real state/DB.
- **`?idea=` prefill, both-keys URL, emoji nicknames, blocked saves** are
  covered green by the feature suites (`quest_editor_view_test.dart`,
  `quest_editor_coin_rules_test.dart`, `quest_editor_data_integrity_test.dart`).

## Verification

```
$ dart format --set-exit-if-changed test/features/quests/p09_bugs_test.dart
Formatted 1 file (0 changed)
$ flutter analyze test/features/quests/p09_bugs_test.dart
No issues found!
$ flutter test test/features/quests/p09_bugs_test.dart
00:04 +30 ~1: All tests passed!        # 17 fixed proofs + 13 probes
$ flutter test test/features/quests/p09_bugs_test.dart --run-skipped
+30 -1: Some tests failed              # BUG-P09-13 fails as documented
$ flutter test test/features/quests
00:15 +402 ~1: All tests passed!
$ flutter test
01:17 +2582 ~2 -35: Some tests failed  # other features; real-date rollover
```

No simulator was booted, installed on, screenshotted or driven; `flutter
clean` was never run; no `// ignore:` and no shared file was touched.

**Out of scope (process, not findings):** the worktree also carries other
stages’ uncommitted work (briefs, `3_test.md`, `4_review.md`, UI PNGs,
`quest_editor_toggle_hit_area_test.dart`); it was left untouched.

VERDICT: PASS
