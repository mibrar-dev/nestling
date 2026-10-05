# K07 · 2 BUILD (integrate, iteration 5) — 2a logic + 2b UI combined

Job: make the two parallel halves compile and pass together. No simulator was
booted (only `5_ui` may touch `BC440E48-B3A3-43BC-971B-0EF5DB621874`), no
design was redesigned, no shared file touched (RULES §1: `features/pip/**` +
`test/features/pip/**` + this folder only), no `pkill`, no `flutter clean`.

**No integration repair was needed.** 2a changed no `lib/` and no `test/` file
at all, and `ORCHESTRATOR_NOTES.md` gained a mid-stage **mandatory** update
(03:03) which 2b implemented item by item. So again the work is verification —
including auditing the mandatory ruling against the shipped diff rather than
against 2b's summary of it — plus loop hygiene.

## What landed

### 2a — non-UI layer (`2a_build_logic.md`, iteration 5)

CONTRACT CHANGES: **none**; the public surface is byte-identical to iteration 3
(re-verified by iterations 4 and 5).

- **No code changed** — the note file only. `1_plan.md` §(b) audited complete,
  and **not one item of `FIXES_4.md` or `4_review.md` sits in this layer**:
  every finding names a views/widgets file, the shared tokens file, or the
  orchestrator, and both parked proofs measure painted widget geometry.
- Deliberately left both `skip: true` lines in place rather than half-opening a
  proof it could not make green — the un-skipping belongs with the fix, in one
  commit (which is how 2b shipped it).
- Recorded the iteration-4 bug-hunt **CORRECTION** (the shell clamps the OS text
  scaler to 1.0–1.3, so 2×–3.2× reachability arguments are unreachable) so
  iteration 6 does not re-litigate it, and re-confirmed the layer's properties:
  no clock read added or existing, coins never rendered as `£`.

### 2b — presentation layer (`2b_build_ui.md`, iteration 5)

Implemented the 03:03 ruling to the letter, after it overrode 2b's first cut:

- **K07-BUG-8 (MAJOR)** — `pip_evolution_stats.dart`: the per-cell
  `FittedBox(fit: scaleDown)` is **removed**. All three numbers use the
  identical `NestType.kidTitle` at the one 30/34 call-site pair, `maxLines: 1`
  **+ `softWrap: false`**; the label has **no cap at all**; the
  `Column` is top-aligned so the three numbers share one top edge however many
  lines any one label wraps to. Iteration 4's
  `IntrinsicHeight` + `CrossAxisAlignment.stretch` is **kept verbatim** — it is
  load-bearing, not a leftover.
- **K07-BUG-9 (minor)** — `pip_evolution_view.dart`: the caption's app-only
  `maxLines: 3` + ellipsis removed; the hero comment that leaned on an
  unreachable 3.16× restated as "the cap is app-only and the design has none; do
  not re-add it".
- Both remaining `skip: true` flags dropped, and the orchestrator's own
  number-top proof added in `pip_evolution_widget_test.dart` (390/320 × 1.0/1.3 ×
  9999 coins, asserting the three painted `RichText` rects share a top edge and a
  painted height to ≤ 0.5 px).

## FIXES

### Done — 1. The mandatory 03:03 ruling audited item by item against the diff

| ruling | verified in the shipped code |
|---|---|
| "REMOVE the per-card `FittedBox` entirely" | gone; the `Column` lays out directly in the card |
| "identical NestType style at the ambient text scale … single line, `softWrap: false`" | one 30/34 call-site pair for all three, `maxLines: 1`, `softWrap: false` |
| "Labels wrap freely with NO `maxLines`" | the label's `maxLines: 2` + ellipsis are gone |
| "Keep the equal-height cards … (IntrinsicHeight + CrossAxisAlignment.stretch)" | unchanged from iteration 4, in the untouched part of the diff |
| "Number tops must be identical (test: equal `getTopLeft().dy` at 390 and 320, 1.0 and 1.3, up to 9999)" | the new widget test does exactly that matrix, on painted rects |
| "Caption `.kcap`: remove `maxLines: 3` and the ellipsis" | done, with the HTML line cited in the comment |
| "Geometry at 390 / scale 1.0 must stay identical to iteration 4" | see Done 2 |

### Done — 2. The 390/1.0 geometry gate, so `5_ui`'s band table must not move

