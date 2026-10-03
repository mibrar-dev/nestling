# P15 · Child profile — Stage 2 INTEGRATE (iteration 3)

Route `/child-profile` · parent mode · feature `family` · light+dark designs.
Inputs re-read: `docs/screens/RULES.md`, `docs/ARCHITECTURE.md`,
`docs/DESIGN_SPEC.md` §5 P15, `docs/design/SPACING_SPEC.md`, `1_plan.md`,
`ORCHESTRATOR_NOTES.md` (exists — all 4 items mandatory, unchanged since 18:13),
`FIXES_1.md`, `FIXES_2.md`, `SHARED_REQUEST.md`, `2a_build_logic.md`,
`2b_build_ui.md`.
`main` was merged before this stage (`b2a8b8f`); the uncommitted tree and the
merge order are loop bookkeeping, not findings.
No simulator was booted, installed on, driven or screenshotted (stage 2 must not).

## Outcome in one line

**P15's own work is complete and green (272/272, analyze clean, format clean),
but the full-suite gate fails on a pre-existing shared/core test that P15 may
not edit — so this stage cannot PASS. Filed as `SHARED_REQUEST.md` §6.**

## Summary of 2a (logic) + 2b (UI)

Again a clean parallel split, and again **CONTRACT CHANGES: none** from both
halves — so there was nothing to reconcile, no mismatched state/event, no
renamed member, no import to rewire. 2a's closing line is "Nothing in the logic
layer is unfinished".

**2a — logic** (`bloc/`, `data/`, `family_routes.dart`):

- **P15-BUG-9 (major)**: a *second* `?childId=` was ignored on the live branch
  page. `BlocProvider.create` runs once per provider element and go_router keys
  the page by matched path, so a later `/child-profile?childId=…` re-rendered
  the page without re-running it. 2a added a private stateful
  `_ChildProfileRoute` wrapper that re-dispatches `FamilyChildSelected` in
  `didUpdateWidget` when the query id changes; the create-time dispatch stays
  so first entry is still selection-before-load. Both skipped proofs
  (BUG-9a/9b) un-skipped and green.
- **Review 3 (minor)**: `watchProfile` could double-subscribe the ledger when a
  multi-table transaction emitted several base events in one `await`. The
  handler now claims the slot synchronously and only the newest run may
  (re)subscribe — an older run can no longer orphan a listener.
- **Review 4/5/8 (minor)**: repoint query cites the shared roster ordering;
  new `SHARED_REQUEST.md` §5 asks for a one-shot
  `childrenInCreationOrder(familyId)`; the two P15 `debugPrint` lines are
  `kDebugMode`-gated; §2 wording refreshed.
- Un-skipped the last `p15_bugs_test.dart` markers.

**2b — UI** (`views/`, `widgets/`, `child_profile_view_test.dart`):

- **P15-BUG-9 (major, view half)**: `ChildProfileView` is now stateful and
  re-dispatches on the router state via `didChangeDependencies` — the same
  mechanism 2a put in the route wrapper, one layer lower, on the widget that
  actually reads the route. Both halves agree; the proofs are green.
- **Cross-feature import removed** (minor): `child_profile_copy.dart` no longer
  imports `moneyPounds` from `pocket_money/presentation/`, which broke the
  per-feature boundary (`ARCHITECTURE.md:75`). It now uses the design-system
  barrel's `formatPounds`; rendered copy (`£3.00 a week · Owed £4.20`) is
  unchanged.
- `ProfileRow` bare geometry (`12/10/16/10`, `40`) → `NestSpacing` tokens.
- `SHARED_REQUEST.md` numbering corrected; §2 corrected to the code's actual
  `leading: (fg) => …` builder form.

## Mandatory ORCHESTRATOR_NOTES items — still satisfied

Both items 2b fixed in iteration 2 are intact (verified in the code, not just
the notes): item 1 — `ProfileRow` keeps the trail outside the flex distribution
so subtitles render in full; item 2 — Quests uses `NestIcons.quests`,
Pocket money the coloured `coin.svg` via a bare `SvgPicture`. Items 3 ("their")
and 4 (DB quest counts) remain deliberate orchestrator rulings, not findings.

## FIXES

| # | Item | Where | Done |
|---|---|---|---|
| 1 | Contract reconciliation between the halves | — | none needed — both reported CONTRACT CHANGES: none |
| 2 | Compile errors / import breaks | — | none |
| 3 | Placeholder-anchor fixes from iteration 1 (`add_children_test.dart` ×4, `today_view_test.dart` ×1) | — | verified still green; `today_view_test.dart` swap recorded in `SHARED_REQUEST.md` §4 for ratification |
| 4 | `p15_bugs_test.dart` skips hiding proofs | 2a | done — every P15 skip removed; `grep -rn "skip" test/features/family/` returns only comments |
| 5 | 2b's hand-back: `child_profile_selection_test.dart` *"an explicit clock decides which period counts"* — 2b believed the expectation was wrong (would need `2` at +1 day, `0` at +8 days) and left it "for the test stage" | `app/test/features/family/child_profile_selection_test.dart:286` | **verified — already correct and green, no change needed** |
| 6 | **`test/core/family_time_test.dart` › *kid_home completions are stamped with the family zone* → `Bad state: Too many elements`** | shared core, **not editable by P15 (RULES §1)** | **left — filed `SHARED_REQUEST.md` §6** |

