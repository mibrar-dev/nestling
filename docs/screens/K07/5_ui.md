# K07 · Pip evolves (`/pip-evolution`) — UI check, stage 5, **iteration 2**

Shots: `tools/screens/shot.sh` flags (`SEED=demo APP_MODE=kid CHILD=maya
THEME=light|dark DISABLE_ANIMATIONS=1`) on the assigned simulator **only** —
`BC440E48-B3A3-43BC-971B-0EF5DB621874` ("Nestling QA 2", 390×844). No other
simulator was booted, installed on or driven.
Design: `design/screens/light|dark/K07-evolution.png` (1170×2532 = 390×844 @3x).
Copy/geometry oracle: `design/html-source/screens/K07-evolution.html` +
`tokens.css` + `components.css`.
Artefacts: `ui/app_{light,dark}_2.png`, `ui/cmp_{light,dark}_2.png`.
**No product code was edited by this stage.**

All numbers below are **logical px**, measured on the native 3× frames with one
script run over design and app through the identical code path (device px ÷ 3),
so any resampling bias cancels. `cmp_*.png` were read visually as well; the
zoom checks were done at 2×.

> **Harness incident (read first).** The first pair of shots was wrong: both PNGs
> came back dark-themed (`bg@195,500 = #1F1C2E`) although one run passed
> `THEME=light`, and the two files were near-identical. Cause and fix in
> "Tooling" below. Every number in this report comes from the **re-shot,
> identity-verified** pair: light `bg@195,500 = #FFFFFF` / `CTA@195,760 =
> #6A58E8`, dark `bg@195,500 = #1F1C2E` / `CTA@195,760 = #A89BFF`, each accepted
> only after two captures 3 s apart produced the same md5.

## Mean diff (`tools/screens/compare.py`)

| theme | mean diff | band 0 (0–105) | 1 (105–211) | 2 (211–316) | 3 (316–422) | 4 (422–527) | 5 (527–633) | 6 (633–738) | 7 (738–844) |
|---|---|---|---|---|---|---|---|---|---|
| light | **9.69 %** | 1.71 | 6.06 | 16.07 | 10.55 | 14.24 | 16.80 | 7.06 | 5.07 |
| dark | **9.00 %** | 1.60 | 6.87 | 14.12 | 8.87 | 13.59 | 15.84 | 6.47 | 4.65 |
| *iter 1 light* | *9.80 %* | *1.71* | *6.47* | *16.48* | *10.55* | *14.24* | *16.80* | *7.06* | *5.07* |
| *iter 1 dark* | *8.94 %* | *1.57* | *6.61* | *13.89* | *8.87* | *13.59* | *15.84* | *6.47* | *4.65* |

Bands 5–6 are numerically identical to iteration 1 (the same +34 px copy shift
and the same card internals). **Band 1 — the sparkle band — dropped
6.47 → 6.06 % (light) and rose 6.61 → 6.87 % (dark, dark-theme accent fills,
see D4)**; band 0 is unchanged at 1.7 %. The residual is dominated by the two
mandated differences: the Pip art swap (band 2, 14–16 %) and the DB-copy stack
shift (bands 3–6).

## UI VERDICT RULE report — the required y positions

| what | design y | app y | Δ |
|---|---|---|---|
| screen title, first ink line | 376.33–402.33 | **376.33–402.33** | **0.00** |
| first control (`.lock-btn.lg` box, top edge) | 47.00 | **47.00** | **0.00** |
| first control (`.lock-btn.lg` box, bottom edge) | 103.00 | **103.00** | **0.00** |
| stat card 1 top border | 545.00 | 579.00 | +34.00 (D1, DB copy) |
| stat card 2 top border | 545.00 | 579.00 | +34.00 (D1, DB copy) |
| stat card 3 top border | 545.00 | 579.00 | +34.00 (D1, DB copy) |
| CTA (`.btn-kid.lilac` ink border, top edge) | 736.00 | **736.00** | **0.00** |

This is **not** a uniform vertical shift: the title line, the lock button, the
bar rule and the CTA are all exactly on the design's y. Only the block *below*
the extra title line moves, by exactly 34 px, which is D1 (accepted).

## Measured element-by-element (identical numbers in both themes)

