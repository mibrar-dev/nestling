# P14 · Rewards manager — Stage 6 adversarial bug hunt (iteration 1)

Route `/rewards` · feature `rewards` · parent mode · design
`design/html-source/screens/P14-rewards.html` + light/dark PNGs
(1170×2532 ÷3). This stage changed **nothing** in `app/lib/**`; it added
`app/test/features/rewards/p14_bugs_test.dart` and this report.

`ORCHESTRATOR_NOTES.md` (12:27 + 12:35) is mandatory and is covered below:
the creation-order ruling is filed as **P14-B05**, and the "do not hard-code
the toggle state" item is pinned by a verified-clean DB-driven guard (the
seed's `Baking together = false` itself ships with `shared/rewards_seed_order`,
not in this snapshot).

Gates on the snapshot (`flutter test test/features/rewards/p14_bugs_test.dart
test/features/rewards/rewards_bloc_test.dart
test/features/rewards/rewards_repository_test.dart
test/features/rewards/rewards_view_test.dart
test/features/rewards/reward_card_widget_test.dart`):

* **+42 passed, 6 skipped, 0 failed** — the six skips are the open-bug
  proofs below; `--run-skipped` makes every one of them fail on the current
  code, and the 9 verified-clean tests pass in both modes.
* `flutter analyze test/features/rewards/p14_bugs_test.dart` → No issues found;
  `dart format` clean.
* Nothing under `app/lib/**`, `app/lib/core/**` or `tools/**` was touched.

## Bug summary

| id | severity | one-liner | failing test (skip-marked) |
|---|---|---|---|
| P14-B01 | **major** | On iOS the keyboard covers the editor sheet — Save, Cancel and Delete sit behind it once the name field is focused | `[P14-B01] the keyboard must not cover the editor sheet controls` |
| P14-B02 | minor | The empty state and the failure surface are top-aligned under the nav bar, not centred in the scroll (plan §4) | `[P14-B02] the empty state is centred in the scroll area` · `[P14-B02] the failure surface is centred in the scroll area` |
| P14-B03 | minor | A sheet write failure closes the sheet and loses the typed input; no inline error caption (plan §4) | `[P14-B03] a sheet write failure keeps the sheet open with an inline error` |
| P14-B04 | minor, latent | Deleting a reward leaves its pending redemption request orphaned; approving it is a silent no-op | `[P14-B04] deleting a reward with a pending request orphans the request` |
| P14-B05 | **major** | The list is ordered by coin price, not creation order (owner rule / ORCHESTRATOR_NOTES 12:27) | `[P14-B05] rewards are listed in creation order, not price order` |

---

## P14-B01 — major — the iOS keyboard covers the editor sheet

**Repro.** `/rewards` → `+ New reward` → focus the `Name` field (the iOS
keyboard opens and floats over the Flutter view — it does not resize it) →
try to tap `Save`. The sheet does not move.

**Measured** (390×844, keyboard inset 300 px):

| element | app rect (bottom) | keyboard top | result |
|---|---|---|---|
| `Save` | 682 → **734** | 544 | 190 px behind the keyboard |
| `Cancel` | 742 → **794** | 544 | 250 px behind the keyboard |
| `Delete` (edit sheet) | below Cancel | 544 | behind |

**Failing test.**
`[P14-B01] the keyboard must not cover the editor sheet controls`
(`--run-skipped`: `Expected: a value less than or equal to <544.0>
Actual: <734.0>`).

**Root cause.** `showNestBottomSheet`
(`app/lib/core/design_system/components/nest_bottom_sheet.dart`) never reads
`MediaQuery.viewInsets`; Flutter's `_ModalBottomSheetLayout` positions the
sheet at `size.height − childHeight` and ignores insets (verified in the
SDK source), and on iOS the keyboard is reported as insets only. On Android
the window resizes so the sheet moves; **iOS is the broken platform**.

**Suggested fix.** Pad the sheet content by
`MediaQuery.viewInsetsOf(context).bottom` and keep it tappable when the
remaining height is short. This is best done once in the shared
`showNestBottomSheet` (file a `SHARED_REQUEST` — every screen's sheet has the
same hole); feature-local alternative: wrap `RewardEditorSheet`'s body in an
`AnimatedPadding(bottom: viewInsets)` + a height-constrained
`Flexible`/`SingleChildScrollView` so Save/Cancel/Delete stay above the
keyboard and the body scrolls.

