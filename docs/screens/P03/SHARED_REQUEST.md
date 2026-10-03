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

Status (integrate stage, iteration 6 — **final disposition: Decision B**):
§8 landed (`0bafd2a`, shared batch 2), so the switch happened: both fields
take `errorText`, the screen-owned error rows and their `buildWhen`
selectors are deleted, and the shared row supplies the live region — the
danger border and the announcement now arrive together. `P03-BUG-16`,
`P03-BUG-20` and `P03-BUG-21` are green regression guards and **no proof
on this screen is skip-marked**: do not re-skip them. The password helper
row stays feature-owned (the shared field's `helperText` is left null) and
is hidden while an error shows, matching the shared field's error-wins
behaviour. Do **not** re-add owned error rows while passing `errorText` —
the message would render twice.

## 6. The served Inter build is ~3–4% wider than the design's, so line
## breaks land early — RESOLVED

Resolved by the shared `body_text_width` work (`a4691f9`, merged `bbc7b55`):
the designs' own Inter 4.001 / Nunito 3.602 builds are bundled in
`app/assets/fonts`, `pubspec.yaml` no longer fetches `google_fonts`, and
`body_text_width_test.dart` pins body advances against the browser's
(including P03's subtitle line 1, 349.06dp, ±1%). So P03-BUG-17 is gone with
**no local change**. Do not chase it with a size/width/letter-spacing hack.

Update (test stage, iteration 6): a *local* proof is possible after all. The
bundled builds load into a widget test through a `FontLoader`
(`test/features/auth/typography_test.dart`, same technique as
`body_text_width_test.dart`), so P03 now pins the design's actual wrap —
"…Children never" / "need an email." — and the 349.06 dp advance with the
design's own metrics, plus the headline, helper and caption breaks and the
design's ink widths. The device capture agrees: the subtitle's two lines sit
at 189.00/213.00 dp against the design's 188.67/212.67.

Original finding (kept for the record): `google_fonts` served an Inter build whose glyph advances are wider
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
## — RESOLVED

**RESOLVED** by shared batch 2 (`0bafd2a`), with the exact shape requested:
`nest_text_field.dart` wraps the gutter row in
`Semantics(liveRegion: true, label: errorText,
child: ExcludeSemantics(child: Text(errorText, …)))`, so the message is
announced once and the node is labelled (P03-BUG-21's shape). P03's switch
(Decision B, §5) then closed P03-BUG-16/20/21 together; nothing local
remains.

Original finding (kept for the record): the shared `errorText` row rendered
as a plain `Text` (`nest_text_field.dart:199-206`) — no live region, no
explicit label node beyond the text's own. Material wrapped
`InputDecoration.errorText` in a `liveRegion`
(`material/input_decorator.dart:419`), so a VoiceOver user heard a
client-side validation error the moment it appeared; the shared row no
longer did. P03 worked around Material and owned its error rows, and its
attempt to re-add the live region regressed into an empty-label node
(P03-BUG-21).

## 9. Observation (not a request): `NestType.caption` is 2.3 dp taller than a
## design label that sets no line-height

Found while measuring P03-BUG-23. The design's `.or-label`
(`P03-create-account.html:27`) sets `font-size: 13px; font-weight: 600` and
**no** line-height, so its row is 13 px × Inter's normal line height ≈ 15.7 dp;
`NestType.caption` is fixed at 13/18 (`typography.dart:64-65`), so any screen
that reaches for the caption token to render such a label paints a 2.3 dp
taller row and shifts everything below it. On P03 that is the whole form
block sitting 2 dp low against the design.

This is a pattern note, not shared work: the fix belongs to the screen
(`_OrRow` should not use the caption token for a label the design gives no
line-height), and §7 is the existing request for the neighbouring case. No
core change is needed for P03 to go green.