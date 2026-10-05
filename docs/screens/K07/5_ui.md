# K07 · Pip evolves (`/pip-evolution`) — UI check, stage 5, **iteration 4**

Shots: `tools/screens/shot.sh` with `SEED=demo APP_MODE=kid CHILD=maya
THEME=light|dark DISABLE_ANIMATIONS=1`, on the assigned simulator **only** —
`BC440E48-B3A3-43BC-971B-0EF5DB621874` ("Nestling QA 2", 390×844). No other
simulator was booted, installed on, driven or screenshotted; no `pkill`, no
`flutter clean`, no interactive `flutter run`. **No product code was edited by
this stage** (RULES §1: only `docs/screens/K07/**`);
`git status --porcelain app/lib` was empty before and after.
Design: `design/screens/light|dark/K07-evolution.png` (1170×2532 = 390×844 @3x).
Copy/geometry oracle: `design/html-source/screens/K07-evolution.html` +
`tokens.css` + `components.css`.
Artefacts: `ui/app_{light,dark}_4.png`, `ui/cmp_{light,dark}_4.png`.

All numbers are **logical px**, measured on the native 3× frames (device px ÷ 3).
Shape positions come from 1-D row/column scans inside per-element windows with
a ≥3-device-px minimum run, run over design and app through the identical code
path, so resampling bias cancels. `cmp_*` were read visually and at 2× zoom as
well, plus five magnified element crops.

## Mean diff (`tools/screens/compare.py`)

| theme | mean diff | band 0 (0–105) | 1 (105–211) | 2 (211–316) | 3 (316–422) | 4 (422–527) | 5 (527–633) | 6 (633–738) | 7 (738–844) |
|---|---|---|---|---|---|---|---|---|---|
| **light (iter 4)** | **9.69 %** | 1.69 | 6.06 | 16.07 | 10.55 | 14.24 | 16.80 | 7.06 | 5.07 |
| **dark (iter 4)** | **8.49 %** | 1.58 | 4.77 | 12.38 | 8.62 | 13.59 | 15.84 | 6.47 | 4.65 |
| *light (iter 3)* | *9.70 %* | *1.75* | *6.06* | *16.07* | *10.55* | *14.24* | *16.80* | *7.06* | *5.07* |
| *dark (iter 3)* | *8.49 %* | *1.63* | *4.77* | *12.38* | *8.62* | *13.59* | *15.84* | *6.47* | *4.65* |

**The screen is pixel-identical to iteration 3 apart from the OS clock.** A
full-frame diff of the shots proves it:

| pair | differing px | bbox (logical) |
|---|---|---|
| `app_light_3 → app_light_4` | **2 013** | x 32.00–72.67, y 19.00–30.67 |
| `app_dark_3 → app_dark_4` | **1 995** | x 32.00–72.67, y 19.00–30.67 |

That box is the status-bar clock, which the STATUS BAR rule excludes; it is the
whole 0.01-point light difference (band 0 1.75 → 1.69) and the whole reason the
dark band 0 moves 1.63 → 1.58. Dark is unchanged to the last decimal in bands
1–7.

This is the expected result and it is itself the finding for this iteration:
the iteration-4 build (`7c29857`) landed the two iteration-3 bug fixes —
`IntrinsicHeight` + `CrossAxisAlignment.stretch` on the stat row (K07-BUG-6)
and the removal of the two app-only `maxLines` caps (K07-BUG-7). **Neither is
visible at 390 px / text scale 1.0**, which is where `5_ui` measures, so the UI
check confirms they regressed nothing here; their 320 px / accessibility-scale
benefit belongs to `3_test`/`6_bugs`, not to this stage.

## Frame identity (the iteration-2 harness trap, D9)

Both captures were accepted only after their theme was asserted **from pixels**,
not from the flag that was passed:

| shot | bg @ (195,500) | CTA face @ (195,760) | bar face @ (195,820) | verdict |
|---|---|---|---|---|
| `app_light_4.png` | `#FFFFFF` | `#6A58E8` (light `--lilac-strong`) | `#FFFFFF` | light frame ✓ |
| `app_dark_4.png` | `#1F1C2E` | `#A89BFF` (dark `--lilac-strong`) | `#1F1C2E` | dark frame ✓ |

Both are 1170×2532 native. Absolute output paths are required — `shot.sh` `cd`s
into the app dir, so a relative `docs/...` out path fails with
`cp: … No such file or directory` (`SHARED_REQUEST.md` item 3).

