# P06 Pocket money setup — Stage 3 TEST (iteration 6)

Route `/pocket-money-setup` · feature `pocket_money` · parent mode · in-memory
Drift DB (`Seed.demo` / `Seed.empty` / `Seed.onboardingKids`), real router +
DI + themes, real bundled fonts where the layout is font-sensitive.

The iteration-6 build needed **no view change** (the shared
`NestBalancedText` ellipsis fix arrived via main, commit `9ba19ab`); the UI
builder added the real-font geometry guard and the stepper-glyph proofs. This
stage re-verifies all of it, extends the real-font guard to the full matrix,
and adds the geometry test the orchestrator's newest note asks for — which
exposes one real defect.

## Tests added (16 new; 132 → 148 in my three files)

### `pocket_money_setup_view_test.dart` (+16, now 87)

New group **"real-font matrix"** (13 tests) — the iteration-5 regressions (a
one-line ellipsized H1, a hyphen instead of U+2212) were only visible with the
real faces, and the geometry guard pins 390×844 at scale 1.0 only. With
`FontLoader` (Inter + Nunito, same recipe as
`privacy_consent_geometry_test.dart`), for light/dark × 320/390/430 × 1.0/1.3:
- the H1's `RenderParagraph.didExceedMaxLines` is **false** (the exact failure
  mode of the iteration-5 regression),
- all seven day pills paint the 32 px band on one shared top edge, with 6 px
  gaps, inside the card's 16 px padded rect,
- the CTA caption, `10 coins = 10p` (from 390 up) and `£3.00` do not ellipsize,
- the CTA panel still ends at y = 844 (bottom-edge owner rule),
- `takeException()` is null in all twelve combinations.
Plus an anchor cross-check at 390/1.0: H1 at y 107 with a 68 px height (two
34 px lines), option cards at y 191/263/335, each 64 tall — the design's ÷3
values, measured independently of the geometry guard's file.

New group **"coin-value trailing alignment (ORCHESTRATOR_NOTES 09:30)"**
(3 tests) — the note's one remaining item, stated in the note's own terms:
the trailing value's right edge must equal the card's content right edge
(x ≈ 354 at 390 — the same edge as the `+` buttons and the Sun chip) within
±1 px. Light, dark, and 430.

Helpers: `_loadBundledFontsForMatrix()` (FontLoader) and
`paragraphOf(tester, text)` (the tree's own `RenderParagraph`, so
`didExceedMaxLines` is read from the painted node — the standalone
`TextPainter` route is unreliable here, as recorded in iteration 2).

## Results

- `dart format --set-exit-if-changed` on my three files → clean (0 changed).
- `flutter analyze lib` + my three files → **No issues found!** (4.3s);
  full-app analyze also clean at the end of the stage.
- `flutter test` (full app) → **+1381: All tests passed!**, exit 0 — measured
  *before* the coin-alignment group was added; with it, see below.
- `flutter test test/features/pocket_money/pocket_money_setup_view_test.dart`
  → **+87 −3**: the three new coin-alignment tests fail (the defect below);
  every pre-existing test in the file is green.
- `flutter test test/features/pocket_money/pocket_money_setup_bloc_test.dart`
  → **+30**, `pocket_money_setup_repository_test.dart` → **+15**,
  `pocket_money_setup_view_geometry_test.dart` → **+6**,
  `p06_weekly_stepper_widget_test.dart` → **+5**, `p06_bugs_test.dart` → **+27**.
- No `skip:` in my files, no `google_fonts`/`GoogleFonts`, no simulator used
  (only the UI stage may drive one). Scope: `app/test/features/pocket_money/**`
  + `docs/screens/P06/**`; `app/lib/` untouched.

## Bugs found

### P06-BUG-13 (MAJOR, mandatory note) — the coin value is not right-aligned

