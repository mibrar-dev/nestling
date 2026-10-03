# P13 · Payout — Stage 5 UI check (iteration 1)

Route `/payout`, simulator BC440E48-B3A3-43BC-971B-0EF5DB621874 (390×844).
Shots: `docs/screens/P13/ui/app_light_1.png`, `app_dark_1.png`
(seed demo, parent mode, Maya). Compares: `cmp_light_1.png`, `cmp_dark_1.png`
vs `design/screens/light|dark/P13-payout.png` (1170×2532 ÷ 3 = logical px;
all y/x below are logical px). Status-bar glyphs excluded per orchestrator
rule (OS draws the real bar).

## Mean diff

- Light: **7.44 %** — band 0 (y 0–105) 36.89 %, band 1 (y 105–211) 16.96 %,
  bands 2–7 (y 211–844) 0.00 / 0.19 / 1.74 / 1.53 / 0.90 / 1.41 %.
- Dark: **2.21 %** — band 0 8.22 %, band 1 3.93 %, bands 2–7
  0.00 / 0.19 / 1.68 / 1.48 / 0.76 / 1.45 %.

Bands 0–1 carry the failure below. Bands 2–7 residual (~1–2 %) is text
rasterisation (bundled Nunito/Inter vs browser render; glyph edges within
±2 px, invisible at 1×) plus the OS home-pill mock (see non-findings).

## Measured y positions (design vs app, light)

| Element | Design y | App y | Δ |
|---|---|---|---|
| Scrim top edge (full-screen dim) | 0 (covers header) | ~152 (below summary card) | **+152 FAIL** |
| Sheet top edge (paper) | ~343 | ~343 | 0 |
| Sheet title "Saturday payout" first glyph row | ~383 | ~383 | 0 |
| Subtitle "Tick once…" | ~413 | ~413 | 0 |
| Maya check rect (green, shape) | x 307–355 @ y 470 | x 307–355 @ y 470 | 0 |
| Leo check rect (empty, shape) | x 307–355 @ y 560 | x 307–355 @ y 560 | 0 |
| CTA rect (green pill, shape) | x 20–369, bottom ~750 | x 20–369, bottom ~750 | 0 |
| Caption "Your children…" last row | ~790 | ~790 | 0 |
| Bottom edge | paper to y 844 | paper to y 844 | 0 |

Sampled colours prove the scrim gap: at (350, 50–150) design is
`#97949E` (= paper × scrim 45 %: exact match for dimmed paper) while app is
`#FBF7F0` pure paper with a bright-white summary card. Dark theme same
shape: design header near-black dimmed, app bright `#15131F` paper + bright
card. Sheet content below y ~343 is pixel-aligned (title, both checks, CTA,
caption all Δ 0).

## Deviations

1. **Scrim does not cover the background header (both themes).**
   Design: `.scrim{position:absolute;inset:0}` dims the whole screen —
   "Pocket money" title and the "Maya is owed £4.20 · Leo is owed £2.10"
   summary card render dimmed (`#97949E` light). App: title + summary card
   render bright/undimmed (`#FBF7F0` paper, white card); scrim starts at
   ~y152. Visible side-by-side without zoom; a designer would reject.
   Fix: in `app/lib/features/pocket_money/presentation/views/payout_view.dart`,
   follow `1_plan.md` §(a) — `_DimmedLedger` must be a plain undimmed Column
   (`Positioned.fill`), with a separate full-`Positioned.fill` scrim
   `GestureDetector` (`ColoredBox(tokens.scrim)`, `onTap: _goBack`) layered
   between it and the `PayoutSheet` `Align(bottomCenter)`. Do not keep the
   scrim as the `Expanded` tail of the header Column (current lines 255–263).
   Side benefit: scrim-tap dismissal then works over the header area too.
2. **Leo name/amount block sits ~2 px high** (design name top ~555, app
   ~553 at x=100; amount baseline +2 px extent). Within the ±2 px rule and
   invisible at 1× — recorded, no fix required beyond the rebuild in (1);
   re-measure after the scrim fix.

Checked OK (no deviation): presence/order of all elements; child order
Maya→Leo; copy incl. `you've`/`Maya's` ASCII apostrophes, `·` U+00B7
separators, `&`, two-line wraps identical; Maya ticked/Leo unticked; savings
toggle ON with `Move £1.00 of Maya's to her Lego fund`; CTA label + caption;
avatars (lilac M / peach L, s44); check 48×48 r14, toggle 51×31, CTA min-h 52
pill, grabber 40×5, sheet radius-top 32, 20 px gutters, cards/sheet/CTA
aligned; dark-mode leaf CTA/cards/toggle; OWNER bottom-edge rule (paper to
y 844 both themes, no coloured strip); no overflow/clipping/ellipsis faults.

Non-findings (not deviations): status-bar time/glyphs (OS-drawn, excluded);
design home-indicator pill (y 825–829, OS-drawn live; app correctly runs
paper to the edge); sheet-text rasterisation ≤2 px.

VERDICT: FAIL