**Concurrent stages.** `git status` at the end of this stage also shows
`docs/screens/K07/3_test.md`, `4_review.md`, the four `.brief_*.md` files and
ten untracked `app/test/features/pip/{zz_probe*_iter4,pip_evolution_stats_scales}_test.dart`.
None of them is this stage's work — this stage wrote exactly two paths,
`docs/screens/K07/5_ui.md` and the four `ui/*_4.png` captures, and touched no
product or test code. The scratch probes belong to the iteration-4 test/bugs
stages running alongside.

## UI VERDICT RULE report — the required y positions

| what | design y | app y | Δ |
|---|---|---|---|
| first control (`.lock-btn.lg` box, top edge) | 47.00 | **47.00** | **0.00** |
| first control (`.lock-btn.lg` box, bottom edge) | 103.00 | **103.00** | **0.00** |
| screen title, first ink line (top … bottom) | 376.33 … 402.00 | **376.33 … 401.67** | **0.00** / −0.33 |
| screen title, second ink line | — (design is one line) | 410.33 … 435.67 | the extra DB line (D1) |
| sub ink | 427.33 … 443.33 | 461.33 … 477.33 | +34.00 / +34.00 (D1) |
| speech-bubble box (outer top … outer bottom) | 463.00 … 529.00 | 497.00 … 563.00 | **+34.00 / +34.00** (D1) |
| stat card 1 top border | 545.00–547.67 | 579.00–581.67 | +34.00 (D1) |
| stat card 2 top border | 545.00–547.67 | 579.00–581.67 | +34.00 (D1) |
| stat card 3 top border | 545.00–547.67 | 579.00–581.67 | +34.00 (D1) |
| stat card 1 / 2 / 3 bottom border | 626.00–628.67 | 660.00–662.67 | +34.00 (D1) |
| caption ink | 649.33 … 662.67 | 683.33 … 696.67 | +34.00 (D1) |
| `.kid-bar` top rule (3 px `--ink`) | 721.00–723.67 | **721.00–723.67** | **0.00** |
| CTA (`.btn-kid.lilac` ink border, top / bottom) | 736.00 / 799.67 | **736.00 / 799.67** | **0.00** |

This is **not** a uniform vertical shift. The first control, the title's first
ink line, the bar rule and the CTA box are all exactly on the design's y. Only
the block below the extra DB title line moves, by exactly 34.00 px = one
`--lh-kid-title` line, and every member of that block moves by the *same*
34.00 px (D1, accepted by `ORCHESTRATOR_NOTES.md:5`).

## Measured element-by-element (identical numbers in both themes)

