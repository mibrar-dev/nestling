# P03 Create account — test notes (Stage 3, iteration 7)

Route `/create-account` · feature `auth` · parent mode. Tests live in
`app/test/features/auth/`; the in-memory Drift DB comes from
`setUpTestScope()` (`Seed.demo` / `Seed.empty` / `Seed.fresh`) and every test
that pumps the app ends with `disposeApp(tester)` (RULES §7). No `lib/` file
was touched by this stage.

## Verdict

**One finding is open**: P03-BUG-24 — the headline ignores the BALANCED
HEADINGS rule. The design's `.h1` sets `text-wrap: balance`
(`components.css:29`) and the HTML is `<h1 class="h1">`
(`P03-create-account.html:36`), so the rule requires `NestBalancedText`; P03
still renders a plain `Text` inside a hand-calibrated
`ConstrainedBox(maxWidth: 240)`, which is exactly the pattern the rule
replaces. It is **not** a pixel defect — the cap already reproduces the
design's break — so this stage returns FAIL for rule compliance, not for a
wrong frame.

While proving the migration feasible I found a **shared-component defect** that
blocks it: with `maxLines` set, `NestBalancedText` collapses to a 0.1 dp box
at text scale 1.3 and renders one glyph per line. Filed as
`SHARED_REQUEST.md` §10 with measurements; P03's own guard for it is green
today and turns red if the migration lands before the shared fix.

Everything else is green: **166 passed, 1 failed, 0 skipped** in the feature
suite; `flutter analyze` → `No issues found!`.

## What iteration 7 closed

- **P03-BUG-23 (MINOR) — fixed.** The build gave `_OrRow`'s label the
  design's own line box (`_orLabelLineBox = 15.7`, derived from the caption
  token's own metrics). Both proofs are green again: the font-independent one
  (`P03-BUG-23 the form block starts at the design band`) and the
  design-fonts one (`the form bands are the design's`). With the design's
  fonts loaded, the email field's top is 443.00 and the password field's
  535.00 — the design PNG's exact bands.
- **P03-BUG-16 / 22 / 17** stay green (danger border in the raster, the
  overhang gate, the design's subtitle break with the bundled fonts).
- **The skip is gone.** The bug-hunt stage left `P03-BUG-24` in
  `p03_bugs_test.dart` marked `skip: true`. A skipped proof is not evidence and
  skipping tests is forbidden, so Stage 3 removed the marker and extended the
  proof (it now also pins `textAlign: TextAlign.left` and the painted gutter,
  not just the widget type). It is the suite's only red.

## Orchestrator note for iteration 8 — one conflict to arbitrate

`ORCHESTRATOR_NOTES.md`'s new UPDATE asks the build to render the h1 with
`NestBalancedText` **and delete the hand-made `maxWidth` constant**, with the
acceptance criterion "the lines must still match the design bands exactly —
L1/L2 tops 112.67 / 146.00". Those two halves cannot both hold against the
design PNG, and the numbers are:

- The design's h1 box is the full 350 dp column (`.scroll { padding: 0 20px }`,
  components.css:65; the screen HTML adds only `.head h1 { display: block }`).
  In 350 dp, greedy *and* balanced both break after "family": line 1 is
  `Create your family`, 251.2 dp of advance.
- The design PNG breaks after **your**: line 1 ink 157.33 dp, line 2
  `family account` 197.68 dp. A 350 dp box cannot produce that; any box in
  [197.7, 251.2) can, which is exactly the range the deleted comment
  documented. So the PNG's break is only reachable with a cap.
- Both breaks are two lines with the same 34 dp pitch, so the orchestrator's
  tops (112.67 / 146.00) pass either way — the criterion cannot tell them
  apart; the ink width can.

Decision needed, and the tests state both options:

- **Keep the 240 dp cap** → the design PNG's break and ink widths are
  reproduced (`the balanced headline keeps the design break and gutter` stays
  green), and the balance component is a no-op that narrows the box to
  197.68 dp without moving anything.
- **Drop the cap** → the rule's letter is satisfied and the tops still match,
  but line 1 grows from 158.56 dp to ~251 dp and no longer matches the design
  PNG; `the balanced headline keeps the design break and gutter` goes red.

