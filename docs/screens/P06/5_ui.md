# P06 Pocket money setup — UI check (Stage 5, iteration 5)

Route `/pocket-money-setup` · feature `pocket_money` · parent mode ·
seed `onboarding_kids` · child `maya` (populated: Maya £3.00, Leo £1.50).
Simulator UDID `BC440E48-B3A3-43BC-971B-0EF5DB621874` (390×844, same as designs).
No Pip on this screen (P01–P07 onboarding rule). No `ORCHESTRATOR_NOTES.md` exists.

## Shots (per stage)

- `bash tools/screens/shot.sh "$PWD/app" /pocket-money-setup "$PWD/docs/screens/P06/ui/app_light_5.png" BC440E48-B3A3-43BC-971B-0EF5DB621874 light onboarding_kids parent maya` → stable frame saved.
- Same with `dark` → `docs/screens/P06/ui/app_dark_5.png`.
  (Absolute `OUT` paths: `shot.sh` `cd`s into the app dir before copying, so a
  relative `OUT` resolves inside `app/` and the copy fails.)

## Compares

- `python3 tools/screens/compare.py design/screens/light/P06-pocket-money.png docs/screens/P06/ui/app_light_5.png docs/screens/P06/ui/cmp_light_5.png`
- `python3 tools/screens/compare.py design/screens/dark/P06-pocket-money.png docs/screens/P06/ui/app_dark_5.png docs/screens/P06/ui/cmp_dark_5.png`

Mean diff: light **6.11%**, dark **6.08%** (up from 2.22%/2.14% in iteration 4).

Band tables (8 horizontal bands, 0 = top):

Light:

```text
mean diff: 6.11%
band  y-range    diff%
  0      0-105    1.62%
  1    105-211    8.71%
  2    211-316   10.47%
  3    316-422   10.32%
  4    422-527    7.49%
  5    527-633    5.28%
  6    633-738    2.76%
  7    738-844    2.25%
```

Dark:

```text
mean diff: 6.08%
band  y-range    diff%
  0      0-105    1.59%
  1    105-211    8.81%
  2    211-316    9.87%
  3    316-422   10.99%
  4    422-527    6.61%
  5    527-633    5.18%
  6    633-738    3.21%
  7    738-844    2.38%
```

Read `docs/screens/P06/ui/cmp_light_5.png`, `cmp_dark_5.png`,
`app_light_5.png`, `app_dark_5.png` against
`design/screens/light|dark/P06-pocket-money.png` and
`design/html-source/screens/P06-pocket-money.html`. Bands 1–4 heat is dominated
by deviation 1 (H1 collapse shifts every row below it).

## Element-by-element (design vs app, light + dark unless noted)

Checked: presence, order, copy (character-by-character vs HTML source),
spacing (±2 px logical), sizes, 20 px gutters / alignment, colours, radii,
shadows, icon choice, overflow/clipping/ellipsis, dark-mode colours, bottom
edge, status-bar rule. Pill/chip/button/card BACKGROUND/BORDER rects compared,
not just text.

- H1: design shows 2-line `How does pocket money / work in your house?`;
  app shows 1-line `How does pocket mone...` + ellipsis in BOTH themes.
  FAIL — see deviation 1.
- Option cards ×3: presence, order, copy, selected `Both` state, colours,
  radii, shadows all match; rects sit ~one line-height higher than design as a
  consequence of deviation 1 (not an independent defect).
- Settings card: structure, 16/16/12 insets, full-bleed dividers, radius 24
  match; vertical position shifted up (consequence of deviation 1).
- `Payout day` chips `Mon…Sun`, `Sat` selected: order, labels, selection,
  pill rects, 44-tall tap boxes, 6 px gaps all correct. Glyph size differs —
  see deviation 3.
- `Weekly base` rows: `M` lilac + `Maya` + `− £3.00 +`, `L` peach + `Leo` +
  `− £1.50 +`, Maya-then-Leo order (CHILD ORDER ✓), amounts match seeded DB
  (DATA OVER MOCKS ✓). Copy exact incl. `£`.
- `Coin value` row: `40×40` coinTint tile + `Coin value` + `10 coins = 10p`,
  copy exact, no overflow. Glyph differs — see deviation 4.
- Caption + `Continue`: copy exact, centred 2-line caption, 52-high pill CTA,
  dense 14 px vertical padding all match.
- Bottom edge: CTA surface runs to the physical edge in light and dark — no
  coloured strip. OWNER BOTTOM EDGE rule ✓.
- Gutters/alignment: 20 px side edges consistent; ignoring the deviation-1
  vertical shift, nothing is a few px off horizontally.
- Dark mode colours: selected-option deep-green tint, Sat pill, coin tile,
  CTA mint/black-text all match the dark PNG.
- `google_fonts`/`GoogleFonts`: absent.

## Numbered deviations (element, design value, app value, fix)

1. H1 truncated to one line (BLOCKER — designer-rejectable) — design: 2-line
   heading `How does pocket money` / `work in your house?`; app (both
   themes): single line `How does pocket mone...` with ellipsis, cutting off
   the screen title and pulling every row below it ~one line-height up
   (this is what inflates bands 1–4 to 7–11%). Read-only pointer for the
   bugs stage (code NOT edited here): `_SetupTitle`
   (`app/lib/features/pocket_money/presentation/views/pocket_money_setup_view.dart:136-149`)
   now renders the copy through `NestBalancedText` with no `maxLines`, where
   iteration 4 rendered plain 2-line `Text`; suspect the shared balanced-text
   default/algorithm constraining to one line. Fix: make the H1 wrap to the
   design's 2-line balanced break (e.g. `maxLines: 2`, no ellipsis) in the
   feature view and/or fix `NestBalancedText` via SHARED_REQUEST if the
   default is shared-owned.
2. Status bar time/icons — design `9:41` + mocks; app real OS time/icons.
   Fix: none (STATUS BAR rule: ignore; band 0 ~1.6% is this only).
3. Day-chip glyph size — design 13 px labels filling ~45.7 px cells; app
   `NestChip` (14 px + padding) via `FittedBox(scaleDown)` renders ~10–11 px.
   Pill/border rects, order, selection, 44 tap targets, gaps, colours correct.
   Fix (shared): optional `labelStyle` override (SPACING_SPEC conflict #6,
   pre-flagged in `1_plan.md` §7 — do not fork the component). Not
   designer-rejectable at screen scope.
4. Coin-tile glyph — design `assets/coin.svg`; app `NestIcons.poundCoin` in
   the same 40×40 radius-16 coinTint tile. Fix: none (token equivalent).
5. Bottom strip / home indicator — design shows a paper/cream strip under the
   CTA; app runs CTA surface to the edge in both themes. Fix: none (OWNER
   BOTTOM EDGE override; app is correct).
6. Text/stepper-edge heat — glyph rasterization after 1170→390 LANCZOS
   rescale; no positional/colour deviation underneath. Fix: none (artifact).

Copy is otherwise character-exact vs the HTML source (ASCII + `£` only);
no misalignment, no clipping, no ellipsis failures outside deviation 1.

VERDICT: FAIL