| element | design | app | Δ |
|---|---|---|---|
| lock button box (1 px `--line` ring, 56²) | x 314.00–370.00, y 47.00–103.00 | x 314.00–370.00, y 47.00–103.00 | **0.00** |
| lock glyph ink bbox (`--ink-2`) | x 333.00–351.00, y 65.00–85.00 | x 333.00–351.00, y 65.00–85.00 | **0.00** |
| sparkle 1 lilac fill box | x 38.33–65.67, y 142.33–169.67 (n=1904) | x 38.33–65.67, y 142.33–169.67 (n=1904) | **0.00**, n identical |
| sparkle 2 green fill box | x 318.33–345.67, y 136.33–163.67 (n=1904) | x 318.33–345.67, y 136.33–163.67 (n=1904) | **0.00**, n identical |
| sparkle 3 gold fill box | x 24.33–51.67, y 260.33–287.67 (n=1904) | x 24.33–51.67, y 260.33–287.67 (n=1904) | **0.00**, n identical |
| sparkle 4 peach fill box | x 340.33–367.67, y 262.33–289.67 (n=1904) | x 340.33–367.67, y 262.33–289.67 (n=1904) | **0.00**, n identical |
| gold dot (r 7) | x 100.67–111.33, y 111.67–122.33 (n=812) | x 100.67–111.33, y 111.67–122.33 (n=812) | **0.00** |
| green dot (r 7) | x 84.67–95.33, y 307.67–318.33 (n=812) | x 84.67–95.33, y 307.67–318.33 (n=812) | **0.00** |
| lilac dot (r 6) | x 301.67–310.33, y 312.67–321.33 (n=540) | x 301.67–310.33, y 312.67–321.33 (n=540) | **0.00** |
| sky dot (r 6) position/size | x 283.67–292.33, y 110.67–119.33 (n=540) | x 283.67–292.33, y 110.67–119.33 (n=540) | **0.00** (colour = D5) |
| growth arrow (`.k7-arrow`) ink box | x 99.67–121.33, y 307.00–325.00 | x 100.00–121.00, y 307.33–324.67 | ≤ **0.33** |
| bubble left border column (x 66) | y 475.00–517.00 (w 42.00) | y 509.00–551.00 (w 42.00) | +34.00, w identical |
| bubble right border column (x 324) | y 476.00–516.00 (w 40.00) | y 510.00–550.00 (w 40.00) | +34.00, w identical |
| bubble row y 466 / app 500 | x 73.00–80.00, 310.00–317.00 | x 73.00–80.00, 309.67–317.00 | **0.00** / 0.33 |
| bubble row y 470 / app 504 | x 68.67–72.33, 317.67–321.33 | identical | **0.00** |
| bubble tail widest row | y 529, w 11.33 (x 189.33–200.67) | y 563, w 17.33 (x 186.33–203.67) | D3 (accepted) |
| stat-card vertical borders (3 px `--ink`) | x 20.00–23.00 / 126.67–129.67 / 140.00–143.00 / 246.67–249.67 / 260.00–263.00 / 366.67–369.67 | identical, all six | **0.00** |
| card 1 / 2 / 3 ink ring bbox | x 20–129.67, 140–249.67, 260–369.67; y 545.00–628.67 (h 83.67) | x 20–129.67, 140–249.67, 260–369.67; y 579.00–662.67 (h 83.67) | **Δx 0.00**, Δy +34.00 |
| card top-border straight run | y 545.00–547.67 | y 579.00–581.67 | +34.00 |
| card bottom-border straight run | y 626.00–628.67 | y 660.00–662.67 | +34.00 |
| card number ink, rel. card top | +19.67 … +41.00 | +20.67 … +41.67 | +1.00 / +0.67 |
| card label ink, rel. card top (first ink row) | +45.00 | +45.67 | **+1.00** by the ±2-device-px search, +0.67 by the row-quantised scan (D10) |
| caption ink box | x 98.00–292.33, y 649.33–662.67 | x 98.00–292.33, y 683.33–696.67 | **Δx 0.00**, Δy +34.00 |
| bar rule (3 px, full width) | y 721.00–723.67, x 0.00–389.67 | y 721.00–723.67, x 0.00–389.67 | **0.00** |
| CTA face (`--lilac-strong`) | x 23.00–367.00, y 739.00–797.00 | x 23.00–367.00, y 739.00–797.00 | **0.00** |
| CTA ink ring | x 20.00–370.00, y 736.00–799.67 (350×64) | x 20.00–370.00, y 736.00–799.67 (350×64) | **0.00** |
| CTA radius ramp (left ink edge) y 736 / 737 / 738 / 739 / 742 / 745 | 42.67 / 38.33 / 35.00 / 33.00 / 28.67 / 25.67 | 43.33 / 38.33 / 35.33 / 33.00 / 28.67 / 25.67 | ≤ **0.66** |
| CTA mid-row extents (y 767) | L 20.00, R 369.67 | L 20.00, R 369.67 | **0.00** |
| CTA label ink | y 759.33–777.67 (h 18.33) | y 760.33–778.67 (h 18.33) | **+1.00** (D10) |
| CTA face / label / bubble face / card face / title ink / stat number ink | light `#6A58E8` `#FFFFFF` `#FFFFFF` `#FFFFFF` `#1E1B3A` `#1E1B3A` · dark `#A89BFF` `#14121F` `#1F1C2E` `#1F1C2E` `#F3F0FA` `#F3F0FA` | identical in both themes | **0** |
| caption + stat labels (`--ink-2`) | light `#4A4668` · dark `#C9C4DC` | identical | **0** |
| page glow @ (195,8) / (195,60) / (195,340) / (195,444) / (330,360) / (60,360) / (195,700) / (195,715) | light `#FEFEFF` `#FBFBFF` `#F0EDFF` `#F6F4FF` `#F7F5FF` `#F7F5FF` `#F8F6FF` `#F7F5FF` | light `#FFFFFF` `#FDFCFF` `#F1EFFF` `#F7F5FF` `#F6F5FE` `#F5F4FD` `#F9F8FF` `#F6F4FE` | ≤ **2** per channel |
| the same 8 points, dark | `#1F1C2F` `#211E35` `#29244C` `#252140` `#24203D` `#24203D` `#24203C` `#25213F` | `#201D30` `#231F36` `#2B254D` `#272241` `#241F3D` `#231E3C` `#25213E` `#241F3E` | ≤ **2** per channel |
| below the bar, y 810–843 | light `#EEEBFF` 89.1 % + `#33304E` 4.7 % (home pill); dark `#2B2550` 76.4 % + variants | **one** colour: light `#FFFFFF` 100.0 %, dark `#1F1C2E` 100.0 % | owner-rule override — app correct |

