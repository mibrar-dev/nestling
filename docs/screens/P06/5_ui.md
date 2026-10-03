# P06 Pocket money setup — UI check (Stage 5, iteration 4)

Route `/pocket-money-setup` · feature `pocket_money` · parent mode ·
seed `onboarding_kids` · child `maya` (populated: Maya £3.00, Leo £1.50).
Simulator UDID `BC440E48-B3A3-43BC-971B-0EF5DB621874` (390×844, same as designs).
No Pip on this screen (P01–P07 onboarding rule). No `ORCHESTRATOR_NOTES.md` exists.

## Shots (per stage)

`tools/screens/shot.sh` `cd`s into the app dir before copying, so a relative
`OUT` resolves inside `app/` after the `cd` and the copy fails. Used absolute
`OUT` paths (same files the stage names):

- `bash tools/screens/shot.sh "$PWD/app" /pocket-money-setup "$PWD/docs/screens/P06/ui/app_light_4.png" BC440E48-B3A3-43BC-971B-0EF5DB621874 light onboarding_kids parent maya` → stable frame saved.
- Same with `dark` → `docs/screens/P06/ui/app_dark_4.png`.

Process note (not a finding): the first dark capture saved a boot-transient
frame showing P03 Create account in light theme (route guard before the
deep-link applied; diff 74.68%). Re-ran the identical command; the re-take is
a stable P06 dark frame (diff 2.14%). Light was stable first try.

## Compares

- `python3 tools/screens/compare.py design/screens/light/P06-pocket-money.png docs/screens/P06/ui/app_light_4.png docs/screens/P06/ui/cmp_light_4.png`
- `python3 tools/screens/compare.py design/screens/dark/P06-pocket-money.png docs/screens/P06/ui/app_dark_4.png docs/screens/P06/ui/cmp_dark_4.png`

Mean diff: light **2.22%**, dark **2.14%**.

Band tables (8 horizontal bands, 0 = top):

Light:

```text
mean diff: 2.22%
band  y-range    diff%
  0      0-105    1.60%
  1    105-211    0.36%
  2    211-316    0.28%
  3    316-422    0.21%
  4    422-527    4.12%
  5    527-633    5.54%
  6    633-738    3.43%
  7    738-844    2.25%
```

Dark:

```text
mean diff: 2.14%
band  y-range    diff%
  0      0-105    1.61%
  1    105-211    0.37%
  2    211-316    0.26%
  3    316-422    0.17%
  4    422-527    3.71%
  5    527-633    5.28%
  6    633-738    3.38%
  7    738-844    2.38%
```

Read `docs/screens/P06/ui/cmp_light_4.png`, `cmp_dark_4.png`,
`app_light_4.png`, `app_dark_4.png` against
`design/screens/light|dark/P06-pocket-money.png` and
`design/html-source/screens/P06-pocket-money.html`. Bands 1–3 are near-clean
(H1 + option cards match); remaining heat is bands 4–6 (day-chip glyph scale
+ stepper/coin-row raster) and band 0/7 (status bar + home indicator).

## Element-by-element (design vs app, light + dark unless noted)

Checked: presence, order, copy (character-by-character vs HTML source),
spacing (±2 px logical), sizes, 20 px gutters / alignment, colours, radii,
shadows, icon choice, overflow/clipping/ellipsis, dark-mode colours, bottom
edge, status-bar rule. Pill/chip/button/card BACKGROUND/BORDER rects compared,
not just text (per CHIP ROWS ruling).

- H1 `How does pocket money work in your house?`: present, 2-line wrap with
  the break after `money` in both — identical to the design, no orphan line.
  Copy exact. Bands 1 heat ~0.3% (raster only).
- Option cards ×3 (`Weekly amount` / `A set amount every week`,
  `Earn per quest` / `Coins turn into pence at payout`, `Both` /
  `Weekly base + bonus for extra quests`, `Both` selected): presence, order,
  copy, 8 px gap, min-height 60, padding 8/13, radius 16, 2 px border, card
  shadow, selected leaf border on leafTint with 22 px radio + 10 px leaf dot
  all match. Card rects align to the same 20 px edges as the settings card.
- Settings card: `NestCard` zero-padding with manual 16/16/12 insets and
  full-bleed 1 px dividers (vertical 8) matches; radius 24, shadow match.
- `Payout day` label + 7 chips `Mon…Sun`, `Sat` selected, single-select:
  order, labels, selection, pill shape/rects, selected leaf-tint/border match;
  44-tall tap boxes, 6 px gaps, 20 px card gutters all aligned.
  Glyph size differs — see deviation 2.
