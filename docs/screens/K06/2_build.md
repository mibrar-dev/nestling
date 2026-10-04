# K06 · Pip's nest (`/pip`) — Stage 2 (INTEGRATE, iteration 2)

Job: make the 2a (logic) + 2b (UI) halves compile and pass together. Smallest
change only — no redesign.

**Outcome: `dart format .` clean (0 changed) · `flutter analyze` → No issues
found · `flutter test` → 3543 pass / 5 skips / 0 fail.** Iteration 2 needed
**one** fix, and it was a two-comment correction inside the K06 feature: 2b's
`k06_bugs_test.dart` header still announced K06-BUG-1/2 as parked after 2a had
un-skipped and fixed them (the classic artefact of two builders working in one
worktree). No product code was touched at this stage. Iteration 1's FIX 1 (the
K03 placeholder-title swap) is still in force and still green.

## 1. Summary of 2a (logic, iteration 2) — `2a_build_logic.md`

**No contract changes at all** — no state/event shape moved, so the UI half
needed no rebase. `PipCareRequested` / `PipWardrobeBuyRequested` /
`PipWardrobeEquipRequested`, `PipState` {status, nest, actionError,
actionNonce}, `kPipNotEnoughCoins`, `pipStageName`, `PipNest.growthFraction`
are all exactly as iteration 1 left them.

- **K06-BUG-1 (major, lost update).** `_care` was SELECT-then-write
  (`coins: kid.coins - cost` from a stale read), so two overlapping taps both
  read 120 and both wrote 115. Now one conditional statement:
  `UPDATE children SET coins = coins - ?, happiness = min(happiness + 1, 5)
  WHERE id = ? AND coins >= ?` (drift `customUpdate`, notifies `children`
  watchers). Zero rows changed = unknown child or unaffordable: silent no-op,
  never negative. Single-tap behaviour byte-identical (feed 5 / bath 3 / play
  free, happiness +1 clamped 0..5).
- **K06-BUG-2 (major, concurrent buys overspent).** `buyItem` is now one
  transaction: re-read the tile, deduct conditionally (same atomic write
  shape), then claim the tile only while still unowned (`owned = false` in the
  WHERE); a lost same-item race refunds inside the same transaction, so a
  double tap charges exactly once. The bloc's `state.nest` pre-check stays as
  the fast toast path, but correctness no longer depends on it.
- Tests: new `atomic writes` group in `pip_repository_test.dart` (5 concurrent
  feeds land at 95 not 115; concurrent wellies+crown leave the balance
  non-negative with exactly one purchase; concurrent same-item buys charge
  once) and the BUG-1/BUG-2 proofs un-skipped.

## 2. Summary of 2b (UI, iteration 2) — `2b_build_ui.md`

