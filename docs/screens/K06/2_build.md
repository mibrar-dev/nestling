# K06 · Pip's nest (`/pip`) — Stage 2 (INTEGRATE, iteration 3)

Job: make the 2a (logic) + 2b (UI) halves compile and pass together. Smallest
change only — no redesign.

**Outcome: `dart format .` clean · `flutter analyze` → No issues found ·
`flutter test` → 3770 pass / 5 skips / 0 fail.** The merged tree arrived with
**9 failures, all of them the price premises that `shared/shared_batch7` moved**
(plus one mandatory ORCHESTRATOR_NOTES item that was never implemented). Three
fixes, all in tests except the mandatory glyph switch:

- **FIX 1** — the ORCHESTRATOR_NOTES item 2 glyph switch (one production edit).
- **FIX 2** — 9 stale price premises re-based to read the seeded row.
- **FIX 3** — a test-file `drift` import the new helper needed.

Iteration 1's K03 placeholder-title swap and iteration 2's `k06_bugs_test.dart`
comment fix are both still in force and still green.

## 1. Summary of 2a (logic, iteration 3) — `2a_build_logic.md`

One contract change, and it is additive:

- **`PipRepository.buyItem` now returns `Future<PipBuyResult>`** instead of
  `void`. New enum in `domain/pip_repository.dart`:
  `bought | cannotAfford | alreadyOwned | unavailable`. Only `cannotAfford`
  produces a toast; the rest stay event-free.
