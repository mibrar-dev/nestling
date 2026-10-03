# Fix list after iteration 8

## From 3_test.md
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


## From 4_review.md
# P04 · Privacy consent — QA code review (STAGE 4, iteration 8)

Feature `privacy_consent` · route `/privacy` · parent mode · branch `screen/P04`.
Reviewed surface: `git diff main...HEAD` at `9ee096b` (iteration-8 build
checkpoint), plus the uncommitted working tree refresh of the brief markers
and `privacy_consent_a11y_test.dart`, plus the working-tree-only
`privacy_consent_geometry_test.dart`.

Checks run for this review:

```
dart format --output=none --set-exit-if-changed lib/features/privacy_consent \
     test/features/privacy_consent        → 20 files, 0 changed
flutter analyze  (whole app)              → No issues found! (ran in 4.8s)
flutter test test/features/privacy_consent/
     → 00:04 +163 -3: Some tests failed.
     3 failures, all in privacy_consent_geometry_test.dart:
       1. "light: every rendered run has no tracking" (line ~235)
       2. "dark: every rendered run has no tracking"  (line ~235)
       3. "the Privacy Notice dialog copy has no tracking either" (line ~265)
```

grep sweeps:

```
grep -rln "google_fonts\|GoogleFonts" app/lib/features/privacy_consent \
     app/test/features/privacy_consent app/pubspec.yaml app/test/test_scope.dart
→ no hits (font rule has been enforced code-side; iteration-6 finding closed)
grep "skip: true" app/test/features/privacy_consent/*.dart
→no hits (0 skips across the feature)
```

## Findings

### 1. MAJOR — three failing widget tests: every text run on the screen inherits Material's default letter-spacing instead of 0

- **Where:** `app/test/features/privacy_consent/privacy_consent_geometry_test.dart`
  (untracked but still discovered by `flutter test`), assertions at
  **lines ~235, ~235, ~265** (`offenders` is not empty).
- **Why:** the live `NestType` styles in
  `app/lib/core/design_system/tokens/typography.dart` omit `letterSpacing` and
  the Flutter `DefaultTextStyle` inherited by the privacy screen carries
  Material's `bodyMedium` tracking. That 0.25 px tracking reaches every
  rendered run except the one local override applied in
  `privacy_consent_view.dart:129-141` (the opt-card title's copyWith now has
  `letterSpacing: 0`). The geometry test correctly identifies every other
  affected run: h1, standfirst, row titles/subtitles, opt-card subtitle, and
  the dialog copy.
  **Evidence:**

  ```
  flutter test test/features/privacy_consent/privacy_consent_geometry_test.dart
  → 00:04 +163 -3: Some tests failed.
  Failing: light: every rendered run has no tracking,
           dark: every rendered run has no tracking,
           the Privacy Notice dialog copy has no tracking either.
  ```

- **Impact:** `flutter test` is red on the feature and (being discovered) on
  the whole app; whenever `flutter_test`'s default font is replaced or the
  bundled fonts are used, the line boxes measured by this test drift
  roughly the same way P04-10 manifests. This is a real end-user alignment
  defect on the screen, not a flaky harness.
- **Fix (one of the two, please execute):**
  - **In-scope P04 workaround** — mirror the opt-card-title patch across all
    tracked text runs in the feature:
    1. `privacy_consent_view.dart:64` h1: `style: context.nestText.h1` →
       `context.nestText.h1.copyWith(letterSpacing: 0)`.
    2. `::70` standfirst: `NestType.body(color: tokens.ink2)` →
       `NestType.body(color: tokens.ink2).copyWith(letterSpacing: 0)`.
    3. `::128` opt-card title: it already zeros tracking — keep it.
    4. `::149` opt-card subtitle: wrap `NestType.bodySmall(...)` in
       `.copyWith(letterSpacing: 0)`.
    5. `::176-186` failure caption: wrap `NestType.caption(...)` similarly.
    6. `::282` row title (`_PromiseRow`): append `letterSpacing: 0` in the
       existing copyWith chain.
    7. `::289` row subtitle and `::335` dialog promise ("Privacy Notice"):
       zero through copyWith; also the `::353` footer link's
       `NestType.caption(...).copyWith(…)`.
       Then the feature suite goes0-failure.
  - **Shared/root fix** — in `app/lib/core/design_system/tokens/typography.dart`
    add `letterSpacing: 0` to every parent `TextStyle` produced by `_inter` /
    `_nunito` helpers (six sites), because the design HTML sets tracking
    only on `.display`/`.status-time`. That is a core change, so keep
    SHARED_REQUEST §7 filed and the local workaround above is still
    necessary on this branch for the opt-card title line box until the
    shared fix lands.