## Registered-diff audit (+34 px, the block below the title)

Comparing the app with the design at the app's own position and then registering
the D1 reflow (`D(y)` vs `A(y+34)`) isolates what each element owes to copy from
what it owes to layout. A shape that contains no copy must read ≈ 0 %:

| registered region (contains no copy) | light | dark |
|---|---|---|
| `.kid-bar` top rule, y 720–726 | **0.00 %** | **0.00 %** |
| gap caption → bar, y 700–721 | **0.00 %** | **0.00 %** |
| CTA box with the label glyphs masked out | **0.24 %** (384 px) | **0.18 %** (284 px) |
| sparkle 1 / 2 / 3 / 4 regions | 0.03 / 0.03 / 1.30 / 0.33 % | 0.00 / 0.00 / 0.67 / 0.14 % |
| gold dot / lilac dot | 0.12 % / 5.15 %¹ | 0.00 % / 0.00 % |
| lock button box | 0.29 % (94 px) | 0.29 % (94 px) |
| bubble top / left / right / bottom border bands | 0.46 / 1.45 / 1.38 / 1.01 % | 0.45 / 1.45 / 1.36 / 1.01 % |
| card 1, 2, 3 — LEFT border band | 1.29 / 1.33 / 1.33 % | 1.27 / 1.34 / 1.34 % |
| card 1, 2, 3 — RIGHT border band | 1.34 / 1.33 / 1.30 % | 1.30 / 1.30 / 1.26 % |
| card 1, 2, 3 — TOP border band | 1.18 / 1.22 / 1.18 % | 1.12 / 1.19 / 1.14 % |
| card 1, 2, 3 — BOTTOM border band | 1.03 / 1.03 / 1.03 % | 1.08 / 1.07 / 1.08 % |

¹ light only, because the design's Songbird has a lilac wing tip inside that
window; the dark design has nothing there, hence 0.00 %.

All twelve card border bands land within 0.3 percentage points of one another —
i.e. the three cards render identically, which is the K07-BUG-6 fix showing up
in the pixels. Everything left is antialiasing on a 3-device-px stroke.

The regions that *do* read high, and why, is the copy the database owns:

| registered region | light | dark | reason |
|---|---|---|---|
| title band y 372–406 (no shift) | 30.17 % | 30.14 % | design `Pip grew into a Songbird!`, app `Pip grew into` |
| sub band y 415–452 | 14.66 % | 14.64 % | `25 times` vs `4 times` |
| bubble text band y 471–520 | 16.21 % | 16.19 % | stage-4 vs stage-3 speech |
| card number band y 556–592 | 9.70 % | 9.69 % | `25 / 250 / 4` vs `4 / 175 / 3` |
| CTA label band y 750–786 (no shift) | 20.69 % | 21.04 % | `Meet Songbird Pip` vs `Meet Fledgling Pip` |
| new-Pip slot x 140–390 y 103–358 | 28.49 % | 22.21 % | PIP mandate (D7) |
| old-Pip slot x 0–72 y 280–356 | 14.76 % | 12.02 % | PIP mandate (D7) |

## Sub-pixel registration search (the Δ resolution that settles "is it a shift?")

For every element whose copy is *identical* in both frames, the diff was
minimised over a ±2 / ±6 device-px search of the app's offset. **dx 0, dy 0
relative to the +34 registration is the global optimum**, which is the proof
that there is no sub-pixel position error hiding inside the rasterisation noise:

| element (identical copy) | diff at dx0/dy0 | best found | verdict |
|---|---|---|---|
| caption `Pip still loves a chin scratch.` (light) | 2.65 % | dx 0, dy 0 → **2.65 %** | no offset |
| caption (dark) | 2.51 % | dx 0, dy 0 → **2.51 %** | no offset |
| card-1 label `quests done` | 10.82 % | dx 0, **dy +3** → 3.11 % | **+1.00 px low** (D10) |
| card-2 label `coins grown` | 10.01 % | dx 0, **dy +3** → 2.79 % | **+1.00 px low** (D10) |
| card-3 label `of 4 stages` | 10.68 % | dx 0, **dy +3** → 2.64 % | **+1.00 px low** (D10) |
| CTA label box | 20.08 % | dx 0, **dy +3** → 18.16 % | **+1.00 px low** (D10) |
| bar rule (control) | **0.00 %** | dx 0, dy 0 → 0.00 % | exact |
| sparkle 1 (control) | **0.03 %** | dx 0, dy 0 → 0.03 % | exact |
| CTA top arc (control) | 0.62 % | dx 0, dy 0 → **0.16 %** | exact |
| bubble box + text | 10.45 % | dx 0, dy 0 → **10.45 %** | exact (copy differs) |
| sub / title line 1 / card number | 14.29 / 29.78 / 12.35 % | dy 0 optimum for all three | exact (copy differs) |

