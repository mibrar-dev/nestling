# K07 · Pip evolves (`/pip-evolution`) — UI check, stage 5, **iteration 3**

Shots: `tools/screens/shot.sh` with `SEED=demo APP_MODE=kid CHILD=maya
THEME=light|dark DISABLE_ANIMATIONS=1`, on the assigned simulator **only** —
`BC440E48-B3A3-43BC-971B-0EF5DB621874` ("Nestling QA 2", 390×844). No other
simulator was booted, installed on, driven or screenshotted; no `pkill`, no
`flutter clean`, no interactive `flutter run`.
Design: `design/screens/light|dark/K07-evolution.png` (1170×2532 = 390×844 @3x).
Copy/geometry oracle: `design/html-source/screens/K07-evolution.html` +
`tokens.css` + `components.css`.
Artefacts: `ui/app_{light,dark}_3.png`, `ui/cmp_{light,dark}_3.png`.
**No product code was edited by this stage** (RULES §1: only
`docs/screens/K07/**`).

All numbers are **logical px**, measured on the native 3× frames (device px ÷ 3)
with one script run over design and app through the identical code path, so
resampling bias cancels. Shape positions come from 1-D row/column scans inside
per-element windows with a ≥3-device-px minimum run (a whole-window bbox is
contaminated by the speech-bubble tail and the status-bar glyphs, which is how
a 34 px shift can hide). `cmp_*` were read visually and at 2× zoom as well.

## Frame identity (the iteration-2 harness trap, D9)

Both captures were accepted only after their theme was asserted from pixels
rather than from the flag that was passed:

| shot | bg @ (195,500) | CTA face @ (195,760) | verdict |
|---|---|---|---|
| `app_light_3.png` | `#FFFFFF` | `#6A58E8` (light `--lilac-strong`) | light frame ✓ |
| `app_dark_3.png` | `#1F1C2E` | `#A89BFF` (dark `--lilac-strong`) | dark frame ✓ |

Absolute output paths were used (`shot.sh` `cd`s into the app dir).
`SHARED_REQUEST.md` item 3 still stands; it did not bite this time.

## Mean diff (`tools/screens/compare.py`)

| theme | mean diff | band 0 (0–105) | 1 (105–211) | 2 (211–316) | 3 (316–422) | 4 (422–527) | 5 (527–633) | 6 (633–738) | 7 (738–844) |
|---|---|---|---|---|---|---|---|---|---|
| **light (iter 3)** | **9.70 %** | 1.75 | 6.06 | 16.07 | 10.55 | 14.24 | 16.80 | 7.06 | 5.07 |
| **dark (iter 3)** | **8.49 %** | 1.63 | 4.77 | 12.38 | 8.62 | 13.59 | 15.84 | 6.47 | 4.65 |
| *light (iter 2)* | *9.69 %* | *1.71* | *6.06* | *16.07* | *10.55* | *14.24* | *16.80* | *7.06* | *5.07* |
| *dark (iter 2)* | *9.00 %* | *1.60* | *6.87* | *14.12* | *8.87* | *13.59* | *15.84* | *6.47* | *4.65* |

**Light is byte-for-byte the iteration-2 screen.** A full-frame pixel diff
`app_light_2 → app_light_3` gives **2 333 differing pixels, all inside
x 31.33–73.00, y 19.00–30.33** — the OS status-bar clock, which the STATUS BAR
rule excludes. The whole 0.01-point light difference is band 0.

**Dark improved 9.00 % → 8.49 %**, and the movement is exactly where D4 was:
band 1 **6.87 → 4.77 %** (sparkles 1–2 and the two top dots), band 2
**14.12 → 12.38 %** (sparkle 3), band 3 **8.87 → 8.62 %**. Bands 4–7 are
unchanged to the last decimal. A frame diff `app_dark_2 → app_dark_3` is
27 862 px confined to x 20.00–369.67, y 19.00–324.33 = the status bar plus the
sparks layer.

