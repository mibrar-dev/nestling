# P06 Pocket money setup — Stage 6 adversarial bug hunt (iteration 5)

Route `/pocket-money-setup` · feature `pocket_money` · parent mode · onboarding
(P05 → P06 → P07). `ORCHESTRATOR_NOTES.md` (including the 07:22 and 07:58
updates) is verified item by item below. No screen code was changed by this
stage — only `app/test/features/pocket_money/p06_bugs_test.dart` and this
report.

Suite state: `flutter test test/features/pocket_money/p06_bugs_test.dart` →
**+25 ~2: All tests passed!** The two skips are this iteration's new findings;
delete the skips to watch them fail:

```text
P06-BUG-11  Expected: a value greater than or equal to <60>   Actual: <34.0>
P06-BUG-12  Expected: '−' (U+2212)                            Actual: '-'
```

## Open bugs

### P06-BUG-11 (MAJOR) — the balanced H1 collapses to one ellipsized line

**Where:** `app/lib/features/pocket_money/presentation/views/pocket_money_setup_view.dart:143`
(`_SetupTitle` calls `NestBalancedText` with no `maxLines`) +
`app/lib/core/design_system/components/nest_balanced_text.dart:37-55` /
`:98-105` (defaults `overflow: TextOverflow.ellipsis`, passes `maxLines: null`).

**Repro / evidence (real bundled fonts, 390×844):**
- The H1 `RenderParagraph` is **350×34, `didExceedMaxLines = true`** — one line,
  ellipsized ("How does pocket money work in your hou…"), while the design
  (`design/screens/light/P06-pocket-money.png` ÷3) draws the H1 at
  **107–175 = two 34 px lines**.
- `NestBalancedText.lineCountFor` returns **1** for the H1 (it lays out with
  `ellipsis: '…'` and `maxLines: null`), so the component takes its
  `minLines <= 1` early-out and never balances.
- Minimal control probe (Flutter 3.47.5): the same text/style at width 200 —
  `overflow: clip, maxLines: null` → 136 tall (4 lines);
  `overflow: ellipsis, maxLines: null` → **34 tall (1 ellipsized line)**;
  `overflow: ellipsis, maxLines: 2` → 68 tall. Under this engine,
  `ellipsis + maxLines: null` collapses the paragraph instead of wrapping.
- Knock-on: the collapsed H1 is 34 px shorter, so the settings card sits at
  **381–651** instead of the design's **415–684** — every y in
  ORCHESTRATOR_NOTES (07:22) is 34 px high even though the card's internal
  gaps are now exactly right.

**Failing test:** `P06-BUG-11: the H1 must wrap to the design's two lines, not
one ellipsized line` (skipped; asserts paragraph height ≥ 60, no
`didExceedMaxLines`, card top 415 ± 1).

**Fix:** shared, per the orchestrator's 07:58 update: `shared/balanced_text_ellipsis`
fixes `NestBalancedText` on main (ellipsis must not collapse a null-`maxLines`
heading) and main is merged before the next build. Keep using
`NestBalancedText` on this screen and **do not work around it** (no local
`maxLines: 2`); after the merge the title must be two lines with the screen
back at the iteration-4 positions. P07 passes `maxLines: 3`
(`paywall_view.dart:411`) so it is unaffected — P06 is the only
null-`maxLines` caller today.

### P06-BUG-12 (minor, mandatory-note item) — stepper minus is a hyphen, not U+2212

**Where:** `app/lib/core/design_system/components/nest_stepper.dart:32`
(`label: '-'`, U+002D) used by `pocket_money_setup_view.dart:_BaseStepper`;
the design HTML (`P06-pocket-money.html:73`) uses `&minus;` (U+2212), a
full-width bar matching the `+` in weight and width.

**Repro:** on the screen, the Maya/Leo decrease buttons render `-`
(`codeUnits [45]`) next to a `+` (`[43]`) — visibly narrower and lighter than
the design's minus. ORCHESTRATOR_NOTES (07:22) explicitly asks for the same
glyph source for `−` and `+`; it is unaddressed by the iteration-5 build.