On #5: the test asserts `4` at the Sat 3 Oct anchor, `2` at +1 day (Sun 4 Oct)
and `0` at +2 days (Mon 5 Oct). That is exactly right under the PERIODS ruling
— the London week runs Mon 29 Sep–Sun 4 Oct, so Sunday's two dailies drop out
while the two weeklies still count, and Monday opens a new week. Ran it by name:
`00:01 +1: All tests passed!` 2b's flag came from the review's stale note, not
from a live red, so nothing was changed.

## The one blocking failure — detail

```
test/core/family_time_test.dart:319
  seed + repository zone plumbing › kid_home completions are stamped with the family zone
  Bad state: Too many elements
```

**It is not a P15 regression and not caused by this merge.** Proof:

- `git diff main HEAD -- app/test/core/family_time_test.dart app/lib/core/data/seed.dart`
  → **empty**. Both files are byte-identical to `main`.
- `git diff --name-only main...HEAD` → this branch touches **no**
  `lib/core/**` and **no** `test/core/**` file. Every changed file is under
  `app/lib/features/family/**`, `app/test/features/family/**`, the one
  recorded `today_view_test.dart` anchor, or `docs/screens/P15/**`.

Cause: the shared demo seed now pre-creates a `to_do` completion row for
`q-plants` (`seed.dart:392`), which this test predates. It then calls
`completeQuest('leo','q-plants')` and asserts `leoRows.single`;
`completeQuest` *flips* an in-period `to_do` row in place but *inserts* a new
one when `inPeriod` is empty, and after `Seed.movedToDubai` the seeded row no
longer satisfies `countsForCurrentPeriod(...)` under `Asia/Dubai` — so two
rows exist. The London leg (`q-reading`) still flips in place and passes,
which is why only the Dubai leg is red.

I did **not** edit it: `app/test/core/**` is shared (RULES §1) and the fix
belongs on `main`, where every other screen loop is hitting the same red. The
full diagnosis and a concrete one-line-intent fix are in
`SHARED_REQUEST.md` §6.

## Verification (run in `app/`, no simulator)

```
$ dart format .
Formatted 496 files (0 changed) in 2.09 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 4.5s)

$ flutter test
03:22 +2553 ~1 -1: Some tests failed.
Failing tests:
  app/test/core/family_time_test.dart: seed + repository zone plumbing
      kid_home completions are stamped with the family zone

$ flutter test test/features/family
00:39 +272: All tests passed!
```

Format clean. Analyze clean. Full suite **2553 pass / 1 skip / 1 fail** — the
skip is `p12_bugs_test.dart:320` (feature `pocket_money`, pre-existing,
unrelated), the fail is the core test above. **P15's own feature suite is
272/272.** No test was skipped, deleted, reworded or weakened to reach this
point; no `analysis_options.yaml` change; no `google_fonts` anywhere. Nothing
in this stage was edited except this note and `SHARED_REQUEST.md` §6 — I made
**no source change**, because there was no P15 breakage to fix.

## Left for the next stage

1. **Unblock `main`** — `SHARED_REQUEST.md` §6 needs the shared fix in
   `test/core/family_time_test.dart`. Until then the full-suite gate stays red
   for every screen loop, and P15 must not attempt the edit itself. Nothing
   else is outstanding from 2a or 2b.
2. **UI stage (5_ui)** — re-shoot `/child-profile` light + dark on udid
   `E7D5555E-378A-49DF-AAEE-16677AF4B9DB`, `compare.py` against
   `design/screens/{light,dark}/P15-child-profile.png`. Band geometry is
   unchanged (hero 47/164, stats 227/82, Pip 325/116, list 457/180, danger
   653/80), whose iteration-2 `5_ui` measured every edge within ±2 px. Per the
   UI VERDICT RULE, report measured y for the title, the first control and
   each card top, design vs app. The one new thing to confirm: switching a
   child via `?childId=` (the BUG-9 fix) re-renders the body **without any
   vertical shift**.
3. `child_profile_row.dart` stays until `SHARED_REQUEST.md` §1 lands on
   `main`; then delete it and return to `NestListRow` (plus §2b's
   `leadingWidget` for the coin illustration). Open shared asks: §1 (row flex),
   §2b (`leadingWidget`), §3 (`NestPip.rowSlot = 84`), §5 (roster-order query),
   §6 (blocking, above).

VERDICT: FAIL
