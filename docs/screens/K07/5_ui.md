# K07 · Pip evolves (`/pip-evolution`) — UI check, Stage 5 iteration 2

Shots: `tools/screens/shot.sh` on the assigned simulator **BC440E48-B3A3-43BC-971B-0EF5DB621874** ("Nestling QA 2", 390×844), `SEED=demo APP_MODE=kid CHILD=maya THEME=light|dark`, `DISABLE_ANIMATIONS=1` (always injected by `shot.sh`).
Design: `design/screens/light|dark/K07-evolution.png` (1170×2532 = 390×844 @3x).
Copy reference: `design/html-source/screens/K07-evolution.html`.
All logical px below = device px ÷ 3. Bands/shots: `ui/app_{light,dark}_1.png`, `ui/cmp_{light,dark}_1.png`.
**No product code was edited by this stage.** No other simulator was booted, installed on or driven.

## Mean diff

| theme | mean diff | band 0 (0–105) | 1 (105–211) | 2 (211–316) | 3 (316–422) | 4 (422–527) | 5 (527–633) | 6 (633–738) | 7 (738–844) |
|---|---|---|---|---|---|---|---|---|---|
| light | **9.80 %** | 1.71 | 6.47 | 16.48 | 10.55 | 14.24 | 16.80 | 7.06 | 5.07 |
| dark | **8.94 %** | 1.57 | 6.61 | 13.89 | 8.87 | 13.59 | 15.84 | 6.47 | 4.65 |

Bands 1–2 are dominated by Pip art (exempt: DB stage 3 vs design stage 4, mandatory
per the PIP rule). Bands 3–5 carry the +34 px copy shift (D1) and the sparkle
defect (D2). Bands 6–7 measure ≤7 %, i.e. the bar/CTA region is clean.

## Measured matches — design vs app (logical px)

Verified row-by-row / column-by-column on both PNGs, light **and** dark
(structurally identical offsets in the two themes unless noted).

| element | design | app | Δ |
|---|---|---|---|
| lock glyph ink bbox | x 333.0–350.67, y 65.0–84.67 | x 333.0–350.67, y 65.0–84.67 | **0** |
| `.kid-bar` top border (full bleed) | y 721.0–723.7 | y 721.0–723.7 | **0** |
| CTA ink-border rect | x 20.0–369.67, y 736.0–799.67 | x 20.0–369.67, y 736.0–799.67 | **0** |
| CTA face colour | light `#6A58E8`, dark `#A89BFF` | light `#6A58E8`, dark `#A89BFF` | **0** |
| CTA top-left radius ramp (18 rows) | 41.67, 36.67, 34.0, 32.33, 30.67 … | 41.33, 36.67, 34.0, 32.0, 30.67 … | ≤ 0.34 |
| stat-card top-border straight runs | 30.0–120.0 / 150.0–240.0 / 270.0–360.0 | 30.0–119.7 / 150.0–239.7 / 270.0–359.7 | ≤ 0.33 |
| stat-card box height | 83.67 | 83.67 | **0** |
| stat-card top-left radius ramp | 34.0, 30.0, 28.0, 26.67, 25.33 … | 34.0, 30.0, 28.0, 26.67, 25.33 … | ≤ 0.33 |
| stat-card ink runs (inner edge, number, label, inner edge) | 548.0–549.0 / 564.67–586.0 / 599.0–611.0 / 624.67–625.67 | 582.0–583.0 / 599.67–620.67 / 634.33–646.0 / 658.67–659.67 | +34.0 each, **internal offsets and heights identical** (number h 21.33/21.0, label h 12.0/11.67) |
| stat-card label x extent | 20.0–129.67 | 20.0–129.67 | **0** |
| speech-bubble box | x 65.0–324.67, y 463.0–528.0 (h 65.0) | x 65.0–324.67, y 497.0–562.0 (h 65.0) | Δx **0**, Δy +34.0 |
| bubble face colour | light `#FFFFFF`, dark `#1F1C2E` | light `#FFFFFF`, dark `#1F1C2E` | **0** |
| bubble top-left radius ramp (14 rows) | 81.0, 76.67, 74.67, 73.0, 71.67, 70.33 … | 80.67, 76.67, 74.67, 73.0, 71.67, 70.67 … | ≤ 0.67 |
| title, first ink line | y 376.33–402.0 | y 376.33–402.0 | **0** |
| sub ink band | y 427.0–443.0 (h 16) | y 461.0–477.0 (h 16) | +34.0 |
| caption ink band / x extent | y 649.33–662.33, x 98.0–288.0 | y 683.33–696.33, x 98.0–288.0 | Δx **0**, Δy +34.0 |
| `.k7-arrow` paint (`--lilac-strong`) | x 99.67–121.0, y 307.0–324.67 | x 100.0–120.67, y 307.33–324.33 | ≤ 0.33 |
| gold dot, r 7 | x 100.67–111.0, y 111.67–122.0 | identical | **0** |
| sky dot, r 6 (light) | x 283.67–292.0, y 110.67–119.0 | identical | **0** |
| lilac glow (background) | light `#F8F7FF`, dark `#231F3B` | light `#F7F6FE`, dark `#221E3A` | ≤ 1 per channel |
| bottom edge, y 812 → 843 | design PNG shows glow `#EEEBFF` / `#2B2550` | `#FFFFFF` / `#1F1C2E` (uniform, single colour) | **owner-rule override — app is correct** (see below) |

