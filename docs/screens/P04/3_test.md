# P04 · Privacy consent — test notes (STAGE 3, iteration 8)

Feature `privacy_consent` · route `/privacy` · parent mode.
Scope this stage: `app/test/features/privacy_consent/**` + `docs/screens/P04/**`
(RULES §1). No production code touched; the finding below is recorded, **not**
patched.

Inputs re-verified: `1_plan.md`, `2_build.md` (iteration 8 integrate — fixed
P04-10 with a local `letterSpacing: 0` and un-skipped its proof), `5_ui.md`,
`6_bugs.md`, `FIXES_7.md`, `SHARED_REQUEST.md` (including §7) and the mandatory
`ORCHESTRATOR_NOTES.md`.

## Test inventory — 166 P04 tests (163 green, 3 red — the finding below)

| File | Tests | Role |
|---|---|---|
| `privacy_consent_bloc_test.dart` | 20 | every event/state path of `PrivacyConsentBloc` |
| `privacy_consent_repository_test.dart` | 13 | Drift contract on the in-memory DB (`Seed.demo` / `empty` / `fresh`) |
| `privacy_consent_view_test.dart` | 27 | copy, light+dark, 320/390/430 × 1.0/1.3 matrix, statuses, navigation, a11y, gutters, bottom edge |
| `privacy_consent_view_contract_test.dart` | 39 | states through the real router, every tap destination, optimistic switch, failure captions, separator overlay, row glyphs, nav geometry, dialog stress, short screens, alignment |
| `privacy_consent_copy_test.dart` | 5 | copy fidelity against the HTML design source (COPY rule) |
| `privacy_consent_artwork_test.dart` | 11 | artwork provenance + painted-pixel theme proof |
| `privacy_consent_a11y_test.dart` | 28 | contrast, system text scale, screen-reader shape, token hygiene, bundled-font rules |
| `privacy_consent_geometry_test.dart` | 6 **(new)** | the design's pixel geometry at real font metrics + the letter-spacing contract |
| `p04_bugs_test.dart` | 17 | the ten bug proofs + clean-behaviour guards |

## The unlock: real font metrics in widget tests

`[P04-10]` showed how to load the bundled faces (`FontLoader('Inter')` /
`FontLoader('Nunito')` from `assets/fonts/*.ttf`). With them the widget tree
reproduces the device numbers, which every earlier stage had to assert
relationally ("the list is the sum of its rows") because `flutter_test`'s
default font is far wider than Inter. New group
**"P04 — design geometry at 390x844 (real Inter/Nunito)"** now pins the
design's own coordinates, in light **and** dark, straight from
`design/screens/*/P04-privacy.png` ÷3:

| Element | Measured | Design |
|---|---|---|
| back chevron centre | y 73 | 73 |
| h1 line box | y 107, 34 high | 107 (28/34) |
| standfirst | y 149, 24 high | 149 (16/24) |
| shield | y 187, 84×84 (centre 229) | 187 / 84 |
| promise rows | y 287, 343, 399, 455 — each 56 | 4 × 56 |
| tiles | 40×40, inset 8 (7 padding + 1 from centring) | tile tops 295/351/407/463 |
| list | y 287, 224 high | 287, 4 × 56 |
| opt card | y 527, 94 high | 527–621 |
| opt title | one 22 px line | one line (P04-10) |
| opt sub | 44 (two 15/22 lines) | two lines |
| bottom CTA | y 708 → 844, full width | owner bottom-edge rule |
| `Continue` | 52 high | 52 |
| gutters | 20 / 370 | 20 |

Every one of those is an exact match, so the screen is pixel-faithful at the
design width — and a 320 dp case asserts that wrapping (legitimate per
SPACING_SPEC §9.3) never breaks the structural identity.

## Finding

### P04-11 — Material's tracking leaks into 14 of 15 text runs (the P04-10 class, screen-wide) — MAJOR (latent)

