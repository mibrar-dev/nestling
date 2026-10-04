# K01 · Who's playing? — Stage 2 (INTEGRATE, iteration 3)

Job: make the 2a (logic) + 2b (UI) halves compile and pass together. Smallest
change only — no redesign.

**Outcome: `dart format` clean (0 changed) · `flutter analyze` → No issues found
· `flutter test` → 2882 pass / 1 skip / 0 fail. Zero fixes required** — this
iteration needed no integration edit at all. Base `21c68f4` contains main.

## 1. Summary of 2a (logic, iteration 3) — `2a_build_logic.md`

Additive to the iteration-2 contract; no `domain/**` or `data/**` change needed.

- **K01-BUG-6 single-flight (bloc).** `_onProfileSelected` returns early —
  *before* writing — when `selectedProfileId` is still unconsumed. 2a's
  reasoning: handlers are sequential, so a transient `_selecting` flag is
  useless (event 2 starts only after event 1 completes); the pending one-shot
  **is** the guard. It clears via `KidHomeSelectionHandled` or the next home
  emission, so genuinely later taps are never dropped.
- **Review finding 2 (bloc).** New state field `profilesFailed` (default
  `false`, in `props`, carried by all eight constructors, set on the profiles
  error path, cleared by any healthy roster).
- **`1_plan.md` §0 apostrophe corrected** to the shipped ASCII form with the
  BUG-A history note, so the plan no longer contradicts
  `k01_copy_parity_test.dart`.
- **Tests** `k01_bloc_paths_test.dart`: BUG-6 reproducer un-skipped, plus
  dropped-burst-leaves-no-trace, outage-flag stream-health, and
  constructor/equality.
- **Deliberately not done:** no bloc-side BUG-2 latch (superseded by the BUG-6
  guard + the view latch pairing).

## 2. Summary of 2b (UI, iteration 3) — `2b_build_ui.md`

- **K01-BUG-3 (dead tile after back)** — the view half-line is now in
  `ProfilePickerView`: `KidHomeSelectionHandled()` dispatched immediately after
  the push starts. Parked widget proof un-skipped. 2b also found the proof had
  been parking on a **harness artifact** (`tester.pump` doesn't drain the real
  Drift `setActiveChild` write) and fixed the proof with
  `tester.runAsync(... Future.delayed ...)` — the same pattern as stage 3's
  `_settleAfterWrite`. Good catch: that was a bad test, not a bad product.
- **K01-BUG-6** — prevented at two layers: the view's selection gate moved from
  the `BlocListener` into tile dispatch (`_ProfilePickerViewState._select`), so
  both the normal row and `_OverflowTileRow` route every tap through one
  `_busy`-armed path; plus the bloc state-gate.
- **Stage-4 finding 2** — the `profiles.isNotEmpty → reload` view heal
  **removed**; the bloc's `copyWithProfilesRecovered` already restores
  `loaded`, so no masking branch is needed.
- Zero `skip:` blocks left on this screen.

## 3. Integration check — the real risk this iteration

Both builders independently edited **the same two bloc lines**, which is the
first genuine seam in three iterations:

| Change | 2a | 2b | Result |
|---|---|---|---|
| `_onProfileSelected` early-return on pending | yes | yes | **converged to one implementation** |
| `profilesFailed: true` on the error path | yes (field existed) | yes (field was never set) | **converged; field now actually written** |

2b flagged the overlap itself and asked for it to be acknowledged. I verified
the merged result rather than trusting that:

- `_onProfileSelected` and `_onProfilesFailed` are each present **exactly
  once**, with a single coherent comment and a single guard — no duplicated
  branch, no orphaned earlier version, no dead early-return.
- The two builders' complementary halves of finding 2 actually fit:
  2a added the `profilesFailed` **field**, 2b added the **write** that 2a's
  note said was missing ("the state flag existed but was never set"). Neither
  half is wasted, and the union is the correct fix.
- All of it is covered by `k01_bloc_paths_test.dart` (23/23).

**No mismatched BLoC states, events, imports or renamed members. No
duplicated bloc logic. No fix was needed.**

## 4. FIXES

