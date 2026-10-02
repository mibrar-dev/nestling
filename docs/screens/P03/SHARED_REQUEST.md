# Shared request — P03 Create account

## 1. `NestNavBar` compact with `title: null` throws — RESOLVED

Resolved by the shared onboarding-header fix landed on `main` (`fc981bc`,
merged into this worktree by `2027506`): the compact branch now renders a
`Builder` that returns `SizedBox.shrink()` for a null/empty title, with no
nested `Expanded`/`Spacer`. P03 reverted its `title: ''` workaround to
`title: null` in build iteration 2 — no P03 action remains.

## 2. Brand buttons expose a doubled screen-reader label — RESOLVED

Resolved by the shared batch `7eaa1f7` ("…a11y/type fixes", merged `4751c52`):
`_BrandButton` now wraps the inner label `Text` in `ExcludeSemantics`
(`nest_brand_buttons.dart:171-173`), so assistive tech hears the label once.
P03's `P03-BUG-4` proof and the view tests' labels are unchanged and green.

## 3. Compact nav-bar height: 44dp rendered vs the design's 60dp — RESOLVED

Resolved by the same shared fix (`fc981bc`): the compact branch now has the
spec's 4/12 vertical padding around its 44dp slots and renders **60dp** on
P03. The former `P03-BUG-3` proof is now green and kept as a regression
guard.

## 4. `NestButton` exposes a doubled screen-reader label — RESOLVED

Resolved by the same shared batch (`7eaa1f7`): the CTA label `Text` is now
inside an `ExcludeSemantics` (`nest_button.dart:216-218`), so the P03 submit
button announces exactly "Create account". The `P03-BUG-6` proof is now
green (un-skipped, kept as a regression guard).

## 5. `NestTextField` couples the error row's layout and the error border to one flag — RESOLVED

Resolved by the shared batch `7eaa1f7` (merged before iteration 4's build;
the build note's claim that it "did not land" is wrong): the decoration no
longer takes `errorText`, the error renders as a **gutter-aligned row under
the input** (13/18 danger w600, same x as the label), the danger border is
forced explicitly, and an error suppresses the helper (error-wins).
`shared_batch1_test.dart` pins all three behaviours.

Consequence for P03: passing `errorText` no longer re-opens `P03-BUG-11`
(the row is on the gutter), so `P03-BUG-16` (no danger border) is a local
switch away — pass `errorText` to both fields and delete the screen-owned
error rows.

Status (bugs stage, iteration 5 — **final disposition: Decision A**): the
screen keeps its own live-region error rows and the proof is
skip-marked with this reason until §8 lands. Switching to the shared row
today would fix the border but drop the announcement of the validation
message (the test/review stages both judge the announcement the higher
value; see `6_bugs.md` P03-BUG-16). When §8 lands, the switch is: pass
`errorText` to both fields, delete the owned rows and their `buildWhen`
selectors, un-skip P03-BUG-16. Do **not** pass `errorText` while keeping the
owned rows — the message would render twice.

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

## 8. `NestTextField`'s gutter error row should announce like Material's did
## (new, non-blocking)

Need: the shared `errorText` row renders as a plain `Text`
(`nest_text_field.dart:199-206`) — no live region, no explicit label node
beyond the text's own. Material wrapped `InputDecoration.errorText` in a
`liveRegion` (`material/input_decorator.dart:419`), so a VoiceOver user heard
a client-side validation error the moment it appeared; the shared row no
longer does. P03 currently works around Material and owns its error rows, and
its attempt to re-add the live region regressed into an empty-label node
(P03-BUG-21); once this shared row announces (e.g.
`Semantics(liveRegion: true, label: errorText,
child: ExcludeSemantics(child: Text(errorText, …)))`), P03 can pass
`errorText`, delete its owned rows, and close P03-BUG-16/20/21 together.
Blocks: no — P03 keeps its own live-region rows and skip-marks P03-BUG-16
pending this (Decision A, see §5). Landing it is a ~3-line core change and
P03's switch then closes the last open P03-local defect.
