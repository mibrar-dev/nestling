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

## 5. `NestTextField` renders `errorText` 20dp inside the field (new,
## non-blocking)

`NestTextField` (`nest_text_field.dart:150-171`) hands `errorText` to
Material's `InputDecoration`, which lays it out on the field's *content* box
— measured `left = 40` for a field whose label, border and input all start at
`left = 20`. The design's `.field` is a flex column
(`components.css:129-135`: label, input, `.helper` and `.error` all share the
column), so the error belongs on the same gutter as the label. P03 already
hides the shared `helperText` and renders its own gutter-aligned helper row
(iteration-2 fix for ORCHESTRATOR_NOTES §4), which leaves the error as the
only indented line in the block — the error text jumps 20dp sideways when it
appears (proof `P03-BUG-11`). Suggested core fix: lay `errorText` out as a
gutter-aligned row under the input, or zero the decoration's error padding.
Blocks: no — P03 can fix it locally by owning the error row too.
