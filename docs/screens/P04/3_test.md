# P04 · Privacy consent — test notes (STAGE 3, iteration 7)

Feature `privacy_consent` · route `/privacy` · parent mode.
Scope this stage: `app/test/features/privacy_consent/**` + `docs/screens/P04/**`
(RULES §1). No production code touched; nothing patched.

Inputs re-verified: `1_plan.md`, `2_build.md` (iteration 7 integrate — both
builder halves made no production change; the only work was deleting the
`google_fonts` breakage the `1b2109e` main merge left in the test layer),
`4_review.md`, `5_ui.md`, `6_bugs.md`, `FIXES_6.md`, `SHARED_REQUEST.md` and
the mandatory `ORCHESTRATOR_NOTES.md` (12:03 / 13:42 / 15:27 updates) plus the
**FONTS rule** (google_fonts removed; Inter/Nunito are bundled assets).

## Test inventory — 159 P04 tests, 0 skipped

| File | Tests | Role |
|---|---|---|
| `privacy_consent_bloc_test.dart` | 20 | every event/state path of `PrivacyConsentBloc` |
| `privacy_consent_repository_test.dart` | 13 | Drift contract on the in-memory DB (`Seed.demo` / `empty` / `fresh`) |
| `privacy_consent_view_test.dart` | 27 | copy, light+dark, 320/390/430 × 1.0/1.3 matrix, statuses, navigation, a11y, gutters, bottom edge |
| `privacy_consent_view_contract_test.dart` | 39 | states through the real router, every tap destination, optimistic switch, failure captions, separator overlay, row glyphs, nav geometry, dialog stress, short screens, alignment |
| `privacy_consent_copy_test.dart` | 5 | copy fidelity against the HTML design source (COPY rule) |
| `privacy_consent_artwork_test.dart` | 11 | artwork provenance + painted-pixel theme proof |
| `privacy_consent_a11y_test.dart` | 28 (3 new this stage) | contrast, system text scale, screen-reader shape, token hygiene, **bundled-font rules** |
| `p04_bugs_test.dart` | 16 | the nine bug proofs + clean-behaviour guards |

## What this stage did

The build stage had already removed the `google_fonts` imports and
`GoogleFonts.config.allowRuntimeFetching` calls (deletions only, no assertions
touched), so the suite compiled again. This stage verified the merged tree and
then made the **FONTS rule self-enforcing**, because "never import
google_fonts" is a rule that fails silently if someone re-adds the dependency.

### New — group "P04 — bundled fonts (orchestrator FONTS rule)"

- `no feature source or test touches google_fonts` — scans **both**
  `lib/features/privacy_consent/**` and `test/features/privacy_consent/**` for
  the package name or `GoogleFonts`, and fails with the exact file:line. It
  skips only its own file (which must name the banned API in order to search
  for it), and is guarded to have read at least ten files so it cannot pass by
  scanning nothing.
  *Teeth check:* dropping a one-line `// google_fonts` file into the test
  directory made it fail with that exact path and line; the file was removed
  and the guard returned green.
- `the type scale resolves to the bundled families` — `NestType.body`,
  `bodyStrong` and `caption` resolve to `Inter`; `h1` and `h3` to `Nunito`.
  This is what the merged `typography.dart` now does with `TextStyle`
  `fontFamily` instead of `GoogleFonts.inter(...)`, so it pins the replacement
  rather than the API that was deleted.
- `every bundled font asset in pubspec exists on disk` — parses
  `pubspec.yaml`'s `fonts:` block and asserts each referenced TTF exists and is
  non-trivial in size. A renamed or deleted font asset is otherwise invisible
  until the app runs on a device.

### Re-verified after the font merge (no regression, 131 pre-existing tests green)

- **Fonts in the harness:** measured, not assumed — the type scale now resolves
  to Inter, but `flutter_test` still does not load bundled font assets, so rows
  still wrap (measured 96–118 px instead of 56). The suite's "scroll the opt
  card into reach before tapping" helper and its "never assert absolute row
  heights in a widget test" rule therefore stay correct; the device
  measurement remains the UI check's job.
- Bloc (20), repository (13), view (27), contract (39), copy (5), artwork (11):
  all green, including the design-CSS-derived separator geometry, the trash
  glyph path provenance, the painted-pixel theme proof for the shield, the
  contrast matrix, the 1.6 → 1.3 system-scale clamp and the screen-reader
  shape.

## Results

```
dart format --output=none --set-exit-if-changed .  → 372 files, 0 changed
flutter analyze                                    → No issues found! (ran in 4.4s)
flutter test test/features/privacy_consent/        → 00:06 +159: All tests passed!
flutter test (whole app)                           → 00:23 +809: All tests passed!
```

Zero failures, zero skips. `--run-skipped` is a no-op, so nothing can hide
behind a skip.

## Bugs found this iteration

**None.** No defect surfaced in the iteration-7 tree; the font migration left
no behavioural change on this screen (the screen never referenced GoogleFonts
itself — only the tests did).

## Open items

None in P04 scope. P04-1 … P04-9 are fixed and green; `SHARED_REQUEST.md`
§1/§2/§6 are consumed and §4's P16 half was never this screen's to fix.
Orchestrator notes 1–4 hold, COPY is still locked to the HTML source, CHILD
ORDER and PIP are N/A for this screen.

## Notes (carried forward)

- Widget tests still render with the harness font, not bundled Inter/Nunito;
  helpers scroll with `ensureVisible` before tapping the toggle, and absolute
  row heights stay a device (UI-check) measurement.
- Light `lilac` on `lilacTint` measures 3.40:1 — compliant for the 24 px glyph
  (WCAG 1.4.11, 3:1) and pinned by the contrast test; a shared palette value,
  so changing it is an orchestrator decision, not P04's.
- `SemanticsHandle` must be disposed inside the test body; Drift reads and
  `Picture.toImage` inside `testWidgets` need `tester.runAsync`; a
  `Future.delayed` must never outlive a test.
- The copy, separator, artwork, hygiene and font tests read
  `design/html-source/**`, `lib/**` and `pubspec.yaml` at runtime and fail
  loudly with the searched paths if the layout changes — never silently.

VERDICT: PASS
