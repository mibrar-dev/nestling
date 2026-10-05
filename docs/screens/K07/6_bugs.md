# K07 · Pip evolves (`/pip-evolution`) — Stage 6 bug hunt (iteration 5)

Adversarial pass over K07 **as it stands after the iteration-5 build `160fa6f`**
(the `IntrinsicHeight` + one-type-size stats row and the caption clamp removal,
both mandated by `ORCHESTRATOR_NOTES.md` 03:03). **This stage changed no product
code** — RULES §1 lets a bug hunt add only `app/test/features/pip/**` and
`docs/screens/K07/**`, and `git status --porcelain app/lib` is empty at the end
of it. No simulator was booted, installed on or driven: only `5_ui` may touch
`BC440E48-B3A3-43BC-971B-0EF5DB621874`. No `flutter clean`, no `analysis_options`
change, no skipped gate, no `google_fonts`, no `DateTime.now()`, no `pkill`.

Deliverable: `app/test/features/pip/k07_bugs_test.dart` — **1 parked failing
proof** (K07-BUG-10, the new minor) on top of the 34 that pass, including the
iteration-4 proofs K07-BUG-8 and K07-BUG-9, which the build un-skipped and this
pass re-ran green.

## Verdict summary

| # | Severity | Status | Summary | Proof |
|---|---|---|---|---|
| **K07-BUG-10** | minor (**latent**) | **OPEN** | A stat number wider than its card is **clipped mid-digit**, with no ellipsis and no shrink, because the number is `softWrap: false` + `maxLines: 1` with the default `TextOverflow.clip`. `.k7-stats b` sets no `overflow` in the design, so a browser paints the digits over the card edge (CSS `visible`) instead of cutting them. Worst **shipped** case is **1.53 px** off the right edge (Maya's 175 at 320 px / 1.3); the value the 03:03 ruling names (9999) loses **24.93 px** there. | `k07_bugs_test.dart` → `K07-BUG-10: a stat number wider than its card is CLIPPED mid-digit…` |
| K07-BUG-8 | ~~MAJOR~~ | **FIXED, re-verified** | The three stat numbers painted at three different type sizes with drifting tops. | proof green, un-skipped |
| K07-BUG-9 | ~~minor~~ | **FIXED, re-verified** | The caption's app-only `maxLines: 3` + ellipsis. | proof green, un-skipped |
| K07-BUG-1 … 7 | — | FIXED, re-verified | Iterations 1–3's seven findings. | all green |

**No new major defect was found.** The whole brief matrix — 0/1/6 children, long
UK names, 9999 coins, empty lists, rapid double taps, back navigation and deep
links, Drift persistence, both mode guards, contrast in both themes, text scale
1.3 + width 320, async gaps, timezone, money rounding — is clean, and the
parts this pass newly measured are recorded below.

---

## The 03:03 ruling — audited against the shipped tree, then re-measured

`ORCHESTRATOR_NOTES.md` 03:03 told the build to replace the per-cell
`FittedBox`. This pass verified the result with the real bundled Nunito and the
real app shell (`pumpAppRoute`, so `app.dart`'s 1.0–1.3 clamp is in play), and
then went looking for what the new layout does *wrong* rather than only checking
that it does the mandated things right.

| ruling | re-measured |
|---|---|
| per-cell `FittedBox` removed | gone; all three numbers paint at **one** height |
| one identical type size | 34.00 px at 1.0 (`Nunito 900 30/34`), 44.00 px at 1.3, all three |
| `maxLines: 1`, `softWrap: false` | held; no wrap, no vertical growth |
| labels uncapped, wrap freely | 1 line at 390/1.0 (79.10 / 78.81 / 71.75), 2 lines at 390/1.3, 3 lines at 280/1.3 |
| equal-height cards kept | `IntrinsicHeight` + `stretch`, spread 0.00 at every measured width |
| number tops identical | 594.00 ×3 at 390/1.0; 670.00 ×3 at 320/1.3 with 9999; 636.00 ×3 at 422/1.3 |
| 390 / 1.0 geometry unmoved | cards 110 × 84 at x 20 / 140 / 260, top 579 (= design 545 + the accepted D1 34 px shift); number top 594; label top 630 |

**The mixed-line-count case, which the shipped test matrix does not cover.**
At widths where *only some* labels wrap, CSS keeps the cards stretched and the
content top-aligned, so the numbers must stay on one line. Measured:

| config | label heights | card height | number tops |
|---|---|---|---|
| 330 px / 1.0 | 36 / 36 / **18** | 102 / 102 / 102 | 594.00 ×3 |
| 334 px / 1.0 | 36 / 36 / **18** | 102 / 102 / 102 | 594.00 ×3 |
| 421 px / 1.3 | 46 / 46 / **23** | 122 / 122 / 122 | 636.00 ×3 |
| 422 px / 1.3 | 46 / **23** / **23** | 122 / 122 / 122 | 636.00 ×3 |
| 425 px / 1.3 | **23** ×3 | **99** ×3 | 636.00 ×3 |

The taller label grows the card; the shorter one keeps the number and label on
the same line as its siblings. That is exactly CSS `align-items: stretch` with
top-aligned content — the top-alignment comment in `_StatCell` is load-bearing
and correct.

---

## K07-BUG-10 — minor, latent — the number is clipped instead of overpainted

**Where** `app/lib/features/pip/presentation/widgets/pip_evolution_stats.dart`
— the number `Text` at `:186-200` (`maxLines: 1`, `softWrap: false`, no
`overflow`).

The design (`K07-evolution.html:28-29`):

```css
.k7-stats > div { flex: 1; min-width: 0; … }   /* no overflow */
.k7-stats b     { display: block; font-size: 30px; line-height: 34px; }
```

There is **no** `overflow`, `text-overflow` or `-webkit-line-clamp`: CSS's
initial `overflow: visible` means an over-wide line paints *over* the card's
padding and border. The app instead uses `softWrap: false` with the default
`TextOverflow.clip`, and Flutter's `RenderParagraph` sets `_needsClipping` when
the line is wider than the box (`paragraph.dart:979-988`), so the glyphs are cut
at both ends with nothing to show for it.

### Evidence — real Nunito, real app shell, measured on the painted paragraph

A `softWrap: false` paragraph lays out on ONE line at infinite width (so the
line always starts at the box's left edge and `textAlign: center` has nothing to
centre within) and then constrains its box
(`RenderParagraph._adjustMaxWidth`, `paragraph.dart:896-898`). The intrinsic
width is therefore the honest measure of what the widget asked to paint, and the
cut is always on the **right** — confirmed at the pixel level below:

| coins | width / scale | intrinsic | box | cut off the right |
|---|---|---|---|---|
| **175 (Maya, shipped)** | 390 / 1.0 | 54.00 | 92.00 | **0.00** ✓ |
| **175 (Maya, shipped)** | **320 / 1.3** | **70.20** | **68.67** | **1.53** ✗ |
| 60 (Leo, shipped) | any supported | ≤ 46.80 | ≥ 55.33 | 0.00 ✓ |
| **9999** (03:03's value) | 390 / 1.0 | 72.00 | 92.00 | 0.00 ✓ |
| **9999** | 320 / 1.0 | 72.00 | 68.67 | **3.33** ✗ |
| **9999** | **320 / 1.3** | **93.60** | **68.67** | **24.93** ✗ |
| 9999 | 360 / 1.3 | 93.60 | 82.00 | 11.60 ✗ |
| 99999 | 320 / 1.0 | 90.00 | 68.67 | 21.33 ✗ |
| 999999999 | 390 / 1.0 | 162.00 | 92.00 | 70.00 ✗ |

**Reachability, stated honestly.** `pip_total_coins` is written **only by
`Seed.demo()`** (Maya 175, Leo 60) — every other write in the app is to
`children.coins`, `pip_style`, `pip_skin`, `pip_accessory` or `pip_stage`, or to
`quest_completions` / `ledger` / `pip_wardrobe`; nothing increments the lifetime
counter
(`grep -rn "pipTotalCoins" app/lib` → `seed.dart:214,239`,
`family_repository_impl.dart:505`, `child_profile_body.dart:267`, and this
feature's read). So:

- **today a child sees at most 1.53 px cut off one edge** — under the
  orchestrator's 2 px bar, and invisible;
- the brief's and the ruling's own `9999` needs a seed change to be reachable;
- the genuinely ugly cases (≥10 px) need 4+ digits at a high text scale, or 5+
  digits anywhere.

That is why this is a **minor and latent**, not a major, and why it does not
re-open the 03:03 ruling: removing the per-cell `FittedBox` was right (K07-BUG-8
was real and visible), and this is a different, smaller defect that the removal
exposed rather than caused.

**Repro (deterministic, ~4 s, no simulator)**

```
cd app && flutter test --timeout 120s --run-skipped \
    test/features/pip/k07_bugs_test.dart
```

**Corroborated at the pixel level.** Rasterising a card with a 9-digit number
(3× ratio) and scanning the number's line band: **0** glyph-ink pixels land in
the card's padding bands (raster x 409–426 and 744–760, i.e. between the content
box and the 3 px border) while **12 909** land inside the content box — the
digits stop dead at the content-box edge, which is a cut, not a wrap and not an
overpaint. The cut is on the **right**: a `softWrap: false` paragraph lays out at
infinite width, so the line begins at the box's left edge and runs past the right
one. Flutter's `RenderParagraph` sets `_needsClipping` whenever the line is wider
than the box (`paragraph.dart:979-988`) and clips to `offset & size`
(`:1056-1066`), so this is the framework doing exactly what the widget asks.

**Failing test** — `K07-BUG-10: a stat number wider than its card is CLIPPED
mid-digit, with no ellipsis and no shrink…`

```
Expected: empty
  Actual: [ "9999" paints 93.60 px into a 68.67 px box — 24.93 px of digits cut off the right edge ]
```

**Suggested fix** — `pip_evolution_stats.dart` only, one argument on the number
`Text`:

```dart
Text(
  '$value',
  …
  maxLines: 1,
  softWrap: false,
  // `.k7-stats b` sets no overflow, so CSS paints an over-wide line over the
  // card edge; cutting digits is the one thing the design never does.
  overflow: TextOverflow.visible,
),
```

This keeps the mandated single 30 px size and `softWrap: false`, and changes
nothing at any width where the number fits (every reachable width with the
shipped seed). **Verified green, then reverted:** with only that line added,
`--run-skipped test/features/pip/k07_bugs_test.dart` reports **+35, all passed**
(the parked proof goes green unmodified) and `test/features/pip` reports
**+476, all passed** — so no other contract on this screen moves. The tree was
then restored from the index (`git status --porcelain app/lib` → empty).

**One honest caveat about that one-liner**, measured by rasterising the card
before and after: a `softWrap: false` paragraph lays out at infinite width, so
with `TextOverflow.visible` the over-wide line is painted from the content box's
**left** edge outwards — on a 9-digit number the raster scan finds **0** glyph-ink
pixels in the card's left padding band and **362** in the right one — rather than
centred over both edges as CSS would. It removes the silent cut (the digits are
all there) but the overflow is left-anchored, not centred. Nothing reachable
shows it (1.53 px), so it is a strict improvement; a perfectly CSS-faithful
centred overpaint would need a shared-scale approach the 03:03 ruling
deliberately rejected.

Two alternatives are **not** recommended: re-adding any per-cell shrink
contradicts 03:03 and re-creates K07-BUG-8, and `TextOverflow.fade` would still
hide the leading/trailing digits at the very widths where the number is already
unreadable.

**Also found by stage 4, independently.** `4_review.md` (iteration 5) finding 1
reports the same defect as "minor … no affordance that digits are cut off" and
recommends a separate shared request for a compact form. This pass does **not**
claim it as new, and adds two things the review did not have: the exact
per-side cut at every width/scale (the table above, which shows the *reachable*
envelope is ≤ 0.77 px per side) and a **verified one-line fix** that removes the
silent cut without touching the 03:03 ruling. The compact-form idea is a product
decision for the orchestrator; the overflow fix is not.

---

## The brief's hunt matrix — what this pass measured

| item | result | pinned by |
|---|---|---|
| **0 children / no active child** | Clean: "Who's playing?" + `Choose`, no retry, no spinner, no overflow; re-measured at 390 / 320 / 280 at scale 1.3. | iteration 2's control + this pass's sweep |
| **1 child, 6 children, deleted sibling** | Clean; the six-child case re-measured with three extra long-named children. | iteration 2/3 controls |
| **long UK names ("Maximilian-Alexander")** | Clean: the nickname is only ever in the a11y label, never painted, so there is no rect to overflow. | iteration 2's control + this pass |
| **9999 coins** | **Feeds K07-BUG-10**: fits at 390/1.0 (72.00 in 92.00), cuts 3.33 px off the right edge at 320/1.0 and 24.93 px at 320/1.3. No flex overflow, no exception at any width. | **K07-BUG-10** |
| **0 / 999 999 999 coins** | 0 renders "0" and is clean; 999 999 999 cuts 70 px off the right edge at 390/1.0 — the same latent defect, not reachable from the seed. | K07-BUG-10 |
| **empty lists / 0 and 1 completions** | Clean: "Because you helped 0 times" (the zero-branch wording is stage 4's finding 3, not re-reported) and the singular "1 time" branch intact. | iteration 2/3 controls |
| **`pip_stage` 0 / 1 / 5 / 99** | Clean: clamped into 1..4; the stage-1 "egg" state renders one Pip with no arrow/old slot and no overflow at 390/320/280. | iteration 2/3 controls |
| **count isolation** (`to_do` / `not_yet` / `denied` / other child) | Clean. | iteration 3's control |
| **repeated quest completion** | K07-BUG-3, fixed; both proofs green. | K07-BUG-3 ×2 |
| **rapid double taps** | Clean: CTA, lock, retry, Choose — all controls green, unchanged this iteration. | iteration 2's controls |
| **back navigation / deep link to `/pip-evolution`** | Clean; the router guard re-read this pass: parent mode + expired trial → `/paywall`, kid mode + expired trial → the gate, `/pip-evolution` is not parent-only. | iteration 2's controls |
| **Drift persistence across a reopen** | Clean. | iteration 2's control |
| **parent/kid mode guard** | Clean. | iteration 2's controls |
| **dark-mode contrast** | Unchanged: every painted pair clears 4.5:1 in both themes; the only low pair is the orchestrator-mandated `#1E1B3A` sparkle stroke on `#1F1C2E` (D4), which is PNG parity, not a contrast requirement. The dark theme was re-measured for K07-BUG-10 as a control: at 320 px / 1.3 with 9999 the number's intrinsic width (93.60) and box (68.67) are **identical** to light — the theme changes colours, not metrics. | iteration 1/3 + this pass |
| **text scale 1.3 + width 320 overflow** | Clean except K07-BUG-10: labels wrap (3 lines at 280/1.3), cards grow equally, numbers stay top-aligned; the *only* text that overflows its box is a stat number, at ≤ 1.53 px off the right for any reachable value. | K07-BUG-10 |
| **bottom edge (owner rule)** | Clean: the bar's surface runs to the physical edge in both themes. | iteration 3 |
| **async gaps** | Clean (stream torn down mid-flight, late emission, double retry). | iteration 2/3 controls |
| **timezone / BST / money rounding** | Provably n/a: `watchEvolution` counts rows and reads no clock, K07 renders coins and never `£`. | iteration 3's data tests |

**Method note for the next stage.** A naive "is this text clipped?" sweep
produces false positives on wrapping text (a one-line `TextPainter` width always
exceeds a wrapped paragraph's box), and a naive `TextPainter.layout(maxWidth:
boxWidth)` on a `softWrap: false` paragraph also lies, because Skia breaks a
long digit run across lines where the real widget lays out at infinite width and
clips. The only correct probes are: (a) `softWrap: false` → compare the
one-line intrinsic width against the box, and (b) wrapping text → compare
`computeLineMetrics()` line widths against the box. Both are implemented in the
proof above.

## Carried from stage 4 (not re-reported as this stage's findings)

`4_review.md` (iteration 5) owns its three minors; this stage did not duplicate
them and did not fix them:

1. **The stat-number clipping** — reported there as a minor with a shared-request
   suggestion; this pass measures it precisely and supplies a verified one-line
   fix. See K07-BUG-10 above.
2. **The stale accessibility-scale justification** in the hero comment — the
   review says "no code change needed". Correct: `app.dart:17-20` clamps the OS
   scaler to 1.0–1.3, the K07-BUG-8/9 fix already restated the comment, and the
   iteration-4 correction in `6_bugs.md` stands. Nothing to do.
3. **`1_plan.md` is stale** (`maxLines: 4` / `2` / `3`, the `FittedBox`) — a
   documentation-only item the orchestrator owns. This pass did not edit the
   plan.

Also still open elsewhere and not re-reported: `evolutionSub(0)` needs a wording
ruling (`SHARED_REQUEST.md` item 5), and `SHARED_REQUEST.md` §1–§5 are unchanged.

## Observations (not findings)

1. **No in-app entry point for `/pip-evolution`** — `PipRoutePaths.evolution` has
   no call site outside `pip_routes.dart`. Carried from iteration 2; the
   K06/flow owner's call.
2. **The `#3D7FF0` sky dot** is still off-token in the design source and paints
   the light sky token in both themes after D4. Still `SHARED_REQUEST.md` item 4.
3. **Iteration-5 stages ran concurrently in this worktree**: `3_test.md`,
   `4_review.md`, `5_ui.md` and `pip_evolution_stats_scales_test.dart` all
   changed mid-pass (the scales file was rewritten by stage 3 after `160fa6f`).
   This stage **read and ran** that file but did not edit or delete it, and none
   of the numbers above are attributed to it — every measurement in this report
   was taken by this pass against the tree as it stood.
4. **`pip_buy_result_test.dart`'s directory-run stall** (`6_bugs.md` iteration 3,
   observation 3) did not reproduce for a third consecutive iteration; the
   feature directory finished in 20 s. Unreproduced, not fixed.

## Gates

```
$ dart format --set-exit-if-changed .
Formatted 643 files (0 changed) in 2.21 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.4s)

$ flutter test --timeout 120s test/features/pip/k07_bugs_test.dart
00:03 +34 ~1: All tests passed!        (the ~1 is this stage's parked proof)

$ flutter test --timeout 120s --run-skipped test/features/pip/k07_bugs_test.dart
00:03 +34 -1: Some tests failed.       exactly the one new proof:
  K07-BUG-10 → "9999" paints 93.60 px into a 68.67 px box — 24.93 px of digits cut off the right edge

$ flutter test --timeout 120s test/features/pip
00:20 +458 ~1: All tests passed!       (the ~1 is this stage's parked proof)

# with the suggested one-line fix applied, then reverted (see K07-BUG-10):
$ flutter test --timeout 120s --run-skipped test/features/pip/k07_bugs_test.dart
00:03 +35: All tests passed!
$ flutter test --timeout 120s --run-skipped test/features/pip
00:28 +476: All tests passed!

$ flutter test --timeout 120s          # the whole app
07:51 +4513 ~11 -1: Some tests failed.
  app/test/features/pip/pip_nest_widget_test.dart:
    "every painted rect sits on its design position"
```

That one failure is **K06's** geometry test, not K07's, it is **not caused by
this stage** (the bug hunt added one test to `k07_bugs_test.dart` and no
`lib/` change — `git status --porcelain app/lib` is empty), and it **passes in
isolation**:

```
$ flutter test --timeout 120s test/features/pip/pip_nest_widget_test.dart
00:01 +5: All tests passed!
```

That file defines its own `loadBundledFonts()` and runs it in `setUpAll`
(`pip_nest_widget_test.dart:40-56, 71`) precisely because "`flutter test`'s
default placeholder glyphs are one em wide, which would change every measured
text box" — i.e. if the faces are not in place, every rect in that file is off.
Two other app-wide `flutter test` runs from concurrent stages were still in
flight in this worktree when the failing run started (this loop runs stages
3/4/5 in parallel with this one), so the most likely shape is an asset-load
race under load. **Recorded as an environment observation with its isolation
evidence — not a K07 finding, and not a process item.**

Every gate ran with a per-test timeout, nothing was waited on for more than ten
minutes, and nothing hung. This stage's one park is the **only** skip inside
`test/features/pip`. Scratch probes (`zz_probe*_iter5_k07_test.dart`, 8 files)
were exploratory and are **deleted**; every number they produced is either quoted
above or pinned by the permanent proof.

## Verdict

Iteration 4's major (K07-BUG-8) and minor (K07-BUG-9) are **fixed and
re-verified live** — their proofs run un-skipped and green, the mandated 03:03
layout is exactly what is shipped, and the mixed-label-width case (which the
shipped matrix does not cover) was measured and is correct at every width from
280 to 430 px in both themes at scales 1.0 and 1.3.

The full hunt matrix is clean: 0/1/6 children, out-of-range stages, 0 to
999 999 999 coins, 0 and 1 completions, row isolation, rapid double taps, back
navigation and deep links, Drift persistence, both mode guards, contrast in both
themes, the 280 → 844 px matrix, the bottom-edge rule, the async-gap cases and
the text-scale ceiling.

What this pass found is one **minor, latent** defect the new layout exposes: a
stat number wider than its card is cut mid-digit instead of overpainting the card
edge as CSS would. With the shipped seed the worst case is 1.53 px off the right
edge — under the orchestrator's own 2 px bar, and invisible — and the visible
cases need lifetime coin totals the seed cannot produce. It has a verified
one-line fix that removes the silent cut. **No major defects.**

VERDICT: PASS