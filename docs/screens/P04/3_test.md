# P04 · Privacy consent — test notes (STAGE 3, iteration 6)

Feature `privacy_consent` · route `/privacy` · parent mode.
Scope this stage: `app/test/features/privacy_consent/**` + `docs/screens/P04/**`
(RULES §1). No production code touched; nothing patched.

Inputs re-verified: `1_plan.md`, `2_build.md` (iteration 6 — no production
change, every FIXES_5 wire-up verified present), `4_review.md`, `5_ui.md`,
`6_bugs.md`, `FIXES_5.md`, `SHARED_REQUEST.md` and the mandatory
`ORCHESTRATOR_NOTES.md` (12:03 / 13:42 / 15:27 updates).

Because the build introduced no new rendering surface, this stage went after
the parts of the contract that were still **asserted by prose rather than by a
test**: contrast, the system text-scale clamp, screen-reader shape and the
"tokens only" rule.

## Test inventory — 156 P04 tests, 0 skipped

| File | Tests | Role |
|---|---|---|
| `privacy_consent_bloc_test.dart` | 20 | every event/state path of `PrivacyConsentBloc` |
| `privacy_consent_repository_test.dart` | 13 | Drift contract on the in-memory DB (`Seed.demo` / `empty` / `fresh`) |
| `privacy_consent_view_test.dart` | 27 | copy, light+dark, 320/390/430 × 1.0/1.3 matrix, statuses, navigation, a11y, gutters, bottom edge |
| `privacy_consent_view_contract_test.dart` | 39 | states through the real router, every tap destination, optimistic switch, failure captions, separator overlay, row glyphs, nav geometry, dialog stress, short screens, alignment |
| `privacy_consent_copy_test.dart` | 5 | copy fidelity against the HTML design source (COPY rule) |
| `privacy_consent_artwork_test.dart` | 11 | artwork provenance + painted-pixel theme proof |
| `privacy_consent_a11y_test.dart` | 25 **(new)** | contrast, system text scale, screen-reader shape, token hygiene |
| `p04_bugs_test.dart` | 16 | the nine bug proofs + clean-behaviour guards |

## Tests added this iteration — `privacy_consent_a11y_test.dart`

### 1. WCAG contrast for every colour pair the screen paints

The design spec claims "token pairs only … sky-on-surface link ≥ 4.5:1" and
nothing asserted it. Nine pairs × both themes, computed with the WCAG 2.x
relative-luminance formula from `Color.computeLuminance()`:

| Pair (both themes) | light | dark | floor |
|---|---|---|---|
| h1 + row titles — ink on paper | 15.45 | 16.30 | 4.5 |
| standfirst + row subs — ink2 on paper | 8.31 | 10.84 | 4.5 |
| failure caption — danger on paper | 4.74 | 7.26 | 4.5 |
| footnote link — sky on surface (13 px) | 5.48 | 7.14 | 4.5 |
| dialog promises — ink2 on surface | 8.87 | 9.82 | 4.5 |
| no-ads glyph — leafInk on leafTint | 7.12 | 8.47 | 3.0 |
| person glyph — lilac on lilacTint | **3.40** | 5.93 | 3.0 |
| pin glyph — sky on skyTint | 4.73 | 6.12 | 3.0 |
| trash glyph — aPeach on peachTint | 4.69 | 8.31 | 3.0 |

Text pairs use WCAG 1.4.3 (4.5:1); the 24 px tile glyphs use 1.4.11 for
meaningful non-text graphics (3:1). A separate test requires light and dark to
**differ** for every token the screen paints, so a test that only inspects one
palette cannot pass while the other ships a hard-coded colour.

Teeth check: raising the icon floor to 4.5 made exactly the lilac pair fail
(`3.399…`), then it was reverted — the assertions are real, not vacuous.

### 2. System text scale above the design-system clamp

A parent with large system text reports 1.6; `NestlingApp` clamps the ambient
scaler to 1.0–1.3 (SPACING_SPEC §10). New tests assert, in both themes:

