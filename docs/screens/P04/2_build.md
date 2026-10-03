# P04 · Privacy consent — build notes (STAGE 2 INTEGRATE, iteration 9)

Feature `privacy_consent` · route `/privacy` · parent mode.
Two builders worked in parallel on this iteration: `2a_build_logic.md` (domain,
data, bloc, DI/routes + bloc/repository tests) and `2b_build_ui.md` (views +
view/widget tests). This file is the integration pass: make the combined result
compile and pass, and confirm the fix on device.

## Integration result: clean, zero repair work

**No integration breakage existed, so I changed no code.** The two halves did
not overlap on any file — 2a touched only the non-UI layer and changed nothing
there; 2b touched `views/` + one a11y test file, neither of which is in 2a's
file-name scope. There was no seam to reconcile.

- **No contract seam.** 2a reports `CONTRACT CHANGES: none` — `PrivacyConsentLoadRequested`,
  `PrivacyConsentCrashToggled(value)`, `PrivacyConsentState(status/items/crashConsent/errorMessage)`,
  `PrivacyConsentRepository`, `registerPrivacyConsent` and
  `PrivacyConsentRoutePaths.privacy` are unchanged. 2b's P04-11 fix is pure
  presentation (an ambient `DefaultTextStyle.merge` + an inlined dialog title),
  so nothing in the bloc/data layer needed to adapt. The view's large diff is
  re-indentation from that wrapper, not a redesign.
- **No import/member seam, no compile errors, no renamed members.**
- **Red-test seam, closed.** Review finding 1 left 3 red tests (the
  letter-spacing contract, light/dark/dialog). 2b fixed the cause; all 3 are
  green and the full feature suite runs with **zero skips**
  (`grep "skip: true" test/features/privacy_consent` → no matches, and the
  runner prints `All tests passed!` rather than `All other tests passed!`, so
  nothing hides behind a skip).

## Summary of 2a (logic)

No files changed — verified in place and green: transactional upsert
(`data/privacy_consent_repository_impl.dart`), optimistic toggle +
state-aware failure + revert-to-stored (`presentation/bloc/privacy_consent_bloc.dart`),
stable DI/route contract. 2a's checks: `flutter analyze lib/features/privacy_consent`
→ No issues found; bloc + repository tests → 33 passed (20 + 13).

2a's one substantive triage call: **P04-11 and the 3 red geometry tests are not
fixable in the logic layer** — the defect is inherited text tracking, the
preferred remedy is shared (`NestType._inter/_nunito`, i.e.
`app/lib/core/**`, which RULES §1 forbids a screen agent to edit), and no
bloc/data change bears on it. Correct, and it left the view work to 2b rather
than forcing a data-layer workaround.

## Summary of 2b (UI)

Fixed **P04-11** (MAJOR, latent) — the P04-10 class, screen-wide.

- **Cause:** the design sets letter-spacing only on `.display`/`.status-time`
  (neither is used on P04), but `NestType` styles omit `letterSpacing` and
  inherit, so Material's `bodyMedium` tracking (0.25) leaked into 14 of 15
  text runs. The iteration-8 test stage's new
  `privacy_consent_geometry_test.dart` pinned it; 3 tests were red.
- **Fix 1 — screen:** the Scaffold body is wrapped in
  `DefaultTextStyle.merge(style: TextStyle(letterSpacing: 0))`. The design gives
  P04 no tracking at all, so zeroing the ambient for the whole screen is
  design-exact — and unlike per-Text `copyWith`s it also reaches
  **core-rendered labels a screen agent cannot edit** (`NestButton`'s
  `Continue`), which the review's own offender list included.