The caption is the informative one: same string, same 15 px Nunito 700, ink
bbox **identical to the device pixel** (x 98.00–292.33, y 649.33–662.67 → after
the +34, x 98.00–292.33, y 683.33–696.67), and a per-column ink profile that
correlates at **Pearson r = 0.986** (light) / **0.986** (dark). The residual
2.5 % is Chrome-vs-Skia antialiasing on the same glyphs (ink coverage 5 366 vs
5 028 device px, 6 %).

## Accent fills and stroke (`svg.sparks`) — the mandatory D4 item, re-measured

Sampled at the design's own `viewBox` coordinates. "fill px" counts pixels
within ±5 of the literal; the dark-token column proves no dark accent leaked in.

| shape | design PNG (both themes) | app light | app dark | literal |
|---|---|---|---|---|
| sparkle 1 lilac | `#7C6CF2` ×1904 | `#7C6CF2` ×1904 | `#7C6CF2` ×1904 | ✓ |
| sparkle 2 green | `#1F9D63` ×1904 | `#1F9D63` ×1904 | `#1F9D63` ×1904 | ✓ |
| sparkle 3 gold | `#F4B400` ×1904 | `#F4B400` ×1904 | `#F4B400` ×1904 | ✓ |
| sparkle 4 peach | `#FF8A5B` ×1904 | `#FF8A5B` ×1904 | `#FF8A5B` ×1904 | ✓ |
| gold dot | `#F4B400` ×812 | `#F4B400` ×812 | `#F4B400` ×812 | ✓ |
| green dot | `#1F9D63` ×812 | `#1F9D63` ×812 | `#1F9D63` ×812 | ✓ |
| lilac dot | `#7C6CF2` ×540 | `#7C6CF2` ×540 | `#7C6CF2` ×540 | ✓ |
| sky dot | `#3D7FF0` ×540 | `#2563D6` ×540 | `#2563D6` ×540 | **D5** (see below) |

Stroke, sampled on the path's own centre-line points (3×3 median):

| probe | design light | app light | design dark | app dark |
|---|---|---|---|---|
| sparkle 1 top / left / right / bottom tip | `#1E1B3A` ×4 | `#1E1B3A` ×4 | `#1E1B3A` ×4 | `#1E1B3A` ×4 |
| sparkle 2 top / left / right / bottom tip | `#1E1B3A` ×4 | `#1E1B3A` ×4 | `#1E1B3A` ×4 | `#1E1B3A` ×4 |
| sparkle 3 top / bottom tip | `#1E1B3A` ×2 | `#1E1B3A` ×2 | `#1E1B3A` ×2 | `#1E1B3A` ×2 |
| sparkle 4 top / bottom tip | `#1E1B3A` ×2 | `#1E1B3A` ×2 | `#1E1B3A` ×2 | `#1E1B3A` ×2 |
| all four dot top points | `#F4B400` `#3D7FF0` `#1F9D63` `#7C6CF2` | identical | identical | identical |

**13 of 13 stroke probes read `#1E1B3A` in the app's dark frame** — the mandated
"no light outline" is present in the pixels, not just in the source. Whole-band
audit of the sparks region (y 90–339, full width) for the dark accents:

| image | `#A89BFF` | `#3CC98A` | `#FF9E78` | `#7FA9FF` |
|---|---|---|---|---|
| design dark | 1 006 (its own `--lilac-strong` arrow) | 0 | 0 | 0 |
| **app dark** | **802** (its own `--lilac-strong` arrow) | **0** | **0** | **0** |
| design light / app light | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 |

The residual `#A89BFF` in both dark frames is the `.k7-arrow`, which *is*
`--lilac-strong` in the design as well (`K07-evolution.html:21`); the arrow's own
bbox matches to ≤ 0.33 px. Not a sparkle.

## Deviations

### D1 — the block below the title sits +34.00 px low — ACCEPTED, not a finding

