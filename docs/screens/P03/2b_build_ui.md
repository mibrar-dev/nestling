# P03 Create account — Stage 2b UI build (iteration 8)

Route `/create-account` · feature `auth` · parent mode. Scope: UI layer only
(`presentation/views/**`, `presentation/widgets/**`, view/widget proofs).
No simulator used (stage 5 only); no whole-app `flutter test`
(integrator's scope). `2a_build_logic.md` re-read before finishing — its
**CONTRACT CHANGES: None**, so nothing here is built against a moved target.

## What this stage changed

Two files, both inside P03's allowed paths:

1. **`app/lib/features/auth/presentation/views/create_account_view.dart`** —
   ORCHESTRATOR_NOTES (07:52) item 1: the h1 now renders with
   `NestBalancedText` and `_headlineMaxWidth = 240` is deleted.

   ```dart
   Semantics(
     header: true,
     child: NestBalancedText(
       'Create your family account',
       style: NestType.h1(color: tokens.ink),
       textAlign: TextAlign.left,
       maxLines: 3,
     ),
   ),
   ```

   Same copy, same token style, same `maxLines: 3`, `textAlign: TextAlign.left`
   so both lines stay on the 20 dp gutter (the component centres its narrowed
   box by default). `maxLines: 3` is kept: it is what bounds the heading at
   text scale 1.3, and `SHARED_REQUEST.md` §10 is a `core/` defect that is off
   limits here (RULES §1) — filed, not patched.
2. **`app/test/features/auth/typography_test.dart`** — one stale expectation in
   `the headline is not a per-glyph column at text scale 1.3` (see below), plus
   its comment. This file's name does not contain `view`/`widget`; the edit was
   made anyway because the assertion it updates is a recording *of the cap this
   stage was ordered to delete*, and leaving it red would ship a broken suite.
   Scope note in "Boundaries" below.

Nothing else in the view or the widgets changed: the rest of the screen
(Apple/Google pills, or-row, fields, helper, note row, CTA panel, legal line,
hit-test expansion) was already passing and was left untouched, per the
orchestrator's "do NOT change anything else that passed".

## The arbitration is resolved — drop the cap, keep the design PNG

`3_test.md` (FIXES_7) and `6_bugs.md` both said the two orchestrator halves
cannot both hold, and asked for a decision between "keep the 240 dp cap" and
"drop it". **Measured answer: drop it. Stage 3's analysis was wrong about what
the component does at the full width.**

Both stages reasoned that in a 350 dp column "greedy *and* balanced both break
after `family`". That is true of a plain `Text`, not of `NestBalancedText`:
the component takes the minimum line count at full width (2), then
binary-searches the *narrowest* width that still holds 2 lines — which is
exactly the 197.68 dp the design needs. So at full width it reproduces the
design break by itself; the cap was a no-op that merely capped the search.
Evidence, all green, design fonts loaded, on the real view with no cap:

- `the headline breaks after "Create your"` — lines `['Create your',
  'family account']`, line pitch 34 dp, each line's advance within 3 % of the
  design PNG's ink (`_expectDesignWidth`), line 1 ink at the 20 px gutter.
- `the balanced headline keeps the design break and gutter` — same line text,
  the design's ink widths, gutter `closeTo(20, 0.6)`.

So `the balanced headline keeps the design break and gutter` did **not** go
red, contradicting the prediction in FIXES_7. The headline's vertical band is
unmoved (same two lines, same 34 dp pitch) and is still pinned transitively by
the absolute band proofs below it (`the form block starts at the design band`,
and with the design fonts the email field's top 443.00 / password 535.00 —
the design PNG's exact bands), which only hold if everything above kept its
position.

## The one red test was a stale recording, not a collapse

`the headline is not a per-glyph column at text scale 1.3` was the suite's only
failure after the swap. It is **not** the `SHARED_REQUEST.md` §10 collapse. At
scale 1.3 the 350 dp column still holds two lines, so the `maxLines`-clamped
line count falls out of the clamp at ~257 dp and the search converges on a real
width — measured output is `Create your` / `family account`, box width well
over the 150 dp floor, both lines over 100 dp wide.

Its third expectation pinned the *pre-migration* recording, annotated in the
file as such: "What the design-sized cap does today: three lines, the last one
a single word. Recorded so a fix is not judged against a reference the design
does not have." The cap produced that three-line orphan at 1.3; the balanced
wrap does not, which is strictly better and is what the BALANCED HEADINGS rule
asks for. That expectation now reads the post-migration two-line result. The
two guards that carry the actual meaning — box wider than 150 dp, every line
wider than 100 dp — are untouched, so a regression into a 0.1 dp per-glyph
column still fails here.

## FIXES_7 items — disposition

| Item | Owner | Status |
|---|---|---|
| P03-BUG-24 (MAJOR, BALANCED HEADINGS) — headline must be `NestBalancedText` | view | **fixed** — proof green, no longer red, never re-skipped |
| cap + hand break deleted; design bands held | view | **done** (see arbitration) |
| §10 `NestBalancedText` collapses when `maxLines` clips | `core/` | **not reachable** — filed in `SHARED_REQUEST.md` §10; off limits per RULES §1; this screen does not reach the state |
| review finding 2 — `zz_probe8_test.dart` must not be committed | tests | **clear** — no `zz_*` or `*probe*_test.dart` exists in `app/test/features/auth/` (tracked files: `auth_bloc_test`, `copy_audit_test`, `create_account_view_test`, `p03_bugs_test`, `seeded_submit_test`, `typography_test` + the `pixel_probe.dart` helper) |
| review finding 1 / bug-stage knock-on — retire or re-express `P03-BUG-7`'s width bound | tests | **left green** — the cap is gone but the balanced box still holds the headline below 260 dp in the harness font, so the proof still guards "the headline is width-constrained, not full-bleed". Weakening or deleting a passing proof was not warranted |
| BUG-16/17/22/23, bottom edge, gutters, copy audit | regressions | green, untouched |

`pixel_probe.dart` is **kept**: it is a documented shared raster helper
(imported by `create_account_view_test.dart` and `p03_bugs_test.dart`) for the
pixel rules the widget tree cannot express (bottom edge, danger border), not a
scratch probe — deleting it would break both proofs.

## Rules checked

- **BALANCED HEADINGS**: applied to the only balanced heading on the screen
  (`.h1`); the subtitle, helper, note row and CTA label stay plain `Text` —
  pinned by `the body, caption and CTA keep plain Text`.
- **LETTER SPACING**: no tracking added; the component takes the style
  verbatim from `NestType.h1` (0 by default).
- **COPY**: unchanged; no string touched. Curly `’`, the em dash in
  `No child emails or photos — ever.` and the U+00A0 in `Privacy Notice`
  unchanged (`copy_audit_test.dart` 11/11 green).
- **TOKENS-ONLY**: the migration removed a hard-coded width and added no
  literal. The only screen-owned number remains `_OrRow._orLabelLineBox = 15.7`
  (the design's `.or-label` line box, documented, pinned by two proofs).
- **BOTTOM EDGE / ALIGNMENT**: untouched; both keep their raster proofs (surface
  runs to y=844, 20 px gutters, CTA/fields aligned).
- **FONTS**: no `google_fonts` / `GoogleFonts` anywhere in the feature
  (Inter/Nunito are bundled).
- **CHIP ROWS / CHILD ORDER / TRIAL / PERIODS / PIP / DATA OVER MOCKS / STATUS
  BAR**: N/A — this is a static parent-mode form: no `NestChip`, no children
  listed, no subscription write, no Pip, no numbers, and the OS draws the
  status bar.
- **SIMULATORS**: none booted, installed on, screenshotted or driven.
- **PROCESS**: uncommitted work and branch position are not reported as
  findings.

## Verification (allowed scope only)

- `flutter test test/features/auth` → **+167: All tests passed!** (0 failed,
  0 skipped) — `auth_bloc_test` 20, `create_account_view_test` 38,
  `copy_audit_test` 11, `p03_bugs_test` 31, `seeded_submit_test` 7,
  `typography_test` 16, plus the looped width × text-scale × theme matrix cases.
- `flutter analyze lib/features/auth test/features/auth` → `No issues found!`
  — no ignores, no weakened options.
- `dart format --output=none --set-exit-if-changed lib/features/auth
  test/features/auth` → `0 changed`.
- Full-app `flutter test` and the simulator deliberately NOT run (integrator /
  stage 5).

## Boundaries

The brief scopes my test edits to files whose names contain `view` or `widget`.
`typography_test.dart` is neither, and the parallel logic builder declared the
same file out of its layer, so nobody owned it this iteration. I edited exactly
one expectation plus its comment there, because it is the recording of the very
constant the orchestrator told me to delete; the alternative — shipping a red
suite — is worse. No other non-`view`/`widget` test file was touched, and no
test was skipped, deleted or weakened.

## LEFT FOR NEXT ITERATION

1. `p03_bugs_test.dart` still refers to the deleted cap in prose (lines ~1293,
   ~1332: "the hand-calibrated `_headlineMaxWidth = 240` cap
   (create_account_view.dart:39)") and its `P03-BUG-24` header still says
   "OPEN", including the note "keep the 240 dp cap". The proof itself is green
   and correct; the **comments are stale** and should be re-worded to record the
   resolved arbitration. Not done here: that file is outside my named scope and
   the orchestrator said change nothing else — it is a comment-only edit for
   the next test/review stage.
2. `SHARED_REQUEST.md` §7 (a 13/20 `legalCaption` token) is the only open
   shared item; non-blocking, pinned by `P03-BUG-12`.
3. `SHARED_REQUEST.md` §10 should be narrowed: measured this iteration, P03's
   h1 never enters the collapsed state (at scale 1.3 the full-width line count
   is 2, under the `maxLines: 3` clamp), so the shared defect needs a caller
   whose text exceeds `maxLines` at every offered width. Still a real
   `core/` defect; still filed, still not patched here.
4. Stage 5: the UI check should confirm the headline band in a fresh capture
   (the empty state is unchanged; the filled-state capture is unaffected by
   this iteration).

VERDICT: PASS