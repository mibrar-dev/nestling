# P04 · Privacy consent — build notes (STAGE 2 INTEGRATE, iteration 8)

Feature `privacy_consent` · route `/privacy` · parent mode.
Two builders worked in parallel on this iteration: `2a_build_logic.md` (domain,
data, bloc, DI/routes + bloc/repository tests) and `2b_build_ui.md` (views +
view/widget tests). This file is the integration pass: its only job was to make
the combined result compile and pass, and to confirm the one new fix on device.

## Integration result: clean, zero repair work

**No integration breakage existed, so I changed no code.** The two halves did
not overlap except on `p04_bugs_test.dart`, and there with no conflicting
hunks (2a explicitly left it alone; 2b owns it).

- **No contract seam.** 2a reports `CONTRACT CHANGES: none` — `PrivacyConsentLoadRequested`,
  `PrivacyConsentCrashToggled(value)`, `PrivacyConsentState(status/items/crashConsent/errorMessage)`,
  `PrivacyConsentRepository`, `registerPrivacyConsent` and
  `PrivacyConsentRoutePaths.privacy` are unchanged. The one new fix is pure
  view typography (a `letterSpacing: 0` in a `copyWith`), so nothing in the
  bloc/data layer had to adapt.
- **No import/member seam.** No compile errors, no renamed members, no test
  turned red by combining the halves.
- **Skipped-proof seam, closed.** 2a correctly refused to touch
  `p04_bugs_test.dart` (outside its file-name scope, and the proof pumps the
  view) but flagged that un-skipping `[P04-10]` is the integrator's job once
  the fix lands. 2b landed the fix and un-skipped it. Verified here:
  `grep "skip: true" test/features/privacy_consent` → no matches, and the
  runner prints `All tests passed!` (not `All other tests passed!`), so there
  are **zero skips app-wide** and nothing can hide behind one.

## Summary of 2a (logic)

No files changed — verified in place and green: transactional upsert
(`data/privacy_consent_repository_impl.dart`), optimistic toggle +
state-aware failure + revert-to-stored (`presentation/bloc/privacy_consent_bloc.dart`),
stable DI/route contract. 2a's checks: `flutter analyze lib/features/privacy_consent`
→ No issues found; bloc + repository tests → 33 passed.

Its one triage call worth recording: **P04-10 is not fixable in the logic
layer** — the title width is pure view typography and the toggle's
value/layout contract is unchanged. Correct; nothing was forced.

## Summary of 2b (UI)

Fixed **P04-10**, the one new finding in FIXES_7 (MAJOR): the opt-card title
`Optional: help improve Nestling` wrapped to two lines and the card ran 22 px
taller than the design (531→643 vs 531→621).

- **Root cause, measured:** the design's `.opt-title` has no tracking, but
  `NestType` styles are `inherit: true` with no `letterSpacing`, so Material's
  `DefaultTextStyle` (`bodyMedium`, 0.3 px) leaks in. With the newly bundled
  Inter the title needs 250.2 px in P04's 247 px text column → wrap. Card went
  94 px → 116 px.
- **Why local, not shared:** the prescribed shared fix (core `NestType`
  default `letterSpacing: 0`, or `NestToggle` `minWidth` 59→51) lives in
  `app/lib/core/**`, which RULES §1 forbids a screen agent from editing. 2b
  applied the RULES-legal half: `letterSpacing: 0` on that one `Text` — the
  design's own value — and recorded the shared half in SHARED_REQUEST §7 as
  still open for core. Title back to one 22 px line, card back to the design's
  94 px; toggle tap target, card padding and row gap untouched.
- Un-skipped `[P04-10]` and refreshed the file header/index.

Files changed by 2b (all inside RULES §1):
`presentation/views/privacy_consent_view.dart` (one style property + comment),
`test/features/privacy_consent/p04_bugs_test.dart`, `docs/screens/P04/SHARED_REQUEST.md` (§7 status).

## FIXES_7 items — all done, none left

| Id | Item | State | Evidence on the integrated tree |
|---|---|---|---|
| P04-1 | first-run opt-in silently dropped | **DONE** (it. 2) | transactional upsert; `[P04-1]` green |
| P04-2 | row 4 empty peach tile | **DONE** (it. 5) | `NestIcons.trash` wired, no `TODO(P04)`; `[P04-2]` green |
| P04-3 | compact nav 16 px short | **DONE** (shared merge) | `[P04-3]` green (60 px bar) |
| P04-4 | dividers inflate the list 3 px | **DONE** (it. 4) | four direct `NestList` children, shared overlay; `[P04-4]` green |
| P04-5 | double-tap wrote the same value twice | **DONE** (it. 2) | optimistic emit; `[P04-5]` green |
| P04-6 | failed OFF claimed "it stays off" | **DONE** (it. 2) | state-aware caption; `[P04-6]` green |
| P04-7 | dark mode rendered the light-baked shield | **DONE** (it. 5) | `NestPrivacyShield`; `[P04-7]` green |
| P04-8 | failed toggle reverted to an unpersisted value | **DONE** (it. 3) | revert to `_crashFrom(items)`; `[P04-8]` green |
| P04-9 | overlapping first-run writes kept the earlier value | **DONE** (it. 4) | single transaction; `[P04-9]` green |
| **P04-10** | **opt-card title wraps, card 22 px tall (NEW, MAJOR)** | **DONE (it. 8)** | local `letterSpacing: 0`; `[P04-10]` un-skipped + green; **device-confirmed below** |
| UI check §deviation 1 | (same defect as P04-10) | **DONE** | ink rows now identical to the design (probe below) |

