# P04 · Privacy consent — QA code review (STAGE 4, iteration 6)

Feature `privacy_consent` · route `/privacy` · parent mode · branch `screen/P04`.
Reviewed surface: `git diff main...HEAD` plus the uncommitted working-tree
build: one stale-comment fix in `privacy_consent_view_test.dart`, the new
`privacy_consent_a11y_test.dart`, no production-code change, new `_6`
screenshots, refreshed stage notes.

Checks run for this review:

```
dart format --output=none --set-exit-if-changed lib/features/privacy_consent \
     test/features/privacy_consent        → 19 files, 0 changed
flutter analyze                            → No issues found! (ran in 3.5s)
flutter test test/features/privacy_consent/ → 00:03 +156: All tests passed!
flutter test  (whole app)                  → 00:29 +684 ~0: All tests passed!
compare.py vs ui/app_light_6.png            → matches the iteration-5 sheet
                                            (light 4.08%, dark 3.98%)
```

## Findings

### 1. MAJOR — P04's feature tests still import `google_fonts` and call `GoogleFonts.*` — the new mandatory FONTS rule is not enforced

The orchestrator's standing rule for this stage is now: "google_fonts was
removed (Inter/Nunito are bundled assets). **Never import google_fonts or call
`GoogleFonts.*` in code or tests; delete any such lines in your feature's
tests.**" The new `privacy_consent_a11y_test.dart` honors it (all bundled-asset
fonts, no runtime fetch), but the four pre-existing feature test files keep the
old pattern:

- `app/test/features/privacy_consent/p04_bugs_test.dart:36` —
  `import 'package:google_fonts/google_fonts.dart';`; and
  `:166` — `GoogleFonts.config.allowRuntimeFetching = false;`
- `app/test/features/privacy_consent/privacy_consent_view_contract_test.dart` —
  `:15` (stale header comment — "GoogleFonts runtime fetching is off in tests"),
  `:28` import, and five call sites (`:475`, `:600`, `:652`, `:702`, `:1389`).
- `app/test/features/privacy_consent/privacy_consent_view_test.dart:18` (import),
  `:99`, `:243` (call sites).
- `app/test/features/privacy_consent/privacy_consent_copy_test.dart:21` (import),
  `:279` (call site).

**Concrete fix:** in each of the four files delete the
`import 'package:google_fonts/google_fonts.dart';` line and every
`GoogleFonts.config.allowRuntimeFetching = false;` line, and in
`privacy_consent_view_contract_test.dart` rewrite the header comment at `:15`
to drop the `GoogleFonts runtime fetching is off in tests` clause. The fonts
used by the widgets are the bundled Inter/Nunito from `NestType`
(`tokens/typography.dart` — main commit `a4691f9`), so no replacement lines
are required; the block-test-font caveat in the comment still applies, just
without naming GoogleFonts. `app/test/test_scope.dart:15,24` still sets the
same line, but it sits outside RULES §1 (`app/test/**` is shared) — it will
clear when the branch merges main, and deleting the four feature-file call
sites first keeps P04 consistent with the rule without forking shared code.

## Disposition of iteration-5 findings

- Minor "stale header comment in the widget contract test" — **fixed**:
  `privacy_consent_view_test.dart:8` now reads "All four promise rows render
  the shared tinted glyph in both themes (`privacy_consent_artwork_test.dart`)."

## Verified correct (no action)

- **Architecture:** unchanged and compliant — feature-first; `domain/` is still
  entity + abstract repository only; one bloc per screen; DI + routes per
  feature; no production-code delta this iteration except the one-line comment
  fix in the view test.
- **RULES §1:** the only tree edits are inside
  `app/lib/features/privacy_consent/**`, `app/test/features/privacy_consent/**`
  and `docs/screens/P04/**`. `AppIos/Podfile.lock` changes are the loop's
  reconciliation with main (the lockfile there already records
  `flutter_timezone` from main) — `git diff main` on it is empty.
- **Design-system usage:** the new a11y test asserts token hygiene directly
  (the sole `Color(0x` in the feature is the transparent `Paint()` in an
  artwork-test helper — a test harness colour, not UI); the view still paints
  only `NestColors`-palette colours; every colour a11y-tested pair is a named
  token. No new literals in the feature sources.
- **DESIGN_SPEC §5 P04 / COPY:** copy still decoded-to-match from the HTML
  source through `privacy_consent_copy_test.dart`; `privacy_consent_artwork_test.dart`
  re-asserts the trash `<path d>` and the shield `NestPrivacyShield` swap in
  both themes.
- **Accessibility:** the new `privacy_consent_a11y_test.dart` (25 tests) covers
  per-theme contrast on every painted pair (text ≥ 4.5:1, the 24 px tile glyphs
  ≥ 3:1 per WCAG 1.4.11), screen-reader shape (one header, all controls
  labelled, promise rows not announced as buttons), a 1.6 system text scale
  clamped to 1.3 still rendering without overflow, and the shield announcing
  as an image.
- **Performance:** no new production code paths; the only source delta is the
  comment fix, so the runtime is unchanged from iteration 5 (cached
  `const Center(NestPrivacyShield(...))`, no SVG decode on toggle rebuilds).
- **Error handling:** unchanged (transactional first-run upsert, state-aware
  failure caption, no new write surface anywhere in the feature).
- **Children's Code:** unchanged — parent-mode onboarding surface, no
  analytics/ads/trackers, one optional default-OFF consent flag, kid-mode
  redirect proof remains green.
- **Owner rules:** bottom CTA surface runs to `y=844` in both themes
  (`#FFFFFF` light / `#1F1C2E` dark), rows and cards aligned to the 20 px
  gutter at 320/390/430, header block pixel-exact (`66–80` / `113–138` /
  `156–170`), list and opt card at design heights, trash tile ink `#B44A1F`,
  dark shield disc `#1A2A4A`.

## ORCHESTRATOR_NOTES status

| Item / update | Status |
|---|---|
| 1 — red-ink bin glyph + all-four-rows glyph test | **Met** (`NestIcons.trash`, `--a-peach` ink, pinned in both themes) |
| 2 — header block | **Met** — Δ0 against the design |
| 3 — rows/dividers, opt card ≈528 | **Met** — pixel-exact |
| 4 — bottom panel to edge, alignment | **Met** both themes |
| 15:27 UPDATE — "design pixels #BA562E" | Shipped token equals design CSS token (`--a-peach` = `#B44A1F`), which is the design's rendered core ink; the note's hand probe was an antialiased edge — no action |
| COPY rule | **Met** and locked by `privacy_consent_copy_test.dart` |
| CHILD ORDER rule | N/A — no children on this screen |
| FONTS rule (this stage) | **Unmet** in the four pre-existing feature test files → finding 1 |

VERDICT: FAIL