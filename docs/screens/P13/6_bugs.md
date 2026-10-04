# P13 · Payout (parent) — Stage 6 bug hunt (iteration 4)

Route `/payout` (feature `pocket_money`), build `ad85ec5` ("P13: checkpoint
after build (iteration 4)"). Focus: audit the orchestrator's copy mandate
(ORCHESTRATOR_NOTES, 23:25) and sweep the changed saverow path for new
defects.

Method: the four-shape/edge copy probes re-run against the new build, the
seeded and long-title strings measured on the rendered widget, a real
320×844 × 1.3 stress with a long goal title, the full feature suite, and the
whole-repo gate. **No simulator was used** (stage rule; only stage 5_ui may).
No screen code was edited (stage rule) — this stage changed only
`app/test/features/pocket_money/p13_bugs_test.dart` (header) and this file.

Guards: `p13_bugs_test.dart` — **23 tests, all active (no skips)**. The only
skip anywhere in the feature suite is the pre-existing
`p12_bugs_test.dart:320` (P12-BUG-04, shared `NestSegmented`).

**VERDICT: PASS — no open findings.**

---

## Findings status

| # | Sev | Status | Verified by |
|---|---|---|---|
| P13-BUG-01 | major | **FIXED** (it 2) | active reproducer + same-frame/busy/partial-retry probes |
| P13-BUG-02 | major | **FIXED** (it 2) | active reproducer + 50p clamp and £0-riding-child probes |
| P13-BUG-03 | major | **FIXED** (it 2) | active reproducer + dark-scrim and scrim-semantics probes |
| P13-BUG-04 | minor | **FIXED** (it 2) | active reproducer + two-failures-then-success probe |
| P13-BUG-05 | minor | **FIXED** (it 2) | active reproducer |
| P13-BUG-06 / P13-I2-01 | minor | **FIXED** (it 3 → mandated it 4) | active reproducer + copy probes below |

## Orchestrator copy mandate (23:25) — implemented and verified

The mandate: **no seed ids in product code**; one ungendered, data-driven
sentence for every goal-bearing child; the design's "her Lego fund" is
intentionally **not** used (so it is not a finding).

**Implementation.** `PayoutSaveRow.label(name, goalTitle)` lost the
`childId` parameter and the `childId == 'maya' && title == 'Lego Friends set'`
branch entirely. It now renders:

- with a goal: `Move £1.00 of {name}'s to their {goal title} fund`
- without one (hand-built fixtures only — the row is hidden when no goal
  exists): `Move £1.00 of {name}'s money to savings`

**Measured copy (rendered widget):**

| Shape | Rendered copy | Required |
|---|---|---|
| Seed (`Maya`, `Lego Friends set`) | `Move £1.00 of Maya's to their Lego Friends set fund` | mandate ✅ |
| Long title, real 320×844 @ 1.3 (`Lego Star Wars Galactic Empire Imperial Ship`) | `Move £1.00 of Maya's to their Lego Star Wars Galactic Empire Imperial Ship fund` | mandate ✅, no overflow, CTA scrolls and posts, route ends on `/money` |
| Goal-bearing Leo (the BUG-06 shape) | no ` her ` / no seed-id gate | active regression test ✅ |

`grep` confirms no `childId == 'maya'` branch and no design pronoun on any
product path (only history comments mention the old string). The copy tests
were updated to the mandated sentence (`payout_view_test.dart`'s
`kSaveCopy`, the audit files, and this file's two expectations); all pass.

## Fresh probes (iteration 4) — all hold

- Seeded saverow string is byte-exact to the mandate and shows the goal title
  verbatim.
- The longer string at a real 320 dp × 1.3 with a very long goal title:
  wraps in the sheet, no overflow exception, CTA reachable/scrollable and
  operable, pops to `/money`.
- Real-font geometry unchanged: saverow 350×72 at y 612, toggle track 51×31
  at x 305–356 (pinned by the geometry test; the suite is green).
- Every iteration-1/2/3 regression guard still passes: double taps, £0-riding
  child, six children at 320×1.3, 320×568, £0.00, single child, deep links,
  kid-mode guard, back mid-write, restart persistence, contrast,
  integer-pence maths.
- No new finding in the changed code.

## Cross-stage note (whole-repo reds — none in P13)

- `test/core/family_time_test.dart` › *kid_home completions are stamped with
  the family zone*: the known date-dependent shared red (orchestrator 23:55,
  fix in flight via `shared/family_time_test_fix`).
- The clean whole-repo run is **2522 passed / 1 skipped / 35 failed**, and
  **zero of the failures are in `pocket_money`** (verified by filtering the
  failing-test paths). The failures are in other features/shared
  (`approvals` ×4, `kid_home` ×6, `onboarding`, …) — other screens' loops and
  the orchestrator own those. P13 writes only `ledgerEntries` (`payout`,
  `savings_move`) and the savings goal; none of its files are on those paths.
- Earlier in this stage one `_probe4_p13_test.dart` "loading" entry appeared
  in a whole-repo run because this stage deleted its own temporary probe
  while that run was compiling — a process artifact, not a screen defect; the
  probe is gone and the clean re-run has no P13 failure.

## Hand-off state

- `dart format` clean; `flutter analyze` → **No issues found!**
- `flutter test test/features/pocket_money` → **461 passed / 1 skipped /
  0 failed** (the single skip is the pre-existing P12-BUG-04, not P13).
- `flutter test` (whole repo) → **2522 passed / 1 skipped / 35 failed**;
  **no `pocket_money` test is among the failures** (see the cross-stage note).
- `p13_bugs_test.dart`: **23 active tests, zero skips**.
- No open P13 findings; no scratch files left from this stage. The only open
  items are the two shared requests (`family_time_test` fix in flight;
  `pumpAppRoute` surface-size convenience, non-blocking).

VERDICT: PASS