- **Where:** the screen renders with `letterSpacing: 0.25` on the h1,
  standfirst, all 4 row titles, all 4 row subs, the opt sub, `Continue`, the
  footnote link and the dialog's 4 promise lines. Only
  "Optional: help improve Nestling" — the string 2b fixed for P04-10 — is 0.
  Source of the leak: `NestType` styles omit `letterSpacing` and inherit
  `true` (`app/lib/core/design_system/tokens/typography.dart:13-28`), so
  Material's `bodyMedium` tracking reaches every run. That is the shared half
  of `SHARED_REQUEST.md` §7, still open.
  Screen-side instances to fix: `app/lib/features/privacy_consent/presentation/views/privacy_consent_view.dart`
  (h1 line 60, standfirst line 70, row titles/subs lines 271/278, opt sub
  lines 143-149, footnote line 357) and the dialog body line 339.
- **Why it is a bug:** `design/html-source/components.css` sets
  letter-spacing **only** on `.display` and `.status-time`
  (`-.01em`); `.h1`, `.body`, `.body-s`, `.caption`, `.list-title`,
  `.list-sub`, `.opt-title`, `.opt-sub`, `.btn` and `.footnote` all take the
  browser default of 0. So the app's typography does not match the design.
- **Repro (test):**
  `app/test/features/privacy_consent/privacy_consent_geometry_test.dart`,
  group "P04 — letter-spacing contract (P04-10 class)" — 3 red tests (light,
  dark, dialog), each printing every offending run with its measured value.
- **Repro (app):** the effect is invisible in the current layout — the 390 dp
  geometry above is exact — but it is latent: 0.25 px × glyph count widened the
  opt title from 242.5 px to 250.2 px and wrapped it (P04-10). Any future copy
  change near a line budget now has the same failure mode, and the design's
  text is simply the wrong width everywhere.
- **Severity:** MAJOR by class (it already caused a 22 px layout regression),
  latent today — which is why it was invisible to the UI check at 390 dp.
- **Fix (not applied):** the RULES-legal local half 2b used —
  `copyWith(letterSpacing: 0)` on each run — or the preferred shared fix in
  §7: `NestType._inter/_nunito` default `letterSpacing: letterSpacing ?? 0`.
  `SHARED_REQUEST.md` §7 now carries the screen-wide measurement.

## Results

```
dart format --output=none --set-exit-if-changed .  → 375 files, 0 changed
flutter analyze                                    → No issues found! (ran in 3.9s)
flutter test test/features/privacy_consent/        → 00:04 +163 -3: Some tests failed.
flutter test (whole app)                           → 00:25 +827 -3: Some tests failed.
```

The 3 failures are exactly the letter-spacing contract above; the whole app is
otherwise green and nothing is skipped.

## Re-verified (unchanged from iteration 7)

Bloc (20) and repository (13) green: loading→loaded, empty stream, stream
error, both toggle directions, optimistic emit, revert-to-stored, error
clearing, transactional first-run upsert with last-write-wins, single-row and
idempotent writes, `Seed.empty` / `Seed.demo`. Views green in light + dark at
320/390/430 × 1.0/1.3: every tap destination, empty/loading/error/first-run
states, semantics labels and ≥ 44 px targets, separator overlay derived from
the design CSS, trash glyph path provenance, painted-pixel shield theming,
copy character-by-character, contrast, the 1.6 → 1.3 system-scale clamp,
token hygiene, bundled-font rules and the owner alignment/bottom-edge rules.
`[P04-10]` (title one line, card 94) is green again after the build's fix.

## Notes

- Loading the bundled faces in one test file does not change the other files:
  `FontLoader` is per-test-isolate, so the rest of the suite still measures
  with the harness font and keeps its relational assertions.
- Widget tests without `FontLoader` still render with the harness font, which
  wraps everything; absolute geometry belongs to
  `privacy_consent_geometry_test.dart` (real metrics) and the UI check.
- `SemanticsHandle` must be disposed inside the test body; Drift reads and
  `Picture.toImage` inside `testWidgets` need `tester.runAsync`.
- Light `lilac` on `lilacTint` measures 3.40:1 — compliant for the 24 px glyph
  and pinned by the contrast test; a shared palette value, so changing it is
  an orchestrator decision.

VERDICT: FAIL
