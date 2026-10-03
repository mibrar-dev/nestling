# P03 Create account — test notes (Stage 3, iteration 8)

Route `/create-account` · feature `auth` · parent mode. Tests live in
`app/test/features/auth/`; the in-memory Drift DB comes from
`setUpTestScope()` (`Seed.demo` / `Seed.empty` / `Seed.fresh`) and every test
that pumps the app ends with `disposeApp(tester)` (RULES §7). No `lib/` file
was touched by this stage.

## Verdict

**PASS.** `flutter test test/features/auth` → **173 passed, 0 skipped, 0
failed**; the full suite → **1198 passed, 0 failed**; `flutter analyze` →
`No issues found!`; `dart format --set-exit-if-changed .` → 394 files, 0
changed. No bug found this iteration.

Iteration 8's mandated work landed and holds: the headline is now rendered by
`NestBalancedText` (`textAlign: TextAlign.left`, `maxLines: 3`) and the
hand-calibrated `_headlineMaxWidth = 240` cap is gone. **P03-BUG-24 is
fixed** and its proof runs green as a regression guard, and the design's own
bands and line breaks are still exactly where the design PNG puts them.

## What I verified about the migration

- **The design break survives without the cap** — with the design's fonts, the
  h1 breaks `Create your` / `family account` at 390 dp, with ink widths
  158.56 / 197.68 dp against the design PNG's 157.33 / 197.68, both lines on
  the 20 dp gutter and 34 dp apart.
- **The balance is what produces it, not a constant.** New test
  `the full 350dp column balances to the design break` lays the same string out
  twice in the same 350 dp column: `NestBalancedText` gives the design's break
  and narrows the box to 197.68 dp, while a plain `Text` in that column
  gives `Create your family` / `account` (251.2 dp of advance on line 1). So
  the component is doing the work the retired cap used to imitate.
- **Correcting iteration 7's prediction.** I reported last iteration that the
  cap had to stay, arguing that a 350 dp column balances to "Create your
  family" / "account" and that the orchestrator's instruction to delete the cap
  conflicted with the design. That was my arithmetic error: the component
  takes the *minimum* line count the column needs and then narrows to the
  **smallest** width that still holds it (197.68 dp here), not the largest.
  The design PNG and the BALANCED HEADINGS rule agree, there is no conflict,
  and the conflict note in iteration 7's report is superseded by this section.
- **No collateral movement.** The absolute band proof still reads the Google
  button's bottom at 371.00, the email field's top at 443.00 and the
  password field's top at 535.00 — the design PNG's values to within a
  pixel — and the shape rects (both field boxes 350 × 52, both brand pills
  52 tall, the two 1 px rules at y 395 spanning 20..176 and 214..370, the CTA
  pill 350 × 52 sixteen dp below the panel) are unchanged.
- **Accessibility is intact.** `labels, header flag and tap targets meet the
  contract` still finds `flagsCollection.isHeader` on the headline: the
  `Semantics(header: true)` wrapper survives the widget swap, and
  `find.text` still resolves the heading as one node.
- **Prior proofs stay green**: P03-BUG-23's two band proofs (the 15.7 dp
  "or" row), P03-BUG-16's painted danger border, P03-BUG-22's gesture gate,
  P03-BUG-17's subtitle break with the bundled fonts, the copy audit, the
  320/390/430 × 1.0/1.0–1.3 matrix, dark mode, the seeded submit path and the
  BOTTOM EDGE pixel proof.

## Tests added this stage

`typography_test.dart` 16 → **17** declared (+7 executed, all green):

- `the full 350dp column balances to the design break` — replaces my
  iteration-7 harness, which built the component inside the 240 dp cap the
  screen no longer uses. It now mirrors the shipped configuration (the full
  350 dp content column, no cap) and adds the greedy-vs-balanced contrast
  that makes the mechanism legible.