- **`K06-BUG-7 (minor) — a buy refused by the fresh balance was silent.** The
  bloc pre-checks *cached* coins, so in a tap burst the second tap passes the
  pre-check while the atomic `buyItem` refuses on the fresh balance — and
  `void` gave the bloc nothing to announce. The bloc now switches on the result
  and emits `withActionFailed(kPipNotEnoughCoins)` on `cannotAfford`. The
  pre-check stays as the fast path for visibly-unaffordable tiles.
- **`PipState.copyWithLoaded` carries a pending action outcome through** instead
  of clearing it, so the refused tap's toast survives the sibling write's
  stream refresh (that *is* BUG-7). It still clears on the next attempt via
  `withActionStarted`, so repeats are announced and the pinned `1 → 0 → 1`
  nonce sequence is unchanged. No field added or removed.

Files: `pip_repository.dart`, `pip_repository_impl.dart`, `pip_bloc.dart`,
`pip_state.dart` + `pip_repository_test.dart` (results + 30/60 premises),
`pip_bloc_test.dart` (refusal pin + carry-through unit test),
`k06_bugs_test.dart` (BUG-7 un-skipped), and three test spies re-signed for the
new return type.

## 2. Summary of 2b (UI, iteration 3) — `2b_build_ui.md`

No view or widget was edited: `5_ui.md` had already closed the structural bands
(2.28 % light / 2.00 % dark, every band Δ 0, BOTTOM EDGE passing, D1 closed),
so the only UI-layer work the merge demanded was in `pip_nest_view_test.dart` —
five stale assertions pinned to the pre-batch-7 seed, re-based to 30/60 with no
production line moved. 2b's triage of `FIXES_2.md` is sound: D2 = shared assets,
D3 = seed (now fixed upstream), BUG-7 = the parallel logic builder's contract.

## 3. Integration check

- **No mismatched BLoC states/events/imports/renamed members.** 2a touched
  domain/data/bloc and 2b touched only `pip_nest_view_test.dart`, so the two
  never met in one file; `flutter analyze` is clean over `lib` + `test`.
- **The `PipBuyResult` contract holds end to end.** `buyItem` returns the
  outcome in all four paths (`unavailable` / `alreadyOwned` / `cannotAfford` /
  lost-race-refund→`alreadyOwned` / `bought`), the bloc announces only
  `cannotAfford`, and the view's existing `BlocListener` on `actionNonce` +
  `actionError` shows the toast — so 2b's "the view side needed nothing" is
  correct and I verified it rather than assumed it (the BUG-7 proof in
  `pip_iter2_fixes_test.dart` drives a real burst and sees the toast).
- **The atomic writes still notify the UI.** Unchanged from iteration 2 and
  still covered: `feed −5` and `buy −price` reach the rendered screen.
- **ORCHESTRATOR_NOTES, all four items:**
  item 1 closed in iteration 2 (BUG-6, dashed border);
  **item 2 now closed by FIX 1 below** (scarf + wellies);
  item 3 closed upstream by batch 7 (seed → 30/60), with FIX 2 keeping the
  proofs honest;
  item 4 informational.
- **Iteration 1/2 fixes intact:** `kid_home_view_test.dart` still locates `/pip`
  by `pushedPath` (no `K06 Pip nest` literal anywhere in the repo), and
  `k06_bugs_test.dart`'s six proofs are still un-skipped and green.

## 4. FIXES

### FIX 1 — ORCHESTRATOR_NOTES item 2: switch to the design glyphs (done; the only production edit)

The 13:52 update says "Once main has them, switch to the shared ones and delete
the local copies, following the batch-7 report", and batch 7 (`2517101`) added
the exact K06 SVGs. 2b reported "zero screen-side work remains" for the glyphs
— that was wrong, and it is the one thing in this iteration that was not merely
a stale premise: the screen was still painting the look-alikes the note names
("Do not substitute"), and the three parked proofs were the standing evidence.

Fix: `widgets/pip_look.dart` `pipWardrobeIcon` now maps
`'scarf' → NestIcons.wardrobeScarf` and `'wellies' → NestIcons.wardrobeWellies`
(batch 7's exact-path assets). Sun hat and crown keep their icons, per the
batch-7 report. Both named proofs are now **live and green** — the byte
comparison reads the design paths out of `K06-pip.html` at test time, so this is
verified against the source, not against the batch's word.

**Scope note — what I did NOT do.** The same update says "delete the local
copies", i.e. items 2/3/4 of the batch-7 report (swap `PipNestSlot` for
`NestPetStage` with `slotHeight/pipBottom/nestFit/showGlow/showGroundShadow`,
`PipCareButton` for `NestKidButton(trailing:)`, and the screen-local
`_DashedBorderPainter` for the shared `NestDashedBorder`). That is a
**refactor of working, UI-verified code**, not an integration fix: the screen
currently passes 5_ui at 2.28 %/2.00 %, and swapping three composed components
is a redesign whose only proof is another UI check I am not allowed to run. Doing
it here could turn a green screen red with no way to prove otherwise. Recorded
as the top item for the next build iteration (§5.1), with the exact call shapes
from the batch-7 report.

### FIX 2 — 9 stale price premises, re-based to the seeded row (done)

`shared_batch7` moved the demo wardrobe to the design's 30/60, so every K06 test
that typed 40/120 was honestly red. **All 9 re-based to READ the seeded row
rather than to type the new number** — the same principle the repo's other
screens use, and the one that survives the next price decision:

| File | Failure | Re-based to |
|---|---|---|
| `pip_atomic_writes_test.dart` ×5 | `Expected <80> Actual <90>`, `Expected <0> Actual <10>`, "one coin short" no longer one short, and **the two-item burst premise was dead** (30 + 60 = 90 ≤ 120, so both now fit and the probe proved nothing) | a `priceOf(item)` helper reading the row; the two-item probe sets the balance strictly **between** the two seeded prices, with `reason: 'only one of $wellies + $crown is affordable'` |
| `pip_orchestrator_notes_test.dart` ×1 | `find.text('40')` / `'120'` gone | the expectation is built from a `SELECT … WHERE child_id = 'maya'` map; the semantics-label assertions follow |
| `pip_nest_interactions_test.dart` ×2 | `Wellies, 40 coins` label gone; and **Leo's tiles showed two identical `30`s**, so `findsOneWidget` on the bare number was ambiguous | a `_price(db, item, {id})` helper; Leo's tiles are matched by their own announcement (`RegExp('^Wellies, 30 coins$')`) rather than by counting bare numbers |
| `pip_nest_states_test.dart` ×1 | `Wellies, 40 coins` / `Crown, 120 coins` in the phantom-button list | same helper, interpolated into the labels |

Two of these were more than a number swap, and both are worth naming:

1. **The two-item burst probe had lost its premise.** Re-typed to 30/60 it would
   have gone *green while asserting nothing* — the balance affords both tiles,
   so "exactly one purchased" is false but "hasLength(1)" … would have failed,
   and the tempting minimal edit (loosen the count) would have destroyed the
   test. It now sets the balance between the prices, which is what makes the
   overspend guard observable at any seed.
2. **Leo's wardrobe has two tiles priced 30.** Matching bare `find.text('30')`
   was ambiguous, so the assertion is per-tile via the announcement a screen
   reader actually speaks.

Also un-skipped by this stage, both green:

- **`K06-BATCH7: the rendered price is the DESIGN number`** — parked precisely
  until the batch landed, exactly as its comment predicted.
- **`K06-BUG-7: the tile that lost the race must still say why`** (in
  `pip_iter2_fixes_test.dart`) — 2a fixed the behaviour but left this parked. It
  needed one more thing: its budget was hard-coded to the old prices, so at
  30/60 a 120-coin balance affords *both* taps and the refusal never happens.
  It now sets `max(wellies, crown) + 5` — a balance that passes the bloc's
  cached pre-check for both taps (the only shape where the DATABASE is what
  refuses, which is the bug) and asserts `sum > balance` so the probe can never
  silently stop testing anything. The group name keeps "was OPEN" so the history
  stays greppable.

### FIX 3 — `pip_nest_states_test.dart` needed the drift import (done)

The new `_price` helper uses `&` on `Expression<bool>`; that file imported
`flutter/material.dart` but not `package:drift/drift.dart`, so it failed to
**compile** (`The operator '&' isn't defined for the type 'Expression<bool>'`),
which took 8 of its tests down with it. One import line, with the same
`hide isNotNull, isNull` the sibling K06 test files use.

