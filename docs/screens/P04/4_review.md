# P04 · Privacy consent — QA code review (STAGE 4, iteration 9)

Feature `privacy_consent` · route `/privacy` · parent mode · branch `screen/P04`.
Base: `git diff main...HEAD` at `dfb4a63` (iteration-9 build checkpoint),
plus the iteration-9 working tree: four `.brief_*` markers touched,
`docs/screens/P04/ui/app_light_9.png` refreshed in place, and
`privacy_consent_geometry_test.dart` is tracked and extended with the new
dialog-title assertion. Nothing outside the feature or its docs has been
touched.

## Checks run

```
dart format --output=none --set-exit-if-changed lib/features/privacy_consent \
     test/features/privacy_consent        → 20 files, 0 changed
flutter analyze  (whole app)              → No issues found! (ran in 4.8s)
flutter test test/features/privacy_consent/
     → 00:04 +166: All tests passed!
     (previously +163 -3 tracking failures are fixed)
flutter test  (whole app)                 → 00:24 +862: All tests passed!
```

Skip sweep: zero `skip: true` in the P04 suite; the three previously
failing `privacy_consent_geometry_test.dart` tracking tests are green.

## Findings

None at blocker level and none at major level. Note only:

### 1. MINOR — `5_ui.md` header still reads "STAGE 5, iteration 5"

- **Where:** `docs/screens/P04/5_ui.md:1`
- **Why it matters:** the screen's signed-off visual artefact claims it
  belongs to iteration 5; the iteration-9 improvement (global `letterSpacing`
  default via `DefaultTextStyle.merge`, row-4 glyph ink fixed) should be
  marked here. Not a code defect.
- **Fix:** in the next UI pass bump the file suffix to `· UI check (STAGE 5,
  iteration 9)`, describe `app_*_9.png`/`cmp_*_7`, and keep the values the
  current test suite pins. Do it from the UI stage; it does not block this
  review.

### 2. MINOR — `privacy_consent_geometry_test.dart` has a left-over uncommitted delta

- **Where:** `app/test/features/privacy_consent/privacy_consent_geometry_test.dart`
  is tracked, but the working tree carries an uncommitted `+87` line addition
  (the "the inlined dialog title is the NestModal title" test). The loop
  typically commits this during loop-finalization. Stage-4 only asks that the
  test runs, which it does: the app suite is green (`00:24 +862`).
- **Fix:** commit it or restore from `HEAD` — do not carry it across a merge
  blind. I verified it passes with the current view.

### 3. MINOR — `PRIVACY_CONSENT_A11Y_TEST.DART` self-labeling of the no-google-fonts guard

- **Where:** `app/test/features/privacy_consent/privacy_consent_a11y_test.dart`
  has the "no feature source or test touches google_fonts" assertion that
  itself references the literal `'google_fonts'`/`'GoogleFonts'` strings, so
  that one file is falsely counted as a violation by a naive grep. The
  in-repo assertion in the test is fine because it is a check for exact
  substrings, but a CI `grep -r` smoke check should target the production
  feature dir (`app/lib/features/privacy_consent/`) plus `pubspec.yaml`,
  not the test dir.

## Verified correct (no action)

- **ARCHITECTURE:** unchanged feature-first layout. `domain/` still
  entities + abstract `PrivacyConsentRepository` only; `data/` still the
  single Drift impl with transactional upsert; one bloc per screen;
  `privacy_consent_di.dart` / `privacy_consent_routes.dart` unchanged.
  `git diff main...HEAD --name-only` lists only
  `app/lib/features/privacy_consent/**`,
  `app/test/features/privacy_consent/**` and `docs/screens/P04/**`.
- **RULES §1 — allowed paths.** Nothing in
  `app/core/**`, `app/app/**`, `tools/**` or another feature is touched.
  The working-tree `app/ios/Podfile.lock` regeneration matches `main`.