| element | design | app | Δ |
|---|---|---|---|
| lock button rect (1 px `--line` border) | x 314.00–370.00, y 47.00–103.00 | x 314.00–370.00, y 47.00–103.00 | **0.00** |
| lock glyph ink bbox | x 333.00–351.00, y 65.00–85.00 | x 333.00–351.00, y 65.00–85.00 | **0.00** |
| gold dot (r 7) | x 97.33–114.67, y 108.33–125.67 | x 97.33–114.67, y 108.33–125.67 | **0.00** |
| sky dot (r 6) | x 280.33–295.67, y 107.33–122.67 | x 280.33–295.67, y 107.33–122.67 | **0.00** |
| sparkle 1 lilac ink box | x 31.33–72.67, y 135.33–176.67 (41.33²) | x 31.33–72.67, y 135.33–176.67 | **0.00** |
| sparkle 1 **top tip** row | y 135.33, x 52.00–52.33 (1 device px) | y 135.33, x 52.00–52.33 | **0.00** |
| sparkle 2 green ink box | x 311.33–352.67, y 129.33–170.67 | x 311.33–352.67, y 129.33–170.67 | **0.00** |
| sparkle 3 gold ink box | x 20.00–58.67, y 253.33–294.67 | x 20.00–58.67, y 253.33–294.67 | **0.00** |
| sparkle 4 peach ink box | x 333.33–370.00, y 255.33–296.67 | x 333.33–370.00, y 255.33–296.67 | **0.00** |
| sparkle 1 mid row (widest, 123 ink px) | y 155.67, x 31.30–72.30 | y 155.67, x 31.30–72.30 | **0.00** |
| sparkle 4 top tip row | y 255.33, x 354.00–354.33 | y 255.33, x 354.00–354.33 | **0.00** |
| title line 1 ink | x 23.67–367.00, y 376.33–402.33 | x 105.33–285.33, y 376.33–402.33 | y **0.00**, x = DB copy (D1) |
| sub ink | x 74.33–316.33, y 427.00–443.33 | x 80.00–311.00, y 461.00–477.33 | Δx copy, Δy +34.00 (D1) |
| speech-bubble box | x 65.00–325.00, y 463.00–528.00 | x 65.00–325.00, y 497.00–562.00 | Δx **0.00**, Δy +34.00 (D1) |
| bubble tail below the box | y 528.00–535.00 (7.00) | y 562.00–572.00 (10.00) | D3 (accepted) |
| stat-card boxes (3 px `--ink` border) | x 20–130 / 140–250 / 260–370, y 545.00–629.00 | same x, y 579.00–663.00 | Δx **0.00**, Δy +34.00 (D1) |
| card top-border straight runs | 29.33–120.67 / 149.33–240.67 / 269.33–360.67 | 29.33–121.00 / 149.33–241.00 / 269.33–361.00 | ≤ **0.33** |
| card number ink, rel. card top | 3.00–41.33 | 3.00–42.33 | ≤ **1.00** |
| card label ink, rel. card top | 54.00–81.00 | 55.00–81.00 | **1.00** |
| caption ink | x 98.00–292.33, y 649.33–662.67 | x 98.00–292.33, y 683.33–696.67 | Δx **0.00**, Δy +34.00 (D1) |
| growth-arrow ink | x 99.67–121.33, y 307.00–325.00 | x 100.00–121.00, y 307.33–324.67 | ≤ **0.33** |
| `.kid-bar` top rule (full bleed) | y 721.00–724.00, x 0–390 | y 721.00–724.00, x 0–390 | **0.00** |
| CTA ink border | x 20.00–370.00, y 736.00–800.00 | x 20.00–370.00, y 736.00–800.00 | **0.00** |
| CTA face | light `#6A58E8` / dark `#A89BFF` | light `#6A58E8` / dark `#A89BFF` | **0** |
| CTA label ink | light `#FFFFFF` / dark `#14121F` | light `#FFFFFF` / dark `#14121F` | **0** |
| bubble face | light `#FFFFFF` / dark `#1F1C2E` | light `#FFFFFF` / dark `#1F1C2E` | **0** |
| stat-card face | light `#FFFFFF` / dark `#1F1C2E` | light `#FFFFFF` / dark `#1F1C2E` | **0** |
| title / stat-number ink | light `#1E1B3A` / dark `#F3F0FA` | light `#1E1B3A` / dark `#F3F0FA` | **0** |
| caption + stat labels (`--ink-2`) | light `#4A4668` / dark `#C9C4DC` | light `#4A4668` / dark `#C9C4DC` | **0** |
| page glow, top of screen | light `#FCFBFF` / dark `#211E35` | light `#FDFCFF` / dark `#231F36` | ≤ **2** per channel |
| below the bar, y 806–843 (x 0–390, every 2 px) | glow `#EEEBFF` / `#2B2550` + home pill | **uniform** `#FFFFFF` / `#1F1C2E`, 0 deviating px | owner-rule override — app correct |

### Accent fills (modal non-ink colour inside each shape)

