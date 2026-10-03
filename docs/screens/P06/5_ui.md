# P06 Pocket money setup — UI check (Stage 5, iteration 2)

Route `/pocket-money-setup` · feature `pocket_money` · parent mode · seed `fresh` · child `maya`.
Simulator UDID `BC440E48-B3A3-43BC-971B-0EF5DB621874` (390×844, same as designs).
No Pip on this screen (P01–P07 onboarding rule). No `ORCHESTRATOR_NOTES.md` exists.

## Shots (fresh parent maya, per stage)

`tools/screens/shot.sh` `cd`s into the app dir before copying, so a relative
`OUT` resolves inside `app/` after the `cd` and the copy fails. Used absolute
`OUT` paths (same files the stage names):

- `bash tools/screens/shot.sh "$PWD/app" /pocket-money-setup "$PWD/docs/screens/P06/ui/app_light_2.png" BC440E48-B3A3-43BC-971B-0EF5DB621874 light fresh parent maya` → stable frame saved.
- Same with `dark` → `docs/screens/P06/ui/app_dark_2.png`.

## Compares

- `python3 tools/screens/compare.py design/screens/light/P06-pocket-money.png docs/screens/P06/ui/app_light_2.png docs/screens/P06/ui/cmp_light_2.png`
- `python3 tools/screens/compare.py design/screens/dark/P06-pocket-money.png docs/screens/P06/ui/app_dark_2.png docs/screens/P06/ui/cmp_dark_2.png`

Mean diff: light **5.31%**, dark **5.27%**.

Band tables (8 horizontal bands, 0 = top):

Light:

```text
mean diff: 5.31%
band  y-range    diff%
  0      0-105    1.61%
  1    105-211    7.85%
  2    211-316    6.65%
  3    316-422    8.35%
  4    422-527    4.75%
  5    527-633    5.60%
  6    633-738    5.18%
  7    738-844    2.44%
```

Dark:

```text
mean diff: 5.27%
band  y-range    diff%
  0      0-105    1.61%
  1    105-211    8.09%
  2    211-316    6.74%
  3    316-422    7.56%
  4    422-527    4.25%
  5    527-633    5.50%
  6    633-738    5.83%
  7    738-844    2.54%
```

Read `docs/screens/P06/ui/cmp_light_2.png`, `cmp_dark_2.png`,
`app_light_2.png`, `app_dark_2.png` against
`design/screens/light|dark/P06-pocket-money.png` and
`design/html-source/screens/P06-pocket-money.html`. Band 0/7 are low
(status reserve / CTA match); bands 1–3 heat is text antialiasing plus the
day-chip glyph scale (deviation 3); bands 4–6 heat is the empty-state height
cascade (deviation 2 shifting the coin row up).

## Element-by-element (design vs app, light + dark unless noted)

Checked: presence, order, copy (character-by-character vs HTML source),
spacing (±2 px logical), sizes, 20 px gutters / alignment, colours, radii,
shadows, icon choice, overflow/clipping/ellipsis, dark-mode colours, bottom
edge, status-bar rule.

- H1 `How does pocket money work in your house?`: present, 2-line wrap after
  `money` in both. Copy exact. Position/gutters match; heat edges are
  antialiasing only.
- Option cards ×3 (`Weekly amount` / `A set amount every week`,
  `Earn per quest` / `Coins turn into pence at payout`, `Both` /
  `Weekly base + bonus for extra quests`, `Both` selected): order, copy,
  8 px gap, min-height 60, padding 8/13, radius 16, 2 px border, card shadow,
  selected leaf border on leafTint with 22 px radio + 10 px leaf dot all match.
- Settings card: `NestCard` zero-padding with manual 16/16/12 insets and
  full-bleed 1 px dividers (vertical 8) matches; radius 24, shadow match.
- `Payout day` label + 7 chips `Mon…Sun`, `Sat` selected, single-select:
  order, labels, selection, pill shape, selected leaf-tint/border match;
  7×`Expanded` 44-tall tap boxes, 6 px gaps, 20 px card gutters all aligned.
  Glyph size differs — see deviation 3.