- `Weekly base` rows: `M` lilac avatar + `Maya` + stepper `− £3.00 +`, then
  `L` peach avatar + `Leo` + stepper `− £1.50 +`, in Maya-then-Leo insertion
  order (CHILD ORDER ruling ✓). Copy exact incl. `£` (U+00A3). Amounts match
  the seeded DB (DATA OVER MOCKS ✓). Stepper buttons 44 circle, value
  min-width 64. No overflow at 390.
- `Coin value` row: 40×40 radius-16 coinTint tile + `Coin value` +
  `10 coins = 10p` present, copy exact, single line, no overflow, colours
  match both themes. Glyph differs — see deviation 3.
- Caption `Nestling never holds or moves money. You pay your way; we keep score.`
  + `Continue`: copy exact (single space after `.`), centred 2-line caption,
  52-high pill CTA, dense 14 px vertical CTA padding all match. CTA rect runs
  full gutter width in both themes.
- Bottom edge: CTA surface runs to the physical edge in light (white) and
  dark (dark surface) — no coloured strip around the home indicator.
  OWNER BOTTOM EDGE rule ✓.
- Gutters/alignment: scroll, option cards, settings card, CTA all share the
  same 20 px side edges; nothing visibly off by a few px.
- Dark mode: paper/surface/line/ink, selected-option deep-green tint,
  selected-Sat pill, coin tile, CTA mint/black-text button all match the
  dark PNG.
- `google_fonts`/`GoogleFonts`: absent (grep clean).
- Read-only code grep: day row already uses `NestChipWrap` (CHIP ROWS ruling
  followed); H1 is plain `Text`, not `NestBalancedText` — see deviation 6
  (no visible effect: line breaks match the design exactly).

## Numbered deviations (element, design value, app value, fix)

1. Status bar time/icons — design: `9:41` + mock signal/wifi/battery;
   app: real OS time + real icons. Fix: none. `NestStatusBar` reserves height
   only; orchestrator STATUS BAR rule says to ignore status-bar differences.
   Band 0 diff (~1.6%) is this only.
2. Day-chip glyph size — design: 13 px centred labels filling the ~45.7 px
   cells; app: `NestChip` (14 px label + `0 14px` padding) in a 44-tall tap
   box via `FittedBox(scaleDown)`, rendered glyphs ~10–11 px (visibly
   smaller, outside ±2 px). Pill/border rects, order, selection, tap size
   (44), gaps, colours all correct; only glyph scale drifts. Fix (shared, not
   screen scope): optional `labelStyle` override on the shared chip
   (SPACING_SPEC conflict #6, pre-flagged in `1_plan.md` §7 as a follow-up
   `SHARED_REQUEST` candidate — do not fork the component). Screen used the
   correct component correctly; text stays legible, single-line, centred, no
   overflow. Not designer-rejectable at screen scope.
3. Coin-tile glyph — design/HTML: `assets/coin.svg` gold coin;
   app: `NestIcon(NestIcons.poundCoin)` in the same 40×40 radius-16 coinTint
   tile. Fix: none. Token-correct design-system equivalent; size, tile,
   colour, position match; not designer-rejectable.
4. Bottom strip / home indicator — design: paper/cream strip under the CTA
   with a home pill on it; app: CTA surface runs to the physical edge in
   light and dark. Fix: none. OWNER BOTTOM EDGE rule overrides the designs;
   the app is correct and the design is stale here. Band 7 diff (~2.3%) is
   this intentional override plus the live home indicator.
5. Text/stepper-edge heat (bands 4–6, 3–6%) — design vs app glyph
   rasterization after the compare's 1170→390 LANCZOS rescale, concentrated on
   day chips, stepper circles, amounts and the coin row. No positional, size,
   spacing, or colour deviation underneath; copy and wrapping verified
   identical. Fix: none (compare artifact).
6. H1 widget class (non-visual note, no UI deviation): the BALANCED HEADINGS
   ruling asks for `NestBalancedText` on `.h1`, but the view renders this H1
   with plain `Text`. Visible result matches the design exactly (same 2-line
   break after `money`, no orphan), so there is nothing a designer would
   reject on screen. Flagged for the build stage only; no fix at this stage
   (do not edit code here).

No other spacing drift: H1→options 16, option gap 8, options→settings 16,
`Payout day` label→chips 6, dividers vertical 8, CTA caption→button 8 all match
the HTML/`SPACING_SPEC` within ±2 px. No misalignment, no clipping, no
ellipsis failures, no hard-coded colours/sizes, no `google_fonts`.

VERDICT: PASS
