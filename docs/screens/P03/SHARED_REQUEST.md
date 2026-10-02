# Shared request — P03 Create account

## 1. `NestNavBar` compact with `title: null` throws — RESOLVED

Resolved by the shared onboarding-header fix landed on `main` (`fc981bc`,
merged into this worktree by `2027506`): the compact branch now renders a
`Builder` that returns `SizedBox.shrink()` for a null/empty title, with no
nested `Expanded`/`Spacer`. P03 reverted its `title: ''` workaround to
`title: null` in build iteration 2 — no P03 action remains.

## 2. Brand buttons expose a doubled screen-reader label (non-blocking)

`NestAppleButton`/`NestGoogleButton` (`nest_brand_buttons.dart`
`_BrandButton`) wrap an explicit `Semantics(label:)` around an `InkWell`
whose subtree holds a `Text` with the same string; the InkWell merges both
into one node, so assistive tech hears e.g.
`'Continue with Apple\nContinue with Apple'`. P03's widget tests pin the
label with `contains` rather than exact equality. Suggested core fix:
`excludeSemantics: true` on the inner label `Text` (or an `ExcludeSemantics`
around it) so only the explicit label survives. Blocks: no.

## 3. Compact nav-bar height: 44dp rendered vs the design's 60dp — RESOLVED

Resolved by the same shared fix (`fc981bc`): the compact branch now has the
spec's 4/12 vertical padding around its 44dp slots and renders **60dp** on
P03. The former `P03-BUG-3` proof is now green and kept as a regression
guard.

## 4. `NestButton` exposes a doubled screen-reader label (new, non-blocking)

`NestButton` (`nest_button.dart:151-153`) wraps
`Semantics(button: true, label: widget.semanticLabel ?? widget.label)` around
a `GestureDetector` whose `Text(widget.label)` merges into the same node, so
every primary CTA announces its label twice. P03's submit button reads
`'Create account\nCreate account'` in the semantics tree (proof
`P03-BUG-6`, currently skipped; the app-wide blast radius is every
`NestButton`). Suggested core fix: same as item 2 — exclude the inner label
`Text` from semantics. Blocks: no.

## 5. `NestTextField` couples the error row's layout and the error border to one flag (new, blocking P03-BUG-16)

`NestTextField` (`nest_text_field.dart:150-171`) hands `errorText` to
Material's `InputDecoration`, which lays it out on the field's *content* box
— measured `left = 40` for a field whose label, border and input all start at
`left = 20`. The design's `.field` is a flex column
(`components.css:129-135`: label, input, `.helper` and `.error` all share the
column), so the error belongs on the same gutter as the label. P03 already
hides the shared `helperText` and renders its own gutter-aligned helper row
(iteration-2 fix for ORCHESTRATOR_NOTES §4), and iteration 3 also owns the
error row — which is why the error is now on the gutter
(proof `P03-BUG-11`).

The catch: `errorText != null` is also the *only* flag that selects
`errorBorder` (`nest_text_field.dart:128-171`). With `errorText: null` the
input keeps its resting `line` border, so the design's
`input[aria-invalid="true"] { border-color: var(--danger) }`
(`components.css:135`, SPACING_SPEC §3) is lost — an invalid field now reads
as untouched with red text only (proof `P03-BUG-16`). Passing `errorText`
again restores the border but re-opens the 20dp indent, so BUG-11 and BUG-16
are mutually exclusive with the component as it stands.

Suggested core fix: separate the two concerns — a `hasError` (or
`errorBorder`) flag that drives the border independently of whether the
component renders the message row; a gutter-aligned error layout would close
the other half. Blocks: yes for P03-BUG-16 — the screen cannot converge on
both proofs until this lands (P03 keeps the visible gutter fix and leaves
`P03-BUG-16` skipped; if the shared change is not taken, the orchestrator
should explicitly retire that proof instead).

## 6. The served Inter build is ~3–4% wider than the design's, so line
## breaks land early (new, non-blocking)

Need: `google_fonts` serves an Inter build whose glyph advances are wider
than the one the design HTML was rendered with, so text that fits on one
line in the design wraps a word early in the app. Measured on P03's light
capture against `design/screens/light/P03-create-account.png` (identical
style tokens on both sides — `--fs-body: 16px; --lh-body: 24px`, no
letter-spacing, in both):

| string | design | app | ratio |
|---|---|---|---|
| "At least 8 characters" | 125.7dp | 130.7dp | 1.040 |
| "No child emails or photos — ever." | 264.7dp | 272.7dp | 1.030 |
| "Create your" (Nunito) | 157.0dp | 159.4dp | 1.015 |

Consequence on P03: the subtitle must read
`By continuing you agree to our Terms and` … the design breaks it after
"Children never"; the app runs out of room one word earlier and breaks
after "Children" (ORCHESTRATOR_NOTES iteration-3 item 2). The screen cannot
fix this without breaking the token rule (font size and letter-spacing are
both specified by `NestType.body`), so it needs a shared answer: pin/bundle
the Inter build the designs were rendered with, or accept the drift in the
compare thresholds. Files: `pubspec.yaml` (google_fonts) / any asset
pipeline that serves web fonts. Blocks: no — the app is otherwise correct
and the copy is verbatim.

## 7. `NestType` has no caption variant for the design's legal-link line
## height (new, non-blocking)

Need: the design's legal links use `13px/20px` (`.link { line-height: 20px }`,
`P03-create-account.html:26`) while `NestType.caption` is fixed at `13/18`
(`typography.dart:64-65`). P03 currently overrides with
`copyWith(height: 20 / 13)`, which hard-codes a type metric the design system
owns (the standing tokens-only rule). Suggested core addition:
`NestType.legalCaption` (13/20 w400 ink-2 and a 13/20 w600 sky link variant)
in `core/design_system/tokens/typography.dart`, after which both P03
overrides disappear. Blocks: no — `P03-BUG-12` pins the current override and
the geometry matches the design.
