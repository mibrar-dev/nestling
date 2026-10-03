# P06 Pocket money setup — UI check (Stage 5, iteration 6)

Route `/pocket-money-setup` · feature `pocket_money` · parent mode ·
seed `onboarding_kids` · child `maya` (populated: Maya £3.00, Leo £1.50).
Simulator UDID 604697A9-11DA-462F-9837-396E9CA2493A (390×844, same as designs).
No Pip on this screen (P01–P07 onboarding rule). No `ORCHESTRATOR_NOTES.md` exists.

## Shots (per stage)

- `bash tools/screens/shot.sh "$PWD/app" /pocket-money-setup "$PWD/docs/screens/P06/ui/app_light_6.png" 604697A9-11DA-462F-9837-396E9CA2493A light onboarding_kids parent maya` → stable frame saved.
- Same with `dark` → `docs/screens/P06/ui/app_dark_6.png`.
  (Absolute `OUT` paths: `shot.sh` `cd`s into the app dir before copying, so a
  relative `OUT` resolves inside `app/` and the copy fails.)

## Compares

- `python3 tools/screens/compare.py design/screens/light/P06-pocket-money.png docs/screens/P06/ui/app_light_6.png docs/screens/P06/ui/cmp_light_6.png`
- `python3 tools/screens/compare.py design/screens/dark/P06-pocket-money.png docs/screens/P06/ui/app_dark_6.png docs/screens/P06/ui/cmp_dark_6.png`

Mean diff: light **0.89%**, dark **0.82%** (iteration 5's H1 truncation is fixed).

Band tables (8 horizontal bands, 0 = top):

Light:

```text
mean diff: 0.89%
band  y-range    diff%
  0      0-105    1.60%
  1    105-211    0.36%
  2    211-316    0.28%
  3    316-422    0.21%
  4    422-527    0.34%
  5    527-633    0.14%
  6    633-738    1.12%
  7    738-844    3.08%
```

Dark:

```text
mean diff: 0.82%
band  y-range    diff%
  0      0-105    1.59%
  1    105-211    0.37%
  2    211-316    0.26%
  3    316-422    0.17%
  4    422-527    0.29%
  5    527-633    0.14%
  6    633-738    1.21%
  7    738-844    2.54%
```

Read `docs/screens/P06/ui/cmp_light_6.png`, `cmp_dark_6.png`,
`app_light_6.png`, `app_dark_6.png` against
`design/screens/light|dark/P06-pocket-money.png` and
`design/html-source/screens/P06-pocket-money.html`. Bands 1–5 are near-clean;
remaining heat is band 0 (status bar), day-chip glyph raster (band 4 edge),
caption/CTA raster + home indicator (bands 6–7).

## Element-by-element (design vs app, light + dark unless noted)

Checked: presence, order, copy (character-by-character vs HTML source),
spacing (±2 px logical), sizes, 20 px gutters / alignment, colours, radii,
shadows, icon choice, overflow/clipping/ellipsis, dark-mode colours, bottom
edge, status-bar rule. Pill/chip/button/card BACKGROUND/BORDER rects compared,
not just text.

- H1 `How does pocket money work in your house?`: 2-line wrap with the break
  after `money`, identical to the design in both themes — iteration 5's
  single-line truncation is FIXED. Copy exact. Bands 1 heat ~0.3% (raster).
- Option cards ×3 (`Weekly amount` / `A set amount every week`,
  `Earn per quest` / `Coins turn into pence at payout`, `Both` /
  `Weekly base + bonus for extra quests`, `Both` selected): presence, order,
  copy, 8 px gap, min-height 60, padding 8/13, radius 16, 2 px border, card
  shadow, selected leaf border on leafTint with 22 px radio + 10 px dot all
  match; rects sit at design y-positions.
- Settings card: 16/16/12 insets, full-bleed 1 px dividers (vertical 8),
  radius 24, shadow all match.
- `Payout day` chips `Mon…Sun`, `Sat` selected: order, labels, selection,
  pill rects, 44-tall tap boxes, 6 px gaps, 20 px gutters all correct.
  Glyph size differs — see deviation 2.
- `Weekly base` rows: `M` lilac + `Maya` + `− £3.00 +`, `L` peach + `Leo` +
  `− £1.50 +`, Maya-then-Leo order (CHILD ORDER ✓), amounts match seeded DB
  (DATA OVER MOCKS ✓). Copy exact incl. `£`. Steppers 44 circle.
- `Coin value` row: 40×40 radius-16 coinTint tile + `Coin value` +
  `10 coins = 10p`, copy exact, single line, no overflow. Glyph differs —
  see deviation 3.
- Caption `Nestling never holds or moves money. You pay your way; we keep score.`
  + `Continue`: copy exact, centred 2-line caption, 52-high pill CTA, dense
  14 px vertical CTA padding all match.
- Bottom edge: CTA surface runs to the physical edge in light and dark — no
  coloured strip. OWNER BOTTOM EDGE rule ✓.
- Gutters/alignment: 20 px side edges consistent across scroll, cards, CTA;
  nothing a few px off.
- Dark mode colours: selected-option deep-green tint, Sat pill, coin tile,
  CTA mint/black-text all match the dark PNG.
- `google_fonts`/`GoogleFonts`: absent.

## Numbered deviations (element, design value, app value, fix)

1. Status bar time/icons — design `9:41` + mocks; app real OS time/icons.
   Fix: none (STATUS BAR rule: ignore; band 0 ~1.6% is this only).
2. Day-chip glyph size — design 13 px labels filling ~45.7 px cells; app
   `NestChip` (14 px + padding) via `FittedBox(scaleDown)` renders ~10–11 px.
   Pill/border rects, order, selection, 44 tap targets, gaps, colours correct.
   Fix (shared): optional `labelStyle` override (SPACING_SPEC conflict #6,
   pre-flagged in `1_plan.md` §7 — do not fork the component). Legible,
   centred, no overflow. Not designer-rejectable at screen scope.
3. Coin-tile glyph — design `assets/coin.svg`; app `NestIcons.poundCoin` in
   the same 40×40 radius-16 coinTint tile. Fix: none (token equivalent).
4. Bottom strip / home indicator — design shows a paper/cream strip under the
   CTA; app runs CTA surface to the edge in both themes. Fix: none (OWNER
   BOTTOM EDGE override; app is correct; band 7 diff ~2.5–3.1% is this plus
   the live indicator).
5. Caption/CTA/coin-row raster heat (bands 5–6, ≤1.2%) — glyph rasterization
   after 1170→390 LANCZOS rescale; no positional/colour deviation underneath.
   Fix: none (artifact).

Copy is character-exact vs the HTML source (ASCII + `£` only); no
misalignment, no clipping, no ellipsis failures, no hard-coded colours/sizes.

VERDICT: PASS