### FIXES — nothing else

No other breakage: no import, rename, DI, route or `analysis_options` change
was needed, and `test/core/data/repositories_test.dart` (the shared pip group
2a flagged as expecting the old 75) is **already correct on `main`** — batch 7
fixed it in the same commit — so it needed nothing from here and passes.

## 5. Left for the next stages (not mine to settle)

1. **The batch-7 "delete the local copies" half** — swap `PipNestSlot` →
   `NestPetStage(slotHeight: 206, pipBottom: 81, nestFit: BoxFit.contain,
   showGlow: false, showGroundShadow: false)`, `PipCareButton` →
   `NestKidButton(trailing:)`, and the local dashed painter →
   `NestDashedBorder`. Exact call shapes are in
   `docs/screens/_shared/shared_batch7_REPORT.md` §"What K06 must switch to".
   This needs a build iteration plus a 5_ui re-check, not an integrate pass.
2. **`SHARED_REQUEST.md` §7 — the sun-hat glyph** (new, filed by this stage).
   Batch 7 left `NestIcons.sunHat` alone reporting it "already match[es] the
   design geometry"; the proof shows it does not (`m2.413.8h19.2…` +
   an extra `m7.411.6h9.2` vs the design's `m316h18…`). The note names only
   Scarf and Wellies, so this is the same defect class left with one tile, and
   K06 may not edit shared assets (RULES §1). One parked proof, oracle read from
   the HTML.
3. **`kPipNotWearable`** ("That one is not something Pip can wear.") is still
   the only on-screen string not in the design — unchanged since iteration 1,
   still awaiting ratification.
4. **`NestProgress`'s kid highlight spans the whole track** rather than only the
   filled span (shared component).
5. **The UI check has not re-run.** Two things to watch, both expected: the
   scarf/wellies tiles now draw *different* artwork (band 6 should shrink), and
   the wardrobe numbers changed 40/120 → 30/60, so the UI verdict's
   "DB-driven content is excluded" note becomes "DB == design" — stage 5 should
   now be able to hold the prices to ±2 px like any other element.

## 6. Verification

### Skips — 5, all accounted for, and one fewer than iteration 2