## UI VERDICT RULE report — the required y positions

| what | design y | app y | Δ |
|---|---|---|---|
| screen title, first ink line | 376.33–402.00 | **376.33–402.00** | **0.00** |
| first control (`.lock-btn.lg` box, top edge) | 47.00 | **47.00** | **0.00** |
| first control (`.lock-btn.lg` box, bottom edge) | 102.67 | **102.67** | **0.00** |
| stat card 1 top border | 545.00–547.67 | 579.00–581.67 | +34.00 (D1, DB copy) |
| stat card 2 top border | 545.00–547.67 | 579.00–581.67 | +34.00 (D1, DB copy) |
| stat card 3 top border | 545.00–547.67 | 579.00–581.67 | +34.00 (D1, DB copy) |
| `.kid-bar` top rule (3 px `--ink`) | 721.00–723.67 | **721.00–723.67** | **0.00** |
| CTA (`.btn-kid.lilac` ink border, top / bottom) | 736.00 / 799.67 | **736.00 / 799.67** | **0.00** |

This is **not** a uniform vertical shift: the first control, the title's first
ink line, the bar rule and the CTA box are all exactly on the design's y. Only
the block below the extra DB title line moves, by exactly 34 px = one
`--lh-kid-title` line (D1, accepted).

## Measured element-by-element (identical numbers in both themes)

