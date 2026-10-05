# K07 · Stage 2b — build, UI chunk (iteration 5)

Scope owned and touched: `app/lib/features/pip/presentation/views/**` and
`presentation/widgets/**` for K07, plus the presentation tests named in
`FIXES_4.md`. **No domain/, data/, bloc/ or route file was edited** — the only
`app/lib` diff is the two files below. No simulator was booted, installed on,
driven or screenshotted (only stage 5 may touch
`BC440E48-B3A3-43BC-971B-0EF5DB621874`), no `flutter clean`, no
`analysis_options` change, no `pkill`, no whole-app `flutter test`.

`2a_build_logic.md` carries **no CONTRACT CHANGES** for iteration 5 (re-read at
the end of this stage; the logic builder's iteration-4 note stands: the public
bloc surface is unchanged from iteration 2/3). Nothing in the logic layer moved
under this build.

**`ORCHESTRATOR_NOTES.md` gained an 03:03 (iteration 5) update mid-stage and it is
mandatory** — it gives the exact fix for K07-BUG-8/K07-BUG-9. This build
implements it to the letter; see "The orchestrator's 03:03 ruling" below for the
item-by-item mapping. All other `ORCHESTRATOR_NOTES` items (D1–D4) are unchanged
and remain satisfied.

## The orchestrator's 03:03 ruling — item by item