- Note for the loop: the file is currently only untracked — it still runs via
  discovery. Either it lands in a commit that resolves the issue, or the test
  is moved behind a clearly marked `@Skip`/quarantine while SHARED_REQUEST §7
  stays open. It may not keep failing in the CI default run.

### 2. MINOR — zz_probe was deleted but left no sign, while the geometry test that would replace it is untracked

- **Where:** filesystem (`app/test/features/privacy_consent/`), working tree
  only. `zz_probe_test.dart` is gone from disk; its replacement
  `privacy_consent_geometry_test.dart` is present and failing (see finding 1).
- **Why:** the loop's agent dropped the probe into the tree without
  committing its replacement; leaving a failing untracked test behind means CI
  and any checkout catching a run will also hit finding 1.
- **Fix:** either track the geometry test along with the finding-1 fix, or
  remove/iterate it out of the tree. Match the Stage 2/6 "sign off on test"
  convention by committing the associated proof once green.

### 3. MINOR — `privacy_consent_a11y_test.dart:311-334` embeds the literal strings it asserts are absent

- **Where:** `app/test/features/privacy_consent/privacy_consent_a11y_test.dart:311-334`
  (the `'google_fonts'` / `'GoogleFonts'` grep filter inside its own
  no-google-fonts allowlist).
- **Why:** the feature test directory therefore contains false-positive
  literals that a plain `grep -rn "google_fonts|GoogleFonts"` will surface —
  that's what confused my first grep, which returned 5 hits in P04 when the
  code is genuinely clean. The test is green because its own scanner is
  intentionally blunt, but automation tooling and humans reading the tree
  will flag it repeatedly.
- **Fix:** either accept the blunt scanner and document the false positives
  in the rule he meets, or build the literal from pieces
  (`'google' + '_fonts'`, `'Google' + 'Fonts'`) before matching.

### 4. MINOR — loop bookkeeping (not a code defect)

- `git log` still carries `3944935 P04: loop iteration 7 (... ui=FAIL bugs=FAIL)`
  in its subject, while the loop moved on to iteration 8 without writing an
  equivalent "iteration 7 final" line. Stage 5/6 for iteration 8 should
  produce thoseverdicts; this is loop-metadata only.

## Verified passing (no action)

- All other checks from iteration 7 are still valid for this tree:
  `dart format`: 20 files, 0 changed; `flutter analyze`: No issues found;
  `[P04-2]`/`[P04-7]` are un-skipped and green; the parent loop marker
  reads `build=PASS review=PASS` (docs regenerated at iteration 5/6).
- Copy / design rules: the `privacy_consent_copy_test.dart` token walk still
  asserts the screen matches the HTML source (curly quotes, em dashes).
- Owner bottom-edge rule: `_7` shot confirms the CTA surface runs to the
  physical edge in both themes (dark `#1F1C2E`, light `#FFFFFF`).

## Open shared dependencies (owner: orchestrator)

- SHARED_REQUEST §7 — the shared-side letter-spacing fix in `NestType`
  (core path, off-limits to this feature). The working tree already contains
  the request marker.
- Loop carry-overs: iteration-7's `ui=FAIL bugs=FAIL` is split between
  stages 5/6, which iteration 8 still has to close.