- Six scale cases — `320/390/430 dp at scale 1.5 and 2.0` — accessibility
  scales past the 1.3 the brief asks for. Each asserts the box never collapses
  (SHARED_REQUEST §10's failure mode), every line carries words, and the break
  is still the design's.

`p03_bugs_test.dart` 31 (no new test, one de-vacuumed):

- `P03-BUG-7 the headline is width-constrained for the design break` asserted
  `rendered width <= 260`. In this harness — which substitutes a much wider
  display font — that passed for the wrong reason: `NestBalancedText` cannot
  find a two-line width for that font within `maxLines: 3`, so the shared
  clamp (§10) collapses the box to **0.1 dp** and any "narrower than 260"
  expectation is satisfied trivially. The design-accurate 197.68 dp pin lives
  in `typography_test.dart`, where the real fonts are loaded; this proof now
  pins what holds in *every* font — the h1 is the balanced component, it
  carries `--fs-h1`, and it lays out in the full 350 dp column with no cap.

## Bugs found

None this iteration.

### Shared defect, still open (not a P03 bug) — `SHARED_REQUEST.md` §10

`NestBalancedText.balancedWidthFor` binary-searches the narrowest width whose
line count is `<= lineCount`, measuring through the same `maxLines`-clamped
painter, so whenever the text needs more lines than `maxLines` allows at some
width the predicate stops discriminating and the search runs to ~0.

Iteration 8 sharpened the reachability data, and corrected my iteration-7
"Blocks: yes":

| configuration | text scale | rendered box |
|---|---|---|
| 350 dp column (shipped) | 1.0 / 1.3 / 1.5 / 1.8 / 2.0 | 197.73 → 257.03 dp, design break, **never collapses** |
| 240 dp cap (retired) | 1.0 | 197.68 dp, design break |
| 240 dp cap (retired) | 1.3 | **0.10 × 132.00 dp**, one glyph per line |
| fallback display font (harness) | 1.0 | **0.10 × 102.00 dp**, three lines of fragments |

The trigger is precisely *natural line count == `maxLines`*. P03's h1 needs
two lines at every width and scale measured, so it stays out of the clamped
region and the migration is safe; the defect remains live for any heading
whose natural line count equals its cap — and for any screen that ends up
rendering a substituted display font. §10 now says so and is no longer listed
as blocking P03.

## Rules checked this iteration

- **BALANCED HEADINGS**: the h1 is a `NestBalancedText`; the subtitle,
  helper, note row and CTA label are verified to stay outside the component
  ("never use it on .h2/.h3/.body/.caption").
- **SIMULATORS**: none used — this stage must never boot, install on,
  screenshot or drive a simulator. The `ui/filled-*.png` captures from
  iteration 6 remain the filled-state evidence; nothing was re-captured.
- **UI CHECK MEASURES SHAPES**: the shape-rect group from iteration 7 still
  passes (fields, brand pills, or-row rules, CTA pill).
- **LETTER SPACING**: zero tracking across every rendered run, including the
  rebuilt `_OrRow` style.
- **FONTS**: no `google_fonts` import or `GoogleFonts.*` call anywhere in the
  feature; the design fonts are loaded through a `FontLoader`.
- **ORCHESTRATOR_NOTES iteration-8 items**: both honoured — the migration is in
  and green (un-skipped and passing), and no `zz_`/`*probe*` scratch file
  remains in `app/test/features/auth/`.
- **CHIP ROWS / TRIAL / PERIODS / CHILD ORDER / PIP / DATA OVER MOCKS**:
  N/A — no chips, no `subscription_status` write, no periods, no child list,
  no Pip, no design numbers.
- **BOTTOM EDGE / ALIGNMENT**: both keep their pixel proofs.
- **COPY**: unchanged, byte-identical to the HTML.

## Results (`app/`)

- `dart format --set-exit-if-changed .` → `Formatted 394 files (0 changed)`.
- `flutter analyze` → `No issues found!` — no ignores, no weakened options.
- `flutter test test/features/auth` → **173 passed, 0 skipped, 0 failed**.
  Declared per file: `auth_bloc_test.dart` 20,
  `create_account_view_test.dart` 38, `copy_audit_test.dart` 11,
  `p03_bugs_test.dart` 31, `seeded_submit_test.dart` 7,
  `typography_test.dart` 17, plus the looped matrix and scale cases.
- `flutter test` (full suite) → **1198 passed, 0 skipped, 0 failed**.

## For the next stage

1. Nothing is blocking this screen. `SHARED_REQUEST §7` (a 13/20 legal-caption
   token, so the screen can stop overriding `height` locally) and `§10` (the
   balanced-wrap clamp) remain the open shared items; both are non-blocking
   here and both have proofs or guards in place.
2. `ui/filled-light.png` / `ui/filled-dark.png` are the design-state captures
   for the UI stage to compare against the design PNGs (2.08% / 2.05% when
   they were taken).

VERDICT: PASS