| Finding | Fix | Proof |
|---|---|---|
| **K06-BUG-6 / `5_ui` D1 / ORCHESTRATOR_NOTES item 1** (major) — locked tiles had no visible dashed border: the screen-local `_DashedBorderPainter` was a `CustomPaint.painter`, i.e. *behind* the tile, and the opaque `surface-2` fill covered it edge to edge | now `foregroundPainter`, which is where CSS paints `border` over `background` | `K06-BUG-6` live + a new painter test |
| **K06-BUG-4** — nest art box was 230 × 230 with `BoxFit.fill` | the design's own `.k6-pet .nest { width:230px; height:206px; bottom:0 }` box, art letterboxed uniformly (`BoxFit.contain`, the browser's default for an SVG `<img>`) | `K06-BUG-4` live + a slot test |
| **K06-BUG-5** — care buttons lost equal heights at text scale 1.3 (Play's `Free` pill grew to 101 while Feed/Bath stayed 96) | `IntrinsicHeight` + `CrossAxisAlignment.stretch`, which is what `.k6-care`'s flex row + `align-items: stretch` does | `K06-BUG-5` live + a 1.3× alignment test |
| **K06-BUG-3 / `4_review.md` #9** — the wardrobe heading drew U+2019 while the HTML source writes ASCII 0x27 | `"Pip's wardrobe"`; `1_plan.md` §1e corrected with the same edit | `K06-BUG-3` live + the byte-level oracle in `pip_copy_parity_test.dart` |
| **`4_review.md` #11** — progress semantics read "…of the way to **a** Songbird" | `'Pip is $pct% of the way to $nextName'`, the design's own `aria-label`, percentage still from the DB | two semantics assertions moved with it |

## 3. Integration check — the seam, verified not trusted

- **No mismatched BLoC states/events/imports/renamed members.** 2a changed
  nothing above the repository, 2b nothing below the view; the only shared file
  either touched is `pip_orchestrator_notes_test.dart`'s neighbourhood, and
  `flutter analyze` is clean over `lib` + `test`.
- **The atomic writes still notify the UI.** Both new `customUpdate` calls pass
  `updates: {_db.children}` / `{_db.pipWardrobe}`, which is what keeps
  `watchNest()` (and therefore the bloc, the coin labels and the progress
  fraction) live after a charge or a purchase — the integration risk this
  rewrite created, and it is covered: `pip_nest_view_test.dart` still proves
  feed −5 and buy −price reach the rendered screen.
- **The equip/toast split from iteration 1 survives.** The bloc still emits
  nothing for `wellies`/`crown`; the view still owns `kPipNotWearable`.
- **Copy: I re-derived it from the HTML bytes rather than trusting the notes,
  because 2b *reversed* a plan-mandated character.** Reading
  `design/html-source/screens/K06-pip.html` directly: line 71 is
  `<div class="k6-sec">Pip's wardrobe</div>` — a literal ASCII 0x27 with zero
  non-ASCII characters in that text node — while the title is `Pip &middot;
  Fledgling` (U+00B7) and the caption is `Nothing here is a chore &mdash; it is
  all just for fun.` (U+2014). The app now renders exactly those three: ASCII
  apostrophe, U+00B7, U+2014. 2b's reversal of `1_plan.md` §1e is correct
  under the orchestrator COPY rule ("compare copy character-by-character with
  the HTML source"); plan and code now agree.
- **ORCHESTRATOR_NOTES (11:30), all four items accounted for:**
  item 1 **fixed** (BUG-6, dashed border now paints); item 2 **blocked on a
  shared asset** — see §5; item 3 **DB wins**, no literal price anywhere
  (`'${item.priceCoins}'` in the tile and its semantics label), filed as
  `SHARED_REQUEST.md` §6 with both options for the orchestrator; item 4 is
  informational.
- **Iteration 1's FIX 1 still in force**: `kid_home_view_test.dart` locates the
  pushed `/pip` route with `pushedPath(tester) == '/pip'` and no placeholder
  title anywhere (`grep 'K06 Pip nest'` over the repo returns nothing). The K03
  suite is green.

## 4. FIXES

### FIX 1 — two stale comments in `k06_bugs_test.dart` (done, the only edit)

The two builders worked in parallel in this one worktree, and 2b wrote the
file header (and the section banner above `main()`) while 2a was still fixing
the logic races:

```
- // K06-BUG-1 and K06-BUG-2 are still parked: they are the repository/bloc
- // lost-update races, which belong to the logic layer (2a) …
+ // Bug proofs. K06-BUG-1 / K06-BUG-2 stay `skip: true` (the logic layer's
+ // races: the repository's read-modify-write and the bloc's stale pre-check);
```

Both statements are now false. Verified before touching them: `grep 'skip:
true'` in the file matches **no** test declaration, all six proofs are named
`K06-BUG-1…6`, and
`flutter test test/features/pip/k06_bugs_test.dart --run-skipped` →
`00:01 +6: All tests passed!`. The next stage reading that header could
otherwise have "re-parked" two fixed majors.

Fix: both comments rewritten to state that all six proofs are fixed and run
live, and to record which half took which (2a: BUG-1/2; 2b: BUG-3…6). No
assertion, no `skip:`, no product code touched — comments only.

2b's own note carries the same stale sentence ("Still `skip: true` in
`k06_bugs_test.dart`"). I did **not** rewrite a builder's note — it is the
historical record of what that stage observed — and §5 below records the
resolution instead.

### FIXES — nothing else

No other integration breakage existed: no import, rename, DI, route or
`analysis_options` change was needed, and `pip_di.dart` / `pip_routes.dart`
still need nothing because `PipBloc(repository:)` kept its signature.

## 5. Left for the next stages (not mine to settle)

1. **ORCHESTRATOR_NOTES item 2 is still blocked on shared assets** (the one
   mandatory note item not yet met). `NestIcons.scarf` / `.wellies` / `.sunHat`
   resolve to look-alike `app/assets/icons/*.svg`; RULES §1 forbids a screen
   agent from editing shared assets and the note forbids substituting a glyph,
   so `SHARED_REQUEST.md` §5 carries the design's verbatim path data plus a
   self-updating proof. Its 3 parked proofs fail for exactly that reason and
   nothing else (verified with `--run-skipped`: the asset's path data vs the
   HTML's, e.g. scarf `m7.63.6h8.8v13.2…` vs the design `m53h4v18h5z…`).
2. **`kPipNotWearable`** ("That one is not something Pip can wear.") is still
   the only on-screen string not in the design — unchanged since iteration 1,
   still awaiting ratification or a replacement. Not a regression.
3. **`NestProgress`'s kid highlight spans the whole track** instead of only the
   filled span (shared component, out of scope for a screen agent).
4. **The UI check has not been re-run.** Every fix above is asserted in a
   widget test, but only stage 5 can confirm the rendered result in light and
   dark. Two band-level things to watch, both from 2b: the wardrobe band (the
   dashed border now exists in both themes — band 6's heat should shrink) and
   the pet band (the nest art is ~12 % smaller and ~10 px lower — band 2's
   diff should shrink).
5. **One tension I resolved by measurement, for the record.** ORCHESTRATOR_NOTES
   item 4 says "Pip … and the nest are correct", while stage 6's BUG-4 called
   the nest art box wrong and 2b changed it. I re-measured both design PNGs
   myself with a pixel scan of the ink rows rather than picking a side:
   **light** widest ink row at logical y 277.7, x 108.3–281.3 → **173.3 px**;
   **dark** y 277.7, x 113.3–276.3 → **163.3 px** (a narrower span only because
   dark-mode ink on a dark sky loses contrast at the same threshold). Both sit
   on `202 units × 206/240 = 173.4`, i.e. the 206 scale, and the widest row's
   height matches `206 × (240 − 150)/240 = 77.3` px above the slot's bottom
   edge (356) → y 278.7 predicted vs 277.7 measured. So 2b's BUG-4 fix is
   right, and note item 4 was judging the slot and Pip's placement (both
   untouched). Stage 5's band-2 numbers are still the final word.

## 6. Verification

### Skips — all 5 accounted for, none introduced by me

| Test | Why |
|---|---|
| `pip_orchestrator_notes_test.dart` ×3 (item 2: scarf / wellies / sunhat glyph) | parked on shared `app/assets/icons/*.svg` — RULES §1; `SHARED_REQUEST.md` §5 |
| `kid_home/k01_bugs_test.dart` — K01-BUG-7 | pre-existing, K01's |
| `pocket_money/p12_bugs_test.dart` — P12-BUG-04 | pre-existing, P12's |

`grep 'skip: true'` across `test/features/pip` matches exactly the three
documented glyph proofs and no other line. No K06 test was skipped, disabled or
weakened at this stage; `k06_bugs_test.dart` went from 6 parked proofs to 0.

### Standing rules checked

- **PIP** — nest slot + growth preview use the active child's own `PipAvatar`
  from the DB profile; `grep pip_stage_ lib/features/pip` → 0 hits.
- **DATA OVER MOCKS** — prices render `item.priceCoins`; no price literal
  anywhere in the tile or the view.
- **FONTS / CLOCK / IDS** — `grep google_fonts|GoogleFonts` in
  `lib/features/pip` + `test/features/pip` → 0; `grep DateTime.now()
  lib/features/pip` → 0; `grep newId(` → 0 (this screen writes no new rows).
- **KID BACKGROUND / BOTTOM EDGE / ALIGNMENT / CHIP ROWS / LETTER SPACING /
  BALANCED HEADINGS / ACCESSIBILITY / TRIAL / PERIODS** — untouched this
  iteration and still satisfied (2b's `IntrinsicHeight` change is an ALIGNMENT
  improvement; no control was re-wrapped, so the 9 `SemanticsAction.tap`
  contracts are unchanged).
- **SIMULATORS** — none booted, installed on, screenshot or driven. No
  `flutter clean`, no `analysis_options` change, no `google_fonts` added, no
  image attached (design PNGs read locally, never attached).

### Verification tails

```
$ dart format .
Formatted 566 files (0 changed) in 1.87 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.8s)

$ flutter test --timeout 120s
02:05 +3543 ~5: All tests passed!

$ flutter test --timeout 120s test/features/pip
00:06 +160 ~3: All tests passed!

$ flutter test --timeout 120s test/features/pip/k06_bugs_test.dart --run-skipped
00:01 +6: All tests passed!
```

The last run is the regression guard for all six iteration-1 bug findings, not a
skipped suite: every proof passes. The two non-K06 suites that navigate to
`/pip` (`test/app/routes_smoke_test.dart`, `test/features/kid_home/`) are
included in the full run above and are green.

## 7. Files changed by this stage

- `app/test/features/pip/k06_bugs_test.dart` — FIX 1, two comment blocks.
- `docs/screens/K06/2_build.md` (this file, supersedes iteration 1's).

No `app/lib/**` file was touched: the merged logic + UI compiled and passed as
the two builders left it.

VERDICT: PASS