`ORCHESTRATOR_NOTES.md` 03:03 ("iteration 5, exact fix for K07-BUG-8/9
(mandatory)") appeared mid-stage and overrides my first cut of the stats fix.
Every item:

| ruling | implementation |
|---|---|
| "Stats row: REMOVE the per-card `FittedBox` entirely" | Removed — the `Column` lays out directly in the card. |
| "All three numbers use the identical NestType style at the ambient text scale (no per-card scale-down), single line, `softWrap: false`" | All three are `NestType.kidTitle` at the one `30/34` call-site pair, `maxLines: 1`, **`softWrap: false`** added. (My first cut had `maxLines: 1` without `softWrap: false`; the orchestrator's version is explicit and is what ships.) |
| "Labels wrap freely with NO `maxLines`" | `maxLines: 2` + ellipsis **removed** from the label. This part was not in my first cut; it also needed the `IntrinsicHeight` row kept so a wrapped label grows all three cards. |
| "Keep the equal-height cards from iteration 4 (IntrinsicHeight + CrossAxisAlignment.stretch)" | Kept verbatim. |
| "Number tops must be identical across the three cards (test: equal `getTopLeft().dy` at 390 and 320, scale 1.0 and 1.3, numbers up to 9999)" | New widget test **in this stage's own file**, `pip_evolution_widget_test.dart` → `the three stat NUMBERS share one top edge and one type size at 390 and 320 px, scale 1.0 and 1.3, up to 9999 coins (ORCHESTRATOR_NOTES 03:03)`. It writes `pip_total_coins = 9999`, pumps through `pumpEvolution` (the app shell, so the 1.3 is the clamped device value) and asserts the top and painted-height spreads across all four combinations. Passing. |
| "Caption `.kcap`: remove `maxLines: 3` and the ellipsis (same as K07-BUG-7)" | Done — see K07-BUG-9 below. |
| "Geometry at 390 / scale 1.0 must stay identical to iteration 4 (UI check passed there)" | Verified: the iteration-4/`k07_bugs` control at 390/1.0 pins 110×84 at x 20/140/260 with the numbers at 34.00 px, and `pip_evolution_widget_test`'s `110 wide with 10 px gaps` pins y 545 / height 84. All pass unchanged; at 390/1.0 nothing scales, so the removal is invisible there. |
| "Bug hunt next pass: only report NEW major defects … sub-pixel layout differences under 2 px are not majors" | Noted for the next pass; nothing to implement in the UI layer. |

Note the ordering effect: a wrapped label now makes the cards taller than 84 px
at narrow widths, which is the same content-driven growth iteration 4
introduced and is what the browser does (`.k7-stats > div` height is auto).

## Files changed

| file | change |
|---|---|
| `lib/features/pip/presentation/widgets/pip_evolution_stats.dart` | dropped the per-cell `FittedBox(fit: scaleDown)`; the cells' `Column` now lays out directly at ONE 30 px/34 and one 14 px/18 for all three cards, number `maxLines: 1` + `softWrap: false`, label with no cap at all — **K07-BUG-8** |
| `lib/features/pip/presentation/views/pip_evolution_view.dart` | dropped the caption's `maxLines: 3` + ellipsis; corrected the hero comment that leaned on an unreachable 3.16× — **K07-BUG-9** |
| `test/features/pip/k07_bugs_test.dart` | dropped both remaining `skip: true` flags (K07-BUG-8, K07-BUG-9) |
| `test/features/pip/pip_evolution_widget_test.dart` | +1 test: the orchestrator's own number-top/size proof over 390/320 × 1.0/1.3 × 9999 coins |

The `IntrinsicHeight` + `CrossAxisAlignment.stretch` row from iteration 4 is
**kept** — FIXES_4's own control asserts the design 110×84 at x 20/140/260 and
that control is unchanged and green, so the stretch is a load-bearing part of the
fix, not reverted.

## K07-BUG-8 (MAJOR) — one type size for all three numbers

`app/lib/features/pip/presentation/widgets/pip_evolution_stats.dart`, `_StatCell`:
the per-cell `FittedBox(fit: BoxFit.scaleDown)` is **removed**; the number + label
`Column` now lays out directly inside the card's 12/6 padding, top-aligned
(`MainAxisAlignment.start`) because CSS block flow starts `.k7-stats b`/`span`
at the top of the padding box — the three numbers then share one top edge no
matter how many lines any one label wraps to (`center` would re-splay them at an
intermediate width where only some labels wrap).

This is option 1 of FIXES_4's three, which that file itself calls "the only one
of the three that is exactly CSS-faithful at every width": `.k7-stats > div`
fixes each card at `flex: 1` and `.k7-stats b`/`span` set **one** `font-size` for
all three cards, so a browser that runs out of room **wraps** the label — it never
shrinks one card's type. The app's per-cell `scaleDown` was doing exactly that,
because each cell's content has a different intrinsic width (`4`/`120`/`3`,
`quests done`/`coins grown`/`of 4 stages`), so the narrower cells shrank less:

| width / scale | painted number heights (before) | number-top drift (before) |
|---|---|---|
| 390 / 1.3 (the app's own max) | 39.37 / 39.51 / **43.40** | **3.16 px** |
| 320 / 1.0 (no a11y setting) | 29.52 / 29.63 / **32.54** | **2.40 px** |
| 390 / 1.0, `pip_total_coins = 999 999 999` | 34.00 / **19.31** / 34.00 | — |

With the `FittedBox` gone all three numbers are the design's single line box
(34.00 px at scale 1.0, 44.00 at 1.3) and their tops are the card top + padding
for all three. The label wraps inside the fixed card width with **no cap** when
it must — the orchestrator's 03:03 ruling, and what CSS does: `.k7-stats span`
is `display: block` with no clamp, so the line wraps and the card's auto height
grows.

`softWrap: false` is on the **number**, per the ruling, and is correct rather
than a leftover: `.k7-stats b { display: block; font-size: 30px; line-height:
34px }` is a **single** line in CSS, and K07-BUG-9's own reachability argument is
now bounded by `app.dart`'s 1.0–1.3 clamp — at 1.3 on a 320 px card (inner
~86 px) a 1-digit number is ~24 px wide, so all three numbers fit, and the new
widget test above proves it up to 9999 coins. The iteration-4 control
`K07-BUG-8 fix cannot be "shrink every card by the same amount"` pins the
390/1.0 result at 34.00 / 110 / 84 and passes untouched.

**What moved in the negative direction, measured:** the cards at 320 px are now
tall enough for a wrapped label **and** a full 34 px number, i.e. the K07-BUG-6
behaviour (content-driven growth, one height) is preserved. Numbers cannot
overflow their card at any supported width/scale; a 9-digit value at 320 px
would clip inside the card rather than shrink, which is exactly what a browser
does too, and the design's own answer to "too wide" is wrapping, not scaling.

## K07-BUG-9 (minor) — the caption's cap is gone

`app/lib/features/pip/presentation/views/pip_evolution_view.dart`: dropped
`maxLines: 3` and `overflow: TextOverflow.ellipsis` from `k07-caption`.

Verified against the source rather than memory: `.kcap`
(`K07-evolution.html:14`) sets only `font-family`, `font-weight`, `font-size`,
`line-height` and `color` — **no clamp** — and `.scroll` scrolls, so the browser
grows the line. This was the same app-only clamp K07-BUG-7 removed from the hero
and the sub, left behind on the caption. FIXES_4 notes the cap is **not
reachable today** (the shell clamps at 1.3, where the caption needs 1–2 lines);
it is fixed anyway because "app-only" is the defect, and the permanent proof now
prevents the fourth cap being re-added silently.

Also corrected, exactly as FIXES_4 asks: the hero/sub comment that justified
removing the two caps with "iOS reaches 3.16×" — a scale `app.dart:17-20` clamps
away — is restated as **"the cap is app-only and the design has none; do not
re-add it"**, so a future pass cannot use the unreachable-scale claim to
"restore" a cap.

### Knock-ons checked

None, and FIXES_4's own note says so. `pip_evolution_copy_test.dart:353` only
asserts the caption is *not* a `NestBalancedText` (the balanced-heading rule),
which is orthogonal; `k07_bugs_test.dart:1611` and the 280/320/390 matrix assert
`didExceedMaxLines == false`, which stays true with the cap gone. Confirmed by
running both suites (below) — unlike the hero/sub caps, nothing pinned this one.

## Also handled: the iteration-4 bug hunt's new controls

Both iteration-4 controls (`the app clamps the OS text scaler to 1.0–1.3` and
`K07-BUG-8 fix cannot be "shrink every card by the same amount"`) were already
present and green, and the harness-bug fix the bug stage applied to itself
(`addTearDown(clearTextScaleFactorTestValue)`) is intact — with both skips
dropped, `k07_bugs_test.dart` now runs **+34 with zero skips**.

## Gates (this stage only, every run with `--timeout`)

```
$ dart format lib/features/pip/presentation/{views,widgets} \
      test/features/pip/{k07_bugs,pip_evolution_widget}_test.dart
    Formatted (0 changed)

$ flutter analyze lib/features/pip test/features/pip/pip_evolution_widget_test.dart \
      test/features/pip/k07_bugs_test.dart
    No issues found! (ran in 11.6s)

$ flutter test --timeout 120s test/features/pip/k07_bugs_test.dart
    → +34: All tests passed!     (was +32 ~2 — both parked proofs now RUN)

$ flutter test --timeout 120s  <the 14 K07 presentation suites>   # view, widget,
      copy, a11y, iter2_fixes, stats_scales, stream_contract, nest_view,
      nest_widget, sparks, orchestrator_notes, sparkles_bug,
      shared_component_fidelity, k07_bugs
    → +218: All tests passed!

$ flutter test --timeout 120s test/features/pip/pip_evolution_widget_test.dart
    → +25: All tests passed!     (was +24 — the orchestrator's number proof)
```

218 K07 presentation proofs green (this stage's 14-file run), including the new
widget proof of the orchestrator's four number-top combinations, with zero skips
left inside `k07_bugs_test.dart`. Nothing hung; nothing ran longer than a minute.
Files were named rather than passing `test/features/pip` wholesale, because
iteration 2 measured that `pip_buy_result_test.dart` stalls when the whole
directory runs at once; the integrator's directory run should cover it and the
K06 suites, which this diff cannot affect.

The FIXES_3-relevant evidence is unchanged: the 390 px / 1.0 control in
`k07_bugs_test.dart` still pins the cards at 110×84, x 20/140/260 and the numbers
at 34.00 px, so the iteration-4 stretch fix and this iteration's type fix hold
together at the geometry the UI check passed in iteration 4.

## Deliberately not actioned

- **`4_review.md` finding 1's `alignment: Alignment.topCenter` / "numbers sit
  ~12 px below the CSS position"** — superseded by this fix, not skipped. That
  finding asked for the number **tops** to be asserted and FIXES_4's K07-BUG-8
  is that assertion; with the `FittedBox` gone, the numbers' tops are
  card-top + 3 px border + 12 px padding for all three, i.e. the CSS inset, and
  the one-height row (iteration 4) keeps that identical across the three cells.
  There is no longer a per-cell scale or alignment to correct.
- **`4_review.md` finding 3 / „Carried from stage 4" item 3** — `evolutionSub(0)`
  still renders "Because you helped 0 times". Unchanged for the third iteration:
  it is `pip_evolution_copy.dart` (2b's file) but the wording needs an
  orchestrator sign-off that `SHARED_REQUEST.md` item 5 and
  `ORCHESTRATOR_NOTES.md` do not give, and inventing copy is worse than leaving
  it. Listed under `LEFT FOR NEXT ITERATION` again.
- **The correction in FIXES_4** ("do not hunt 2×–3.2×; the envelope is
  1.0–1.3") — adopted, not actioned as code. It is quoted in the corrected
  comment and drove the decision to leave the number's `maxLines: 1` alone.
- **`SHARED_REQUEST.md` items 1–5** — still open where the orchestrator has not
  ruled. Item 4 (the off-token `#3D7FF0` dot) must **not** be "fixed" locally:
  the D4 ruling paints the light sky token in both themes.
- **`1_plan.md` §(a).3/§(a).4/§(a).6 re-ratification** — carried from iteration 4.
  The plan still documents the hero/sub caps that iteration 4 dropped and the
  diagram still shows `Row(spacing: 10)` where the tree has
  `IntrinsicHeight > Row(stretch: true)`; this iteration adds §(a).6's
  `FittedBox`-based description to what needs re-ratifying. Documentation only;
  no code is blocked by it, and the plan is not 2b's file.

## LEFT FOR NEXT ITERATION

1. **`evolutionSub(0)`'s zero branch** (`pip_evolution_copy.dart`) — needs an
   orchestrator wording ruling before any code moves. When it lands,
   `k07_bugs_test.dart`'s `0 and 999999999 coins…` control pins today's wording
   and must move on purpose.
2. **`1_plan.md` re-ratification** by the orchestrator for §(a).3 (hero cap),
   §(a).4 (sub cap), §(a).6 (`Row(spacing: 10) stats`, the removed per-cell
   `FittedBox`, `softWrap: false` on the number, no cap on the label) — the
   shipped values are "no caps anywhere the design has none" and "one type size
   for all three stat cards". Documentation only.

## Verdict

The UI layer is implemented: `FIXES_4.md`'s two open items are both closed in the
files this stage owns, the mid-stage `ORCHESTRATOR_NOTES.md` 03:03 ruling is
implemented item by item (including its own new number-top proof in this stage's
test file), the iteration-4 stretch fix is preserved and proven alongside them,
both parked proofs are un-skipped and green, and the unreachable-3.16× comment
the fix list flagged is corrected so the caps cannot be restored by accident.
`k07_bugs_test.dart` has no skips left. Nothing is left half-done.

VERDICT: PASS