**Left for later iterations — outside P04 scope, not P04's to fix:** the
app-wide `letterSpacing: 0.3` leak into design text on every other screen,
tracked as SHARED_REQUEST §7 (shared half). When core fixes it, the view's
local `letterSpacing: 0` becomes a harmless no-op that can be deleted.

ORCHESTRATOR_NOTES items 1–4 remain met. FONTS rule: the only remaining
`google_fonts`/`GoogleFonts` hits app-wide are the **string literals inside
`privacy_consent_a11y_test.dart`, which is the guard test that asserts their
absence** — correct, not a violation. COPY still locked to the HTML source;
CHILD ORDER / PIP N/A.

## Gates (app/, integrator run)

```
dart format .
→ Formatted 374 files (0 changed) in 1.19 seconds.
  (dart format --output=none --set-exit-if-changed
     lib/features/privacy_consent test/features/privacy_consent → 19 files, 0 changed)

flutter analyze
→ Analyzing app...
→ No issues found! (ran in 4.8s)

flutter test test/features/privacy_consent
→ 00:05 +160: All tests passed!        (160 passed, 0 skipped, 0 failed)

flutter test                            (whole app)
→ 00:26 +824: All tests passed!        (824 passed, 0 skipped, 0 failed)
```

Bug-proof file, run explicitly (expanded reporter) — all ten adversarial
proofs green, none skipped:

```
[P04-1] first run: the toggle tap is actually stored
[P04-2] every promise row renders its leading glyph
[P04-3] header block matches the 60px design bar
[P04-4] dividers do not add height to the promise list
[P04-5] double-tapping the switch toggles twice
[P04-6] a failed OFF write never claims "it stays off"
[P04-7] dark mode renders the themed shield, not the baked asset
[P04-8] a double-failed rapid toggle reverts to the stored value
[P04-9] overlapping first-run writes keep the last value
[P04-10] the opt-card title stays on one 22px line
→ 00:02 +17: All tests passed!
```

## Device verification of P04-10 (2b handed the re-shoot to the integrator)

`shot.sh /privacy` light + dark (`SEED=fresh`, parent, iPhone 16e,
`604697A9-11DA-462F-9837-396E9CA2493A`) → `ui/app_{light,dark}_8.png`, then
`compare.py` vs the design PNGs.

| | iteration 7 (wrapped) | **iteration 8 (fixed)** | iteration 6 baseline |
|---|---|---|---|
| Light mean diff | 4.45 % | **3.79 %** | 4.08 % |
| Light band 5 (527–633, the opt card) | 6.82 % | **2.60 %** | 4.19 % |
| Light band 6 (633–738) | 0.82 % | **0.40 %** | 0.40 % |
| Dark mean diff | 4.43 % | **3.76 %** | 3.98 % |
| Dark band 5 | 7.79 % | **2.88 %** | 4.44 % |
| Dark band 6 | 0.80 % | **0.39 %** | 0.39 % |

Bands 5–6 are not merely back to the iteration-6 baseline — they are
**better** than it, because the bundled Inter matches the design's own static
build more closely than the runtime-downloaded face did. Both themes are now
the best this screen has measured.

Ink-row probe of the opt card (dark pixels, x 20–370 dp) — the geometry the
bug hunt measured, before and after:

```
it7 shot  light (wrapped)   545.0-560.0  567.0-582.0  591.0-604.7  613.3-619.7
it8 shot  light (FIXED)     545.0-560.0        569.0-582.7  591.3-604.7
design   light (target)     545.0-560.0        569.0-582.7  591.0-604.7
```

The iteration-7 shot had a **fourth** ink run (the wrapped "Nestling" line at
567–582, plus the 613–620 line it pushed down). The iteration-8 shot has
three runs whose bounds match the design to within 0.3 dp — the title is one
line again. Dark mode agrees (it8 ink extent 545.0–587.3 / 591.0–604.7 vs
design 544.7–587.7 / 591.0–604.7; it7 ran on to 626.7).

Owner rules re-confirmed on the new shots: bottom CTA surface runs to the
physical edge in both themes; 20 px gutters; h1, chevron, shield, trash glyph
and copy unchanged. Status-bar clock and home-indicator pill ignored per the
STATUS BAR rule. No overflow or clipping anywhere on the screen.

## Files changed by the integrator

None (code). `docs/screens/P04/2_build.md` (this file) plus the four
iteration-8 screenshots/compares under `docs/screens/P04/ui/` are the only
writes.

VERDICT: PASS