| Test | Why |
|---|---|
| `pip_orchestrator_notes_test.dart` — item 2 (extra): the sunhat glyph | **new**: filed as `SHARED_REQUEST.md` §7, shared asset (RULES §1). The note does not name the sun hat. |
| `kid_home/k01_bugs_test.dart` — K01-BUG-7 | pre-existing, K01's |
| `kid_home/k03_bugs_test.dart` — K03-BUG-16 / K03-BUG-17 | K03's, parked in its own loop |
| `pocket_money/p12_bugs_test.dart` — P12-BUG-04 | pre-existing, P12's |

K06 went from 4 parked to 1: the `K06-BATCH7` price proof, the `K06-BUG-7`
refusal proof and both named glyph proofs are live. `grep 'skip: true'`
across `test/features/pip` now matches exactly one declaration.

### Standing rules checked

- **PIP / DATA OVER MOCKS** — the nest slot and growth preview still use the
  active child's own `PipAvatar`; prices still render `item.priceCoins`, and
  after FIX 2 no K06 test types a price at all.
- **ORCHESTRATOR_NOTES 11:30 item 2** — satisfied for both named glyphs, proven
  against the HTML bytes.
- **FONTS / CLOCK / IDS** — `google_fonts|GoogleFonts` → 0 hits in
  `lib/features/pip` + `test/features/pip`; `DateTime.now()` → 0 in
  `lib/features/pip`; `newId(` → 0 (this screen writes no new rows).
- **COPY / ALIGNMENT / BOTTOM EDGE / KID BACKGROUND / ACCESSIBILITY / CHIP ROWS /
  LETTER SPACING / BALANCED HEADINGS** — untouched this iteration; FIX 1 swaps
  an icon asset only, and no control was re-wrapped, so the 9
  `SemanticsAction.tap` contracts are unchanged (the phantom-button proof still
  asserts exactly which nine nodes advertise a tap).
- **SIMULATORS** — none booted, installed on, screenshot or driven. No
  `flutter clean`, no `analysis_options` change, no `google_fonts` added, no
  image attached.

### Verification tails

```
$ dart format .
Formatted 586 files (0 changed) in 1.77 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 2.6s)

$ flutter test --timeout 120s
01:32 +3770 ~5: All tests passed!

$ flutter test --timeout 120s test/features/pip
00:05 +199 ~1: All tests passed!
```

Before the fixes, for the record:

```
$ flutter test --timeout 120s
01:37 +3757 ~9 -9: Some tests failed.
  … 5 × pip_atomic_writes_test.dart (wardrobe group)
  … pip_nest_interactions_test.dart  (equipping / Leo switch)
  … pip_nest_states_test.dart         (phantom buttons)
  … pip_orchestrator_notes_test.dart  (item 3 prices)
```

Two proofs worth running alone, because they are the evidence for this
iteration's two substantive claims:

```
$ flutter test --timeout 120s test/features/pip/k06_bugs_test.dart --run-skipped
  → all six K06-BUG proofs pass (no skip in the file)

$ flutter test --timeout 120s test/features/pip/pip_iter2_fixes_test.dart \
    --run-skipped --plain-name K06-BUG-7
  → passes: the refused tile now announces itself
```

## 7. Files changed by this stage

- `app/lib/features/pip/presentation/widgets/pip_look.dart` — FIX 1, the two
  glyph constants.
- `app/test/features/pip/pip_atomic_writes_test.dart` — FIX 2, 5 probes.
- `app/test/features/pip/pip_orchestrator_notes_test.dart` — FIX 2 (price
  premise read from the row), plus 4 proofs un-skipped and the sun-hat proof
  isolated as §7.
- `app/test/features/pip/pip_nest_interactions_test.dart` — FIX 2, 2 probes.
- `app/test/features/pip/pip_nest_states_test.dart` — FIX 2 + FIX 3.
- `app/test/features/pip/pip_iter2_fixes_test.dart` — the BUG-7 proof's
  budget re-based and un-skipped.
- `docs/screens/K06/2_build.md` (this file), `docs/screens/K06/SHARED_REQUEST.md`
  (§5 partly-landed, §6 done, §7 new).

No other `app/lib/**` file was touched: the merged logic + UI compiled and passed
as the two builders left it.

VERDICT: PASS