| shape | design PNG | app | note |
|---|---|---|---|
| sparkle 1 lilac | light `#7C6CF2` / dark `#7C6CF2` | light `#7C6CF2` / dark `#A89BFF` | light exact; dark = `--lilac` token (D4) |
| sparkle 2 green | `#1F9D63` / `#1F9D63` | `#1F9D63` / `#3CC98A` | light exact; dark = `--success`/`--leaf` token (D4) |
| sparkle 3 gold | `#F4B400` / `#F4B400` | `#F4B400` / `#F4B400` | exact both themes |
| sparkle 4 peach | `#FF8A5B` / `#FF8A5B` | `#FF8A5B` / `#FF9E78` | light exact; dark = `--peach` token (D4) |
| gold dot | `#F4B400` / `#F4B400` | `#F4B400` / `#F4B400` | exact |
| green dot | `#1F9D63` / `#1F9D63` | `#1F9D63` / `#3CC98A` | light exact; dark token (D4) |
| lilac dot | `#7C6CF2` / `#7C6CF2` | `#7C6CF2` / `#A89BFF` | light exact; dark token (D4) |
| sky dot | `#3D7FF0` / `#3D7FF0` | `#2563D6` / `#7FA9FF` | **D5** — `#3D7FF0` is not a token in either theme |

## Deviations

### D1 — the stack below the title sits +34.0 px low — ACCEPTED, not a finding

`4_review`/`ORCHESTRATOR_NOTES.md:5` rules: *"D1 the Fledgling copy wrap shifting
the stack by 34: ACCEPT (DB truth)."* Confirmed unchanged and still confined to
the copy-driven block:

| | design | app | Δ |
|---|---|---|---|
| title line 1 | y 376.33–402.33 | y 376.33–402.33 | **0.00** |
| title line 2 | — | y 410.33–436.33 | the extra DB line |
| sub | y 427.00 | y 461.00 | +34.00 |
| bubble top | y 463.00 | y 497.00 | +34.00 |
| card tops | y 545.00 | y 579.00 | +34.00 |
| caption | y 649.33 | y 683.33 | +34.00 |
| bar rule / CTA | y 721.00 / 736.00 | y 721.00 / 736.00 | **0.00** |

The DB title is `Pip grew into a Fledgling!` (Maya is stage 3) and wraps to two
balanced lines (`NestBalancedText`, HTML line 55 `.kid-title` → `text-wrap:
balance`), so the extra 34 px line-height pitch pushes only what follows. Hard-
coding the design's stage-4 copy is forbidden (DATA OVER MOCKS). **No fix.**

### D2 — every sparkle was missing its top point — **FIXED, verified**

Iteration 1's one live blocker (`ORCHESTRATOR_NOTES.md:3`, "fix as the UI check
says — the exact HTML 4-point path at the 4 spots"). The build stage fixed
`_sparkPath` (`Path.addPolygon` now receives the `M` pair as its first vertex
instead of a discarded `moveTo`). Evidence on screen:

| sparkle | design ink box | app ink box | top-tip row, design | top-tip row, app |
|---|---|---|---|---|
| 1 lilac | x 31.33–72.67, y 135.33–176.67 | x 31.33–72.67, y 135.33–176.67 | y 135.33, 1 px at x 52.0–52.3 | y 135.33, 1 px at x 52.0–52.3 |
| 2 green | x 311.33–352.67, y 129.33–170.67 | x 311.33–352.67, y 129.33–170.67 | y 129.33, 1 px at x 332.0–332.3 | y 129.33, 1 px at x 332.0–332.3 |
| 3 gold | x 20.00–58.67, y 253.33–294.67 | x 20.00–58.67, y 253.33–294.67 | y 253.33, 1 px at x 38.0–38.3 | y 253.33, 1 px at x 38.0–38.3 |
| 4 peach | x 333.33–370.00, y 255.33–296.67 | x 333.33–370.00, y 255.33–296.67 | y 255.33, 1 px at x 354.0–354.3 | y 255.33, 1 px at x 354.0–354.3 |

Iteration 1 measured all four as 41.0 × 27.0 with the top **14 px missing**; they
are now 41.33 × 41.33 and **byte-identical row profiles to the design** (the
1-device-px tip, the 123-ink-px waist row, the mirrored bottom tip), and the 3 px
`--ink` stroke with `strokeJoin.round` is unchanged. Confirmed in the 2× zoom
and in the `cmp_*` diff panels, where the four sparkles now show only hairline
edge differences. **No fix needed.**

### D3 — bubble tail is 3 px taller than the design PNG — ACCEPTED, not a finding

