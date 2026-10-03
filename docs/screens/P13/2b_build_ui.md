# 2b — Build, UI chunk (iteration 3) — P13 Payout

Iteration 2's UI-defect list (`FIXES_2.md`) is fully closed. No simulator,
no whole-app `flutter test`, no `flutter clean`, no `google_fonts`.

## Files changed (UI chunk only)

| File | Fix |
|---|---|
| `app/lib/features/pocket_money/presentation/views/payout_view.dart` | Summary text left-aligned at the card's 16-px padding edge (`textAlign: TextAlign.start`); drop the plan's "centered" assumption — 5_ui deviation 1. |
| `app/lib/features/pocket_money/presentation/widgets/payout_sheet.dart` | `PayoutSaveRow.label` gates the design string on the **exact seeded shape** (goal child `maya` AND goal title `Lego Friends set`); any other shape — a goal-bearing Leo with a Lego goal included — gets the neutral data-driven sentence, never the design's gendered "her Lego fund". P13-BUG-06 / P13-I2-01. |
| `app/test/features/pocket_money/payout_widget_geometry_test.dart` | +2 real-font pins: summary text is start-aligned at x ≈ 36, and the saverow toggle track is the design's 51×31 at (305, 633); also retires 5_ui deviation 2 on the current build (see below). |
| `app/test/features/pocket_money/payout_responsive_test.dart` | Toggle target assertions migrated to the current NestToggle contract (track 51×31 layout, 59×44 hit overhang asserted by tapAt at the 6 px outside the pill). |
| `app/test/features/pocket_money/p13_bugs_test.dart` | P13-BUG-06 reproducer un-skipped and green. |
| `app/test/features/pocket_money/p13_iter2_audit_test.dart` | P13-I2-01 reproducer un-skipped and green; header note updated. |

Gates: `flutter analyze lib/features/pocket_money test/features/pocket_money`
→ **No issues found**; `dart format --set-exit-if-changed` → 0 changed after
running it; `flutter test test/features/pocket_money` → **439 passed / 1
pre-existing P12 skip / 0 failed** (32 s). No `google_fonts`, no
`letterSpacing` additions, no `analysis_options` edits, no new `skip:`/`@`
ignores — every skip left is a reproducer for an unrelated screen's open
finding.

## FIXES_2.md — item by item

### From 5_ui.md

1. **Summary text centred (both themes)** — the design's `.caption` sets no
   `text-align`, so the design glyphs start at the card's padding edge
   (measured x 37). P13's `_DimmedLedger` summary `Text` now uses
   `textAlign: TextAlign.start` and drops the `NestCard` default, and the
   geometry test pins `textAlign` plus the left edge at 36 ± 1.5. `1_plan.md`
   §(a) wrongly said "centered"; the HTML/CSS overrides the plan.
2. **Toggle track 4 px left (both themes)** — NOT reproduced on the current
   build. The screenshot's 301–351 track belongs to build `bf9f239`, whose
   `NestToggle` laid out a `ConstrainedBox(minWidth: 59, minHeight: 44)`
   (`git show bf9f239:…/nest_toggle.dart`); the merge `87cf5d4` ("NestToggle
   51x31 + hit slop") moved it to `size = child.size` with the overhang in
   `hitTest`. Measured with real fonts via `FontLoader`: track rect
   **(305, 632.5, 356, 663.5)** — design is 305–355 @ y 633–663, i.e. correct,
   and the text is back on its 44-px line box. The new
   `'the saverow toggle track is flush with the card content edge'` geometry
   test pins `(305, 633)` with widths 51/31 so a future DS regression fails
   loudly in P13.

### From 3_test.md

- **P13-I2-01 / P13-BUG-06** (goal-title-keyed pronoun): fixed by gating the
  design string on the exact seeded shape (see the sheet table above). Both
  reproducers now run unskipped and are green, and they assert the negative
  (no ` her ` in the copy for Leo). The remaining tension — the design string
  cannot be said about a non-Maya goal child from the data — is a product
  decision and stays documented at `PayoutSaveRow.label`.

### From 3_test.md / 5_ui.md — suites

- **`recordPayout` guards** (P13-BUG-02): verified still working by the audit
  file (amount 0 / negative / clamp backstop / `goalId == null` / `0` with a
  move). No edits needed.
- **Submit guards** (P13-BUG-01/04/05): untouched this iteration; the audit
  file's same-frame double-tap and sibling tests still pass.
- **ORCHESTRATOR_NOTES items 1–3** (scrub, amounts, row text y): verified
  already pinned by the iteration-2 geometry test; the 5_ui side passed them
  ✓ at iteration 2. No regression.
- **`flutter test` whole repo** still carries the shared `family_time_test`
  wall-clock failure as SHARED_REQUEST #2 — not P13, noted in 3_test and the
  request, out of this stage's scope. P13's own suite is the one I gate on.

### Extra fix discovered this iteration (shared DS drift)

Main's `87cf5d4` reworked `NestToggle` to a 51×31 laid-out box with a 59×44
hit overhang (its semantic rect went from 59×44 to 51×31), which turned three
`payout_responsive_test.dart` assertions that expected the widget's rect to be
≥44 red. I migrated those three assertions to the current contract: the pill's
width is still ≥44 (asserted), its height is pinned to the design's 31, and
the 6 px overhang tap is checked functionally — `tester.tapAt(pill.top + 2)`
must still flip the toggle. That behaviour is the one the brief's "tap
target ≥ 44 parent, including a tap landing on the 6 px outside the 51×31
toggle pill" asks for. `NestDevice.tapParent` remains 44; no `Skip:`/ignore
added.

## Owner rules re-checked

- **Copy**: `P13SaveRow.label`'s design string is byte-identical to
  `P13-payout.html:29` on the seeded path (`Maya` + `Lego Friends set`); the
  fallback strings are clearly marked and only used for non-seeded shapes.
- **No hard-coded colours/sizes**: the summary `textAlign` is semantic;
  the label gate reads the database title/child id at the call site; no new
  numeric literals in product code.
- **Bottom edge / alignment / child order / PIP / trial**: untouched by
  this iteration's edits and still green in the suite.
- **Fonts / letter-spacing**: no `google_fonts` import or reference anywhere
  in the pocket_money feature; no `letterSpacing` call sites; the only
  `NestType.x().copyWith` usages are the iteration-2 documented cases.

## Contract with the logic builder

`2a_build_logic.md` (iteration 3) reports **no CONTRACT CHANGES** — no
event/state/repository edits this iteration. The UI layer codes against the
same BLoC/`MoneyLedgerData`/`MoneyChild` shapes as iteration 2.

## LEFT FOR NEXT ITERATION

- P13-I2-01's "tension is a product decision" branch stays open for an
  orchestrator answer: keep Maya-verbatim + neutral fallback, or make the
  saverow fully data-driven and diverge from the design copy on the seeded
  path. I implemented the former (seeded copy preserved, fallback for any
  other shape) because the design copy-check keeps the seeded path verbatim.
- Nothing in `1_plan.md` §(a)/`(b)`/`(c)` is outstanding; the earlier build
  files (`2_build.md`, iteration 1/2 notes) remain as history.

VERDICT: PASS