`ORCHESTRATOR_NOTES.md:5` rules *"D1 the Fledgling copy wrap shifting the stack
by 34: ACCEPT (DB truth)."* Re-measured, and this iteration it is **exactly**
34.00 on every member of that block (sub +34.00/+34.00, bubble outer box
+34.00/+34.00, all three card top borders +34.00, all three bottom borders
+34.00, caption +34.00) with the title's first ink line, the lock button, the bar
rule and the CTA box all at **0.00**. Maya is stage 3 in the database
(`core/data/seed.dart`), so the title is `Pip grew into a Fledgling!`, which
wraps to two balanced lines (`NestBalancedText`, HTML line 55
`.kid-title { text-wrap: balance }`) and adds one 34 px line. Hard-coding the
design's stage-4 copy is forbidden (DATA OVER MOCKS). **No fix.**

### D2 — sparkle top points — still exact

All four sparkle ink boxes match to **0.00 px** with **identical fill pixel
counts** (1904 each), and the registered diff per sparkle region is
0.00–1.30 %. The iteration-2 `Path.addPolygon` fix and the D4 palette change
still hold. **No fix.**

### D3 — bubble tail is the CSS 18 × 9, the PNG export is smaller — ACCEPTED, not a finding

The bubble **box** is exact (outer y 463.00–529.00 design / 497.00–563.00 app,
both 66.00 tall; left column 42.00 px in both; right column 40.00 px in both).
Below the box the design's export tapers over 6 rows from 11.33 px wide and the
app over 9 rows from 17.33 px wide, same centre x. `ORCHESTRATOR_NOTES.md:4`:
*"D3 bubble tail: ACCEPT the CSS 18×9 (shared NestSpeechBubble follows
`.speech::after`; the PNG export is smaller). Not a finding."* Verified against
the source: `components.css:192` is `border: 9px solid transparent;
border-top-color: var(--ink); border-bottom: 0` → an 18 × 9 tail. The app is
the correct one. **No fix.**

### D4 — dark-mode sparkle/dot accents — still fixed, re-verified on screen

13/13 stroke probes `#1E1B3A` in dark, all eight fills at the light literals
with the design's own pixel counts, zero dark accents in the layer, and dark mean
diff unchanged at 8.49 % with band 1 at 4.77 % — identical to iteration 3, which
is the point: the fix is stable, not drifting. `cmp_dark_4.png` shows no light
outline. **No further fix.**

### D5 — the sky dot's design hex is off-token — observation, app is correct

