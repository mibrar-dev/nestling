# P15 · Child profile — bug hunt (Stage 6, iteration 1)

Route `/child-profile` (`FamilyRoutePaths.childProfile`) · feature `family` ·
parent mode · designs `design/screens/{light,dark}/P15-child-profile.png` ·
tree tested: iteration-1 checkpoint **`586a9d2`** ("P15: checkpoint after
build (iteration 1)"), main merged through `abf2a96`.

Sources re-read for this pass: `docs/screens/RULES.md`, `docs/ARCHITECTURE.md`,
`docs/DESIGN_SPEC.md` §5 P15, `docs/design/SPACING_SPEC.md`, `1_plan.md`,
`2_build.md`, `2a_build_logic.md`, `2b_build_ui.md`; the built screen
(`child_profile_view.dart`, `child_profile_body.dart`,
`child_profile_copy.dart`, `family_bloc.dart`, `family_repository_impl.dart`,
`family_routes.dart`) and the family test suite. The iteration-1 test /
review / UI stages ran concurrently with this stage; their notes and
`ORCHESTRATOR_NOTES.md` (18:15) are cross-checked below.

Method: every hypothesis was probed against the real tree first (widget /
repository / bloc probes with real in-memory Drift and bundled fonts); the
red ones were then written as skipped proofs in
`app/test/features/family/p15_bugs_test.dart` with their bug id, so this
stage adds no red to the suite (the test stage's own red repros are separate).

**Result: 5 bugs owned by this stage — 4 major (1, 6, 7, 8) and 1 minor (3).**
The parallel test stage independently found the same P15-BUG-1 plus three more
(P15-BUG-2/4/5) and the UI stage FAILed on `ORCHESTRATOR_NOTES.md` item 1.
**VERDICT: FAIL** (the brief's PASS bar is "no major bugs").

| Id | Severity | Summary | Failing proof |
|---|---|---|---|
| P15-BUG-1 | **major** | `/child-profile?childId=` is ignored: P05 "Edit Leo" and P08 Today's Leo card open **Maya's** profile (also test stage P15-BUG-1, review finding 1) | `P15-BUG-1a`, `P15-BUG-1b` |
| P15-BUG-6 | **major** | Removing a child deletes only the `children` row — pending approvals, completions, ledger, quests, wardrobe, badges, goals survive | `P15-BUG-6` |
| P15-BUG-7 | **major** | Removing the active child leaves `app_state.active_child_id` pointing at the deleted row (review finding 2) | `P15-BUG-7` |
| P15-BUG-8 | **major** | `watchProfile` period math uses the wall clock, not the pinned seed anchor — demo numbers/suite break on 2026-10-04 (review finding 3) | `P15-BUG-8` |
| P15-BUG-3 | minor | A second identical remove failure is suppressed as a duplicate state — no fresh toast (same root as test stage P15-BUG-3) | `P15-BUG-3` |

Ids 1–5 belong to the test stage's repros (its un-skipped red proofs in
`child_profile_view_test.dart`, `child_profile_bloc_test.dart`,
`child_profile_states_test.dart`, `child_profile_copy_test.dart`,
`child_profile_theme_size_test.dart` and `SHARED_REQUEST.md` §1); 6–8 are the
bugs this stage found that the test stage did not cover.

---

## P15-BUG-1 — major — the `childId` query parameter is ignored

**Repro (user path).** Open P05 `/add-children` → tap the pencil on **Leo's**
card (or P08 `/today` → tap **Leo's** kid card). P15 opens showing **Maya**:
hero "Maya", "Age 7–9 · Pip is a Fledgling", "Remove Maya from family". Deep
link `/child-profile?childId=leo` does the same.

**Evidence.**

* `family_routes.dart:31-41` builds `ChildProfileView` without reading
  `state.uri.queryParameters['childId']`.
* `family_repository_impl.dart:93,119` selects `app_state.activeChildId`
  (demo seed: `'maya'`).
* `kid_card_grid.dart:130` (P05) and `today_loaded_body.dart:557` (P08) both
  navigate with `?childId=${child.id}`; nothing calls
  `AppSession.setActiveChild` on those paths (`grep setActiveChild` → only
  `launch.dart:58`).
* Probe on `586a9d2`: `/child-profile?childId=leo` → `profile.child.id ==
  'maya'`; P05 Edit Leo → `'maya'`.

**Failing tests.** `p15_bugs_test.dart` → `P15-BUG-1a`
(`/child-profile?childId=leo must show Leo`), `P15-BUG-1b`
(`P05's Edit Leo pencil must open Leo's profile`). Both RED on `586a9d2`.
The test stage's `P15-BUG-1` group proves the same via the Today tap.

**Suggested fix.** Make the route honour the selector: in `childProfileRoute`,
read `state.uri.queryParameters['childId']`, validate it against the family's
children and persist it through `AppSession.setActiveChild` **before** the
first `FamilyLoadRequested` (a small stateful wrapper around
`ChildProfileView`: `initState` → `await session.setActiveChild(param)` →
`add(FamilyLoadRequested)`), or pass the id into `FamilyBloc` as an initial
selection override. `_selectProfileChild` already falls back to the
first-created child for unknown ids, so validation is optional. This fixes
both entry points without touching P05/P08.

**Impact.** Any "open this child" affordance in the app shows another child's
data — including the remove action and the Pip slot. Wrong-child personal
data class.

---

## P15-BUG-6 — major — `removeChild` orphans every dependent row

**Repro.** `/child-profile` → "Remove Maya from family" → Remove → confirm.
Maya's two pending approvals (`q-dishwasher`, `q-table`) are still in the
database; P11 `/approvals` then renders them as `Child · …` rows
(`approvals_repository_impl.dart:44,51` fall back to `'Child'`/lilac when the
child row is gone). Her six quests stay active and listed in P10; her ledger,
wardrobe, badges and goal stay behind.

**Evidence.** `family_repository_impl.dart:304-306` deletes only
`children`. Probe (real demo DB, `repo.removeChild('maya')`) on `586a9d2`:

| Table | Rows still referencing `maya` |
|---|---|
| `quest_completions` | 7 (2 × `done_pending`, 2 × `approved`, 3 × `to_do`) |
| `ledger_entries` | 11 |
| `quests` (`assignee_child_id`) | 6 |
| `pip_wardrobe` | 4 |
| `earned_badges` | 4 |
| `savings_goals` | 1 |
| `reward_redemptions` | 0 (none seeded) |

The confirm modal promises "They will lose their quests, coins and Pip. This
cannot be undone." (`child_profile_copy.dart`), so the rows must go with the
child. (The schema's `references(Children, #id)` are declarative only —
`beforeOpen` never enables `PRAGMA foreign_keys`, so nothing cascades.)

**Failing test.** `P15-BUG-6` (`removing a child deletes their dependent
rows`) asserts all seven tables are empty for the removed child. RED on
`586a9d2`.

**Suggested fix.** One transaction in `FamilyRepositoryImpl.removeChild`:
delete `quest_completions`, `ledger_entries`, `savings_goals`,
`reward_redemptions`, `earned_badges`, `pip_wardrobe` rows for the child and
the child's assigned `quests` (unassigning family-wide quests is the
alternative if their history must survive), then the `children` row — plus
the P15-BUG-7 selection move below.

**Impact.** User-visible data retention after an explicit, irreversible-looking
delete; P11's inbox shows rows for a child who no longer exists.

---

## P15-BUG-7 — major — `active_child_id` keeps the deleted child

**Repro.** `/child-profile` → remove Maya → confirm → read `app_state`.
`active_child_id` is still `'maya'`.

**Evidence.** Probe on `586a9d2` (UI remove flow, real DB):
`state.activeChildId == 'maya'` after the removal; P15 itself falls through
to Leo via `_selectProfileChild`, which is why the screen looks fine. But
every kid-mode repository resolves `state?.activeChildId ?? 'maya'`
(`pip_repository_impl.dart:25`, `kid_shop_repository_impl.dart:22`,
`kid_jar_repository_impl.dart:24`, `badges_repository_impl.dart:20`; the
review lists six call sites) — with the stale id they keep watching the
deleted child (and, because of P15-BUG-6, her ledger rows are still there for
K09 to render).

**Failing test.** `P15-BUG-7` (`the confirm-remove clears the stale
active_child_id`) — RED on `586a9d2`.

**Suggested fix.** In the same transaction as P15-BUG-6: if
`app_state.active_child_id == childId`, set it to the first remaining child in
creation order (matching the P15 fallback) or NULL when the family is empty.

**Impact.** Cross-screen wrong-child data after a removal; the persisted
session disagrees with the UI's own selection.

---

## P15-BUG-8 — major — period math is wall-clock bound, not anchor-aware

**Repro.** `Seed.anchorOverride = DateTime.utc(2020)`; `Seed.demo(db)`;
`FamilyRepositoryImpl(db).watchProfile().first` → `questsThisWeek == 0`, but
the seed's own story day is now 2020-01-01, whose "done today" daily
completions must count → 4.

**Evidence.** `family_repository_impl.dart:102` uses
`DateTime.now().toUtc()` for `countsForCurrentPeriod`. `flutter_test_config`
pins `Seed.anchorOverride = 2026-10-03`, so on the real date 2026-10-04 the
demo's daily completions (10-03) stop counting: `child_profile_bloc_test.dart`
("selects the activeChildId child with the demo numbers", expects
`questsThisWeek == 4`) fails with no code change — and so does this stage's
`P15-BUG-8` proof. The established pattern already exists:
`today_repository_impl.dart:15-26` takes an injectable clock defaulting to
`Seed.anchorOverride ?? DateTime.now().toUtc()`. (Secondary effect: a screen
left open across London midnight keeps yesterday's counts until the next DB
write, because nothing re-evaluates `now`.)

**Failing test.** `P15-BUG-8` (`demo numbers must follow the pinned seed
anchor`) — RED on `586a9d2` (actual 0, expected 4).

**Suggested fix.** Mirror `TodayRepositoryImpl`:

```dart
FamilyRepositoryImpl({required AppDatabase db, DateTime Function()? clock})
    : _clock = clock ?? _defaultClock;
static DateTime _defaultClock() =>
    Seed.anchorOverride?.toUtc() ?? DateTime.now().toUtc();
```

and use `_clock()` at `family_repository_impl.dart:102`.

**Impact.** Test-integrity major: the loop's required green suite breaks from
2026-10-04; production demo data is unaffected because the seed anchors to
today.

---

## P15-BUG-3 — minor — repeat identical remove failure is silent

**Repro.** With a repository whose `removeChild` throws (DB failure path),
dispatch `FamilyRemoveChildRequested` twice. The first emits
`errorMessage: 'Exception: offline'`; the second computes an identical
`FamilyState`, which Equatable suppresses, so `BlocListener.listenWhen`
(`previous.errorMessage != current.errorMessage`) never fires again — the
user retries, it fails, and no toast appears.

**Evidence.** Bloc probe with a throwing mock on `586a9d2`: two failures,
`1` error state observed. The test stage's `P15-BUG-3` proves the same root
from the load-recovery side (`FamilyState.copyWith` cannot clear
`errorMessage`); this proof covers the remove path.

**Failing test.** `P15-BUG-3` (`a repeated remove failure raises a fresh
toast`) — RED on `586a9d2`.

**Suggested fix.** Clear the signal when the toast is shown (view adds a
`FamilyErrorShown` event that nulls `errorMessage`) or add a monotonically
increasing failure token to the state and listen on it.

**Impact.** Missing feedback on a repeated failure — minor, DB-failure path.

---

## Parallel stages — cross-check (all landed while this stage ran)

* **`4_review.md`** independently found the same three majors: finding 1 =
  P15-BUG-1, finding 2 = P15-BUG-7 (+ orphan cleanup, P15-BUG-6), finding 3 =
  P15-BUG-8. Its minors 4–10 (duplicate failure toast, missing header
  semantics, hero wrap, bare `size: 84`, pronoun, today-test scope, missing
  view-state tests) are tracked there and are not duplicated here; its
  finding 4 overlaps the test stage's P15-BUG-2/3.
* **Test stage red proofs at this snapshot** (`flutter test
  test/features/family` → `+215 ~6 -6` at ~18:47 BST): `P15-BUG-1a/b`
  (deep link, view), `P15-BUG-2` (load failure reported twice, states),
  `P15-BUG-3` (recovered load keeps the dead message, bloc), `P15-BUG-4`
  (stage-1 Pip reads "an Egg", copy), and `P15-BUG-5` (`NestListRow`
  ellipsises the three subtitles, theme/size — orchestrator item 1). The test
  stage's files were still changing while this document was written (an
  earlier snapshot also had two red icon/image-label accessibility proofs in
  `child_profile_theme_size_test.dart`, light + dark, since resolved by that
  stage's own edits); the counts above are a snapshot. Its `3_test.md` was
  not yet written when this snapshot was taken.
* **`5_ui.md`** measured every band within ±2 px (hero 47, stats 227, Pip 325,
  list 457, danger 653; no uniform shift) but FAILed on orchestrator item 1
  (subtitles ellipsised ~40–60 px early on all three rows) and deviations 2/3
  (plain check instead of circled check; `£` glyph instead of the coin
  illustration).
* **`SHARED_REQUEST.md`** already carries the two shared blockers: §1
  `NestListRow` starves the main column (`Flexible` trailing reserves half the
  row; the CSS is `.list-main { flex: 1 } .list-trail { flex-shrink: 0 }`) —
  orchestrator item 1 — and §2 the missing circled-check icon + coin
  illustration — orchestrator items 2/3. RULES §1 forbids the screen from
  editing `core/design_system/**`, so these are correctly requests, not
  screen fixes.
* **`ORCHESTRATOR_NOTES.md` (18:15) verification:** item 1 — still failing at
  this snapshot, proven by the test stage's `no list-row paragraph is
  ellipsised at 390` (RED) and `SHARED_REQUEST.md` §1; items 2/3 — still
  failing (plain `NestIcons.check`, `NestIcons.poundCoin`), assets requested in
  `SHARED_REQUEST.md` §2; item 4 — the pronoun "their" and the DB quest counts
  are **not** reported as findings anywhere in this document.

## Verified sound (adversarial probes on `586a9d2`, all green)

| Probe | Result |
|---|---|
| 0 children — `Seed.empty()` deep link | `No children yet` + copy + CTA → `/add-children` ✓ |
| Empty state at 320 × textScale 1.3 | no overflow exception ✓ |
| 1 child (after Maya's removal) | selection falls to Leo; screen, Pip and copy correct ✓ |
| 6 children, `active_child_id` = 6th | 6th child's profile renders, no exception ✓ |
| Long UK name (`Maximilian-Alexander`) + £999.99 owed + 9999 coins + 9999 Pip coins at 320 × 1.3 | no overflow; ellipsis holds; danger button wraps and grows ✓ |
| Empty quest/ledger lists | `0 active · 0 daily, 0 weekly`, `Owed £0.00`, `0 of 250 · 0%` ✓ |
| Rapid double tap on `Remove …` | one dialog only (second tap hits the barrier) ✓ |
| Confirm-remove double tap | idempotent `DELETE … WHERE id` — one removal ✓ |
| System back from `/kid-pin` push | returns to the profile with state intact ✓ |
| Restart (re-pump the app on the same DB) | removal persisted; Leo shown ✓ |
| Kid-mode deep link `/child-profile` | redirected to `/parental-gate` ✓ |
| Dark mode pump | renders, no exception; tokens only ✓ |
| Dialog buttons / empty CTA semantics | `SemanticsAction.tap` present; performAction drives the real effect ✓ |
| Delayed `removeChild` failure after `bloc.close()` | no unhandled emit-after-close error ✓ |
| Money rounding | `_owedPence` is an exact replica of P12 `summarise` (pence, payout-instant tie included); `moneyPounds` = 2 dp ✓ |
| Copy / fonts / letter spacing | U+2013/U+00B7/U+203A checked; no `google_fonts` in feature or tests; `NestType` letterSpacing 0 ✓ |
| Simulator policy | no simulator was booted, installed on, screenshotted or driven in this stage ✓ |

## Gates (run in `app/` on `586a9d2` + this stage's test file)

```
$ dart format test/features/family/p15_bugs_test.dart
Formatted 1 file (0 changed) in 0.01 seconds.

$ flutter analyze
No issues found! (ran in 7.4s)

$ flutter test --no-pub test/features/family/p15_bugs_test.dart
00:00 +0 ~6: All tests skipped.

$ flutter test --no-pub test/features/family        # snapshot ~18:47 BST
00:12 +215 ~6 -6: Some tests failed.
```

The six `~` are this stage's skipped proofs. The six `-6` are the **test
stage's un-skipped bug repros** (listed under "Parallel stages") — the open
bugs themselves, expected at iteration 1 and fixed by the next build; they
are not caused by this stage's file. `flutter analyze` is clean and this
stage added no red.

No production file was changed by this stage: the only additions are
`app/test/features/family/p15_bugs_test.dart` (all six proofs `skip:`-marked
with their bug ids) and this document.

VERDICT: FAIL