Also confirmed: side gutters 20 everywhere; cards, caption, bubble and CTA share
the same left/right edges; no red/error colour anywhere; no overflow, clipping or
ellipsis (the title's second line, the 2-line bubble and all three labels fit
inside their boxes); no coloured strip anywhere between y 812 and the physical
edge in either theme.

**Bottom edge (owner rule) — PASS.** Sampled every row from y 812 to y 843
across x 5–385: light is a single uniform `#FFFFFF`, dark a single uniform
`#1F1C2E`, i.e. the bar's own surface runs to the physical screen edge and around
the home indicator. The design PNGs put the lilac glow there
(`#EEEBFF` / `#2B2550`) — the owner rule overrides the PNG, and the app is on the
right side of it. (The design's *own* bar interior at y 730–790 is `#FFFFFF` /
`#1F1C2E`, which is what the app paints everywhere.)

## Deviations

### D1 — the whole stack sits +34.0 px low (EXEMPT, orchestrator-accepted — not a finding)

The DB title is `Pip grew into a Fledgling!` (Maya is stage 3), which is one
glyph wider than the design's `Pip grew into a Songbird!` and greedily wraps to
two lines with a 34 px pitch. Everything below the title therefore moves down by
**exactly +34.0 px** and every gap is preserved:

| | design | app | Δ |
|---|---|---|---|
| title ink, line 1 | y 376.33 | y 376.33 | **0** |
| title ink, line 2 | — | y 410.33–436.0 | +34 (the extra line) |
| sub | y 427.0 | y 461.0 | +34.0 |
| speech bubble top | y 463.0 | y 497.0 | +34.0 |
| stat cards top | y 545.0 | y 579.0 | +34.0 |
| caption top | y 649.33 | y 683.33 | +34.0 |
| CTA / bar | y 736.0 / 721.0 | y 736.0 / 721.0 | **0** |

This is DB copy, forbidden from being hard-coded (DATA OVER MOCKS), and
`ORCHESTRATOR_NOTES.md:5` already rules it: *"D1 the Fledgling copy wrap shifting
the stack by 34: ACCEPT (DB truth)."* The screen title itself is **not** shifted
(Δ 0) — only the block below the extra line is — so this is not the "uniform
vertical shift of the whole screen" the UI VERDICT RULE targets. **No fix.**

### D2 — MAJOR — all four sparkles lose the design's top point (NOT FIXED)

Iteration 1's D2 was supposed to be fixed per `ORCHESTRATOR_NOTES.md:3`. It is
still on screen, in both themes, at all four spots.

Measured (light; the dark numbers differ only by fill, not shape):

| sparkle | design bbox (w × h) | app bbox (w × h) | Δ |
|---|---|---|---|
| 1 lilac (top-left) | x 31.3–72.3, y 135.3–176.3 → **41.0 × 41.0** | x 31.3–72.3, y 149.3–176.3 → **41.0 × 27.0** | top **14 px missing** |
| 2 green (top-right) | x 311.3–352.3, y 129.3–170.3 → **41.0 × 41.0** | x 311.3–352.3, y 143.3–170.3 → **41.0 × 27.0** | top **14 px missing** |
| 3 coin (mid-left) | x 20.0–61.7, y 253.3–297.7 → 41.7 × 44.3 | x 20.0–61.7, y 267.3–297.7 → 41.7 × 30.3 | top **14 px missing** |
| 4 peach (mid-right) | x 333.3–369.7, y 255.3–296.3 → **36.3 × 41.0** | x 333.3–369.7, y 269.3–296.3 → **36.3 × 27.0** | top **14 px missing** |

The x extents, the x offsets and the **bottoms** are all identical (Δ ≤ 0.33):
the shapes are bottom-aligned and the horizontal reach is unchanged, because the
vertex being dropped is `(32, 30)` — the top tip, on the shape's centre line. The
design's symmetric 4-point sparkle renders as a flat-topped, single-downward-point
blob: a completely different shape language, in four places, on the screen's
celebration layer. 14 px is far outside the ±2 px budget.

Side by side (design | app, 3× nearest-neighbour, light theme):
`ui/cmp_light_1.png` diff panel bands 1–2; the four crops read
lilac/green/coin/peach, all four wrong in the same way.

**Root cause** — `app/lib/features/pip/presentation/widgets/pip_evolution_sparks.dart:168-179`
(`_SparksPainter._sparkPath`):

```dart
return Path()
  ..moveTo(numbers[0], numbers[1])          // the sparkle's TOP tip
  ..addPolygon(<Offset>[ /* numbers[2..] */ ], true);
```

