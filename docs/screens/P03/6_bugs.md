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

VERDICT: FAIL
