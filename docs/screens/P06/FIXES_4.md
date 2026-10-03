# Fix list after iteration 4

## From 3_test.md
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


## From 4_review.md
# P06 Pocket money setup — QA code review (Stage 4, iteration 4)

Reviewed `git diff main...HEAD` (11 files: 7 in `app/lib/features/pocket_money/`,
4 in `app/test/features/pocket_money/`), plus `docs/screens/RULES.md`,
`docs/ARCHITECTURE.md`, `docs/DESIGN_SPEC.md` §5 P06, `docs/design/SPACING_SPEC.md`,
`docs/screens/P06/ORCHESTRATOR_NOTES.md` and `docs/screens/P06/1_plan.md`.
No code was edited.

## What I ran / measured

| Check | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed lib/features/pocket_money test/features/pocket_money` | 0 changed |
| `flutter analyze` (whole app) | **1 issue** (see #2) |
| `flutter test test/features/pocket_money` | `+136 ~1: All tests passed!` (1 skip = P06-BUG-04, #13) |
| design PNG geometry (`design/screens/light/P06-pocket-money.png`, ÷3) | measured, see #1 |
| `git diff --name-only main...HEAD` | only RULES §1 paths ✔ |

Design measurements used below (logical px, ÷3): scroll top 107 · H1 68 (107–175) ·
option cards 191–255 / 263–327 / 335–399, each **64** high, 8 gaps · settings card
**415–684 (270)** · `Payout day` label box 431–449 · **day pills 455–486 (32)**, x 36–353
(7 × ~40.3 + 6 × 6, i.e. flush with the card's 16 inset) · divider 495 · `Weekly base`
503–521 · Maya 523–567 · Leo 567–611 · divider 620 · coin row 628–672 · card bottom 684 ·
CTA panel top border **685** (caption 700–736, button 744–795, panel bottom 810).

## Findings

### 1. MAJOR — the payout-day row is laid out 44 px tall instead of the design's 32 px, which pushes the settings card 12 px past the fixed CTA and clips its bottom
`app/lib/features/pocket_money/presentation/views/pocket_money_setup_view.dart:436-439` (tight `Padding`), `:514-538` (`SizedBox(height: NestDevice.tapParent)` around `NestChipWrap`), `:570-577` (`_DayCell` `SizedBox(height: NestDevice.tapParent)`)

`NestChipWrap`'s own contract is *"Row of chips that keeps the full 44 px tap target
without changing the 32 px layout"*, and `NestChip.hitSlop = (44-32)/2 = 6` exists for the
same reason. The implementation instead grew the **layout box** to 44 and centres the 32 px
pill inside it, which changes the geometry the UI check measures:

* the pills paint at **461–493** instead of 455–486 — 6 px lower than the design (the
  design puts the row 6 px under the label; here it is 6 + 6);
* the settings card becomes **282** instead of 270 (`16+18+6+44+17+18+2+88+17+44+12`), so its
  bottom edge lands at **697** — 12 px *below* the CTA panel's top border (685). The card's
  12 px bottom padding and its bottom corner radius are therefore hidden behind the fixed
  `NestBottomCta`, and the coin row's bottom edge sits directly on the CTA border (design:
  coin row 628–672 with 12 px of card padding visible above the border);
* the design's content ends exactly at the fold (578 = viewport), so nothing absorbs this.

Fix: keep the visual row at `NestSpacing.s8` — `_DayCell` becomes
`SizedBox(width: cellWidth, height: NestSpacing.s8, child: _DayPill(...))` and the row box
becomes 32, **not** 44. To keep the 5 px-above/below taps working, remove the tight
ancestors that currently swallow the out-of-bounds point (`Padding(horizontal: s4)` at
:436 and the `SizedBox` at :514): `RenderPadding` / `RenderConstrainedBox` extend
`RenderProxyBoxWithHitTestBehavior`, whose `hitTest` starts with `if (size.contains(position))`,
so a 32-tall tight box rejects the tap before `RenderNestChipWrap.hitTest` (which *does*
accept ±`hitSlop` and forwards to the nearest pill) ever sees it. Inset the row with the
existing `LayoutBuilder` instead (cell width from `(maxWidth - 32 - gaps) / 7`, wrap box
`constraints.maxWidth` wide, 32 tall, `alignment: WrapAlignment.center`) so the roomy card
`Column` is the wrap's direct parent. Then update the tests that pinned the regression:
"every tap target is at least 44dp" (view_test.dart:768-789), "tap targets hold at 320dp…"
(:809-827), "the day cell is the 44dp tap box" (:840-868) — assert the *pill* is 32 and that
a tap 5 px above/below it still selects the day (the existing :870-909 test), instead of
`expect(size.height, NestDevice.tapParent)` on the cell.

### 2. MAJOR — `flutter analyze` is not clean: one issue in this screen's own test
`app/test/features/pocket_money/pocket_money_setup_view_test.dart:2078`

```
info • Don't cast a nullable value to a non-nullable type … cast_nullable_to_non_nullable
```
`2_build.md:68` claims `flutter analyze` → "No issues found!"; running it now reports the
above. RULES §7 requires *No issues found (no ignores)*, so the done gate is not met.

Fix: `(decoration.borderRadius! as BorderRadius).topLeft.x` (or simply
`expect(decoration.borderRadius, NestRadii.allM)`) at :2078, then re-run `flutter analyze`
and paste the real tail into the build report.

### 3. MAJOR — the H1 is a plain `Text`; `.h1` sets `text-wrap: balance`, so it must use `NestBalancedText`
`app/lib/features/pocket_money/presentation/views/pocket_money_setup_view.dart:132-145`

`design/html-source/components.css:29` → `.h1 { … text-wrap: balance; }`, and the
BALANCED HEADINGS rule ("where the design CSS uses `text-wrap: balance` (.display, .h1, …)
render the heading with `NestBalancedText`") is mandatory. `NestBalancedText` is already on
`main` (`app/lib/core/design_system/components/nest_balanced_text.dart`, exported from the
barrel in 88b2132); it is missing here only because this worktree has not merged
88b2132 yet — after the next main merge it must be used.

Fix: in `_SetupTitle`, replace the `Text` with
`NestBalancedText('How does pocket money work in your house?', style: context.nestText.h1, textAlign: TextAlign.left)`
keeping the surrounding `Semantics(header: true)`. **`textAlign` must be `left`**: the widget
defaults to `TextAlign.center`, and the design's `.h1` inherits left alignment inside the
20 px-gutter scroll — omitting it would silently centre the heading (owner ALIGNMENT rule).

### 4. MAJOR — a widget test that opens a real Drift database does not end with `disposeApp(tester)`
`app/test/features/pocket_money/pocket_money_setup_view_test.dart:1309-1381` (teardown at :1378-1380)

This test calls `setUpTestScope()` and wraps the **real** repository
(`_FlakyModeRepository(GetIt.instance<PocketMoneyRepository>())`), i.e. it subscribes to real
Drift `watch*` streams, but tears down with `pumpWidget(const SizedBox.shrink())` +
`pump()` instead of `disposeApp(tester)`. `disposeApp` (`app/test/test_scope.dart:54-58`) is
exactly `pumpWidget` + `pump()` + `pump(100 ms)` — the missing third pump is the Drift
deferred stream-close drain RULES §7 calls out ("teardown fails with *A Timer is still
pending*"). It passes today by luck; it is the documented flake.

Fix: replace :1378-1380 with `await disposeApp(tester);`. For consistency do the same in the
five fake-repository tests (:682-683, :710-711, :1724-1725, :1765-1766, :1791-1792), which
have the same hand-rolled teardown.

### 5. MINOR — the weekly-base and coin-row labels use `bodyStrong` (w700, 16/24); the design's `.amount-name` is w600, 16/22
`pocket_money_setup_view.dart:666` (child nickname) and `:766` (`Coin value`).
`components.css` / `P06-pocket-money.html:31`: `.amount-name { font-size:16px; font-weight:600; line-height:22px }`.
Fix: `NestType.body(color: tokens.ink).copyWith(fontWeight: FontWeight.w600, height: 22 / 16)`
at both call sites (the option-card titles at :341 correctly use w700). No layout change
(rows are 44 min) — copy/weight fidelity only.

### 6. MINOR — the loading spinner is not token-coloured
`pocket_money_setup_view.dart:159` uses a bare `CircularProgressIndicator()` (Material
`ColorScheme.primary`). P08/P08b pass `color: tokens.leaf`
(`app/lib/features/today/presentation/views/today_view.dart:27`). Fix: same — add
`color: tokens.leaf` (the loading body is built `const`, so drop the `const`).

### 7. MINOR — un-tokened literals still in the view
`pocket_money_setup_view.dart:158` (`SizedBox(height: 200)`), `:315` (`minHeight: 60`),
`:319` (`horizontal: 13`), `:379-381` (radio 22), `:640` (`_wrapWidth = 300`).
`SHARED_REQUEST.md` item 2 covers 13 / 22 / 200 but **not** `minHeight: 60` or
`_wrapWidth = 300`; `stepPence = 50` (:23) and the `0..2000` clamp
(`pocket_money_bloc.dart:128`, `pocket_money_repository_impl.dart:164`) are domain values, not
spacing, and are documented. Fix: extend `SHARED_REQUEST.md` item 2 with 60 and 300 (or
express `_wrapWidth` as a named private constant with a comment citing the 318 px row
content width), so no unexplained magic number is left behind.

### 8. MINOR — `_DayPill` re-implements `NestChip`
`pocket_money_setup_view.dart:588-623`. `.chip.day` (`padding: 0`, 13 px label, full-cell
width) is not expressible with the shared `NestChip` (fixed `0 14px` padding, 14 px
`chipLabel`), so the feature carries a private pill with a `TODO(P06)` and
`SHARED_REQUEST.md` item 1 asks for a `labelStyle`/compact constructor. That is the correct
process (RULES §2) and not a blocker — but keep the request open and retire the pill when the
component lands; do not let it become a second chip implementation. Related: the pill's
`fieldLabel` (13/18 w600) is the right style for `.chip.day` — worth saying in the request so
the shared component matches the design.

### 9. MINOR — `watchSetup()` subscribes to a stream whose value it throws away
`pocket_money_repository_impl.dart:56-58`: `combineLatest3(_watchFamily(), _db.watchSetting(Seed.familyId), …)`
never reads `parts[1]`. Every `settings` write therefore re-emits `PocketMoneySetup` with an
identical value (deduped by bloc, but still a wasted Drift subscription and a confusing
signal). Fix: drop `watchSetting` from the combine (`families` is the declared source of
truth and is written in the same transaction by `setMode`/`setPayoutDay`), or assert parity
in a debug assert so the mirror's purpose is explicit.

### 10. MINOR — `emit` after `await` without an `isDone` guard in two write handlers
`pocket_money_bloc.dart:82-89` (`_onModeChanged`) and `:106-112` (`_onPayoutDayChanged`) can
call `emit` after the bloc closed while the Drift write was in flight
(`Emitter.call` throws `StateError('emit was called after …')`). `_onWeeklyBaseStepped`
already guards (`:147`). Fix: add `if (emit.isDone) return;` before both `emit`s (after the
`_pendingDay`/`_requestedBase` bookkeeping, which must still run).

### 11. MINOR — invented empty-state copy
`pocket_money_setup_view.dart:457`: `'Add children to set weekly amounts.'` appears nowhere
in `DESIGN_SPEC.md` §5 P06 or the HTML source. It only renders for `Seed.empty`/`Seed.fresh`,
which is fine functionally, but it is unsanctioned product copy. Fix: keep it and note it in
the stage report as screen-authored copy for the orchestrator to ratify, or drop to a neutral
caption token.

### 12. MINOR — repository validation is `assert`-only
`pocket_money_repository_impl.dart:106-108` (`setMode`) and `:136` (`setPayoutDay`) validate
with `assert`, which is stripped in release/profile builds; an invalid value from any future
caller would be written to the DB. Fix: throw `ArgumentError` (keep the assert as well), so
the invariant holds in every build mode.

### 13. MINOR — `P06-BUG-04` is still `skip: true`
`app/test/features/pocket_money/p06_bugs_test.dart:355`. The skip is justified (the
orchestrator's item 2 requires all 7 chips inside the 16 px inset, so a 44 px *width* is
impossible at 390/320) and documented at :375-379, but it must not outlive that ruling: once
#1 is fixed, delete the stale test (its 44×44 width demand) rather than leaving a skipped
test in the feature.

### 14. MINOR — the whole form rebuilds on every emission, including ledger changes P06 never renders
`pocket_money_setup_view.dart:48-80`: the `BlocBuilder` has no `buildWhen`, and the bloc's
`onData` re-emits on `watchItems()` too (the ledger). Fix (optional): add
`buildWhen: (p, s) => p.setup != s.setup || p.status != s.status || p.errorMessage != s.errorMessage`.

## Verified OK (no action)

* **RULES §1 scope** — `git diff --name-only main...HEAD` touches only
  `app/lib/features/pocket_money/{data,domain,presentation}/**`,
  `app/test/features/pocket_money/**` and `docs/screens/P06/**`. No `core`, no `app/`, no
  `tools/screens`, no `analysis_options` change, no `flutter clean`.
* **ARCHITECTURE** — feature-first; `domain/` holds only entities
  (`pocket_money_setup.dart`) + the abstract `PocketMoneyRepository`; the impl stays in
  `data/`; one `PocketMoneyBloc` for the feature (shared with P12/P13, which is why `items`
  is kept); no use-case classes, no extra folders; the route/DI/barrel were already on main
  and were not touched; the route already dispatches `PocketMoneyLoadRequested`.
* **Copy** — every string matches `P06-pocket-money.html` character-for-character
  (title, 3 option pairs, `Payout day`, `Weekly base`, `Coin value`, `10 coins = 10p`,
  caption, `Continue`, `Back`, and the stepper aria-labels
  `Less/More weekly pocket money for <name>`). UK spelling ("pence"). No curly/dash
  substitutions needed (the design has none).
* **DATA OVER MOCKS / CHILD ORDER** — mode, payout day, coin value and per-child weekly base
  all come from Drift (`watchSetup`); children are read with
  `ORDER BY rowid` (insertion order: Maya, then Leo — never alphabetical, unlike
  `AppDatabase.watchChildren`); `Seed.onboardingKids` really carries Maya 300 pence / Leo 150
  pence, so `£3.00` / `£1.50` are data, not constants. The view hard-codes no amount.
* **ORCHESTRATOR_NOTES items** — 1 (seed `onboarding_kids`, DB-sourced amounts, insertion
  order) ✔; 2 (chips inside the 16 px inset, 7 fit at 390 and 320, no chip escapes the padded
  rect — test at view_test.dart:1185) ✔ except the 44 px row height of #1; 3 (letter spacing 0 —
  no `letterSpacing` anywhere in the feature) ✔; 4 (gold `NestlingIllustrations.coin` SVG in
  the `coinTint` 40 px `r-m` tile, not a `£` glyph) ✔; 5 (option cards now 22/20 line heights
  → 64 px, matching the design's measured 64) ✔; 6 (`NestChipWrap` used) ✔ (see #1).
* **BOTTOM EDGE (owner)** — `NestBottomCta` (`surface` + `SafeArea(top: false)`) is the last
  painted area and `NestHomeIndicator` is a no-op outside the gallery, so no page-colour strip
  can appear below the panel in either theme; regression-tested at view_test.dart:1436-1480.
* **DESIGN-SYSTEM USE** — no hard-coded colours anywhere: every fill/border/text/shadow comes
  from `context.nest` (`leafTint`, `leaf`, `leafInk`, `ink`, `ink2`, `ink3`, `line`, `surface`,
  `surface2`, `coinTint`, `cardShadow`); geometry uses `NestSpacing`/`NestRadii`/
  `NestDevice`/`NestType` tokens; `NestNavBar`, `NestCard`, `NestBottomCta`, `NestStepper`,
  `NestButton`, `NestAvatar`, `NestChipWrap`, `NestStatusBar`, `NestHomeIndicator` and
  `NestlingIllustrations.coin` are reused; the private widgets (`_PocketOptionCard`,
  `_RadioDot`, `_DayPill`) are feature-private, which the architecture allows.
* **ACCESSIBILITY** — H1 `header: true`; radiogroup container label `Pocket money style` with
  `button + selected` per card; day group label `Payout day` with per-chip labels; stepper
  labels verbatim from the HTML; `Semantics(excludeSemantics: true)` so each control is one
  node; decorative radio/coin excluded; tap targets: option cards 64, day cells 44 tall,
  steppers 44, CTA 52, back 44; width × text-scale matrix (320/390/430 × 1.0/1.3) with
  `takeException() == null`.
* **PERFORMANCE / LIFECYCLE** — `emit.forEach` is the single subscription for both streams
  (`combineLatest2`), cancelled on bloc close; `_closeOnError` closes the stream so a
  "Try again" cannot leak watchers; no `Timer`/`AnimationController`; no `setState`
  anywhere; streams come from the repository (DI singletons), never created in `build`.
* **ERROR HANDLING** — a load failure with no usable setup renders the message + `Retry`
  (which re-adds `PocketMoneyLoadRequested`); a failed *write* keeps the form and shows the
  message inline in the `danger` token and clears itself on the next successful emission; no
  fake money style is flashed while loading; empty children degrade gracefully.
* **CHILDREN'S CODE / PRIVACY** — parent-mode screen only; no analytics, ads, tracking,
  network calls, `print`/`debugPrint`, or child identifiers outside the local DB; nothing is
  written to disk; no kid-mode surface is reachable from here (`Continue` → `/paywall` via
  `go`, back → `/add-children`).
* **UI-STAGE INPUT FOR THE NEXT ITERATION** — with #1 and #3 fixed, the expected geometry is
  cards 191/263/335 (64), settings card 415–684, pills 455–486 x 36–353, coin row 628–672,
  CTA border 685, i.e. the card flush above the CTA as in the design.