This stage pins the design PNG (the stage brief's reference), so the green
guard fails if the cap is dropped; that is deliberate, not an accident.

Also checked: no `zz_`/`*probe*` scratch files remain in
`app/test/features/auth/` (orchestrator item 2), and `flutter analyze` is
clean.

## Tests added this stage

`typography_test.dart` 9 → **16** (+7, all green — the finding itself lives in
the bugs file, per the house pattern):

- **Shapes, not only text (new UI-check rule).** Every visible
  background/border rect measured from the design PNG at 3× and pinned:
  the two field boxes (x 20, width 350, tops 443 / 535, height 52), the Apple
  and Google pills (tops 255 / 319, height 52), the "or" row's two 1 px
  hairlines (y 395, x 20..176 and 214..370 — 38 px of gap for the 13 px label
  and two 12 px gaps), and the CTA pill (x 20, width 350, height 52, 16 dp
  below the panel top). A collapsed pill, a lost fill or a shifted rule now
  fails here even if the text lands in the right place.
- **BALANCED HEADINGS, migration guards.** `the balanced headline keeps the
  design break and gutter` and `the migration keeps the pixels at the design
  size` build the component the rule asks for inside the cap the design needs
  and assert it reproduces `Create your` / `family account`, the design's ink
  widths, the 20 dp gutter and the measured 197.68 dp narrowed box. `the body,
  caption and CTA keep plain Text` asserts the subtitle, helper, note row and
  CTA label stay outside the component ("never use it on
  .h2/.h3/.body/.caption"), so a fix cannot spread it.
- **Collapse guard.** `the headline is not a per-glyph column at text scale
  1.3` asserts the rendered box stays wider than 150 dp and every line carries
  words — green today, red if the component is swapped in before §10 lands.
- **LETTER SPACING rule.** `every rendered run has zero tracking` walks every
  `RichText` on the screen (including the rebuilt `_OrRow` style) and fails on
  any non-zero `letterSpacing`.

`p03_bugs_test.dart` 30 → **31** (+1, red): P03-BUG-24, un-skipped and
extended. No other file changed.

## Bugs found

### P03-BUG-24 (MAJOR, mandatory rule — OPEN) — the headline ignores BALANCED HEADINGS

`app/lib/features/auth/presentation/views/create_account_view.dart:39` and
`:103-111` — `static const double _headlineMaxWidth = 240;` wrapping
`Text('Create your family account', style: NestType.h1(…), maxLines: 3)`.

Repro:
`flutter test test/features/auth/p03_bugs_test.dart --plain-name "P03-BUG-24"`.
`find.byType(NestBalancedText)` → 0 widgets.

No pixel difference at the design size: with the design's fonts the cap
already yields `Create your` (158.56 dp) / `family account` (197.68 dp) on the
20 dp gutter, matching the design PNG. The cost of the cap is that it is
hand-calibrated ("any cap in [198, 252) breaks the design's wrap") and drifts
silently when a type token changes — the reason the rule exists.

Two things the migration must respect, both measured (design fonts loaded):

1. **`textAlign: TextAlign.left`.** The component centres its narrowed box by
   default; the design left-aligns both lines on the gutter.
2. **Keep the 240 dp cap.** Inside it the component narrows to 197.68 dp and
   neither the break nor the ink moves. Dropping it moves the 390 dp break to
   `Create your family` / `account`.

### Shared defect (filed, not a P03 bug) — `NestBalancedText` collapses when `maxLines` clips

`app/lib/core/design_system/components/nest_balanced_text.dart`
(`balancedWidthFor`). The binary search asks for the narrowest width whose line
count is `<= lineCount`, but it measures through the same `maxLines`-clamped
painter. When the text needs more lines than `maxLines` allows, the count is
clamped at every width, the predicate never fails, and the search converges to
~0.

| text scale | plain `Text` | `NestBalancedText(maxLines: 3)` |
|---|---|---|
| 1.0 | 240.00 × 68.00 dp, `Create your` / `family account` | 197.68 × 68.00 dp, same two lines |
| 1.3 | 240.00 × 132.00 dp, `Create your` / `family` / `account` | **0.10 × 132.00 dp, `C` / `r` / `eate your family account`** |

`SHARED_REQUEST.md` §10: search on the unclamped count, or fall back to the
full-width `Text` when the unclamped count already exceeds `maxLines`.
**Blocks** the migration as specified (the proof requires `maxLines: 3`, which
is also what bounds the heading at text scale 1.3); not blocking if the
migration drops `maxLines`.

## Rules checked this iteration

- **SIMULATORS**: none used. Stage 3 must never boot, install on, screenshot
  or drive a simulator; the filled-state captures
  (`ui/filled-light.png`, `ui/filled-dark.png`) are iteration-6 evidence and
  were not re-taken. `docs/screens/P03/filled_shot.sh` is left in place for
  stage 5, which owns simulator use.
- **BALANCED HEADINGS**: the finding above; body/caption text verified to stay
  outside the component.
- **UI CHECK MEASURES SHAPES**: covered by the new shape-rect group.
- **LETTER SPACING**: zero tracking verified across every rendered run.
- **FONTS**: no `google_fonts` import or `GoogleFonts.*` call in
  `lib/features/auth/` or `test/features/auth/`.
- **CHIP ROWS**: N/A — P03 renders no `NestChip` (checked).
- **TRIAL / PERIODS / CHILD ORDER / PIP / DATA OVER MOCKS**: N/A — P03 writes
  no `subscription_status`, lists no children, shows no Pip, and its submit
  path takes no numbers.
- **BOTTOM EDGE / ALIGNMENT**: both keep their pixel proofs; alignment
  produced P03-BUG-23 last iteration and is now green.
- **COPY**: unchanged — all nine strings byte-identical to the HTML
  (`copy_audit_test.dart` 11/11).
- **PROCESS**: not reported as findings. The only hygiene item was the
  `skip: true` above, which I removed because the rules forbid skipping tests
  and a skipped proof is not evidence.

## Results (`app/`)

- `dart format --set-exit-if-changed .` → `Formatted 394 files (0 changed)`.
- `flutter analyze` → `No issues found!` — no ignores, no weakened options.
- `flutter test test/features/auth` → **166 passed, 0 skipped, 1 failed** (the
  P03-BUG-24 proof). Declared per file: `auth_bloc_test.dart` 20,
  `create_account_view_test.dart` 38, `copy_audit_test.dart` 11,
  `p03_bugs_test.dart` 31, `seeded_submit_test.dart` 7,
  `typography_test.dart` 16, plus the looped matrix cases.
- `flutter test` (full suite) → **1183 passed, 0 skipped, 1 failed**.

## For the next stage

1. `SHARED_REQUEST §10` first: `NestBalancedText` must not collapse when
   `maxLines` clips. P03's guard turns red without it.
2. Then the P03-BUG-24 migration: `NestBalancedText(text, style: NestType.h1(
   color: tokens.ink), textAlign: TextAlign.left, maxLines: 3)` inside the
   existing 240 dp cap. The two typography guards must stay green.
3. `SHARED_REQUEST §7` (a 13/20 legal-caption token) remains the only other
   open shared item; non-blocking, pinned by `P03-BUG-12`.

VERDICT: FAIL