# P08b · Today empty — Stage 5 UI check (iteration 2)

Route `/today-empty` · parent · seed `new_family` (per SCREENS.tsv + ORCHESTRATOR_NOTES item 8, which override the stage brief's `empty`) · child `maya` · simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB.
Worktree contains `Seed.newFamily` and `/today-empty` in the Today `StatefulShellBranch`; tab bar renders with Today active in both shots.

Shots: `docs/screens/P08b/ui/app_light_2.png`, `app_dark_2.png` (1170×2532; absolute out-paths — relative `OUT` breaks because `shot.sh` `cd`s into `app/` before `cp`).
Compares: `cmp_light_2.png`, `cmp_dark_2.png`.

## Mean diff

- Light: **1.44%** (was 5.81% in iteration 1; bands: 0–105: 2.92 · 105–211: 1.31 · 211–316: 3.66 · 316–422: 0.24 · 422–527: 0.59 · 527–633: 0.19 · 633–738: 0.09 · 738–844: 2.50)
- Dark: **1.26%** (was 5.51%; bands: 0–105: 2.99 · 105–211: 0.73 · 211–316: 2.77 · 316–422: 0.24 · 422–527: 0.53 · 527–633: 0.16 · 633–738: 0.09 · 738–844: 2.61)

All geometry measured in logical px (pixels ÷ 3), light and dark identical unless noted.

## Measured positions (design → app)

| Element | Design | App | Δ |
|---|---|---|---|
| Screen title top ("Good morning, Sarah") | 53.0 | 53.0 | 0 |
| Empty-card top | 121.0 | 121.0 | 0 |
| "Add a quest" button rect | y 423–475, h 52, x 40–350 | y 423–475, h 52, x 40–350 | 0, shape exact |
| "Your nest is quiet" (h2) top | 302.0 | 302.3 | +0.3 |
| Tip card top | 555.7 | 555.7 | 0 |
| Tab-bar top | 727.0 | 727.0 | 0 |
| Card gutters | x 20–370 | x 20–370 | 0, aligned |

## Iteration-1 findings — all resolved

1. Date-line suffix: app now shows `· A fresh nest` (day-part `Mon 5 Oct` is DB-driven — seed anchored to today — and excluded). FIXED.
2. Vertical shift: title/card/button/h2/tip/tab-bar all within ±0.3 px of the design (was a uniform +8). FIXED.
3. "Browse ideas" underline: pixel scan shows the underline row is now sky-blue with zero dark pixels (was ink `(16,16,48)`); text rows sky in both. FIXED (≤1 px antialiasing-level offset on the link row remains, inside tolerance).

## Checked and passing

- Presence/order: greeting (no `+`, no avatar) → empty card (140 px art, h2, message, 8 px spacer, 52 px primary button, 44 px link row) → inset tip → tab bar (Today active leaf). No overflow, clipping, or ellipsis.
- Copy byte-exact vs HTML source: `Your nest is quiet`; two-sentence message with `Maya and Leo` in creation order; tip title/body with curly quotes, em dash (`each — "Make`), en dash (`Reading – 20 minutes`); `Add a quest`; `Browse ideas`; greeting `Good morning, Sarah` (real-clock morning, DB parent name).
- Button/card/tip shapes: background/border rects measured, not just text — all exact (table above); r-24 cards, pill button, leaf fill with white (light) / dark (dark) label, inset tip with no shadow.
- Bottom edge (owner rule): tab-bar surface runs to the physical edge (light `#FFFFFF` sampled y 815–843; dark likewise surface). The design PNG's cream strip + home pill predates the rule — the app correctly follows the rule. Compliant.
- Dark mode: geometry identical to light; dark tokens correct throughout (card surface, paper bg, leaf button with dark label, sky link, ink-2 body). No dark-only deviation.
- Alignment: consistent 20 px gutters, cards and tab bar on the same edges.

## Residual heat — all excludable, none a P08b deviation

- Status-bar band (0–105, ~3%): OS-drawn time/glyphs (`05:01/05:02` vs `9:41`) — ignored per STATUS BAR rule.
- Date day-part (`Mon 5 Oct` vs `Sat 4 Oct`): DB-driven via `Seed.anchorDay` — excluded per DATA OVER MOCKS / UI VERDICT RULE.
- Pip art (band 2, ~3%): v1 egg SVG vs `PipAvatar` mochi·sunny stage 1 — MANDATED by the PIP orchestrator rule; size/position of the slot match (140 px art, card geometry exact).
- Money tab glyph (band 7 marker): design credit-card vs shared `NestIcons.money` banknote (`nestling_assets.dart:69`), identical on every parent screen — shared chrome, not a P08b finding (this stage may not touch `core/`).
- Home-indicator strip: covered under bottom-edge compliance above.
- "Browse ideas" sub-pixel edge: ≤1 px, inside the ±2 px rule.

No code edited (read-only inspection plus `shot.sh`/`compare.py` outputs). `ui/` contains only the four iteration-2 PNGs.

VERDICT: PASS