Iteration 4 is the iteration whose UI check passed, so the ruling's "geometry at
390 / scale 1.0 must stay identical" is the load-bearing claim. The design pins
are untouched and green in the current tree: the three cards 110 wide at
x 20 / 140 / 260, 84 tall (`3 + 12 + 34 + 2 + 18 + 12 + 3`), top **545**, and
the number box's bottom at `545 + 34`. At 390/1.0 nothing scales, so removing
the `FittedBox` is invisible there — which is why this stage could make the fix
without touching the verified band table.

### Done — 3. Loop hygiene

- **Zero skips** in `test/features/pip` — verified by grep (only the two hits are
  lines 13 and 20 of `k07_bugs_test.dart`'s own convention comment) and by the
  directory run reporting no `~` marker. `k07_bugs_test.dart` runs its whole
  file.
- No scratch artefact carried over: nothing untracked under `app/`, and
  `dart format --set-exit-if-changed .` reports 0 changed.
- `pip_buy_result_test.dart`'s directory-run stall (`6_bugs.md` observation 3)
  did **not** reproduce — second consecutive iteration; the directory finished in
  27 s. Recorded as unreproduced, not fixed: nobody changed it.

### Verified, no change needed

- **Contract**: 2a says none, and the tree matches. Both views still switch on
  their own stream (`state.evolutionStatus` / `state.nestStatus`), the stats are
  still fed `evolution.questsFinishedCount`, and `PipLoadRequested` still opens
  both streams (unchanged on purpose — `SHARED_REQUEST.md` §2 has no ruling).
- **Tokens only**: every size in the changed widget comes from
  `EvolutionStatsGeometry` or a `NestType` call-site pair; no colour or literal
  size was introduced, and no shared file was touched.
- **Nothing outside RULES §1 was edited by me**; no `analysis_options` change, no
  `google_fonts`, no `DateTime.now()`, no `Wrap`/`Row` chip rows.

### Left

- **`evolutionSub(0)`** = "Because you helped 0 times" under "Pip grew into a
  Hatchling!" — the missing zero branch needs a wording ruling
  (`SHARED_REQUEST.md` item 5; no ruling in `ORCHESTRATOR_NOTES.md`). Third
  iteration carried; no copy invented. When it lands,
  `k07_bugs_test.dart`'s `0 and 999999999 coins…` control must move on purpose.
- **`1_plan.md` re-ratification (orchestrator)** — the plan now diverges in five
  places: §(a).3 hero cap, §(a).4 sub cap, and §(a).6's `Row(spacing: 10) stats`,
  its `FittedBox(scaleDown)` guard, and `maxLines: 1` on the stat label. The
  shipped values are "no cap anywhere the design has none" and "one type size for
  all three cards". **I did not edit the plan**: it is the build stage's
  contract, and 2b is not its owner. Documentation only; no code is blocked, and
  `k07_bugs_test.dart` + `pip_evolution_copy_test.dart` pin the shipped values so
  a silent regression fails loudly.
- **`SHARED_REQUEST.md` §1-§5**, non-blocking notes for the orchestrator: the
  K07 background deviation (no `KidScope`, no `.meadow`), the screen-scoped load
  event, the no-entry-point note, the `shot.sh` pre-first-frame save, and the
  off-token `#3D7FF0` sky dot (§4 — must **not** be "fixed" locally; the D4
  ruling paints the light sky token in both themes).
- **`5_ui`**: re-verify the dark sparkles (D4) and the stat-card band, expected
  unmoved at 390/1.0 per Done 2.
- **No in-app entry point for `/pip-evolution`** — the CTA leaves to `/pip`;
  whether K06 should open K07 on a stage-up is the K06/flow owner's call.
- **The 03:03 hunt-scope ruling** ("only NEW major defects a child or parent
  would actually see at supported settings; sub-2 px differences are not
  majors") applies to the next bug pass; nothing to implement here.

## Gates

```
$ dart format .
Formatted 643 files (0 changed) in 2.65 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 6.1s)

$ flutter test --timeout 120s test/features/pip
00:27 +452: All tests passed!      (no `~`: zero skips in the feature)

$ flutter test --timeout 120s
05:15 +4508 ~10: All tests passed!
```

`~10` are the suite's own skips and **none is K07's**: `k01_bugs` (1),
`k03_bugs` (2), `k09_bugs` (6), `p12_bugs` (1). The whole-suite run took 5:15
this iteration (main added tests since iteration 4's 1:40) — comfortably inside
the 10-minute rule, nothing hung.

Files changed by this stage: **none** under `app/` — iteration 5's integration
needed no code change — plus this `docs/screens/K07/2_build.md`.

VERDICT: PASS