---

## P14-B02 — minor — empty and failure surfaces are top-aligned, not centred

**Repro A (empty).** Delete every reward (`Seed.demo`, then
`DELETE FROM rewards`) → open `/rewards`. `NestEmptyState` renders at
y 107 → 481; centre **294.0** vs the scroll viewport centre **475.5**
(181.5 px off). The design surface hugs the nav bar and leaves 363 px of dead
space below.

**Repro B (failure).** A load failure (`watchItems` errors) → the message +
`Try again` column renders at y ≈ 107 → 247; union centre **153.0** vs
**475.5** (322.5 px off).

**Failing tests.**
`[P14-B02] the empty state is centred in the scroll area` ·
`[P14-B02] the failure surface is centred in the scroll area`.

**Root cause.** `_RewardsScroll` is a `ListView`, so the `Center` inside its
child gets an unbounded main axis, shrink-wraps and pins the surface to the
top. Plan §4 says "centred in the scroll" for both states.

**Suggested fix.** Use a `CustomScrollView` with
`SliverFillRemaining(hasScrollBody: false, child: Center(...))` (or a
`LayoutBuilder` + `SingleChildScrollView` + `ConstrainedBox(minHeight:
constraints.maxHeight)`), keeping the 20 px gutters and the 66 px bottom pad.

---

## P14-B03 — minor — a failed sheet write loses the input with no inline error

**Repro.** Repository `createReward` throws (e.g. disk full / DB closed) →
`+ New reward` → type `Pizza night` → `Save`. The sheet closes
(`find.text('New reward')` = 0), the typed name is gone, and the list is
replaced by the full-screen failure state (`Try again`); no inline caption.

**Failing test.**
`[P14-B03] a sheet write failure keeps the sheet open with an inline error`
(`--run-skipped`: `Expected: exactly one matching candidate … "New reward"`,
`Actual: Found 0`).

**Root cause.** `RewardEditorSheet._submit()` calls `onSave` then `_close()`
synchronously; the write result is only observable on the list's stream state
(plan §4 wants the sheet kept open with a `danger` 13/18 w600 caption above
Save). The 2a build flagged this as a missing per-write result channel.

**Suggested fix.** Give the write events a result channel (`RewardsCreate/
Update/DeleteRequested` returning a `Future`/emitting a per-write result the
sheet awaits) or drive an `errorText` into the sheet from a `BlocListener`;
keep the sheet open and render the caption above Save on failure.

---

## P14-B04 — minor, latent — deleting a reward orphans its pending request

**Repro.** Seed demo → insert the row K08's `requestReward` writes
(`reward_redemptions`: `r-cafe`, `maya`, `requested`) → open `/rewards` →
`Edit Trip to the park cafe` → `Delete` ×2. The reward row is gone but the
redemption row remains `requested` (foreign keys are off). `watchRequests()`
then maps it to title `Reward` / 0 coins, and `approveRedemption` returns
silently — no coins are deducted and the status never leaves `requested`.

**Failing test.**
`[P14-B04] deleting a reward with a pending request orphans the request`
(`Expected: empty`, `Actual: [RewardRedemption(… status: requested …)]`).

**Root cause.** `RewardsRepositoryImpl.deleteReward` deletes only the reward
row; there is no cascade or guard for `reward_redemptions` (and SQLite FK
enforcement is off app-wide).

