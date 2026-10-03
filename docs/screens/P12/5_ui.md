# P12 · Money (ledger) — Stage 5 UI check (iteration 2)

Route `/money`, simulator BC440E48-B3A3-43BC-971B-0EF5DB621874 (390×844).
No code edited in this stage.

## Captures

- `bash tools/screens/shot.sh $PWD/app /money $PWD/docs/screens/P12/ui/app_light_2.png BC440E48-B3A3-43BC-971B-0EF5DB621874 light demo parent maya` → stable frame saved.
- Same with `dark` → `app_dark_2.png`.
- (Repeat of the iteration-1 finding: the brief's relative `docs/screens/P12/ui/…` OUT path fails because `shot.sh` `cd`s into `$APP_DIR` before copying, so absolute `$PWD/…` OUT paths were used. Shared script left untouched.)
- `python3 tools/screens/compare.py design/screens/light/P12-money.png docs/screens/P12/ui/app_light_2.png docs/screens/P12/ui/cmp_light_2.png`
- `python3 tools/screens/compare.py design/screens/dark/P12-money.png docs/screens/P12/ui/app_dark_2.png docs/screens/P12/ui/cmp_dark_2.png`

## Mean diff

- Light: **1.92%** (bands: 0: 1.69, 1: 0.48, 2: 2.98, 3: 0.44, 4: 0.20, 5: 3.50, 6: 3.57, 7: 2.51)
- Dark: **1.90%** (bands: 0: 1.66, 1: 0.56, 2: 2.77, 3: 0.35, 4: 0.18, 5: 3.51, 6: 3.60, 7: 2.60)

Residual diff is status bar (ignored), DB-driven rows/date (accepted), and sub-glyph/antialias rendering. Compare PNGs read at full resolution alongside both app screenshots and both design PNGs.

## Measured positions — UI VERDICT RULE (±2 px)

Method: both PNGs normalised to 390×844 (same as `compare.py`), then row-profile edge detection on background transitions (paper/surface-2/hero fills), identical thresholds for design and app. Title/first-control/card-top table (logical px, y = top edge, x = left edge):

| element | light design | light app | Δ | dark design | dark app | Δ |
|---|---|---|---|---|---|---|
| screen title `Pocket money` top | 62 | 62 | 0 | 62 | 62 | 0 |
| first control (segmented) top | 105 | 105 | 0 | 105 | 105 | 0 |
| hero card top | 172 | 172 | 0 | 173 | 173 | 0 |
| goal card top | 401 | 401 | 0 | 400 | 400 | 0 |
| history card top | 504 | 505 | +1 | 504 | 504 | 0 |
| hero left x | 20 | 20 | 0 | 20 | 20 | 0 |
| goal left x | 20 | 20 | 0 | 20 | 20 | 0 |

No uniform vertical shift: every anchor matches within ±1 px. Two raw readings above ±2 were investigated and are NOT layout shifts: (a) light hero-bottom paper-threshold crossing 393 vs 399 is the soft `sh-2` shadow falloff crossing an arbitrary threshold — the goal-top anchor (401/401) and the near-zero band-3 diff (0.44%) prove the card ends in the same place; (b) tab-bar bottom 809 vs 843 is the OWNER bottom-edge rule — the design's paper strip + home pill vs the app correctly running bar surface to the physical edge. A 4 px-step full-hero profile (rows 173–397) is identical design-vs-app in both themes, including payout-button top (~311) and bottom (~363).

## Element-by-element

Against `design/html-source/screens/P12-money.html`: title, segmented Maya|Leo (Maya selected), hero (`Maya is owed` / `£4.20` with −0.4 tracking / breakdown / full-width `Payout time`), goal card (coin art 56, `Lego Friends set — £24.99` with em dash U+2014, `£15.50 saved · 62%` with U+00B7, 62% progress), history header + rows (40×40 tiles r12, gap 12, min-h 56, no dividers, ellipsis, per-type icon/tint/sign), tab bar with Money active, 20 px gutters everywhere, radii/shadows/dark tokens all match. Row buttons + footer caption sit below the fold in BOTH design and app (identical fold: history bottom 724/724); covered by the 12 passing widget tests.

## Numbered deviations

1. Status bar — design mock `9:41` vs OS `12:58`/`12:59` + real icons. Design value: mock glyphs; app value: OS bar. Fix: none — ignored per STATUS BAR rule.
2. Hero breakdown payout date — design `Next payout Sat 4 Oct`; app `Next payout Sat 3 Oct`. Fix: none — DATA OVER MOCKS, seed story day Sat 3 Oct 2026 (`1_plan.md` §a).
3. History rows — design `Paid · Sat 27 Sep / £3.80`, `Quest bonus · Put the bins out / +£0.12`, `Birthday money (added by Mum) / +£10.00`, `Spent · Comic / −£2.00`; app `Weekly pocket money / Sat 3 Oct / +£3.00`, `Quest bonus · Put the bin… / +£0.12`, `Quest bonus · Hoover th… / +£0.40` (DB newest-first). Fix: none — DATA OVER MOCKS, accepted by `1_plan.md` §a. Visible row geometry (tiles, gaps, trailing amounts, ellipsis, `+12p · Approved` subs) matches the per-type spec.
4. Breakdown glyph rows (~265–277, band 2 ≈ 2.8–3.0%) — same copy, HTML-vs-Flutter text rasterisation differs by a pixel in the amount/breakdown line box. Fix: none — line tops within tolerance, invisible to a designer (no red edge in heat map, button/card anchors exact).
5. Tab-bar bottom / home area — design paper strip + pill; app bar surface to edge in both themes. Fix: none — OWNER BOTTOM-EDGE rule overrides the designs; compliant.
6. Alignment — all cards/bars share x 20…370 in both themes, nothing off. Fix: none.

Note: iteration 1 (10.46%/8.22%) showed a uniform shift that is gone in iteration 2 after the loop's main-merge; per PROCESS ITEMS this is loop-handled, not a finding.

VERDICT: PASS
