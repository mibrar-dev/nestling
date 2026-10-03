# P04 · Privacy consent — QA code review (STAGE 4, iteration 7)

Feature `privacy_consent` · route `/privacy` · parent mode · branch `screen/P04`.
Reviewed surface: `git diff main...HEAD` at `4b6a61a` plus the uncommitted
working-tree build notes (iteration-7 build checkpoint `4b6a61a` and the
dec 3, 2026 docs/screenshots refresh). `main` is ahead on shared work by the
K03 merge (`HEAD..main`: 7 commits), so this screen is behind main — per
ORCHESTRATOR_RULES that is a process note, not a finding.

Checks run for this review:

```
dart format --output=none --set-exit-if-changed lib/features/privacy_consent \
     test/features/privacy_consent        → 19 files, 0 changed
flutter analyze  (whole app)              → No issues found! (ran in 4.7s)
flutter test test/features/privacy_consent/ → 00:04 +159: All tests passed!
flutter test (whole app)                  → 00:22 +809: All tests passed!
```

Grep check sweeps the thing the iteration-6 verdict claimed was violated:

```
grep -rln "google_fonts\|GoogleFonts" \
    app/lib/features/privacy_consent app/test/features/privacy_consent
→ no files
grep -rn "google_fonts\|GoogleFonts" \
    app/pubspec.yaml app/test/test_scope.dart
→ no lines
```

Iteration-7 UI check (Stage 5) artifacts `ui/app_{light,dark}_7.png` and
`ui/cmp_{light,dark}_7.png` exist. The committed `docs/screens/P04/5_ui.md`
is still dated iteration 5, but that isloop-bookkeeping: the branch tip's
rendering numbers and token-match notes from the previous stage match
what `_7` shots show. If that file is expected to be refreshed, do it in
Stage 5's output slot, not here.

## Findings

### 1. MINOR — stale test instruction survives in the plan

- **Where:** `docs/screens/P04/1_plan.md:145` — the plan still tells readers
  "Every app-pumping test ends with `disposeApp(tester)`;
  `GoogleFonts.config.allowRuntimeFetching = false`."
- **Why:** `google_fonts` is gone from pubspec and from every test file.
  A future reader following the plan will import a package that no longer
  exists and call a symbol that no longer compiles. The directive in
  ORCHESTRATOR_RULES ("never import google_fonts or call GoogleFonts.*")
  is enforced everywhere in code, but the plan text contradictsit.
- **Fix:** in `docs/screens/P04/1_plan.md:145` drop the clause after the
  semicolon and append: "Fonts render from bundled assets via `NestType`;
  no runtime fetch, no `GoogleFonts.*` in tests." Everything else in the
  plan already matches the shipped code.

No blocker or major findings. Everything else from iteration 6's review has
been addressed on this tip.

### Closed since iteration 6

- **FONTS rule (was iteration 6's MAJOR, blocked merge):** the four
  pre-existing feature test files had their `import 'package:google_fonts/
  google_fonts.dart';` lines removed, every
  `GoogleFonts.config.allowRuntimeFetching = false;` call removed (including
  `privacy_consent_view_contract_test.dart`'s 5 call sites and the stale
  comment line), and `2a_build_logic.md` / `2b_build_ui.md` document the
  sorts: `privacy_consent_view_test.dart`,
  `privacy_consent_view_contract_test.dart`,
  `privacy_consent_copy_test.dart`, `p04_bugs_test.dart`. Whole-app
  `flutter analyze` is clean, i.e. nothing danglingin the tree.
- Stale TODO(P04) claim in `privacy_consent_view_test.dart:8` — fixed in
  iteration 6, still fixed.
- `[P04-2]` / `[P04-7]` proofs un-skipped and green since iteration 5; with
  this cleanup the P04 suite runs 159/159 with 0 skips.

## Verified correct (no action)

- **Architecture:** unchanged shape — `domain/` is still entity + abstract
  repository only; `data/` still one impl; `bloc/` per screen with
  `LoadRequested`/`CrashToggled`; DI (`PrivacyConsentRouteNames`,
  `addRoutes` in `privacy_consent_di.dart`) and route constant unchanged;
  no `Feature` folders invented.
- **RULES §1:** `git diff main...HEAD` touches only
  `app/lib/features/privacy_consent/**`, `app/test/features/privacy_consent/**`,
  and `docs/screens/P04/**` (plus the four loop markers). No core, no router,
  no shared path edits.
- **Design-system usage:** the view still renders through `NestPrivacyShield`,
  `NestIcons.trash`, `NestList`, `NestCard`, `NestToggle`, `NestButton`,
  `NestBottomCta`, `NestSpacing` tokens only; the one duplicated HOC detail
  fromiteration 4 (nested `NestList` of single Column) is gone.
- **DESIGN_SPEC §5 P04 / COPY:** copy is unchanged since earlier stages —
  `privacy_consent_copy_test.dart` still walks the HTML source token by token
  (U+2019, U+2014 everywhere), and P04 tests only fail if the design copy
  drifts.
- **Accessibility:** the new `privacy_consent_a11y_test.dart` (25 tests)
  asserts WCAG luminance pairs (text ≥ 4.5:1, 24 px tile glyphs ≥ 3:1 per
  WCAG 1.4.11) in light and dark, one header node before thepromise rows,
  every interactive control labelled, >= 44 px targets, and that a 1.6
  system text scale is clamped to 1.3 without breaking layout. Theshield
  keeps its image semantics node with the design's alt text.
- **Performance:** production surface is a two-line wire-up on a tree that
  already ran at iteration-5/6 quality; `const` where possible, no new
  streams, `emit.forEach` still disposed on `BlocProvider` teardown (the
  write-after-close proof remains green). No production-code diff this
  iteration beyond what stage 2a/2b recorded — so performance inherits
  the already-verified behavior.
- **Error handling:** first-run upsert is transactional, the failure caption
  is state-aware, and a stale `errorMessage` is cleared by the next successful
  stream emission — all three pinned by bloc/repository tests that run green.
- **Children's Code:** no analytics/ads/trackers in the diff; no child data
  reads; the only write is the optional, default-OFF crash-report consent
  flag on `settings.crashReportConsent`; kid mode is still redirected from
  `/privacy` to `/parental-gate` (green proof).
- **Owner rules:** bottom `NestBottomCta` surface runs to the physical edge
  in both themes (`#1F1C2E` dark / `#FFFFFF` light); alignment holds —
  header band, card gutters, and list bottoms at Δ0 against the design.

## ORCHESTRATOR_NOTES status

| Item / update | Status |
|---|---|
| 1 — red-ink bin glyph + glyph test | **Met** — wired in iteration 5, pinned by `privacy_consent_artwork_test.dart` and the refreshed a11y test |
| 2 — header block ≈ design | **Met** — probes Δ0 since the shared nav fix |
| 3 — list rows / divider → opt card ≈528 | **Met** — owned by shared `NestList` overlay; pixel-exact |
| 4 — bottom panel to edge, perfect alignment | **Met** both themes; compared against `_7` sheets |
| 12:03 / 13:42 / 15:27 UPDATEs | Superseded — all reached by iteration 5/6 |
| COPY rule | **Met** |
| CHILD ORDER rule | N/A |
| FONTS rule | **Met** this iteration (the iteration-6 blocker) |

VERDICT: PASS