# P06 Pocket money setup — Stage 3 TEST (iteration 4)

Route `/pocket-money-setup` · feature `pocket_money` · parent mode · in-memory
Drift DB (`Seed.demo` / `Seed.empty` / `Seed.onboardingKids`), real router +
DI + themes.

Iteration 3 passed every stage. This iteration the build absorbed
`ORCHESTRATOR_NOTES.md` (six mandatory items, the last one written after the UI
builder hit a rate limit), fixed P06-BUG-09, and merged the shared
`NestChip` padding and letter-spacing work. My stage re-verifies all of it and
extends coverage over the new code.

## Tests added (7 new; 106 → 113 in my three files)

### `pocket_money_setup_view_test.dart` (+5, now 67) — new group "iteration 4 contract"

| Test | Note item | What it pins |
|---|---|---|
| `Seed.onboardingKids (the shoot seed) renders the children from the database, in insertion order` | **1** | the mandated shoot seed is fully exercised: Maya £3.00 above Leo £1.50, avatars M/L, no "Add children to set weekly amounts." caption, and a stepper tap starts from the DB value (no view defaults) |
| `no text on the screen carries letter spacing` | **3** | sweeps **every** `Text` on the screen in light and dark: no non-zero `letterSpacing` anywhere (the sanctioned cases are P12's hero −0.4 and K02's `.mark` 1.28, neither on P06), plus explicit spot checks on the H1 and the CTA caption |
| `option cards use the HTML line heights 22/20` | **5** | `.opt-title` 16px @ height 22/16 and `.opt-sub` 15px @ 20/15 (from the HTML), card ≥64 tall with the 20px gutters, and the 22px radio at exactly `2px border + 13px padding` from the card edge |
| `the coin tile is a 40×40 coinTint tile with the gold coin glyph` | **4** | the tile's **shape**, not its text: 40×40 (`NestSpacing.s10`), `coinTint` fill, `r-m` radius, a 24×24 (`s6`) `NestlingIllustrations.coin` SVG inside it, still inside an `ExcludeSemantics`, and no leftover `NestIcon(poundCoin)` £ glyph anywhere |
| `the chip row is a NestChipWrap, so its 44px hit area survives the 32px pills` | **6** + CHIP ROWS rule | the row builds through the shared `NestChipWrap`, the wrap's row box is 44 tall while the pills paint 32 — the structure behind the ±5 px tap test the integrator added |

Also hardened two helpers/findings while writing these: `_coinTile()` had to
re-anchor from the removed `NestIcon` to the coin SVG, and the option-card
height assertion is now a lower bound plus explicit line-box checks, because
the widget-test fallback font wraps the sub onto two lines (the same
text-metric caveat recorded in iteration 2).

### `pocket_money_setup_bloc_test.dart` (+1, now 30)

| Test | What it pins |
|---|---|
| `P06-BUG-09 — a slow day write plus an unrelated emission still lands the correction` | the day-request guard is compared against the last **requested** day: tap Sun (write held in flight) → stepper write re-emits the setup still reporting Saturday → tap Sat. The final payout day must be 6 (Sat), with Maya's stepper write intact at 350p |

This one is **verified to have teeth**: with the pre-BUG-09 line
(`_pendingDay = null` on every emission) temporarily restored in
`pocket_money_bloc.dart`, the test fails with `Expected: <6> Actual: <7>`; with
the shipped fix it passes. The bloc file was restored byte-for-byte
(`git diff` empty) — no screen code was changed by this stage.

New helper `_SlowPayoutDayRepository` (delegates to the real repository, delays
`setPayoutDay` by 40 ms) makes the in-flight window deterministic instead of
racy.

### Not duplicated on purpose

The integrator had already added, in the same feature directory, the two tests
ORCHESTRATOR_NOTES items 2 and 6 explicitly ask for (`chip row: every chip stays
inside the card padding`, `chip row: taps 5 px above and below a chip select
it`) plus `at 320 all seven chips fit without a scroll view` and `every day cell
paints a 32dp pill at all widths`. I verified them by reading, not by rewriting
them, and added the structural `NestChipWrap` assertion alongside.

## Results