`K07-evolution.html:42` hard-codes `<circle cx="268" cy="8" r="6"
fill="#3D7FF0"/>`. `#3D7FF0` is **not** a value in `tokens.css` for either theme
— `--sky` is `#2563D6` (light, `tokens.css:20`) / `#7FA9FF` (dark,
`tokens.css:105`) — and per the mandatory D4 note the whole layer is
theme-invariant, so the app paints the light `--sky` `#2563D6` in both themes.
Position and size are exact (Δ 0.00, same 540-px fill area as the design); this
is the only colour difference on the screen (592/584 differing device px in that
one dot's window, 13.6 % of a 4 356-px window). Same finding as iterations 2 and
3, already filed as `SHARED_REQUEST.md` item 4 and pinned by a test. **No code
fix** — a literal hex is forbidden and a new token is a `main` decision.

### D6 — page-glow gradient ≤ 2 per channel — observation

At eight sample points the app is within 2/255 per channel of the design's
`radial-gradient` interpolation in both themes (table above; worst cases (195,60)
light `#FBFBFF` → `#FDFCFF` = −2 and (60,360) light `#F7F5FF` → `#F5F4FD` = −2).
Invisible side by side; every face, ink and border colour is exact. **No fix.**

### D7 — Pip art differs from the PNG by mandate — observation

The design paints `pip-stage-3.svg` (68 px, `left 2 bottom 4`, `opacity .24
grayscale`) and `pip-stage-4.svg` (240 px, `right 6 bottom 0`); the PIP rule
requires the child's own Pip, so the app renders Maya's DB profile
(Mochi · sunny · stage 3) in the same slots with `oldStage = stage − 1 = 2`
(`pip_evolution_stage.dart:95-97`). Ink extents therefore differ by shape, not by
placement: the new-Pip ink bbox is design x 151.00–370.00 / y 110.00–340.00 vs
app x 165.67–370.00 / y 110.00–324.67. Every element the layout owns around the
art — the growth arrow (Δ ≤ 0.33), all four dots and all four sparkles
(Δ 0.00), the title below (Δy 0.00) — is within ±2 px. **No fix.**

### D8 — no home-indicator pill, and no coloured band under the bar — app correct by owner rule

The design PNGs paint the page glow below the bar plus a home pill. Census of
y 810–843, x 2–387 at a 2-device-px step (29 529 samples):

| image | distinct colours | dominant |
|---|---|---|
| design light | 7 | `#EEEBFF` ×26 314 (89.1 %), `#33304E` ×1 393 (4.7 %, pill) |
| **app light** | **1** | **`#FFFFFF` ×29 529 (100.0 %)** |
| design dark | 11 | `#2B2550` ×22 553 (76.4 %), `#2A244E`, `#2A244F`, + pill |
| **app dark** | **1** | **`#1F1C2E` ×29 529 (100.0 %)** |

The app paints **one** colour — the bar's own surface — across the whole band,
so it runs to the physical edge with no meadow/page-tint strip and no coloured
ring around the home indicator, in light and dark. That is exactly what the
loop's BOTTOM EDGE owner rule requires (*"the area below any bottom bar down to
the physical screen edge MUST use the SAME surface colour as that bar… UI
checks must FAIL a screen that shows one"*), and it overrides the PNG. The
missing pill is an OS affordance, the same class the STATUS BAR rule tells this
stage to ignore. **No fix.**

### D9 — TOOLING: `shot.sh` needs an absolute out path and can save a pre-first-frame capture — shared

Unchanged from iterations 2 and 3 and re-confirmed. Two things this iteration:
(1) the relative `docs/screens/K07/ui/…` out path in the stage brief **fails** —
`shot.sh` `cd`s into the app dir, so the brief's literal command aborts with
`cp: docs/screens/K07/ui/app_light_4.png: No such file or directory`; absolute
paths work. (2) the tool still waits on the app *process* and accepts two
identical captures 1 s apart, which can both be the previous launch's image. It
did not misfire here — the frame-identity assertion above caught nothing.
`SHARED_REQUEST.md` item 3 remains open. **No screen fix.**

### D10 — +1.00 px label baselines inside exact boxes — within tolerance, no fix

Two ink baselines sit exactly 1.00 logical px (3 device px) lower than the
design's, inside boxes that themselves match to 0.00 px:

| element | design | app | Δ |
|---|---|---|---|
| stat-card label ink, rel. the card's own top border | +45.00 | +46.00 | **+1.00** (all three cards, by the sub-pixel search) |
| CTA label ink, rel. the CTA border box | y 759.33 … 777.67 (h 18.33) | y 760.33 … 778.67 (h 18.33) | **+1.00** top and bottom |

The sub-pixel search above puts the optimum at exactly dy +3 device px for all
three labels and the CTA label, so this is a real 1 px baseline offset rather
than AA — and it is font-internal: the label/card/CTA *boxes*, radii, borders and
radii ramps are all 0.00, the label ink heights are exact, and the caption's
equivalent offset is **0.00**. Within the ±2 px rule and below what a designer
would see. **No fix** — recorded so the next iteration compares against the same
numbers instead of re-deriving them.

### D11 — the iteration-4 build is invisible at 390 px — observation, expected

`7c29857` (K07-BUG-6 + K07-BUG-7) produces a screen byte-identical to iteration 3
outside the status-bar clock (2 013 / 1 995 px in a 41 × 12 px box). That is the
correct outcome, not a gap: the card-height defect only appears when a cell is
narrower than its content (320 px and below) and the line-clamp defect only at
≥ 2.5× text scale, neither of which this stage can see at 390 px / 1.0×. What
this stage *can* confirm is that the fix did not disturb anything at the
reference size: all twelve card border bands still read 1.03–1.34 % and remain
mutually identical, and the title/sub/bubble still break with no clamp-induced
cut (see the copy check). **No fix.**

## Checks that passed (no deviation a designer would reject)

- **Alignment / gutters (owner rule)**: 20 px side gutter everywhere, and every
  edge the layout owns is on the design's to **0.00 px**. Card vertical borders
  land on x 20.00/129.67, 140.00/249.67, 260.00/369.67 — 10.33 px gaps, 3 px
  `--ink` strokes at x 20–23 / 126.67–129.67 / 140–143 / 246.67–249.67 /
  260–263 / 366.67–369.67, identical to the design. The bubble (x 73.00–80.00
  and 309.67–317.00 at its first border row), the caption (x 98.00–292.33 in
  both) and the CTA (x 20.00–369.67 in both) share those same edges. The three
  cards' top edges and bottom edges each spread **0.00 px** across the row.
- **Element order / presence**: lock button → Pip stage slot (old silhouette,
  growth arrow, new Pip) → title → sub → speech bubble → 3 stat cards →
  caption → bar rule → CTA. Nothing missing, nothing extra.
- **Bottom edge (owner rule)**: 1 distinct colour in the whole y 810–843 band,
  both themes (see D8).
- **Colours**: every face, ink and border token measured identical in both
  themes; the only colour deviation on the whole screen is the 6 px sky dot
  (D5) and ≤ 2/255 of gradient interpolation (D6).
- **No overflow**: **zero** exact `#FFFF00` pixels in any of the four frames
  (Flutter's RenderFlex stripe colour) — no overflow stripe anywhere; the design
  PNGs are also 0. The only pure `#000000` pixels in the app light frame
  (2 820, all in logical y 18–30) are the OS status-bar clock, which the
  STATUS BAR rule excludes.
- **No clipping / ellipsis**: the 2-line title breaks as `Pip grew into` /
  `a Fledgling!` (balanced, no one-word orphan), the bubble reads
  `Flap, flap! Look at Pip's` / `wings!`, all three stat labels and the caption
  fit inside their boxes with room either side, the CTA label fits with room
  either side. No `…`, no hard cut, no truncation anywhere — the app-only
  `maxLines` caps that could have cut them are gone (D11).
- **Icons**: the only glyphs are the design's `.lock-btn` padlock (ink bbox
  Δ 0.00) and the `.k7-arrow` chevron (Δ ≤ 0.33). No substitute icons.
- **Copy**: every string is DB-driven and character-for-character the HTML's
  ASCII apostrophe style (`0x27`) — `Pip grew into a Fledgling!`,
  `Because you helped 4 times`, `Flap, flap! Look at Pip's wings!`,
  `4 quests done`, `175 coins grown`, `3 of 4 stages`,
  `Pip still loves a chin scratch.`, `Meet Fledgling Pip`. The design's stage-4
  variants (`Songbird`, `25`, `250`, `4`, `Hear that? That is Pip's new song!`,
  `Meet Songbird Pip`) are the same templates one stage up. The three *identical*
  strings (the three stat labels and the caption) overlay the design to the
  device pixel. Exempt per DATA OVER MOCKS.
- **Mandated items honoured** (re-read in the source this iteration, not
  assumed): `PipAvatar` with the DB profile in **both** Pip slots and no
  `pip_stage_*.svg` anywhere in `features/pip` outside comments; `PipEvolutionStats`
  is `IntrinsicHeight` + `CrossAxisAlignment.stretch`; the hero title uses
  `NestBalancedText`; `_SparksPainter` resolves stroke and every fill from
  `NestColors.light` and its `shouldRepaint` is `false`; no `google_fonts` in
  `features/pip` or its tests; no `letterSpacing` anywhere in the feature; no
  `DateTime.now()`; no hard-coded hex in `features/pip/presentation/**`;
  tokens only.

## Verdict

Mean diff **9.69 % light / 8.49 % dark**, and the screen is pixel-identical to
iteration 3 outside the OS clock — the iteration-4 build changed nothing at the
reference size, which is the correct outcome for a 320 px / accessibility-scale
fix.

Everything the layout owns is within ±2 px of the design, most at exactly
0.00 px. Measured this iteration and re-proved by a ±2 device-px registration
search rather than by eye: the lock button and its glyph (0.00), all four
sparkles including their tips and fill areas (0.00, identical pixel counts),
all four dots (0.00 on position and size), the growth arrow (≤ 0.33), the
speech-bubble box and all four of its border bands (66.00 px tall in both,
42.00/40.00 px side runs, 0.46–1.45 % registered), all twelve stat-card border
bands (mutually identical to within 0.3 pp, so the three cards are one row again
— the K07-BUG-6 fix), the caption (Δx 0.00, ink bbox identical to the device
pixel, column-ink Pearson r = 0.986), the bar rule (**0.00 %** differing pixels),
the CTA box, face, ring and radius ramp (0.00, 0.18–0.24 % registered once the
label glyphs are masked out), every gutter and every edge.

Not a uniform vertical shift: the first control, the title's first line, the bar
rule and the CTA are all on the design's y; only the DB-copy block below the
extra title line moves, and it moves by the same 34.00 px throughout.

The remaining deltas are all accounted for and none is a visible defect a
designer would reject: the two orchestrator-accepted ones (D1 +34 px DB-copy
reflow, D3 the CSS 18×9 tail), the mandated Pip-art swap (D7), one off-token
design literal the app correctly refuses to fake (D5, filed), ≤ 2/255 of gradient
interpolation (D6), an OS-drawn home indicator plus the owner-mandated uniform
bottom edge (D8), two +1.00 px label baselines inside exact boxes (D10), the
invisible-at-390 fix (D11) and the shared capture race plus the relative-path
trap in tooling (D9).

VERDICT: PASS
