# P15 · Child profile — Stage 2 INTEGRATE (iteration 4)

Route `/child-profile` · parent mode · feature `family` · light+dark designs.
Inputs re-read: `docs/screens/RULES.md`, `docs/ARCHITECTURE.md`,
`docs/DESIGN_SPEC.md` §5 P15, `docs/design/SPACING_SPEC.md`, `1_plan.md`,
`ORCHESTRATOR_NOTES.md` (exists — 4 mandatory items, unchanged), `FIXES_3.md`,
`SHARED_REQUEST.md`, `2a_build_logic.md`, `2b_build_ui.md`.
No simulator was booted, installed on, driven or screenshotted (stage 2 must not).

## Outcome in one line

**P15 is complete and green (family 281/281, format clean, analyze clean). The
full-suite gate is still red on the same shared/core test as iteration 3, which
`main` still has not fixed — so this stage cannot PASS. Second iteration on the
same blocker; escalated in `SHARED_REQUEST.md` §6 with a verified patch.**

## Summary of 2a (logic) + 2b (UI)

`FIXES_3.md` was a short list and the split held cleanly. **CONTRACT CHANGES:
none** from both halves again — nothing to reconcile, no state/event mismatch,
no renamed member, no import to rewire.

**2a — logic**: deliberately **zero code changes**. It triaged every `FIXES_3`
item and confirmed items 1–5 were already closed, re-verified the
`child_profile_selection_test.dart` expectation as correct (2 is right at +1 day
under PERIODS — London week Mon 29 Sep–Sun 4 Oct), confirmed §6 is already
filed, and triaged the one new bug to the UI layer. Its honest report:
`test/features/family/` → 280 pass, **1 fail**, solely the BUG-10 view proof in
the UI builder's own file.

**2b — UI**: closed **P15-BUG-10** (minor) — the iteration-3 BUG-9 fix called
`GoRouterState.of(context)` in `didChangeDependencies`, which *asserts* when no
router is above the context, so `ChildProfileView` threw
`GoError: There is no GoRouterState above the current context` in any bare
`MaterialApp` pump (widget test, preview harness, design gallery). Fixed with
the two-line guard `if (GoRouter.maybeOf(context) == null) return;` before the
`GoRouterState.of` read — off-router mounts build unharmed, and because
`GoRouterState.of` is the dependency that re-fires on a live location change,
BUG-9's live re-selection keeps working. The BUG-10 proof was kept as the repro
(it wraps a bare `MaterialApp` in `NestTheme.light()`, since `context.nest` is
the one thing a route-less mount legitimately still needs).

## Mandatory ORCHESTRATOR_NOTES items — still satisfied

Items 1–2 intact in code (verified, not taken on trust): `ProfileRow` keeps the
trailing outside the flex distribution so all three subtitles render in full;
Quests uses `NestIcons.quests`, Pocket money the coloured `coin.svg` via a bare
`SvgPicture`. Items 3 ("their") and 4 (DB quest counts) remain deliberate
orchestrator rulings, not findings.

## FIXES

| # | Item | Where | Done |
|---|---|---|---|
| 1 | Contract reconciliation between the halves | — | none needed — both reported CONTRACT CHANGES: none |
| 2 | Compile errors / import breaks | — | none |
| 3 | Placeholder anchors from iteration 1 (`add_children_test.dart` ×4, `today_view_test.dart` ×1) | — | verified still green |
| 4 | No `skip:` hiding P15 proofs | 2a/2b | confirmed — `grep -rn "skip" test/features/family/` returns only prose |
| 5 | `child_profile_selection_test.dart` clock expectation | — | verified correct upstream; ran it green, no change |
| 6 | **P15-BUG-10** — `GoError` on a router-less `ChildProfileView` mount | `child_profile_view.dart` | **done by 2b** (`GoRouter.maybeOf` guard); repro kept as the proof |
| 7 | **`test/core/family_time_test.dart` › *kid_home completions are stamped with the family zone* → `Bad state: Too many elements`** | shared core, **not editable by P15 (RULES §1)** | **left — 2nd iteration; `SHARED_REQUEST.md` §6 escalated** |

### On #7 — still un-actioned, and now fully diagnosed