- the effective scaler at the headline really is **1.3**, read from the widget
  context (`MediaQuery.textScalerOf(...).scale(1)`), so a future clamp change
  that breaks the screen's 1.3 layout is visible;
- the screen still renders head, rows and `Continue` with no exception;
- at **320 dp with a 1.6 system scale** the opt card and the toggle stay
  reachable — scrolled into view, tapped, and the opt-in persists.

### 3. Screen-reader shape

One header node on the h1; each promise row is a single merged node with no
`tap`/`long-press` action and no `isButton` flag; every interactive control
carries a readable label (`Back`, `Share anonymous crash reports`,
`Read the full Privacy Notice`, `Continue`). The `SemanticsHandle` is released
inside the test body — `addTearDown` runs after the end-of-test semantics
check, which is a trap this suite hit before.

### 4. Token hygiene — the "never hard-code colours" rule, enforced

- `no feature source contains a colour literal`: every `.dart` file under
  `lib/features/privacy_consent/` is scanned for `Color(0x`, `Colors.` and
  `Color.fromARGB`; the scan is guarded to have found at least five files so it
  cannot pass by reading nothing.
- `the view paints only named palette entries`: every `tokens.<name>` the view
  reaches for must exist in the design-system palette allow-list, and the ones
  the screen must paint (`paper`, `ink`, `ink2`, `sky`, `danger`, `aPeach`,
  `peachTint`) must be present.

### 5. Re-verified unchanged (131 pre-existing tests still green)

Bloc: loading→loaded, empty stream, stream error, items without a `crash` row,
both toggle directions, optimistic emit, revert-to-stored, error clearing,
transactional first-run upsert with last-write-wins. Repository: default OFF,
5 rows, crash-row mirror, untouched columns, single-row upsert, idempotent
write, `Seed.empty` / `Seed.demo`. Widget: light+dark, 320/390/430 × 1.0/1.3,
320×568, empty/loading/error/first-run states, every tap destination, separator
overlay (design-CSS-derived geometry), artwork provenance and painted pixels,
copy character-by-character, owner alignment and bottom-edge rules.

## Results

```
dart format --output=none --set-exit-if-changed .  → 371 files, 0 changed
flutter analyze                                    → No issues found! (ran in 2.8s)
flutter test test/features/privacy_consent/        → 00:02 +156: All tests passed!
flutter test (whole app)                           → 00:16 +801: All tests passed!
```

Zero failures, zero skips — the whole app is green.

## Bugs found this iteration

**None.** No defect surfaced in the iteration-6 tree.

## Observations (not defects, nothing to patch)

- **Light `lilac` on `lilacTint` measures 3.40:1.** It clears WCAG 1.4.11
  (3:1 for graphical objects) and the glyph it tints is a 24 px icon, so P04 is
  compliant — but it is below the 4.5:1 text floor and sits just 0.4 above the
  limit, so it is the most fragile pair on the screen. It is a shared palette
  entry (`NestColors.light.lilac`) used by other screens, so changing it is an
  orchestrator decision, not a P04 one; the test now pins the measured value so
  a regression is caught rather than discovered in an audit.
- Widget tests run without the bundled Inter/Nunito faces, so the block test
  font widens every line and pushes the opt card below the fold although it
  fits on a 390×844 device; helpers scroll with `ensureVisible` first.
  Absolute row heights stay a device (UI-check) measurement.
- `SemanticsHandle` must be disposed inside the test body; Drift reads and
  `Picture.toImage` inside `testWidgets` need `tester.runAsync`; a
  `Future.delayed` must never outlive a test.
- The copy, separator, artwork and hygiene tests read
  `design/html-source/**` and `lib/**` at runtime and fail loudly with the
  searched paths if the layout changes — deliberately, never silently.

## Open items

None in P04 scope. P04-1 … P04-9 are all fixed and green; `SHARED_REQUEST.md`
§1/§2/§6 are consumed, and §4's P16 half was never this screen's to fix.
Orchestrator notes 1–4 are all satisfied and proven by tests.

VERDICT: PASS
