# Fix list after iteration 7

## From 3_test.md
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


## From 4_review.md
# P03 Create account — QA code review (Stage 4, iteration 7)

Scope reviewed: `git diff main...HEAD` through `520cd82` (iteration-6
INTEGRATE) and `5e70e1a` (iteration-7 checkpoint). Reference set:
`docs/ARCHITECTURE.md`, `docs/screens/RULES.md`, `docs/DESIGN_SPEC.md`
§5 P03 and §0.9, `docs/design/SPACING_SPEC.md` §3,
`design/html-source/screens/P03-create-account.html`, `components.css:129-135`,
`ORCHESTRATOR_NOTES.md` (all mandatory), the standing COPY / FONTS /
LETTER SPACING / CHIP ROWS / BALANCED HEADINGS rules, `1_plan.md`,
`FIXES_1…4`, `2_build.md` (iter-7 INTEGRATE), `3_test.md` (iter-6),
`SHARED_REQUEST.md`.

Evidence gathered by this stage:

- `flutter analyze` → `No issues found! (ran in 2.9s)` — no ignores, no
  weakened options; no `GoogleFonts` string anywhere under
  `app/lib` + `app/test`.
- `flutter test test/features/auth` → **+159: All tests passed!**,
  0 failed, 0 skipped (files: `auth_bloc_test.dart` 20,
  `create_account_view_test.dart` 38, `copy_audit_test.dart` 11,
  `p03_bugs_test.dart` 30, `seeded_submit_test.dart` 7,
  `typography_test.dart` 9, plus 44 harness-unit lines in the new
  builders' files).
- `framework` fonts: `pubspec.yaml:90-108` bundles Inter 400/500/600/700 and
  Nunito 700/800/900 — the same builds that rendered the design; nothing
  from `google_fonts` is referenced.
- Device checks against `ui/filled-light.png` (iteration 6 capture):
  or-row ink band in the app spans 394–399 vs design 393–399; email label
  426–431 vs 424–431; field white starts 449+1 in app vs 449 design; the
  two legal-caption runs sit at x 262–300 / 149–241 vs 258–297 / 150–240.
  A post-BUG-23 capture was owed to the UI stage at the end of iteration 6;
  iteration 7's two proofs are green, so a fresh capture should show the
  form block on the design's own bands — that check belongs to the UI stage.
- `git status` touches only `app/lib/features/auth/**`,
  `app/test/features/auth/**`, `docs/screens/P03/**` — RULES §1 respected.

## Iteration-6 findings — both answered

| # | Finding | Status |
|---|---|---|
| 1 | BLOCKER — red suite, one proof shared-blocked | **closed**: the shared batch-2 merge fixed the component, §5/§8 record Decision B, suite green and skip-free |
| 2 | MINOR — overlap double-fired | **closed** via the gesture-entry gate; BUG-22's proof asserts collection of only the right boxes |

## Verified-correct this iteration

- **BUG-23 (form block 2 dp low) is fixed in code and green-proved.** The or-row label now takes everything from `NestType.caption` and only replaces the line box with
  `NestType.caption(color: tokens.ink2).copyWith(height: _orLabelLineBox / base.fontSize!)`, where `_orLabelLineBox = 15.7` is the single number the design owns (`13px/600` on Inter's natural 1.2077 line box). Both proofs (font-independent + fonts-loaded) pass; the token-derived style was re-integrated from the parallel builder without a behavioural change.
- **BUG-17 (subtitle break) is resolved shared-side**, and the build rightly did not hand-hack the subtitle's size or letter-spacing; the next capture should show it.
- **SHARED_REQUEST §5/§6/§7/§8** now record a single disposition each: §5/§8 RESOLVED (shared row won, live region preserved in the component), §6 RESOLVED (fonts bundled, google_fonts gone), §7 still open (13/20 legalCaption token) but pinned by two proofs.
- **BOTTOM EDGE / ALIGNMENT** now have pixel proofs in both themes (the CTA's surface runs to y=844 in light and dark; no strip) and the or-row fix is the only geometric drift closed this iteration.
- **FONTS / LETTER SPACING / CHIP ROWS / CARRYOVER**: no `google_fonts` import anywhere, `NestType` styles used with only `height`/`color` overrides (tracking is 0 by default), no `NestChip` on this screen, no `NestBalancedText` misuse anywhere (see finding 1).
- **CHILD ORDER / TRIAL / PIP / DATA OVER MOCKS / PERIODS**: N/A for P03.

## Findings

### 1. MAJOR — the h1 still hand-breaks with a `maxWidth` constant, not `NestBalancedText`

`app/lib/features/auth/presentation/views/create_account_view.dart:39-42`
(`_headlineMaxWidth = 240`) and `:101-111` (`Semantics(header: true, child:
ConstrainedBox(maxWidth: _headlineMaxWidth, child: Text('Create your family
account', style: NestType.h1(…), maxLines: 3)))`).

The iteration-7 rule is explicit: where the design CSS uses
`text-wrap: balance` (`.display`, `.h1`, `.kid-title`, `.kid-hero`, any
screen-local `.balance`), render the heading with `NestBalancedText`. P03's
heading is `.h1` — explicitly in scope — and the fix is a swap of the same
copy, style, and `maxLines: 3`, no new constant. The `ConstrainedBox` answer
looks correct today only because it forces the same 2-line break; at the
spec widths the proofs (`P03-BUG-7`, `typography_test.dart`) already see the
same geometry, and `NestBalancedText` is what exists for exactly this
computation. Until the swap, the screen is one width/font-asset change away
from a silent divergence from the design (and any future screen that
copies this cap inherits it).

Concrete fix:

```dart
Semantics(
  header: true,
  child: NestBalancedText(
    'Create your family account',
    style: NestType.h1(color: tokens.ink),
    maxLines: 3,
    textAlign: TextAlign.start,
  ),
),
```

Delete `_headlineMaxWidth` and its comment block; the two proofs should
still pass because the rule already documents the balanced break.

### 2. MINOR — `zz_probe8_test.dart` must not be committed

`app/test/features/auth/zz_probe8_test.dart` — an untracked FontLoader debug
probe left by the test stage (its content is duplicated in
`typography_test.dart`'s own setup and it has never been committed). It is
inside `app/test/features/auth/`, which is an allowed edit path, so the next
stage could accidentally bring it in. Delete it or move it under
`docs/screens/P03/`.

## Checked and clean (no finding)

- **Architecture** — feature-first; `domain/` = abstract repository + entities
  only; one bloc per screen; DI/routes per feature; only route-path constants
  cross feature boundaries; no use-case classes, no `utils` dumping ground.
- **RULES §1 / §4 / §7** — only allowed paths touched (auth feature + its
  test folder + P03 docs); password still never persisted; owner row still
  idempotent; feature tests all green with no skips, `disposeApp(tester)`
  honoured throughout.
- **TOKENS-ONLY** — the view has no hard-coded colours, radii or text sizes;
  the one owned number (`15.7`) is the HTML's computed line box, named and
  documented; the legal caption's 13/20 debt is confined to
  `SHARED_REQUEST.md` §7's open item.
- **A11Y** — filled-state pins (label/eye/enabled CTA) and the error live
  region are green; headline is the only `header:`; brand labels announce
  once each; every interactive box ≥44dp; text-scale 1.3 at 320/390/430
  absorbs overflow via the scroll view with no clip.
- **ERROR HANDLING** — both submit handlers `on Object catch` + `addError`,
  in-flight guards, form stays editable; the failed submit's announcement is
  still sent through the widget tree.
- **CHILDREN'S CODE** — no analytics, no ads, no child data, no photos, no
  location; the privacy note is the first visual element under the fields.
- **PROCESS** — noted, not reported as findings: the 14:06 interruption,
  the loop's own merge, uncommitted work.


## From 6_bugs.md
# P03 Create account — bug hunt (Stage 6, iteration 7)

Route `/create-account` · feature `auth` · parent mode · design
`design/screens/{light,dark}/P03-create-account.png` + HTML source. Tree
tested: the iteration-7 INTEGRATE checkpoint `5e70e1a` plus the work in
progress. **No screen code was changed by this stage** — the bugs file
gained the P03-BUG-24 proof and two stale-comment fixes, and this report was
written. `ORCHESTRATOR_NOTES.md` and the standing rules (PIP — vacuous, status
bar, data-over-mocks, bottom edge, alignment, COPY, CHILD ORDER — N/A, FONTS,
LETTER SPACING, CHIP ROWS — N/A, BALANCED HEADINGS, TRIAL, SIMULATORS) were
applied. **No simulator was used by this stage** (UI stage only).

**Concurrency note (process, not a finding):** the iteration-7 **test stage
is running in this worktree while this stage works** (process `254`/`284`
family); its transient `zz_probe*_test.dart` files come and go in
`test/features/auth/`. I left them alone; the numbers below are the auth
suite as measured during this stage (166 passed / 1 skipped) and the build
checkpoint's full-suite figure.

## Ledger

| ID | Severity | Area | Status |
|---|---|---|---|
| P03-BUG-1…23 | — | iterations 1–6's bugs (incl. BUG-23, the 2dp form offset) | **all fixed**; proofs green |
| **P03-BUG-24** | **MAJOR (mandatory rule)** | the headline ignores the BALANCED HEADINGS rule and still uses a hand-calibrated `maxWidth: 240` cap | **open this stage**; proof `P03-BUG-24`, skip-marked |

## P03-BUG-24 (MAJOR, mandatory rule) — the headline is not rendered with `NestBalancedText`

**Where** `create_account_view.dart:39` (`_headlineMaxWidth = 240`) and
`:101-112`:

```dart
Semantics(
  header: true,
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: _headlineMaxWidth),
    child: Text('Create your family account', style: NestType.h1(…), maxLines: 3),
  ),
),
```

**The rule** (standing orchestrator rule, iteration 7 brief): “BALANCED
HEADINGS (main, NestBalancedText): where the design CSS uses
`text-wrap: balance` (.display, .h1, .kid-title, .kid-hero, plus any
screen-local `.balance`), render the heading with `NestBalancedText`. It
keeps the same copy, style and maxLines, and its lines break like the
design (no one-word orphan line).” P03's headline is `<h1 class="h1">` and
`.h1 { … text-wrap: balance; }` is in `components.css:29` — squarely in
scope. The screen instead carries a hand-measured 240dp pixel cap, which is
exactly the hand-tuned pattern the rule exists to replace: it drifts
silently the next time a type token, the font build, or the copy changes
(and it took a bespoke proof, `P03-BUG-7`, to pin it). The shared component
landed with shared batch 3 and is already used by P07
(`paywall_view.dart:406-416`).

**Repro** `flutter test test/features/auth/p03_bugs_test.dart --run-skipped`
→ `P03-BUG-24 the headline is rendered with NestBalancedText` fails on
`find.byType(NestBalancedText)` (0 found). The proof also pins the two
properties a careless migration would break: the copy/maxLines are unchanged
(`text`, `maxLines == 3`) and the headline's rendered left edge stays on the
20dp gutter (the design's two lines both start at ink x=22, so the migration
must pass `textAlign: TextAlign.left|start` — `NestBalancedText`'s default is
**centre**, which would visibly centre the heading).

**Suggested fix** (screen-local, one block):

```dart
Semantics(
  header: true,
  child: NestBalancedText(
    'Create your family account',
    style: NestType.h1(color: tokens.ink),
    textAlign: TextAlign.left,   // design is left-aligned on the gutter
    maxLines: 3,
  ),
),
```

then delete `_headlineMaxWidth` (and its comment). `NestBalancedText` keeps
the line count the full width needs and shrinks to the narrowest width that
still fits it, so with the bundled Nunito the break is the design's
“Create your / family account”; `typography_test.dart` already pins that
break with the design's real fonts, so the migration is covered on device
metrics.

**Knock-on for `P03-BUG-7`'s proof** (heads-up for the fixer):
`P03-BUG-7` asserts the headline `Text`'s width ≤ 260 (the old cap). After
the migration the width is the dynamically balanced box (in the harness'
wide fallback font that is ≈308 for the 3-line case), so that bound becomes
obsolete — the BALANCED HEADINGS rule plus `typography_test.dart`'s real-font
break proof supersede it. Retire or re-express `P03-BUG-7` as part of the
migration rather than trying to satisfy both bounds.

## Everything else verified

- **P03-BUG-23 (the 2dp form offset) — fixed and green.** The `_OrRow`
  label now takes family/size/tracking/colour from `NestType.caption` and
  replaces only the line box (`_orLabelLineBox = 15.7`, the design's own
  `.or-label` metric). Both proofs (the font-independent line-box/gap proof
  and the `typography_test.dart` design-band proof) pass; measured band tops
  now match the design within a rounding dp.
- **Iterations 1–6's bugs** — BUG-16 (danger border + labelled live region
  via the landed §8 row), BUG-17 (shared-resolved with the bundled fonts and
  now locally pinned in `typography_test.dart`), BUG-18/19/20/21/22 (overhang
  reachability, first-frame measurement, live regions, gesture-entry gate)
  are all green regression guards; the feature suite has no other skip.
- **FONTS** — no `google_fonts` import or `GoogleFonts.*` call anywhere in
  `lib/` or `test/`; Inter/Nunito are bundled assets. **LETTER SPACING** —
  no local tracking; the two caption line-height overrides remain
  `NestSpacing.s5 / 13`, and the or-label's line box is the documented
  single design-owned number. **CHIP ROWS / CHILD ORDER / PERIODS / TRIAL /
  PIP / DATA OVER MOCKS** — N/A on this static parent-mode form (no
  subscription writes; the demo seed is the active subscriber).
- **Standing hunt list** — kid-mode guard (`/create-account` → gate), back
  and deep links, restart persistence (one owner row, password never
  written), double-tap guard, 320/390/430 × 1.0/1.3 matrix, dark-mode
  contrast, bottom edge (surface to y=844, now a raster proof) and the 20px
  gutters: all covered by green proofs or N/A as before.
- **`_OrRow` style** — the only new literal in the feature (`15.7`) is the
  design's own line box, named and documented; not a token violation to
  file.
- **`SHARED_REQUEST.md` §7** — the non-blocking `NestType.legalCaption`
  13/20 token request remains the only open shared item; §9 now notes the
  neighbouring “label whose CSS sets no line-height” case.

## Suite state at hand-off

- Auth suite during this stage: **166 passed, 1 skipped** (the skip is this
  stage's `P03-BUG-24`; `--run-skipped` fails it for the reason above).
- Build checkpoint: full suite **1176 passed, 0 failed, 0 skipped**;
  `dart format` and `flutter analyze` clean.
- The feature code analyzes clean; the only analyze noise seen in the tree
  was the concurrently-running test stage's transient probe files, which are
  its own work in progress and excluded here.

## Verdict

One MAJOR, mandatory-rule bug remains (P03-BUG-24: the headline must use
`NestBalancedText` per the standing BALANCED HEADINGS rule; the 240dp cap is
the hand-tuned pattern that rule replaces). The fix is one widget block plus
deleting the cap, keeping `textAlign` left, and retiring the now-obsolete
`P03-BUG-7` width bound. Everything else on the screen is closed and green;
`SHARED_REQUEST.md` §7 is the only open shared item and is non-blocking.

