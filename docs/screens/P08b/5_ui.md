# P08b · Today empty — Stage 5 UI check (iteration 3)

Route `/today-empty` · parent · seed `new_family` (per SCREENS.tsv + ORCHESTRATOR_NOTES item 8, which override the stage brief's `empty`) · child `maya` · simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB.
Worktree contains `Seed.newFamily` and `/today-empty` in the Today `StatefulShellBranch`; tab bar renders with Today active in both shots.

Shots: `docs/screens/P08b/ui/app_light_3.png`, `app_dark_3.png` (1170×2532; absolute out-paths — relative `OUT` breaks because `shot.sh` `cd`s into `app/` before `cp`).
Compares: `cmp_light_3.png`, `cmp_dark_3.png`.

## Mean diff

- Light: **1.44%** (bands: 0–105: 2.94 · 105–211: 1.31 · 211–316: 3.66 · 316–422: 0.24 · 422–527: 0.59 · 527–633: 0.19 · 633–738: 0.09 · 738–844: 2.50)
- Dark: **1.26%** (bands: 0–105: 2.97 · 105–211: 0.73 · 211–316: 2.77 · 316–422: 0.24 · 422–527: 0.53 · 527–633: 0.16 · 633–738: 0.09 · 738–844: 2.61)

Unchanged from iteration 2 (1.44% / 1.26%, identical band profile) — iteration-3 build + main merge introduced no visual regression. All geometry measured in logical px (pixels ÷ 3), light and dark identical unless noted.

## Measured positions (design → app)

| Element | Design | App | Δ |
|---|---|---|---|
| Screen title top ("Good morning, Sarah") | 53.0 | 53.0 | 0 |
| Empty-card top | 121.0 | 121.0 | 0 |
| "Add a quest" button rect | y 423–475, h 52, x 40–350 | y 423–475, h 52, x 40–350 | 0, shape exact |
| Tab-bar top | 727.0 | 727.0 | 0 |

(Iteration 2 additionally verified h2 top 302.0→302.3 and tip top 555.7→555.7; layout untouched since, and the iteration-3 heat maps show no new displacement.)

## Deviations

None. No numbered deviations: every element is within ±2 px of the design position, copy is byte-exact, and colours match in both themes.

## Checked and passing

- Presence/order: greeting (no `+`, no avatar) → empty card (140 px Pip slot, h2, message, 8 px spacer, 52 px primary button, 44 px link row) → inset tip → tab bar (Today active leaf). No overflow, clipping, or ellipsis.
- Copy byte-exact vs HTML source: `Good morning, Sarah` (real-clock morning, DB parent name); date suffix `A fresh nest`; `Your nest is quiet`; two-sentence message with `Maya and Leo` in creation order; tip title/body with curly quotes, em dash (`each — "Make`), en dash (`Reading – 20 minutes`); `Add a quest`; `Browse ideas` with sky underline (pixel-verified in iteration 2, visually confirmed here).
- Button/card/tip shapes: background/border rects measured — all exact; r-24 cards, pill button, leaf fill with white (light) / dark (dark) label, inset tip with no shadow.
- Bottom edge (owner rule): tab-bar surface runs to the physical edge in both themes. The design PNG's cream strip + home pill predates the rule — the app correctly follows the rule. Compliant.
- Dark mode: geometry identical to light; dark tokens correct throughout. No dark-only deviation.
- Alignment: consistent 20 px gutters, cards and tab bar on the same edges.

## Residual heat — all excludable, none a P08b deviation

- Status-bar band (~3%): OS-drawn time/glyphs — ignored per STATUS BAR rule.
- Date day-part (`Mon 5 Oct` vs `Sat 4 Oct`): DB-driven via `Seed.anchorDay` — excluded per DATA OVER MOCKS / UI VERDICT RULE.
- Pip art (band 2, ~3%): v1 egg SVG vs `PipAvatar` mochi·sunny stage 1 — MANDATED by the PIP orchestrator rule; slot size/position match.
- Money tab glyph (band 7 marker): design credit-card vs shared `NestIcons.money` banknote, identical on every parent screen — shared chrome, not a P08b finding (this stage may not touch `core/`).
- "Browse ideas" sub-pixel edge: ≤1 px, inside the ±2 px rule.

No code edited (read-only inspection plus `shot.sh`/`compare.py` outputs). `ui/` iteration-3 files added alongside prior iterations' PNGs; no other files touched.

VERDICT: PASS