Box is exact (x 65.00–325.00, h 65.00 both, Δy +34 from D1). Tail: design
y 528.00–535.00 (7.00 with the 3 px border), app y 562.00–572.00 (10.00),
same centre x. `ORCHESTRATOR_NOTES.md:4`: *"D3 bubble tail: ACCEPT the CSS 18×9
(shared NestSpeechBubble follows `.speech::after`; the PNG export is smaller).
Not a finding."* Verified against the source: `components.css:192` is
`border: 9px solid transparent; border-bottom: 0` → an 18 × 9 tail. **No fix.**

### D4 — dark-mode sparkle/dot accents use the dark accent tokens — observation

Six of the eight accents are the *light-theme* hexes hard-coded in the HTML SVG
(`K07-evolution.html:37-44`) rather than theme tokens, so the dark design PNG
paints them at their light values while the app re-themes them:

`#7C6CF2 → #A89BFF` (`--lilac`), `#1F9D63 → #3CC98A` (`--success`/`--leaf`),
`#FF8A5B → #FF9E78` (`--peach`), `#3D7FF0 → #7FA9FF` (`--sky`); gold `#F4B400`
is the same token in both themes and matches. This is the item `4_review.md`
finding 9 flagged for an orchestrator ruling, still unruled in
`ORCHESTRATOR_NOTES.md`. **The app is on the right side of the rules here**:
"never hard-code colours — tokens only" plus `ORCHESTRATOR_NOTES.md:3` ("token
fills"), and `NestColors.dark` transcribes `tokens.css` exactly
(`app/lib/core/design_system/tokens/colors.dart:324` etc.). Light mode matches
the PNG pixel-for-pixel on every accent except D5. **No code fix.** If the
orchestrator wants PNG parity in dark mode it is a shared decision (either
literal accents — forbidden — or new dark accent tokens), i.e. a `main` change,
not a screen change.

### D5 — the sky dot's design hex is off-token — observation, app is correct

`K07-evolution.html:42` hard-codes `<circle cx="268" cy="8" r="6" fill="#3D7FF0"/>`.
`#3D7FF0` is **not** a value in `tokens.css` for either theme — `--sky` is
`#2563D6` (light, `tokens.css:20`) and `#7FA9FF` (dark, `tokens.css:105`), which
is what the app paints (light `#2563D6` measured on screen). The 12 px dot is
positionally exact (Δ 0.00); only the fill differs, by 24 in blue in light and by
a full re-theme in dark. Same class as D4. **No code fix**; worth a line in the
design-source bug list for whoever owns the HTML.

### D6 — page-glow gradient is up to 2 per channel off — observation

Top-of-screen background: light `#FCFBFF` (design) vs `#FDFCFF` (app); dark
`#211E35` vs `#231F36`. That is the CSS `radial-gradient` interpolation in
Chrome vs Impeller, ≤ 2/255 per channel, invisible side by side. Bubbles, cards,
bar, CTA, all ink and all face colours are exact (table above). **No fix.**

### D7 — Pip art differs from the PNG by mandate — observation

The design paints `pip-stage-3.svg` (68 px silhouette, `left 2 bottom 4`,
`opacity .24 grayscale`) and `pip-stage-4.svg` (240 px, `right 6 bottom 0`); the
PIP rule requires the child's own Pip, so the app renders Maya's DB profile
(Mochi · sunny · stage 3) at the same slot and `oldStage = stage − 1` for the
silhouette (`pip_evolution_stage.dart:95-100,158`). Ink extents therefore differ
by shape, not by placement: in a sparkle-free window the new Pip's ink runs
design x 151.00… y 107.33–340.00 vs app x 165.67… y 107.33–338.00 (the art's
silhouette is narrower/rounder at stage 3), the old silhouette's ink bottom is
design 344.00 vs app 338.33. Every element the layout owns around the art —
the growth arrow (Δ ≤ 0.33), the dots (Δ 0.00), the slot rows, the title below —
is within ±2 px. **No fix.**

### D8 — no home-indicator pill in the app shot — observation

The design PNGs paint a home pill (x 127–263, y 825–830, `#33304E` / `#FFF`);
the app shot has no ink at all below the CTA. That is an OS affordance drawn by
the simulator, the same class the loop's STATUS BAR rule tells this stage to
ignore ("`NestStatusBar` now only reserves height; the OS draws the real status
bar"), and the bar's *surface* correctly runs to the physical edge (see the
bottom-edge row below). **No fix.**

### D9 — TOOLING: `tools/screens/shot.sh` can save a pre-first-frame capture — shared

Not a screen defect, but it produced a **false 71.31 % mean diff** on the first
light comparison and would have failed this check on a harness artefact.
Repro (three consecutive runs, identical command, no code change in between):

| run | `THEME=` passed | frame actually captured |
|---|---|---|
| 1 | light | dark (`bg@195,500 = #1F1C2E`) |
| 2 | dark | light (`bg@195,500 = #FFFFFF`) |
| 3 | light | light ✓ |

`shot.sh` starts its stability loop 1 s after the *process* appears in
`launchctl list`, but the run uses `--no-resident`, so the tool has already
exited and Flutter may not have painted; the two "identical consecutive"
captures can both be the pre-frame state, which is the previous launch's image.
Workaround used for the accepted shots (same flags, no repo file touched): after
`READY`, `sleep 8`, then 5 captures 3 s apart, keep the first repeated md5, and
**assert the frame's identity** (bg + CTA face sample) before saving.
Two changes to `tools/screens/shot.sh` would remove the trap (it is out of scope
for a screen agent, RULES §1): wait for the app's first frame rather than the
process, and require stability across ≥ 3 captures ≥ 2 s apart. Iteration 1's
relative-output-path note still stands too — the output path must be absolute.
Filed as item 3 of `docs/screens/K07/SHARED_REQUEST.md`.

## Checks that passed (no deviation a designer would reject)

- **Alignment / gutters**: 20 px side gutter everywhere; lock button, cards 1–3
  (x 20/140/260 with 10 px gaps, 3 px `--ink` borders at 20–23, 127–130,
  140–143, 247–250, 260–263, 367–370), bubble, caption (x 98.00–292.33) and CTA
  (x 20.00–370.00) all share the same edges; top-border straight runs match to
  ≤ 0.33 px; radius ramps identical.
- **Bottom edge (owner rule)**: every row y 806–843 across x 0–390 is a single
  colour — light `#FFFFFF`, dark `#1F1C2E` — **0 deviating pixels**, so the bar
  runs to the physical edge in both themes with no meadow/page-tint strip and no
  coloured ring around the home indicator. The design PNGs show the glow there
  (`#EEEBFF` / `#2B2550`); the owner rule overrides the PNG and the app is
  correct.
- **Colours**: every face and ink token measured identical in both themes
  (bubble/card/bar/CTA faces, `--ink`, `--ink-2`, CTA label ink).
- **No overflow**: zero pure-yellow (`#FFFF00`-ish) pixels in either app shot —
  no Flutter overflow stripe anywhere; the design PNGs also have zero.
- **No clipping / ellipsis**: the 2-line title (balanced, no one-word orphan),
  the 2-line bubble and all three stat labels fit inside their boxes; nothing is
  truncated and no `…` appears.
- **Icons**: the only glyph is the design's `.lock-btn` padlock (ink bbox Δ 0.00)
  and the `.k7-arrow` chevron (Δ ≤ 0.33). No substitute icons.
- **Copy**: every string is DB-driven and character-for-character the HTML's
  ASCII apostrophe style — `Pip grew into a Fledgling!`, `Because you helped 4
  times`, `Flap, flap! Look at Pip's wings!`, `4 quests done`, `175 coins grown`,
  `3 of 4 stages`, `Pip still loves a chin scratch.`, `Meet Fledgling Pip`. The
  design's stage-4 variants (`Songbird`, `25`, `250`, `Hear that? That is Pip's
  new song!`) are the same templates one stage up. Exempt per DATA OVER MOCKS.
- **Mandated items honoured**: `PipAvatar` with the DB profile for both Pip
  slots; `NestBalancedText` for the `.kid-title`; no `google_fonts`; no
  letter-spacing overrides; tokens only, no hex literals in this feature's
  painting path.

## Verdict

Iteration 1's single live defect (D2, all four sparkles 14 px short and the wrong
shape) is fixed and now measures **0.00 px** against the design at all four
spots, tips included, in both themes. Every layout-owned element — the lock
button and its glyph, the four sparkles and four dots, the growth arrow, the
three stat cards with their internals, the speech-bubble box, the caption, the
bar rule, the CTA box, face and label, every gutter and every radius — is within
±2 px of the design (most at 0.00), the page glow is within 2/255, the bottom
edge is a single uniform bar surface to the physical edge in light and dark, and
there is no overflow, clipping or ellipsis. The remaining deltas are the two
orchestrator-accepted ones (D1 +34 px DB-copy reflow, D3 3 px tail), two
token-vs-hard-coded-hex observations that put the **app** on the right side of
the rules (D4, D5), the mandated Pip-art swap (D7), an OS-drawn home indicator
(D8) and a harness capture race in shared tooling (D9).

VERDICT: PASS