| element | design | app | Δ |
|---|---|---|---|
| lock button box (1 px `--line`) | x 314.00–369.67, y 47.00–102.67 | x 314.00–369.67, y 47.00–102.67 | **0.00** |
| lock glyph ink bbox | x 333.00–350.67, y 65.00–84.67 | x 333.00–350.67, y 65.00–84.67 | **0.00** |
| sparkle 1 lilac ink box | x 31.67–72.00, y 135.67–176.00 (41.33²) | x 31.67–72.00, y 135.67–176.00 | **0.00** |
| sparkle 1 top-tip column runs | y 135.67–141.33 / 170.33–176.00 | identical | **0.00** |
| sparkle 2 green ink box | x 311.67–352.00, y 129.67–170.00 | x 311.67–352.00, y 129.67–170.00 | **0.00** |
| sparkle 2 top-tip column runs | y 129.67–135.33 / 164.33–170.00 | identical | **0.00** |
| sparkle 3 gold ink box | x 20.00–58.00, y 253.67–294.00 | x 20.00–58.00, y 253.67–294.00 | **0.00** |
| sparkle 3 top-tip column runs | y 254.33–262.00 / 285.67–293.33 | identical | **0.00** |
| sparkle 4 peach ink box | x 333.67–369.67, y 255.67–296.00 | x 333.67–369.67, y 255.67–296.00 | **0.00** |
| sparkle 4 top-tip column runs | y 259.00–267.00 / 285.00–292.67 | identical | **0.00** |
| gold dot (r 7) ink box | x 97.67–114.00, y 108.67–125.00 | x 97.67–114.00, y 108.67–125.00 | **0.00** |
| sky dot (r 6) ink box | x 280.67–295.00, y 107.67–122.00 | x 280.67–295.00, y 107.67–122.00 | **0.00** |
| green dot (r 7) ink box | x 81.67–98.00, y 304.67–321.00 | x 81.67–98.00, y 304.67–321.00 | **0.00** |
| lilac dot (r 6) ink box | x 298.67–313.00, y 309.67–324.00 | x 298.67–313.00, y 309.67–324.00 | **0.00** |
| growth arrow (`.k7-arrow`, `--lilac-strong`) | x 99.67–121.00, y 307.00–324.67 | x 100.00–120.67, y 307.33–324.33 | ≤ **0.33** |
| title line 1 ink | y 376.33–402.00, x 23.67–366.67 | y 376.33–402.00, x 105.67–285.00 | Δy **0.00**, Δx = DB copy (D1) |
| title line 2 ink | — | y 410.33–436.00, x 115.67–274.00 | the extra DB line |
| sub ink | y 427.33–443.00, x 74.67–316.00 | y 461.33–477.00, x 80.00–310.33 | Δy +34.00 (D1), Δx copy |
| speech-bubble top border straight run | y 464.50, x 76.33–313.33 | y 498.50, x 76.33–313.67 | Δx **0.34**, Δy +34.00 (D1) |
| speech-bubble bottom border run | y 526.50, x 74.00–315.67 | y 560.50, x 74.00–315.33 | Δx **0.34**, Δy +34.00 (D1) |
| bubble left border col x66 | y 475.00–516.67 | y 509.00–550.67 | Δy +34.00 (D1) |
| stat-card vertical borders (3 px `--ink`) | x 20.00–22.67 / 127.00–129.67 / 140.00–142.67 / 247.00–249.67 / 260.00–262.67 / 367.00–369.67 | identical | **0.00** |
| stat-card top border straight run | x 29.67–120.00 | x 29.67–120.00 | **0.00** (radius equal) |
| card number ink, rel. card top | +10.00…+41.00 | +10.00…+41.67 | ≤ **0.67** (different digits) |
| card label ink, rel. card top | +54.33…+66.00 | +55.33…+67.00 | **1.00** |
| card label ink x (labels are identical copy) | 36.00–113.67 / 156.33–233.00 / 280.00–350.00 | identical | **0.00** |
| caption ink | y 649.33–662.33, x 98.00–292.00 | y 683.33–696.33, x 98.00–292.00 | Δx **0.00**, Δy +34.00 (D1) |
| `.kid-bar` top rule | y 721.00–723.67, x 0.00–389.67 | y 721.00–723.67, x 0.00–389.67 | **0.00** |
| CTA ink border | x 20.00–369.67, y 736.00–799.67 | x 20.00–369.67, y 736.00–799.67 | **0.00** |
| CTA corner profile (rows 736.3 / 737 / 738 / 745 / 752) | 43.0 / 37.0 / 34.33 / 25.33 / 21.33 (left edge) | 43.33 / 37.0 / 34.33 / 25.33 / 21.33 | ≤ **0.33** |
| CTA label ink | y 759.33–777.33 (h 19.00), centre x 195.17 | y 760.33–778.33 (h 19.00), centre x 195.17 | **1.00** vertical, height exact |
| CTA face | light `#6A58E8` / dark `#A89BFF` | light `#6A58E8` / dark `#A89BFF` | **0** |
| CTA label ink | light `#FFFFFF` / dark `#14121F` | light `#FFFFFF` / dark `#14121F` | **0** |
| bubble face | light `#FFFFFF` / dark `#1F1C2E` | light `#FFFFFF` / dark `#1F1C2E` | **0** |
| stat-card face | light `#FFFFFF` / dark `#1F1C2E` | light `#FFFFFF` / dark `#1F1C2E` | **0** |
| title / stat-number ink | light `#1E1B3A` / dark `#F3F0FA` | light `#1E1B3A` / dark `#F3F0FA` | **0** |
| caption + stat labels (`--ink-2`) | light `#4A4668` / dark `#C9C4DC` | light `#4A4668` / dark `#C9C4DC` | **0** |
| page glow @ (195,12) / (195,340) / (195,444) / (330,360) | `#FEFEFF` `#F0EDFF` `#F6F4FF` `#F7F5FF` / `#1F1C2F` `#29244C` `#252140` `#24203D` | `#FFFFFF` `#F1EFFF` `#F7F5FF` `#F6F5FE` / `#211E30` `#2B254D` `#272241` `#241F3D` | ≤ **2** per channel |
| below the bar, y 806–843 (x 0–390) | glow `#EEEBFF` / `#2B2550` + home pill | **one** colour `#FFFFFF` / `#1F1C2E`, 0 deviating px of 65 520 | owner-rule override — app correct |

## Accent fills and stroke (`svg.sparks`) — the mandatory D4 item