**Failing test:** `P06-BUG-12: the stepper minus must be the design's U+2212
(&minus;)` (skipped). The orchestrator's 07:58 update asks for "a test that the
minus button's glyph is not U+002D"; this asserts the stronger positive form
(`== '\u2212'`), which also fails on U+002D today.

**Fix:** shared — `NestStepper` should render `'\u2212'` (keeping the existing
semantics labels), or the screen needs a glyph override on `NestStepper`
(forking the component is not allowed). File a `SHARED_REQUEST` if the shared
change is not made in the next build.

## Earlier findings — all still green

The unskipped guards cover: P06-BUG-01/01b/01c (stepper accumulation),
02/02b (day guard), 03 (pill 32 px), 05 (inline write error),
06 (stale message), 07 (unknown child), 08 (day-row align), 09 (pending-day
confirmation), the iteration-4 note guards (seed `onboarding_kids`, chip rects
inside the 16 px inset at 390/320/430, `NestChipWrap` ±5 px and gap taps,
option-card 22/20 line heights, gold coin tile), and the attack holds
(kid-mode guard, restart persistence, 6 children at 320 × 1.3, £0.00/£20.00,
async gap, contrast).

## ORCHESTRATOR_NOTES (07:22) verification

| Target | Result |
|---|---|
| "Payout day" label y 524 (sheet) | app label box 397, card top 381 → **34 px high** (BUG-11 knock-on) |
| day-chip row centre +6 → 0 | **fixed inside the card**: label→pill 6.0, pill 32.0 |
| "Weekly base" +12 → 0 | **fixed**: pill→weekly 17.0 (8+1+8) |
| Maya/Leo/coin +12 → 0 | **fixed**: weekly→Maya 13.0, Maya→Leo 22.0, Leo→coin 39.0, card→bottom 23.0, card height **270.0** |
| real-font geometry test | added in `p06_bugs_test.dart` ("the payout card keeps the design's 270 height and gap chain", `FontLoader` like the P04 test); absolute-y pins tied to BUG-11 |
| stepper glyphs − (U+2212) like + | **not done** → P06-BUG-12 |
| FIXES_4 items | #1 (32 px row / card height) fixed; #3 (`NestBalancedText`) adopted but broke the wrap (BUG-11); #2/#4–#6, #9–#10, #12–#14 fixed by the build; #7/#8 parked on `SHARED_REQUEST.md`; #11 empty-state copy still needs orchestrator ratification (screen-authored `Add children to set weekly amounts.` renders only for `Seed.empty`/`Seed.fresh`) |

### UPDATE (07:58) rows

| Target | Result |
|---|---|
| #1 the title truncates to one line; shared fix lands on main, keep `NestBalancedText` | independently reproduced as **P06-BUG-11** (paragraph 350×34, `didExceedMaxLines`, card 34 px high); skipped failing test in place; no local workaround added |
| #2 minus glyph must not be U+002D; add a test | asserted `== U+2212` in **P06-BUG-12** (fails on `-` today) |
| #3 card targets measured from the two-line title's bottom: chip row centre 555, Weekly base 597, Maya 630, Leo 674, Coin value 735 (±1) | title-anchored guard added and green today (296 / 329 / 359 / 403 / 464 logical offsets, ±1); the absolute positions return once BUG-11's fix merges |

## Verdict rationale

The iteration-5 build fixed the card's internal vertical drift exactly, but the
mandated `NestBalancedText` adoption regressed the H1: under Flutter 3.47.5 the
component's `ellipsis` + `maxLines: null` lays the heading out as **one
truncated line** and drags the whole card 34 px above the design — a visible,
screen-level defect with a deterministic repro. The stepper minus glyph from
the same notes update is also still open. Two findings, one major, both with
skipped failing tests, so the stage fails.

VERDICT: FAIL