- **Fix 2 — dialog:** the Privacy Notice dialog now renders its title as the
  first child instead of via `NestModal(title:)`. 2b measured why: the dialog
  route *does* capture the screen's zeroed style, but the `Dialog`'s
  `Material` re-applies `AnimatedDefaultTextStyle(theme.textTheme.bodyMedium)`
  nearer to the content, so a core-rendered `NestModal` title is unreachable
  from the screen. The inlined title is pixel-identical to NestModal's own slot
  (same `NestType.h3(ink)`, centred, `maxLines: 3`, ellipsis, `SizedBox(s4)`
  before the content). The dialog *body* lines already measured `null`
  tracking and needed no change.
- **Fix 3 — review finding 3 (MINOR):** `privacy_consent_a11y_test.dart` built
  its banned-package needles from adjacent string literals and dropped its
  self-exclusion, so the guard now also scans itself and plain greps no longer
  false-positive on it.
- The iteration-8 `letterSpacing: 0` on the opt-card title was kept (harmless,
  and it documents the original wrap site).

Files changed by 2b (all inside RULES §1):
`presentation/views/privacy_consent_view.dart`,
`test/features/privacy_consent/privacy_consent_a11y_test.dart`,
`docs/screens/P04/SHARED_REQUEST.md` (§7 iteration-9 status + the
Dialog-Material evidence).

## FIXES_8 items — all done, none left

| Id | Item | State | Evidence on the integrated tree |
|---|---|---|---|
| P04-1 | first-run opt-in silently dropped | **DONE** (it. 2) | transactional upsert; `[P04-1]` green |
| P04-2 | row 4 empty peach tile | **DONE** (it. 5) | `NestIcons.trash` wired; `[P04-2]` green |
| P04-3 | compact nav 16 px short | **DONE** (shared merge) | `[P04-3]` green (60 px bar) |
| P04-4 | dividers inflate the list 3 px | **DONE** (it. 4) | four direct `NestList` children; `[P04-4]` green |
| P04-5 | double-tap wrote the same value twice | **DONE** (it. 2) | optimistic emit; `[P04-5]` green |
| P04-6 | failed OFF claimed "it stays off" | **DONE** (it. 2) | state-aware caption; `[P04-6]` green |
| P04-7 | dark mode rendered the light-baked shield | **DONE** (it. 5) | `NestPrivacyShield`; `[P04-7]` green |
| P04-8 | failed toggle reverted to an unpersisted value | **DONE** (it. 3) | revert to `_crashFrom(items)`; `[P04-8]` green |
| P04-9 | overlapping first-run writes kept the earlier value | **DONE** (it. 4) | single transaction; `[P04-9]` green |
| P04-10 | opt-card title wraps, card 22 px tall | **DONE** (it. 8) | local `letterSpacing: 0`; `[P04-10]` green; superseded in scope by P04-11 |
| **P04-11** | **Material tracking leaks into 14/15 runs (NEW, MAJOR)** | **DONE (it. 9)** | screen-wide `DefaultTextStyle.merge` + inlined dialog title; 3 contract tests green; **device-verified below** |
| review 1 | 3 failing letter-spacing tests | **DONE** | `privacy_consent_geometry_test.dart` → 6/6 green |
| review 2 | geometry test untracked | **DONE** | tracked since `0f70e71`; lands with this iteration's commit |
| review 3 | a11y guard's own banned-font literals | **DONE** | needles built from pieces, self-scan on; `grep -rn "google_fonts\|GoogleFonts" lib test pubspec.yaml` → **zero hits app-wide** |
| review 4 | loop bookkeeping | not a finding (orchestrator 03:58) | no action |

**Left for later iterations — outside P04 scope, not P04's to fix:** the
core-side tracking default. While it is absent, the view's
`DefaultTextStyle.merge` wrapper and the dialog's inlined title are the load-
bearing fix; once core lands its zero default they become redundant no-ops that
can be simplified. The geometry contract tests keep passing either way (an
explicit `0` beats any ambient). Tracked as SHARED_REQUEST §7, which now also
carries 2b's finding that **every `NestModal` title on every screen** renders
with 0.25 px tracking until core is fixed.

