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

VERDICT: FAIL