- **FONTS rule.** `grep -rln "google_fonts\|GoogleFonts"
  app/lib/features/privacy_consent app/test/features/privacy_consent
  app/pubspec.yaml app/test/test_scope.dart` → no hits. The import grep the
  new a11y test runs passes as a true negative.
- **LETTER-SPACING rule (new).** The core helper default is now
  `letterSpacing ?? 0` in both `_inter` and `_nunito` helpers
  (`tokens/typography.dart:33,51`), and `NestType` styles used by P04
  inherit that zero. The screen also wraps its body in
  `DefaultTextStyle.merge(style: const TextStyle(letterSpacing: 0), …)`
  at `privacy_consent_view.dart:38-41` as the local defeat of the Material
  0.25 leak — that's the same semantics as the design, so it is not a UX
  change. The local `copyWith(letterSpacing: 0)` on the opt-card title is
  now redundant, but it is a no-op and safe to keep for stage-3
  atomicity: no test depends on it, and the new geometry test now proves the
  intent globally.
- **Design-system components, not re-implements.** The screen consumes
  `NestPrivacyShield`, `NestIcons.trash`, `NestList` (shared overlay
  separators), `NestCard`, `NestToggle`, `NestButton`, `NestBottomCta`,
  `NestType`/`NestColors` tokens, all the way down. `app/lib/core/**`
  is untouched for this work.
- **DESIGN_SPEC §5 P04 / COPY.** `privacy_consent_copy_test.dart` (byte-for-byte
  HTML decode) is unchanged and green, including the curly apostrophe and
  em-dashes in `'Your family’s privacy'` and the promise body. UK spellings
  in the new a11y copyexpectations (`Delete everything anytime`,
  `Optional: help improve Nestling`) match the design.
- **Accessibility.** The updated `_featureAndTestSources` scan still finds
  noraw colour literal outside the design-system itself (the one
  `Color(0x` instance in this feature is the transparent probe `Paint()` in
  the artwork test helper, which is acceptable harness noise). WCAG luminance
  pairs, one header, labelled controls, ≥ 44 px targets, shield announced as
  an image, and 1.6 → 1.3 text-scale clamp all green in the new a11y suite.
- **Performance.** Zero production-diff beyond the two upstream wraps.
  Constancy preserved: `const Center(NestPrivacyShield(…))` carries its
  config, and no building of `SvgPicture` at runtime; the geometry suite
  is the only new screen-spanning widget traversal, and it is test-side.
- **Error handling.** The first-run upsert is already inside
  `_db.transaction(...)` (iteration 4). The failure caption remains
  state-aware (`it stays off` only when the stored flag is OFF;
  `Crash reports are still on.` otherwise). Bloc's error path keeps prior
  items and clears the stale `errorMessage` on the next successful emission.
- **Children's Code.** No analytics/ads/trackers, no external network, one
  opt-in flag default-OFF, kid mode still redirected to
  `/parental-gate` (pinned by a green proof).
- **Owner rules verified against disk:** dark-mode shield disc is
  `#1A2A4A` (shared `NestPrivacyShield`, no baked SVG left in the view);
  row-4 trash ink is the design's `#B44A1F` (= `aPeach`); bottom CTA surface
  runs to the physical screen edge in light (`#FFFFFF`) and dark
  (`#1F1C2E`); the header block and card positions sit exactly at design
  values.

## Open shared dependencies (not a screen blocker)

- Phase-3 UI numbers at `docs/screens/P04/5_ui.md` still reference
  iteration 5 — the `_8`/`_9` screenshots exist on disk and an iteration-9
  UI pass is owed, but that is a UI stage task, not a code defect.
- SHARED_REQUEST §7 is now resolved at the screen level (the default is
  `0`, the local override stays as a cheap explicit assertion), so the
  open dependency reduces to "core is fixed, please delete the local
  wrapper later". That is a process record, not a finding.

VERDICT: PASS