ORCHESTRATOR_NOTES items 1–4 remain met. FONTS rule: zero hits app-wide.
LETTER SPACING rule: P04 sets no tracking anywhere the design does not, and the
new ambient zero is the design's own value — nothing was added back.

## Gates (app/, integrator run)

```
dart format .
→ Formatted 376 files (0 changed) in 2.56 seconds.
  (dart format --output=none --set-exit-if-changed
     lib/features/privacy_consent test/features/privacy_consent → 20 files, 0 changed)

flutter analyze
→ Analyzing app...
→ No issues found! (ran in 5.0s)

flutter test test/features/privacy_consent
→ 00:06 +166: All tests passed!        (166 passed, 0 skipped, 0 failed)

flutter test                            (whole app)
→ 00:28 +860: All tests passed!        (860 passed, 0 skipped, 0 failed)
```

The previously-red geometry file, run explicitly — all 6 green, including the
three letter-spacing contract tests that review finding 1 left failing:

```
light: the design numbers, exactly
dark:  the design numbers, exactly
320dp: the same identity holds when the copy wraps
letter-spacing contract · light: every rendered run has no tracking
letter-spacing contract · dark:  every rendered run has no tracking
letter-spacing contract · the Privacy Notice dialog copy has no tracking either
→ 00:01 +6: All tests passed!
```

## Device verification of P04-11 (2b handed the re-shoot to the integrator)

This iteration changed production rendering for **every** text run on the
screen, so a device re-shoot was mandatory, not optional. `shot.sh /privacy`
light + dark (`SEED=fresh`, parent, iPhone 16e, `604697A9-11DA-462F-9837-396E9CA2493A`)
→ `ui/app_{light,dark}_9.png`, then `compare.py` vs the design PNGs.

| | iteration 7 | iteration 8 | **iteration 9** |
|---|---|---|---|
| Light mean diff | 4.45 % | 3.79 % | **1.85 %** |
| Light band 1 (105–211, H1 + subtitle) | 6.02 % | 6.02 % | **0.29 %** |
| Light band 3 (316–422, promise rows) | 7.77 % | 7.77 % | **3.75 %** |
| Light band 5 (527–633, opt card) | 6.82 % | 2.60 % | **0.52 %** |
| Dark mean diff | 4.43 % | 3.76 % | **1.74 %** |
| Dark band 1 | 6.29 % | 6.29 % | **0.31 %** |
| Dark band 5 | 7.79 % | 2.88 % | **0.77 %** |

The largest change in nine iterations. Zeroing the inherited tracking narrows
each run by 0.25 px × glyphs — ~5 px on the 20-character H1 — and a 5 px
horizontal shift of a whole word changes almost every glyph edge, so the bands
that were previously blamed on "font-raster doubling" collapse. Bands 1 and 5
were not raster noise after all; they were sub-pixel text misalignment.

Ink-row probe, shot vs design (dp), light — every run now matches:

```
SHOT  light   112-138  155-170  198-257 | 299-334  355-370  378-390  410-430 | 545-560  569-583  591-605 | 690-742  767-779
DESIGN light  112-138  155-170  198-257 | 300-333  356-371  377-389  411-430 | 545-560  569-583  591-605 | 690-742  767-780
```

H1, subtitle, shield, opt-card title/sub/caption and the Continue button are
exact; the four promise rows and the footnote are within 1 px. Dark agrees.
Read from the Review pane, both themes: no text wraps anywhere new, the opt
card is one 22 px title line, the trash glyph and navy shield disc are intact,
20 px gutters, and the bottom CTA panel surface runs to the physical edge with
no coloured strip in either theme. Status-bar clock and home-indicator pill
ignored per the STATUS BAR rule; no overflow or clipping.

## Files changed by the integrator

None (code). `docs/screens/P04/2_build.md` (this file) plus the four
iteration-9 screenshots/compares under `docs/screens/P04/ui/` are the only
writes.

VERDICT: PASS