- `Coin value` row: 40×40 radius-16 coinTint tile + `Coin value` +
  `10 coins = 10p` present, copy exact, single line, no overflow, colours
  match both themes. Glyph differs — see deviation 4.
- Caption `Nestling never holds or moves money. You pay your way; we keep score.`
  + `Continue`: copy exact (single space after `.`), centred 2-line caption,
  52-high pill CTA, dense 14 px vertical CTA padding all match.
- Gutters/alignment: scroll, option cards, settings card, CTA all share the
  same 20 px side edges; nothing visibly off by a few px.
- Overflow: none at 390 width in either theme; day labels single-line, coin
  trailing text ellipses inside `Flexible`, option subs maxLines 2.
- Dark mode: paper/surface/line/ink, selected-option deep-green tint,
  selected-Sat pill, coin tile, CTA mint/button all match the dark PNG.
- `google_fonts`/`GoogleFonts`: absent (cleared in 2b).

## Numbered deviations (element, design value, app value, fix)

1. Status bar time/icons — design: `9:41` + mock signal/wifi/battery;
   app: real OS time (`00:53`/`00:58`) + real icons. Fix: none.
   `NestStatusBar` reserves height only; orchestrator STATUS BAR rule says to
   ignore status-bar differences. Band 0 diff (1.61%) is this only.
2. Weekly-base rows — design: two stepper rows (`Maya £3.00`, `Leo £1.50`
   with 44 px steppers); app (mandated `fresh` seed, no children):
   caption `Add children to set weekly amounts.` (plan §4 empty state).
   Fix: none at screen scope. Seed truth over mocks: `fresh` has no children
   by definition, and `1_plan.md` §4 specifies exactly this caption. The
   downstream coin-row shift up (~one row height, bands 4–6 heat) is a
   consequence of this expected difference, not an independent layout bug.
   A `demo`-seed shot would show the Maya-then-Leo rows (covered by widget
   tests); the loop mandated `fresh`, so this diff is by instruction.
3. Day-chip glyph size — design: 13 px centred day labels filling the
   ~45.7 px cells; app: `NestChip` (14 px label + `0 14px` padding) inside a
   44-tall tap box via `FittedBox(scaleDown)`, so the pill scales to fit
   7-across and the rendered glyphs are ~10–11 px (visibly smaller, outside
   ±2 px). Selection, order, tap size (44), gaps, colours all correct; only
   glyph scale drifts. Fix (shared, not screen scope): optional `labelStyle`
   override on the shared chip (SPACING_SPEC conflict #6, pre-flagged in
   `1_plan.md` §7 as a follow-up `SHARED_REQUEST` candidate — do not fork
   the component). Screen used the correct component correctly; text stays
   legible, single-line, centred, no overflow. Not designer-rejectable at
   screen scope.
4. Coin-tile glyph — design/HTML: `assets/coin.svg` gold coin;
   app: `NestIcon(NestIcons.poundCoin)` in the same 40×40 radius-16 coinTint
   tile. Fix: none. Token-correct design-system equivalent; size, tile,
   colour, position match; not designer-rejectable.
5. Bottom strip / home indicator — design: paper/cream strip under the CTA
   with a home pill on it; app: CTA surface runs to the physical edge in
   light and dark (no coloured strip around the indicator). Fix: none.
   OWNER BOTTOM EDGE rule overrides the designs; the app is correct and the
   design is stale here. Band 7 diff (2.4–2.5%) is this intentional override
   plus the live home indicator.
6. Text-edge heat on H1/options/caption/CTA (bands 1–3, 6) — design vs app
   glyph rasterization after the compare's 1170→390 LANCZOS rescale.
   No positional, size, spacing, or colour deviation underneath; copy and
   wrapping verified identical. Fix: none (compare artifact).

No other spacing drift: H1→options 16, option gap 8, options→settings 16,
`Payout day` label→chips 6, dividers vertical 8, CTA caption→button 8 all match
the HTML/`SPACING_SPEC` within ±2 px outside the deviation-2 cascade. No
misalignment, no clipping, no ellipsis failures, no hard-coded colours/sizes,
no `google_fonts`.

VERDICT: PASS