- `dart format --set-exit-if-changed test/features/pocket_money` → clean (4 files, 0 changed).
- `flutter analyze` (full app) → **No issues found!** (ran in 3.6s).
- `flutter test test/features/pocket_money/pocket_money_setup_bloc_test.dart` → **+30: All tests passed!**
- `flutter test test/features/pocket_money/pocket_money_setup_repository_test.dart` → **+15: All tests passed!**
- `flutter test test/features/pocket_money/pocket_money_setup_view_test.dart` → **+67: All tests passed!**
- `flutter test test/features/pocket_money/` → **+136 ~1: All tests passed!**
- `flutter test` (full app) → **+1126 ~3: All tests passed!**, exit 0.
- The skips are the documented bug-proof entries in `p06_bugs_test.dart` (and
  two other files' own skips). **My three files contain no `skip:`** and no
  `google_fonts`/`GoogleFonts`. Scope: `app/test/features/pocket_money/**` +
  `docs/screens/P06/**` only (RULES §1); no screen source edited.

## Bugs found

### P06-BUG-10 (MAJOR, orchestrator-rule violation) — the `.h1` is not balanced

- **File:line** — `app/lib/features/pocket_money/presentation/views/pocket_money_setup_view.dart:132-145`,
  `class _SetupTitle` builds
  ```dart
  Semantics(header: true, child: Text('How does pocket money work in your house?', style: context.nestText.h1))
  ```
- **Rule** — the mandatory orchestrator rule "BALANCED HEADINGS (main,
  NestBalancedText): where the design CSS uses `text-wrap: balance`
  (`.display`, `.h1`, …), render the heading with `NestBalancedText` … Never use
  it on `.h2`/`.h3`/`.body`/`.caption`." `design/html-source/components.css:29`
  declares `.h1 { … text-wrap: balance; }` and P06's only heading is that
  `.h1`, so the rule applies.
- **Visible consequence** — the design
  (`design/screens/light/P06-pocket-money.png`, read at iteration 4) breaks the
  heading into two near-equal lines, "How does pocket money" / "work in your
  house?". A greedy `Text` break takes the longest line that fits, which puts
  "work" on line 1 and leaves a short second line — the exact orphan the rule
  exists to prevent. (Line-for-line proof belongs to the UI stage: widget
  tests render with the ~1em-per-glyph fallback font, so break assertions are
  unreliable here — the same caveat recorded in iteration 2.)
- **Why it is still there** — `NestBalancedText` is **already on main**
  (`app/lib/core/design_system/components/nest_balanced_text.dart`, shared
  batch 3 `58b42de`, merged `88c2132`) but is not in this worktree:
  `git merge-base --is-ancestor 58b42de HEAD` → false (the branch last merged
  main at `f579ff4`). The screen cannot adopt a component that is not on its
  branch, so this is a merge-order dependency rather than a design mistake.
  Logged as item 3 in `docs/screens/P06/SHARED_REQUEST.md`; the screen change
  is one line (`Text` → `NestBalancedText`, same copy/style/maxLines) for the
  next build stage.
- **Not patched** (Stage 3 rule). No test asserts the break, because such an
  assertion would be flaky here and would fail for a reason the next build
  fixes by merging main rather than by editing this file. The ready-to-paste
  regression test, for when `NestBalancedText` is available:
  ```dart
  expect(
    find.ancestor(
      of: find.text('How does pocket money work in your house?'),
      matching: find.byType(NestBalancedText),
    ),
    findsOneWidget,
  );
  ```

### Everything else is clean

All six ORCHESTRATOR_NOTES items verified by a passing test: seed
`onboarding_kids` renders the DB children in insertion order, the chip row
stays inside the card's 16 px padded rect at 320/390/430 with 32 px pills and
even gaps, nothing on the screen carries tracking, the coin tile paints the
gold SVG in a 40×40 `coinTint` tile, the option cards use the HTML 22/20 line
heights, and the chip row goes through `NestChipWrap` with a 44 px hit area.
P06-BUG-01/02/03/05/06/07/09 all remain covered and green; P06-BUG-04 stays
intentionally skipped in the bug-proof file (its ≥44 px **width** demand is
superseded by note item 2 — seven chips must fit inside the 16 px inset).

## Cross-stage notes

- The day row moved back inside the card's 16 px padding this iteration, so the
  iteration-3 measurement (2 px breakout inset, 44.3 px cells at 390) no longer
  applies: cells are now ~39.9 px wide at 390 with 6 px gaps and the row is
  flush with the `Payout day` label on both sides. My alignment group pins that
  shared inner edge, so a future change to the row breaks a test.
- P06-BUG-04's skip is the only open item carried from iteration 3 and it is
  blocked on the same shared `NestChip` day variant as SHARED_REQUEST items 1/2.

VERDICT: FAIL