Checked again this iteration, from the other direction:
`git diff $(git merge-base main HEAD) main -- app/test/core/family_time_test.dart`
is **empty** — `main` has not touched that file since our merge base (its last
commit is still `eed280d`), so the red is not waiting on a merge and no amount
of re-merging will clear it.

I did not assume the iteration-3 root cause; I **probed it** with a throwaway
test replicating the test's exact sequence (then deleted it):

```
q-plants repeatRule = daily
seeded rows  = 1  to_do        2026-10-03T07:00:00Z  Europe/London
leg1 q-reading (London)      rows = 1  Europe/London
leg2 q-plants  (after move)  rows = 2  -> .single THROWS
   [ to_do       Europe/London 2026-10-03T07:00:00Z,
     done_pending Asia/Dubai  2026-10-03T23:59:54Z ]
```

The seed's row is London-stamped 07:00Z on the 3rd; once the family zone moves
to Dubai (UTC+4) and the wall clock is past ~20:00Z, Dubai's "today" is already
the 4th, so `countsForCurrentPeriod('daily', …)` is false, `inPeriod` is empty,
and `completeQuest` takes its **insert** branch instead of flipping in place.

Two consequences worth the maintainer's attention, both now in §6:

- **The test is wall-clock flaky, not deterministically broken.** It passes when
  the suite runs early in the UTC day and fails in the evening. Re-running to
  see it go green is not a fix, and CI timing will make it look intermittent.
- **The behaviour under test is correct** — the row `completeQuest` just wrote
  really is stamped `Asia/Dubai`, which is precisely what the test wants to
  prove. Only the row-*selection* assumption (`.single`) is stale. So the fix
  must not loosen the zone expectation.

I also verified the proposed fix on both legs: ordering by `createdAt`
descending and asserting on `first` returns `Asia/Dubai` for the Dubai leg and
`Europe/London` for the London leg, so both existing expectations survive. §6
now carries a ready-to-apply diff, plus an optional shared follow-up
(`completeQuest` hardcodes `DateTime.now().toUtc()`, so no test can pin the
instant it stamps — the same injectable-clock seam P15-BUG-8 gave
`FamilyRepositoryImpl`).

## Verification (run in `app/`, no simulator)

```
$ dart format .
Formatted 496 files (0 changed) in 1.37 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.2s)

$ flutter test
01:07 +2562 ~1 -1: Some tests failed.
Failing tests:
  app/test/core/family_time_test.dart: seed + repository zone plumbing
      kid_home completions are stamped with the family zone

$ flutter test test/features/family
00:08 +281: All tests passed!

$ flutter test test/core/family_time_test.dart      # re-checked after the date rolled
01:00 +21 -1: Some tests failed.   (same single test)
```

Format clean. Analyze clean. Full suite **2562 pass / 1 skip / 1 fail** — skip
is `p12_bugs_test.dart:320` (pre-existing, `pocket_money`), fail is the core
test above. **P15's own feature suite is 281/281**, including the BUG-10 proof.
No test was skipped, deleted, reworded or weakened; no `analysis_options.yaml`
change; no `google_fonts`. The probe file was deleted and the tree re-verified
clean (format/analyze) afterwards. No source change was needed this stage.

## Left for the next stage

1. **Escalation — `SHARED_REQUEST.md` §6, now iteration 2 un-actioned.** This
   is the only thing between P15 and a green full-suite gate, and it is not fix-
   able from this worktree. It needs a shared edit on `main`; §6 has a verified
   diff ready to apply. Nothing else is outstanding from 2a or 2b.
2. **UI stage (5_ui)** — iteration 3's `5_ui` already PASSed with band geometry
   within ±2 px, and 2b reports no visual delta this iteration (the change
   surface was router-less mount robustness only). Re-shoot is cheap insurance:
   `/child-profile` light + dark on udid `E7D5555E-378A-49DF-AAEE-16677AF4B9DB`,
   `compare.py` against both design PNGs, reporting measured y for the title,
   the first control and each card top.
3. `child_profile_row.dart` stays until `SHARED_REQUEST.md` §1 lands on
   `main`; then delete it and return to `NestListRow` (plus §2b's
   `leadingWidget` for the coin illustration). Open shared asks: §1 (row flex),
   §2b (`leadingWidget`), §3 (`NestPip.rowSlot = 84`), §5 (roster-order query),
   §6 (blocking, above).

VERDICT: FAIL
