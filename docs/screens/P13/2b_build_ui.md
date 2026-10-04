# 2b — Build, UI chunk (iteration 4) — P13 Payout

Iteration 4's only P13 change is the orchestrator's 23:25 copy mandate
(alongside an already-green iteration-3 suite + the shared
`family_time_test.dart` wall-clock failure, SHARED_REQUEST #2 — not P13).

## Orchestrator mandate (23:25) — done

`PayoutSaveRow.label` no longer branches on seed ids or on any title pattern.
There is ONE data-driven, ungendered sentence for every goal-bearing child:

- with a goal: `"Move $£1.00 of $name's to their $goalTitle fund"`
  - seeded shape: `Move £1.00 of Maya's to their Lego Friends set fund`
  - a goal-bearing Leo renders `Move £1.00 of Leo's to their Lego City fund`
- without a goal (or whitespace title): `Move £1.00 of $name's money to
  savings`

The seeded design's `… to her Lego fund` appears nowhere at runtime now; it
is referenced only as documentation. Product code never branches on
`childId == 'maya'` again; the gate is deleted, not relocated.

## Files changed

| File | Change |
|---|---|
| `payout_sheet.dart` | `PayoutSaveRow.label` rewritten to the mandate; `childId` param dropped; docs updated. Row geometry kept; the sentence wraps like the design, toggle stays at its rect. |
| `payout_view_test.dart` | `kSaveCopy` updated to the mandated sentence; DB-goal scoop test expects `… to their Bike fund`. |
| `payout_responsive_test.dart` | `kSaveCopy` updated. |
| `payout_widget_geometry_test.dart` | Saverow row card owner string updated to the mandated sentence. |
| `p13_bugs_test.dart` | BUG-06 expectations still pass (no `' to her'`); `Holiday` goal string now the mandated form; reason comments rewritten. |
| `p13_iter2_audit_test.dart` | Seeded-path and non-Lego goal tests now expect the single mandated sentence with the goal title verbatim; P13-I2-01 expects `Move £1.00 of Leo's to their Lego City fund`; `skip: false` kept. |
| `p13_iter3_audit_test.dart` | Group A rewritten as the ungendered matrix: every shape yields the mandated sentence, zero shape may produce ` her ` (was "exactly one may"); group B now pins the mandated seeded copy and asserts the design's ` her ` string is nowhere; header comments updated. |

## Tests

`flutter test test/features/pocket_money` → **461 passed / 1 skipped /
0 failed**. The only skip remains the pre-existing P12-BUG-04 one.
`flutter analyze lib/features/pocket_money test/features/pocket_money` →
**No issues found**. `dart format` → 0 changed after running it.

## Owner rules re-checked

- **Copy**: the mandated sentence is the only runtime wording for the
  saverow at any shape; `£1.00` stays the design-fixed amount; ASCII 0x27
  apostrophes in all interpolated copy. The seeded design PNG still shows
  `… to her Lego fund` — an intentional, documented divergence (23:25
  mandate); the 5_ui bitlamp will show it as a copy diff, not a layout one.
- **DATA OVER MOCKS**: `$goalTitle` is interpolated straight from the
  database row; a hand-built fixture with any title renders that title.
- **Geometry**: saverow card stays (20, 612, 370, 684) and the toggle track
  stays 51×31 at (305, 633) — pinned by the iteration-3 geometry tests, all
  still green (the longer sentence still wraps to two lines).
- **No seed-id branches in product code**: `label()` has no access to the
  child object, only to the name + goal title strings.
- **FONTS / LETTER SPACING / BOTTOM EDGE / CHILD ORDER / PIP / BALANCED
  HEADINGS / NestChipWrap / TRIAL / PERIODS**: untouched; nothing added.

## Contract with the logic builder

`2a_build_logic.md` iteration 4: `CONTRACT CHANGES: None`. No
event/state/repo shape changed.

## From FIXES_3.md — disposition

- **`2_build` FAIL**: already analysed as not-my-scope —
  `test/core/family_time_test.dart:319` is shared `core` + wall-clock;
  SHARED_REQUEST #2 covers it and stays open. Everything P13-owned is PASS.
- **`3_test` iteration 3**: P13's suite was green (461) with no P13 bugs;
  its review of iteration 3's `label()` gate left a documented product
  smell — which iteration 4 has now resolved per the orchestrator's ruling.

## LEFT FOR NEXT ITERATION

- Design PNG still documents `… to her Lego fund`; the 5_ui comparison will
  flag that span. The owner rule is explicit — product code never follows the
  design's pronoun, so iteration 4's app intentionally differs by mandate.
  Recommend updating `P13-payout.html` copy to the ungendered sentence on the
  next design pass so the diff returns to zero.
- Nothing in plan §(a)/(b)/(c) remains open for P13's UI layer.

VERDICT: PASS