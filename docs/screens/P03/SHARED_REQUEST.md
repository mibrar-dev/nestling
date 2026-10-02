# Shared request — P03 Create account

## 1. `NestNavBar` compact with `title: null` throws — RESOLVED

Resolved by the shared onboarding-header fix landed on `main` (`fc981bc`,
merged into this worktree by `2027506`): the compact branch now renders a
`Builder` that returns `SizedBox.shrink()` for a null/empty title, with no
nested `Expanded`/`Spacer`. P03's `title: ''` workaround
(`create_account_view.dart:83-87`) can be simplified to `title: null` in the
next build pass.

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