**Suggested fix.** In the feature-owned repository, delete the reward and its
redemptions in one transaction (or block the delete while a request is
pending) — an orchestrator/product call, since keeping request history may
also be legitimate. Latent today (K08's request UI is not built yet), but
reachable as soon as it is.

---

## P14-B05 — major — the list is ordered by price, not creation order

**Repro.** Seed demo → open `/rewards`. The cards render
`30 min extra screen time, Stay up 15 min later, Pick Friday film, Choose
dinner, Baking together, Trip to the park café` — `coinPrice ASC`, not the
order the rewards were added.

**Measured** (`RewardCard` title order):

| expected (creation order, owner rule) | actual (price order) |
|---|---|
| 30 min extra screen time | 30 min extra screen time |
| Pick Friday film | **Stay up 15 min later** |
| Stay up 15 min later | **Pick Friday film** |
| Baking together | **Choose dinner** |
| Trip to the park café | **Baking together** |
| Choose dinner | Trip to the park café |

**Failing test.**
`[P14-B05] rewards are listed in creation order, not price order`
(`--run-skipped`: `at location [1] is 'Stay up 15 min later' instead of
'Pick Friday film'`).

**Root cause.** `RewardsRepositoryImpl.watchItems()` still calls
`_db.watchRewards(Seed.familyId)`, whose query is
`ORDER BY coinPrice` (`app_database.dart:513`). `ORCHESTRATOR_NOTES.md`
(12:27, 12:35) rules the list must follow the order the rewards were added and
points at `AppDatabase.watchRewardsInCreationOrder` on `main` (branch
`shared/rewards_seed_order`, which also fixes the seed's
`Baking together → needsOk: false`). That shared branch is not in this
snapshot yet (`git merge-base` check: not an ancestor).

**Suggested fix.** With the next main merge, switch `watchItems()` to
`_db.watchRewardsInCreationOrder(Seed.familyId)` and drop the price sort; the
view already renders whatever the stream yields, so no widget change is
needed. Keep the toggle state DB-driven (pinned clean by
`[P14-clean] the toggle state comes from the DB, not the view`).

---

## Verified clean — attacks that were run and held

* **Kid-mode guard**: a kid-mode deep link to `/rewards` lands on
  `/parental-gate` (`selectMode(kid)` + `session.setAppMode('kid')`).
* **Back navigation**: `push('/rewards')` from `/today`, tap `Back` →
  `pushedPath` returns to `/today`.
* **Restart persistence**: a reward created through the sheet is still there
  after `disposeApp` + a fresh app (new bloc/view) over the same Drift DB.
* **Rapid double taps**: two taps on `Save` and two on `+ New reward` in the
  same frame produce exactly one write / one sheet (the pop/push animation
  ignores pointers); a toggle double tap 16 ms apart is two flips and ends
  consistent in UI + DB.
* **Data edges**: 9999 coins and
  `Maximilian-Alexander’s cinema trip` render at 320 px width × 1.3 text
  scale with no overflow and no clipped fixed rects; the empty list renders
  the empty state and `+ New reward` round-trips a create into the list.
* **Accessibility actions**: all 6 toggles, all 6 edit buttons, `Back` and
  `+ New reward` expose `SemanticsAction.tap`; `performAction(tap)` on a
  toggle flips the real `r-screen` DB row. `Save` with an empty name is
  disabled (`enabled: false`, no tap action) — the disabled-control rule.
* **Toggle state is DB-driven** (ORCHESTRATOR_NOTES 12:27): flipping
  `r-baking.needsOk` to `false` in the DB renders that row OFF while the
  other rows stay ON — nothing is hard-coded.
* **Dark mode** at 1.3 scale renders the six seeded rows with no exception.

## Notes, not bugs

* **Same-frame toggle double tap.** Two taps in the same <1 ms frame both
  compute `!true` and write `false` twice; with a 1 ms pump between taps the
  stream has already re-emitted and the second tap restores `true`. A frame is
  16 ms, so a human double tap cannot hit this window — recorded for
  completeness, not filed.
* **Raw exception text.** The failure surface prints `error.toString()`
  (e.g. `Bad state: boom`) rather than a friendly message; cosmetic, matches
  the plan's `errorMessage ?? …` contract.
* **No in-app entry point yet.** `RewardsRoutePaths.rewards` is referenced
  only by the router and smoke tests on this branch; the Family/Money entry
  belongs to other screens. Not a P14 defect.
* **`Reward.detail`** is still carried but unused by P14 (plan §2).

## Verdict rationale

P14-B01 and P14-B05 are major defects: on iOS the primary create/edit flow's
Save, Cancel and Delete controls are covered by the keyboard, and the list is
ordered by coin price against the owner rule / ORCHESTRATOR_NOTES 12:27.
P14-B02–B04 are minor (two plan-§4 layout/copy deviations and one latent
data-integrity gap). Per the stage rule ("PASS only if no major bugs") this
iteration fails.

VERDICT: FAIL