`Path.addPolygon` opens its **own** contour (`_addLeadingPoint` consumes the
pending `moveTo` rather than continuing from it), so the `moveTo` point becomes a
stray one-point subpath that is never filled. The design's 8-vertex star is
painted as a 7-vertex polygon with a flat top edge — 14 px shorter, exactly as
measured. The four dots are `<circle>`s and are unaffected (all four measure Δ 0).

**Fix** (screen-local, RULES §1-legal — the painter lives in
`features/pip/presentation/widgets/`): drop the separate `moveTo` and let
`addPolygon` take the `M` pair as its first point.

```dart
return Path()..addPolygon(<Offset>[
  for (var i = 0; i + 1 < numbers.length; i += 2)
    Offset(numbers[i], numbers[i + 1]),
], true);
```

Path only — no new art, no token change, the 390 px positions and the 3 px ink
stroke all stay as they are. **Evidence:** stage 3 already parked this exact
defect as `K07-BUG-SPARK-1` in `app/test/features/pip/k07_sparkles_bug_test.dart`
(same file, same 14 px). Run for this stage:

```
flutter test --timeout 120s --run-skipped test/features/pip/k07_sparkles_bug_test.dart
  → +1 -2: Some tests failed.
      K07-BUG-SPARK-1: the painted sparkle is the design's polygon, tip included   [E]
      K07-BUG-SPARK-1: the silhouette is symmetric about the design's x = 32 axis
                       with a tip at each end                                      [E]
```

### D3 — the speech-bubble tail is 3 px taller than the design PNG (ACCEPTED — not a finding)

Bubble box is exact (h 65.0 both, x identical). The tail below it: design y
528.0–534.33 (**6.33** tall), app y 562.0–571.33 (**9.33** tall), same centre.
`ORCHESTRATOR_NOTES.md:4`: *"D3 bubble tail: ACCEPT the CSS 18×9 (shared
NestSpeechBubble follows `.speech::after`; the PNG export is smaller). Not a
finding."* **No fix.**

## Observations (not findings)

1. **Spark/dot fills in dark mode use dark tokens, the design PNG hard-codes
   hex.** Measured dark: lilac dot design `#7C6CF2` → app `#A89BFF`; green dot
   `#1F9D63` → `#3CC98A`; sky dot `#3D7FF0` → `#7FA9FF`. The `svg.sparks` fills
   are literal hex in the HTML, while the screen maps them to tokens, which the
   global rule ("never hard-code colours — tokens only") and
   `ORCHESTRATOR_NOTES.md:3` ("token fills") both require. Light mode matches the
   PNG exactly (gold `#F4B400`, green `#1F9D63`, lilac `#7C6CF2`). Recorded so a
   later iteration does not "fix" it back to literals.
2. **Pip art differs by mandate.** The grown Pip is Maya's own Mochi/sunny
   **stage 3** from the DB and the "before" silhouette is stage 2
   (`oldStage = stage − 1`), not the design's `pip-stage-4.svg` /
   `pip-stage-3.svg` illustrations — the PIP rule forbids the v1 art in product
   screens. Slot geometry (68 px silhouette at `left 2, bottom 4`; 30 px arrow at
   `left 76, bottom 24`; 240 px Pip at `right 6, bottom 0`) is preserved and the
   arrow measures Δ ≤ 0.33 px.
3. **Copy is DB-driven** and character-for-character matches the HTML's ASCII
   apostrophe byte style (`Pip's`, not `Pip’s`): `Pip grew into a Fledgling!`,
   `Because you helped 4 times`, `Flap, flap! Look at Pip's wings!`,
   `4 quests done`, `175 coins grown`, `3 of 4 stages`, `Meet Fledgling Pip`,
   `Pip still loves a chin scratch.`. Exempt per DATA OVER MOCKS.
4. **Tool note, not a screen defect:** `tools/screens/shot.sh` `cd`s into
   `$APP_DIR` before it writes the capture, so the output path must be **absolute**
   or the PNG is silently lost (`cp: …: No such file or directory`). The first
   build of this stage also died on a transient Xcode `rsync_receiver` I/O error
   (other loops building on the same machine); the retry was clean. Worth a note
   in the loop brief, but `tools/screens/**` is out of scope for a screen (RULES §1).
5. Process items (uncommitted work, the branch being behind `main`, merge order)
   are handled by the loop/orchestrator and are **not** reported here.

## Verdict

Layout, gutters, alignment, the bar, the CTA, the stat cards, the speech-bubble
box, every radius ramp, the lock button, the arrow, the four dots, the glow and
the bottom-edge rule all measure within ±2 px (most Δ 0) in **both** themes, and
the title itself is on the design's exact y. The one live, orchestrator-mandated
defect is **D2**: all four sparkles are missing their top point — 14 px short and
a visibly different shape in four places — which iteration 1 already reported and
`ORCHESTRATOR_NOTES.md:3` ordered fixed; it is unchanged on screen, and the
parked `K07-BUG-SPARK-1` proof still fails (2 of 3 tests red). A designer would
reject it. D1 and D3 are accepted by the orchestrator and are not counted.

VERDICT: FAIL