Sampled at the design's own `viewBox` coordinates. "fill px" counts pixels
within ±5 of the literal; the dark-token column is the same shape read with the
dark theme's accent, to prove none leaked in.

| shape | design PNG (both themes) | app light | app dark | literal |
|---|---|---|---|---|
| sparkle 1 lilac | `#7C6CF2` ×1904 | `#7C6CF2` ×1904 | `#7C6CF2` ×1904 | `#7C6CF2` ✓ |
| sparkle 2 green | `#1F9D63` ×1904 | `#1F9D63` ×1904 | `#1F9D63` ×1904 | `#1F9D63` ✓ |
| sparkle 3 gold | `#F4B400` ×1904 | `#F4B400` ×1904 | `#F4B400` ×1904 | `#F4B400` ✓ |
| sparkle 4 peach | `#FF8A5B` ×1904 | `#FF8A5B` ×1904 | `#FF8A5B` ×1904 | `#FF8A5B` ✓ |
| gold dot | `#F4B400` ×812 | `#F4B400` ×804 | `#F4B400` ×804 | `#F4B400` ✓ |
| green dot | `#1F9D63` ×812 | `#1F9D63` ×812 | `#1F9D63` ×812 | `#1F9D63` ✓ |
| lilac dot | `#7C6CF2` ×540 | `#7C6CF2` ×540 | `#7C6CF2` ×540 | `#7C6CF2` ✓ |
| sky dot | `#3D7FF0` ×540 | `#2563D6` ×540 | `#2563D6` ×540 | **D5** (see below) |
| dark tokens `#A89BFF` / `#3CC98A` / `#FF9E78` / `#7FA9FF` inside the sparks windows | 0, 0, 0, 0 | 0, 0, 0, 0 | **0, 0, 0, 0** | — |

Stroke, sampled on the path's own centre-line points (3×3 median):

| probe | design light | app light | design dark | app dark |
|---|---|---|---|---|
| sparkle 1 top tip (52,137) | `#1E1B3A` | `#1E1B3A` | `#1E1B3A` | `#1E1B3A` |
| sparkle 1 left/right points (33,156)/(71,156) | `#1E1B3A` | `#1E1B3A` | `#1E1B3A` | `#1E1B3A` |
| sparkle 1 bottom tip (52,175) | `#1E1B3A` | `#1E1B3A` | `#1E1B3A` | `#1E1B3A` |
| sparkle 2 top tip (332,131) / left (313,150) | `#1E1B3A` | `#1E1B3A` | `#1E1B3A` | `#1E1B3A` |
| sparkle 3 top tip (38,255) | `#1E1B3A` | `#1E1B3A` | `#1E1B3A` | `#1E1B3A` |
| sparkle 4 top tip (354,257) | `#1E1B3A` | `#1E1B3A` | `#1E1B3A` | `#1E1B3A` |
| all four dot top points | `#1E1B3A` | `#1E1B3A` | `#1E1B3A` | `#1E1B3A` |

Whole-band audit of the sparks region (y 90–339, full width), counting pixels
within ±6 of the dark theme's ink `#F3F0FA`:

| image | `#F3F0FA` px in the sparks band |
|---|---|
| design dark | **0** |
| **app dark** | **0** |
| design light | 304 539 (the near-white page, expected) |
| app light | 304 539 (identical) |

## Deviations

### D1 — the block below the title sits +34.0 px low — ACCEPTED, not a finding

`ORCHESTRATOR_NOTES.md:5` rules *"D1 the Fledgling copy wrap shifting the stack
by 34: ACCEPT (DB truth)."* Re-measured and still confined to the copy-driven
block:

| | design | app | Δ |
|---|---|---|---|
| title line 1 | y 376.33–402.00 | y 376.33–402.00 | **0.00** |
| title line 2 | — | y 410.33–436.00 | the extra DB line |
| sub | y 427.33 | y 461.33 | +34.00 |
| bubble top / bottom border | y 464.50 / 526.50 | y 498.50 / 560.50 | +34.00 |
| card tops | y 545.00 | y 579.00 | +34.00 |
| caption | y 649.33 | y 683.33 | +34.00 |
| bar rule / CTA box | y 721.00 / 736.00 | y 721.00 / 736.00 | **0.00** |