- **File:line** — `app/lib/features/pocket_money/presentation/views/pocket_money_setup_view.dart`,
  `_CoinValueRow` (the trailing element): the value sits in a
  `Flexible(child: Text('10 coins = ${10 * coinValuePencePerCoin}p',
  softWrap: false, overflow: ellipsis))`. A **loose** `Flexible` gives the
  child its intrinsic width, so the text ends wherever it ends instead of
  trailing to the row's right edge; the design wants a trailing,
  right-aligned element (`Spacer`/`Expanded` + `TextAlign.end`).
- **Repro (real fonts, 390×844, `Seed.onboardingKids`)** — the three new
  geometry tests fail with
  `Expected: 354.0 (±1.0) Actual: <321.869140625>` in light and dark, and the
  same at 430. My measurement lands within 0.2 px of the orchestrator's QA
  note ("in the app it ends at x ≈ 322").
- **Everything else on that row is already correct**, which is what makes the
  value the single outlier: in the same test the `Sun` chip's right edge and
  Maya's `+` button's right edge both land on 354 ±1 (they pass), and the
  40 px coin tile keeps its place (asserted). So the card's 16 px inset, the
  day strip and the stepper column are all aligned — only the value floats.
- **Rule violated** — owner ALIGNMENT ("nothing a few px off"): a 32 px gap
  between the value and the card's content edge, where the design shows the
  value flush with the `+` column.
- **Not patched** (Stage 3 rule). The fix is the note's own prescription:
  replace the loose `Flexible` with a trailing right-aligned element and keep
  `TextAlign.end`. The three tests stay red until that lands, which is the
  signal the loop needs; their names quote the note and the failure message
  carries the target and the measured value, so the assertion cannot be
  mistaken for a bad test.

### Confirmed fixed this iteration (no action needed)

- **The iteration-5 H1 regression** ("How does pocket mone…" on one line) is
  gone: with the real faces the heading paints two 34 px lines at y 107–175
  and `didExceedMaxLines` is false in all twelve matrix combinations. That is
  the shared `shared/balanced_text_ellipsis` fix (main `9ba19ab`), and P06
  still uses `NestBalancedText` with no local `maxLines`/overflow override, as
  the note requires.
- **P06-BUG-01/02/03/05/06/07/08/09/11/12** all remain green in
  `p06_bugs_test.dart` (27 tests, zero skips), including the stepper's U+2212
  minus pinned by code unit in `p06_weekly_stepper_widget_test.dart`.
- The day cells announce `Payout day: <day>` (review #4) — already pinned in
  my own view test and still passing.

## Measurement worth recording (not a defect)

At **320 dp** the coin row's trailing value ellipsizes (`10 coins = 1…`):
the `Flexible` shrinks to whatever is left after the tile, the label and the
gap. `1_plan.md` §5 sanctions exactly this fallback ("the `10 coins` text must
ellipsis, never push the tile"), so the sweep asserts the ellipsis **is**
present at 320 and **absent** from 390 up, and additionally pins that the tile
and the label do not move when it happens. If the orchestrator wants the full
string at 320 as well, that is a design decision (the row would need to wrap),
not a regression.

## Cross-stage notes

- `ORCHESTRATOR_NOTES` items from 04:05, 07:22 and 07:58 all hold and are
  covered by tests: shoot seed `onboarding_kids` with DB-sourced amounts in
  insertion order, chips inside the 16 px inset with 32 px pills and even
  gaps, `letterSpacing` 0 everywhere, the gold coin tile, 64 px option cards,
  `NestChipWrap` ±5 px taps, and the payout-card y targets (pinned by the
  geometry guard at 390 plus my matrix sweep).
- `SHARED_REQUEST` items 4 (`NestStepper` U+2212 override) and 5 (`NestChip`
  day variant → retire `_DayPill`) remain open shared-code asks; neither
  blocks the screen.
- Review #5 (the screen-authored empty-state copy `Add children to set weekly
  amounts.`) is still awaiting the orchestrator's ratification.

VERDICT: FAIL