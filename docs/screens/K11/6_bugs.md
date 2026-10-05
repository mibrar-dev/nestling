# K11 · Badges — stage 6 bug hunt (iteration 1)

Adversarial pass over `/badges` (feature `badges`, kid mode): data edge cases,
rapid double taps, back/deep-link navigation, restart persistence,
mode guards, dark mode, 320 px × 1.3 text scale, async gaps, timezone and
money. Two real bugs were proven; both are **minor** and both have a failing
test in `app/test/features/badges/k11_bugs_test.dart`, marked `skip: true`
with the bug id so the suite stays green (remove the skip / run with
`--run-skipped` to watch them fail). No major bug was found, so the stage
verdict is PASS.

No file under `app/lib/` was touched (stage 6 does not fix the screen).

## Bugs

### K11-BUG-1 — `happyDays` is never clamped to the seven days the card draws

- **Severity:** minor (data robustness; unreachable from the seeded demo,
  whose stored values are 4/3 — needs a stored value outside the schema's
  documented 0..7).
- **Where:** `app/lib/features/badges/presentation/widgets/happy_week_card.dart:86`
  (`on: i < happyDays` fills the dots) and `:97`
  (`HappyWeekCopy.why(happyDays)` prints the line). `Children.happyDays` is
  documented `0..7` at `app/lib/core/data/app_database.dart:93`, but neither
  the column nor the card enforces it. Same defect class as
  `4_review.md` finding 2.
- **What happens:** with `happyDays = 8` the card fills all seven Mon–Sun
  dots (there is no eighth) and prints
  `8 happy days this week — Pip hasn’t stopped singing.` — the line claims a
  day the row cannot draw.
- **Repro:** write `happyDays = 8` for Maya (`db.update(db.children)`), open
  `/badges` → why-line reads “8 happy days” under seven dots.
- **Failing test:** `K11-BUG-1 happyDays 8 renders an impossible week`
  (skipped).
- **Suggested fix:** clamp once in `HappyWeekCard.build`:
  `final n = happyDays.clamp(0, 7);` and use `n` for both the dots and
  `HappyWeekCopy.why(n)`. (Negative input already renders as the zero copy;
  the clamp makes that explicit. Do not fix in this stage.)

### K11-BUG-2 — no active child in a non-Maya family shows the hard-coded Maya shelf

- **Severity:** minor (deep-link / cleared-state edge; the demo family always
  has Maya, so design shots are unaffected; the same `?? 'maya'` convention
  exists in `kid_jar`, `kid_shop`, `pocket_money` and `pip`, so the fix is a
  repository-level decision).
- **Where:** `app/lib/features/badges/data/badges_repository_impl.dart:34`
  (`_badgesFor(state?.activeChildId ?? 'maya')`, and the same fallback in
  `watchItems` at `:23`).
- **What happens:** when `app_state.activeChildId` is null — a deep link to
  `/badges` before a child was picked, or a cleared app_state row — the
  repository fabricates the child id `'maya'` instead of resolving a child
  from the family. In a family whose children are not named Maya, the screen
  shows a shelf that belongs to no child: every badge “Keep going!” and the
  zero-earned subtitle, while the real child's earned badges and happy days
  are invisible.
- **Repro:** a family whose only child is Zoe (one earned badge `bookworm`,
  `happyDays 2`), `activeChildId` null → `/badges` shows
  `No shiny ones yet. Finish a quest to earn your first!` and no
  `Got it!` cell, instead of Zoe's shelf (or the childless empty state).
- **Failing test:** `K11-BUG-2 a non-Maya family with no active child shows
  the Maya shelf` (skipped).
- **Suggested fix:** resolve the active child the way P15 does
  (`FamilyRepositoryImpl._effectiveSelection`): the persisted
  `activeChildId` when it names a real child, else the first child in roster
  order (creation order), else no child. Render that child's shelf or the
  existing childless empty state — never a hard-coded id. Keep
  `watchActiveBadges`'s stream shape and the DB-insertion badge order.

## Checked, no bug found (negative results)

Every probe below was run against the in-memory Drift DB (or the real
repository) and came back clean; the passing probe code was removed from
`k11_bugs_test.dart` so the bugs file contains only the two skipped tests.

| Probe | Result |
|---|---|
| Rapid double tap on Back, single push and a two-deep `/badges` stack (two taps in the same frame) | one pop, no double pop, no exception |
| Rapid double tap on the lock | already pinned by `badges_view_test.dart` (“a fast double tap on the lock opens one gate only”) |
| Whole-screen overflow scan at 320 px / text scale 1.3 (8 scroll steps through the grid + week card) | no `RenderFlex` overflow, no exception |
| Very long badge title (`Maximilian-Alexander Supercalifragilistic`) at 320/1.3 | ellipsised inside the cell; cell keeps the column width, right edge on the 20 px gutter |
| `happyDays = -3` | renders the zero copy `Let’s make today a happy day!`, no dots, no crash (folded into K11-BUG-1's clamp suggestion) |
| Dark mode at 320/1.3, week card scrolled into view | no exception; tokens flip, medal/dot colours keep the design's own colours |
| App restart (in-process: dispose + pump `NestlingApp` again) after earning `early-bird` | earned badge survives; grid re-reads from Drift |
| Empty state → live shelf (insert a badge while `No badges yet` is showing) | grid appears live, no stale empty state |
| Zero children and zero badges (earned/badges/children deleted, active child null) | kid empty state + chrome (back/lock) intact, no crash |
| Parent-mode deep link to `/badges` | renders the kid screen; the router only guards kid→parent locations (`router.dart` parentOnly list), so this is app-wide policy, not a K11 bug |
| `_switchMap` stale-emission race (`4_review.md` finding 3): 10 concurrent switch+write bursts, plus a queued previous-child write probe | no emission from the switched-away child ever landed after the switch; the overlap stays hardening-only, no failing repro |
| Timezone / BST and money rounding | N/A on K11 — no clock use anywhere in the feature (`happyDays` is a stored count) and no £/coins on the screen |
| Nine-id medal map (`ORCHESTRATOR_NOTES.md` update) | probe inserted all nine design ids: each rendered its own `assets/illustrations/badge_*.svg` (no rosette fallback); also pinned by the stage-3 `badges_art_test.dart` |

## ORCHESTRATOR_NOTES status (mandatory items)

- **Seed nine design badges:** handled by the orchestrator on
  `shared/k11_badges_seed` (merged to `main`, then into this worktree by the
  loop before the next build). This stage does not edit `seed.dart`; this
  worktree still shows the 8 legacy rows, which is a process state, not a
  finding. The `TODO(K11)` removal belongs to the build stage after the merge.
- **Badge art for all nine ids:** verified — the `_artFor` map in
  `badge_grid_cell.dart` already carries all nine ids, and the probe above
  proved each renders its own medal asset in the locked state. No stage-6
  action.

## Verification

```
dart format test/features/badges/k11_bugs_test.dart        → clean
flutter analyze test/features/badges/k11_bugs_test.dart    → No issues found!
flutter test --timeout 120s test/features/badges/k11_bugs_test.dart
  → +0 ~2: All tests skipped.          (suite green, bugs marked skip)
temporary unskipped copy (deleted afterwards):
  → +0 -2: K11-BUG-1 … [E] / K11-BUG-2 … [E]   (both bugs proven)
```

No simulator was booted, no `flutter clean`, no files outside
`app/test/features/badges/k11_bugs_test.dart` and `docs/screens/K11/6_bugs.md`
were touched by this stage.

VERDICT: PASS