Maya is stage 3 in the database (`core/data/seed.dart:213`), so the title is
`Pip grew into a Fledgling!`, which wraps to two balanced lines
(`NestBalancedText`, HTML line 55 `.kid-title { text-wrap: balance }`) and adds
exactly one 34 px line to everything after it. Hard-coding the design's stage-4
copy is forbidden (DATA OVER MOCKS). **No fix.**

### D2 — sparkle top points (iteration 1's blocker) — FIXED, still exact

All four sparkle ink boxes and their top-tip column runs match the design to
**0.00 px** in both themes (table above), so the iteration-2 fix
(`Path.addPolygon` receiving the `M` pair as its first vertex) still holds and
the D4 palette change did not disturb the geometry. **No fix.**

### D3 — bubble tail is the CSS 18 × 9, the PNG export is smaller — ACCEPTED, not a finding

Box is exact (top border x 76.33–313.33 design / 76.33–313.67 app, h 65.00
both, Δy +34 from D1). Tail rows below the box: design y 529–534, widest row
11.33 logical px; app y 563–571, widest row 17.33 logical px, same centre x.
`ORCHESTRATOR_NOTES.md:4`: *"D3 bubble tail: ACCEPT the CSS 18×9 (shared
NestSpeechBubble follows `.speech::after`; the PNG export is smaller). Not a
finding."* Verified against the source: `components.css:192` is
`border: 9px solid transparent; border-bottom: 0` → an 18 × 9 tail. **No fix.**

### D4 — dark-mode sparkle/dot accents — **FIXED this iteration, verified on screen**

Iteration 2's live dark-mode defect (`ORCHESTRATOR_NOTES.md` 23:55, mandatory):
every sparkle and dot carried a `#F3F0FA` white ring on the night sky. The
mandated fix is in `pip_evolution_sparks.dart` only — stroke and all five fills
resolve from `NestColors.light`, `shouldRepaint` is `false`.

Measured evidence on the new dark shot:

| check | design dark | app dark (iter 2) | app dark (iter 3) |
|---|---|---|---|
| `#F3F0FA` px in the sparks band | 0 | ~1 100 per shape | **0** |
| sparkle 1 fill | `#7C6CF2` ×1904 | `#A89BFF` | **`#7C6CF2` ×1904** |
| sparkle 2 fill | `#1F9D63` ×1904 | `#3CC98A` | **`#1F9D63` ×1904** |
| sparkle 4 fill | `#FF8A5B` ×1904 | `#FF9E78` | **`#FF8A5B` ×1904** |
| green dot fill | `#1F9D63` ×812 | `#3CC98A` | **`#1F9D63` ×812** |
| stroke at 12 centre-line probes | `#1E1B3A` | — | **`#1E1B3A`, all 12** |

The fill pixel counts are *identical to the design's dark PNG* to the pixel,
and zero dark-accent pixels appear anywhere in the layer. `cmp_dark_3.png` shows
no light outline. **No further fix.**

### D5 — the sky dot's design hex is off-token — observation, app is correct

`K07-evolution.html:42` hard-codes `<circle cx="268" cy="8" r="6"
fill="#3D7FF0"/>`. `#3D7FF0` is **not** a value in `tokens.css` for either
theme — `--sky` is `#2563D6` (light, `tokens.css:20`) / `#7FA9FF` (dark,
`tokens.css:105`) — and per the mandatory D4 note the whole layer is
theme-invariant, so the app paints the light `--sky` `#2563D6` in both themes.
Position and size are exact (Δ 0.00, same 540-px fill area as the design). This
is the same finding as iteration 2, already filed as `SHARED_REQUEST.md` item 4
and pinned by a test. **No code fix**; a literal hex is forbidden and a new
token is a `main` decision.