- **None required.** I made no code change this iteration.
- **Nothing left deferred by me.** Both `LEFT FOR NEXT ITERATION` items in the
  builders' notes are test-stage/orchestrator items, not integration work:
  2b asks that its two bloc lines be acknowledged by the logic chunk — done
  here in §3 — and notes a future "loading while a prior selection hangs"
  shimmer is out of scope (state stays `loading`).

### `profilesFailed` is state-only — deliberate, not dead code

Worth recording because it looks like an oversight: `profilesFailed` is
written by the bloc and carried through every constructor, but **no view reads
it**. That is 2b's resolution of 2a's *suggested* view half-line: instead of
gating a heal on the flag, 2b **deleted the masking branch entirely** and let
the bloc's `copyWithProfilesRecovered` do the restore, so a genuine dead-home
failure always surfaces its card. The flag is still exercised (7 assertions in
`k01_bloc_paths_test.dart`, incl. constructor/equality), so it is not dead
code, and `flutter analyze` raises nothing. Both approaches are defensible;
2b's is the smaller surface. Left exactly as-is — ripping the field out would
be a redesign, and it is a plausible future guard for K02–K05.

## 5. Verification

### Skips

`k01_bugs_test.dart` and `k01_bloc_paths_test.dart` now contain **zero**
`skip:` blocks — 2b's claim verified. The single remaining repo-wide skip is
`test/features/pocket_money/p12_bugs_test.dart:321`, **pre-existing and not
K01's** (that file is untouched by this branch). No test was skipped or
disabled by me.

### Mandatory orchestrator items

`ORCHESTRATOR_NOTES.md` (02:33, unchanged since iteration 2) — all still
satisfied after this iteration's edits: **D1** (cards 16.5 px low) and **D2**
(caption top 747) fixed by 2b in iteration 2 and untouched since;
**D3/D4** remain correctly delegated to the shared `kid_meadow`; **D5** (Leo's
own Pip) correct.

### Standing rules

- **KID BACKGROUND** — K01 renders through the shared `KidScope`
  (`profile_picker_view.dart:163`). Grep for `CustomPaint`/`hill`/`meadow`/
  `gradient` across both K01 files: the only hit is the doc comment on
  `_PickerChrome`. **No local hill or meadow painting.**
- **CHILD ORDER** — no `sort` anywhere in the picker view; tiles render
  `state.profiles` in repo creation order.
- **FONTS** — no `google_fonts` / `GoogleFonts.*` in `kid_home`; the single
  grep hit is the word inside a comment asserting its absence.
- **LETTER SPACING** — none added in `profile_picker_view.dart` /
  `profile_tile.dart`.
- **CLOCK** — **zero** `DateTime.now()` in `lib/features/kid_home`; main's
  `test_clock` commit is merged, so the K03 period math runs on `appNowUtc()`.
  (2a disclosed the two pre-existing calls as orchestrator territory — that is
  now moot on this base.)
- **BOTTOM EDGE / ALIGNMENT** — unchanged by this iteration; matrix probes
  (58/58) cover both.
- **No simulator** used (stage 2 is not 5_ui); no `flutter clean`; no
  `analysis_options` change; no images attached.

### Iteration-2 carry-over resolved

The shared `list_row_trailing_test.dart` reformat I flagged last pass is now
**committed upstream** (`e195954` "checkpoint after build (iteration 2)"), so
`dart format .` reports **0 changed** — the drift no longer re-appears on this
branch. My iteration-2 flag for a durable shared fix is closed.

## 6. Verification tails

```
$ dart format .
Formatted 521 files (0 changed) in 2.25 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 5.0s)

$ flutter test
01:20 +2882 ~1: All tests passed!
```

K01-owned suites, all green in that run:
`k01_bugs_test` 23/23 · `k01_bloc_paths_test` 23/23 ·
`k01_profile_picker_matrix_test` 58/58 · `k01_profile_picker_view_test` 13/13 ·
`k01_profile_picker_geometry_test` 8/8 · `k01_copy_parity_test` 13/13 ·
`k01_copy_fit_test` 7/7 · `kid_home_bloc_test` 38/38 · `kid_home_view_test` 87/87.

## 7. Files changed by this stage

**None.** No code, test or doc outside this stage file was touched.

VERDICT: PASS
