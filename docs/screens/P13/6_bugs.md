# P13 · Payout (parent) — Stage 6 bug hunt (iteration 3)

Route `/payout` (feature `pocket_money`), build `d5e3d82` ("P13: checkpoint
after build (iteration 3)"). Third pass: re-audit the iteration-3 fixes
(P13-BUG-06 / P13-I2-01, `5_ui` deviations 1–2) and sweep the changed code for
new defects.

Method: every reproducer re-run against the iteration-3 build; fresh probes
for the pronoun matrix (four data shapes), the toggle track and its hit
slop/semantics, the summary start-alignment at 390 and at a real 320 dp × 1.3
with four children and a long UK name; then the full feature suite. **No
simulator was used** (stage rule; only stage 5_ui may). No screen code was
edited (stage rule) — this stage touched only
`app/test/features/pocket_money/p13_bugs_test.dart` (+3 regression holds,
header) and this file.

Guards: `p13_bugs_test.dart` — **23 tests, all active (no skips)**. The five
iteration-1 reproducers and BUG-06 are all regression tests now; the only
skip left in the feature suite is the pre-existing `p12_bugs_test.dart:320`
(P12-BUG-04, shared `NestSegmented`).

**VERDICT: PASS — no open findings. All six P13 findings are fixed and
pinned by active tests.**

---

## Findings status

| # | Sev | Status | Verified by |
|---|---|---|---|
| P13-BUG-01 | major | **FIXED** (it 2) | active reproducer + same-frame/busy/partial-retry probes |
| P13-BUG-02 | major | **FIXED** (it 2) | active reproducer + 50p clamp and £0-riding-child probes |
| P13-BUG-03 | major | **FIXED** (it 2) | active reproducer + dark-scrim and scrim-semantics probes |
| P13-BUG-04 | minor | **FIXED** (it 2) | active reproducer + two-failures-then-success probe |
| P13-BUG-05 | minor | **FIXED** (it 2) | active reproducer (background absent from the semantics tree) |
| P13-BUG-06 | minor | **FIXED** (it 3) | active reproducer + the four-shape pronoun matrix below |
| P13-I2-01 | minor | **FIXED** (it 3) | the test stage's reproducer, unskipped (same fix as BUG-06) |
| `5_ui` deviation 1 | minor | **FIXED** (it 3) | summary `TextAlign.start`, left x 36 / design 37 |
| `5_ui` deviation 2 | minor | **FIXED** (it 3) | toggle track 51×31 at x 305–356 / design 305–355 |

## Iteration-3 fixes verified

### P13-BUG-06 / P13-I2-01 — the design copy's gendered "her" leaked (minor) — FIXED

**Fix.** `PayoutSaveRow.label` now renders the design string only for the
exact seeded shape — `childId == 'maya' && title == 'Lego Friends set'` — and
the neutral data-driven sentence
(`"Move £1.00 of {name}'s money to their {title} fund"`) for every other
combination. This closes the review-finding-7 loophole (`contains('lego')`)
that sent a goal-bearing Leo to "her Lego fund".

**Verification — four-shape probe, measured copy:**

| Child + goal | Rendered copy | Expected |
|---|---|---|
| Maya + `Lego Friends set` | `Move £1.00 of Maya's to her Lego fund` | design string verbatim (HTML `P13-payout.html:29`) |
| Maya + `Holiday` | `Move £1.00 of Maya's money to their Holiday fund` | neutral |
| Leo + `Lego Friends set` | `Move £1.00 of Leo's money to their Lego Friends set fund` | neutral (the BUG-06 shape) |
| Leo + `Bike` | `Move £1.00 of Leo's money to their Bike fund` | neutral |

Both reproducers are active regression tests: mine
(`P13-BUG-06: a goal-bearing Leo still gets the design copy with "her"`) and
the test stage's `P13-I2-01`. The seeded design copy is unchanged and still
asserted character-for-character.

### `5_ui` deviation 1 — the dimmed summary was centred — FIXED

`_DimmedLedger`'s summary `Text` now uses `textAlign: TextAlign.start` (the
design's `.caption` sets no `text-align`). Probe: glyph box left **x 36**
(card x 20 + `NestCard` padding 16; design glyph origin 37). At a real
320 dp × 1.3 with four children including "Maximilian-Alexander" the summary
wraps to its two allowed lines and ellipsizes — no overflow exception, still
left-anchored at x 36. The real-font geometry test pins `TextAlign.start` and
`left ≈ 36 ± 1.5`.

### `5_ui` deviation 2 — the toggle track sat 4 px left — FIXED

Main's shared `NestToggle` now lays the 51×31 track out as the widget's box
and overhangs the 59×45 tap area as pure hit slop (no layout shift). Probe:
track `Rect(305, ·, 356, ·)`, size 51×31 — right-flush with the saverow's
content edge (design 305–355). The geometry test pins the same rect, and the
toggle's semantics are unchanged: `toggled` state present, `SemanticsAction.tap`
exposed, `performAction(tap)` flips the real value (a11y rule). A tap 6 px
right of the pill (2 px beyond the design's 4 px slop) is correctly a no-op;
taps inside the slop flip it.

### ORCHESTRATOR_NOTES items 1–3 — still fixed

- **Scrim**: full-screen `(0,0,390,844)` in light and dark; a tap at
  (195, 60) dismisses to `/money`; the scrim's `'Close payout'` node carries a
  real tap action and `performAction` works. Pinned by the geometry test.
- **Amounts**: the amount is the inline 13 px w700 ink-2 span after
  `Weekly + quests · ` (`.money` on the `.caption` line), row height 76 —
  pinned with real fonts.
- **Row text y**: name top 458 / subtitle 480 (±1), Leo 544 / 566 — pinned
  with bundled fonts.

## Fresh adversarial probes — no new findings

- **Pronoun matrix** (above): all four shapes correct; no pronoun leaks.
- **Summary** at 390 and real 320×1.3 (4 children, "Maximilian-Alexander"):
  start-aligned, two-line ellipsis, no overflow.
- **Toggle**: track geometry, hit slop, semantics state and `performAction`
  all correct; saverow stays the design 72 px with bundled fonts.
- **Rename caveat closed**: the `childId == 'maya'` gate could only be
  defeated by renaming the seeded child, and the only nickname writer
  (`FamilyRepository.updateChild`) has **no UI caller** in this build — not
  reachable.
- **Regression set**: the 23 active guards (double taps, £0-riding child,
  320×1.3 / 320×568, six children, £0.00, deep links, kid-mode guard,
  back-mid-write, restart persistence, contrast, integer-pence maths) all
  pass. Money/rounding/timezone surfaces are unchanged by iteration 3.

## Cross-stage note (not a P13 finding)

The whole-repo `flutter test` is still red on shared
`test/core/family_time_test.dart` ("Bad state: Too many elements", the Dubai
day-rollover trigger after 20:00 UTC) — already filed as SHARED_REQUEST #2.
It is core/test code: P13 writes only `ledgerEntries` (`payout`,
`savings_move`) and bumps the savings goal, never `questCompletions`.

## Hand-off state

- `dart format` clean; `flutter analyze` → **No issues found!**
- `flutter test test/features/pocket_money` → **461 passed / 1 skipped /
  0 failed** (the single skip is the pre-existing P12-BUG-04, not P13).
- `p13_bugs_test.dart`: **23 active tests, zero skips**. No open P13
  findings; nothing left to unskip on this screen.

VERDICT: PASS