### D6 — page-glow gradient ≤ 2 per channel — observation, improved

Same class as iteration 2's D6, slightly better: at four sample points the app
is within 2/255 per channel of the design's `radial-gradient` interpolation in
both themes (table above; e.g. (195,340) light `#F0EDFF` → `#F1EFFF`, dark
`#29244C` → `#2B254D`). Invisible side by side; every face, ink and border
colour is exact. **No fix.**

### D7 — Pip art differs from the PNG by mandate — observation

The design paints `pip-stage-3.svg` (68 px, `left 2 bottom 4`, `opacity .24
grayscale`) and `pip-stage-4.svg` (240 px, `right 6 bottom 0`); the PIP rule
requires the child's own Pip, so the app renders Maya's DB profile
(Mochi · sunny · stage 3) in the same slot with `oldStage = stage − 1 = 2`
(`pip_evolution_stage.dart:95`). Ink extents therefore differ by shape, not by
placement. Every element the layout owns around the art — the growth arrow
(Δ ≤ 0.33), all four dots and all four sparkles (Δ 0.00), the slot rows, the
title below (Δy 0.00) — is within ±2 px. **No fix.**

### D8 — no home-indicator pill, and no coloured band under the bar — observation, app correct

The design PNGs paint the page glow below the bar (`#EEEBFF` light / `#2B2550`
dark) plus a home pill at y 826–829, x ≈ 128–261 (`#33304E` / `#DFDCE9`). The
app paints **one** colour across the whole band: y 806–843, x 0–389 at 2 px
steps → 65 520 samples, **0 deviating**, `#FFFFFF` light and `#1F1C2E` dark —
the bar's own surface, i.e. it runs to the physical edge with no meadow or
page-tint strip and no coloured ring, in both themes.

That is exactly what the loop's BOTTOM EDGE owner rule requires (*"the area
below any bottom bar down to the physical screen edge MUST use the SAME surface
colour as that bar… in light or dark mode. UI checks must FAIL a screen that
shows one"*), and it overrides the PNG. The missing pill is an OS affordance,
the same class the STATUS BAR rule tells this stage to ignore. **No fix.**

### D9 — TOOLING: `shot.sh` can still save a pre-first-frame capture — shared

Unchanged from iteration 2 and re-confirmed: the tool waits for the app
*process* and accepts two identical captures 1 s apart, which on this simulator
can both be the previous launch's image. It did not misfire this time — the
frame-identity assertion above caught nothing, and both shots' bands line up
with iteration 2 as expected. `SHARED_REQUEST.md` item 3 remains open and
unblocked-by-workaround. **No screen fix.**

### D10 — two +1.00 px label offsets inside exact boxes — within tolerance, no fix

Two ink baselines sit 1.00 px lower than the design's inside boxes that
themselves match exactly:

| element | design | app | Δ |
|---|---|---|---|
| stat-card label ink, relative to the card top | +54.33…+66.00 (h 11.67) | +55.33…+67.00 (h 11.67) | +1.00 |
| CTA label ink, relative to the CTA border box | y 759.33–777.33 (h 19.00), centre x 195.17 | y 760.33–778.33 (h 19.00), centre x 195.17 | +1.00 |

Both are font-internal (the label *heights* and horizontal centres are exact,
the label x extents are identical to 0.00, and the cards/labels/CTA *boxes*,
radii and borders are 0.00). Within the ±2 px rule and below what a designer
would see. **No fix** — recorded so the next iteration can compare against the
same numbers rather than re-deriving them.

## Checks that passed (no deviation a designer would reject)

- **Alignment / gutters (owner rule)**: 20 px side gutter everywhere. Card
  vertical borders land on x 20.00/127.00, 140.00/247.00, 260.00/367.00 — 10 px
  gaps, 3 px `--ink` borders at 20–22.67, 127–129.67, 140–142.67, 247–249.67,
  260–262.67, 367–369.67 — **identical to the design at Δ 0.00**, and so do the
  bubble (x 76.33–313.67 vs 76.33–313.33), the caption (x 98.00–292.00 in both)
  and the CTA (x 20.00–369.67 in both). Top-border straight runs are 0.00 apart,
  so the corner-radius ramps are equal too.
- **Element order / presence**: lock button → Pip stage slot (old silhouette,
  growth arrow, new Pip) → title → sub → speech bubble → 3 stat cards →
  caption → bar rule → CTA. Nothing missing, nothing extra.
- **Bottom edge (owner rule)**: 0 deviating pixels of 65 520 in y 806–843 in
  both themes (see D8).
- **Colours**: every face, ink and border token measured identical in both
  themes; the only colour deviation on the whole screen is the 6 px sky dot
  (D5) and ≤ 2/255 of gradient interpolation (D6).
- **No overflow**: zero yellow (`#FFFF00`-ish) pixels in either app shot —
  no Flutter overflow stripe anywhere; the design PNGs also have zero.
- **No clipping / ellipsis**: the 2-line title breaks as
  `Pip grew into` / `a Fledgling!` (balanced, no one-word orphan), the bubble
  reads `Flap, flap! Look at Pip's` / `wings!`, all three stat labels and the
  caption fit inside their boxes, the CTA label fits with room either side.
  No `…` and no truncation anywhere.
- **Icons**: the only glyphs are the design's `.lock-btn` padlock (ink bbox
  Δ 0.00) and the `.k7-arrow` chevron (Δ ≤ 0.33). No substitute icons.
- **Copy**: every string is DB-driven and character-for-character the HTML's
  ASCII apostrophe style (`0x27`, per the code's byte check) —
  `Pip grew into a Fledgling!`, `Because you helped 4 times`,
  `Flap, flap! Look at Pip's wings!`, `4 quests done`, `175 coins grown`,
  `3 of 4 stages`, `Pip still loves a chin scratch.`, `Meet Fledgling Pip`.
  The design's stage-4 variants (`Songbird`, `25`, `250`, `4`,
  `Hear that? That is Pip's new song!`, `Meet Songbird Pip`) are the same
  templates one stage up. Exempt per DATA OVER MOCKS.
- **Mandated items honoured**: `PipAvatar` with the DB profile in both Pip
  slots (never `pip_stage_*.svg`); `NestBalancedText` on the `.kid-title`;
  no `google_fonts`; no letter-spacing override; no hard-coded colours or sizes
  in this feature's painting path; `svg.sparks` reads `NestColors.light` in both
  themes per the 23:55 ruling.

## Verdict

The one live dark-mode defect from iteration 2 (D4 / K07-BUG-5) is fixed and
now measures **pixel-identical to the design's dark PNG**: zero `#F3F0FA` in the
sparks band, `#1E1B3A` at all 12 stroke probes, and the light literal fills at
exactly the design's pixel counts — which is what moved the dark mean diff
9.00 % → 8.49 % and band 1 6.87 % → 4.77 %. Light mode is byte-identical to
iteration 2 apart from the OS clock.

Everything the layout owns is within ±2 px of the design (most at 0.00): the
lock button and its glyph, all four sparkles including their top tips, all four
dots, the growth arrow, the speech-bubble box, the three stat cards with their
borders, radii, internals and labels, the caption, the bar rule, the CTA box,
face, label and radius ramp, every gutter and every edge. The page glow is
within 2/255; the bottom edge is a single uniform bar surface to the physical
edge in light and dark; there is no overflow, clipping or ellipsis.

The remaining deltas are the two orchestrator-accepted ones (D1 +34 px DB-copy
reflow, D3 3 px tail), the mandated Pip-art swap (D7), one off-token design
literal the app correctly refuses to fake (D5, filed), ≤2/255 of gradient
interpolation (D6), an OS-drawn home indicator (D8), a sub-pixel label offset
inside tolerance (D10) and the shared capture race in tooling (D9). None is a
visible defect a designer would reject.

VERDICT: PASS
