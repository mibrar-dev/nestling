# P16 Settings — 5_ui (iteration 4)

Route `/settings` · parent mode · child maya · seed demo · simulator 604697A9-11DA-462F-9837-396E9CA2493A (390×844).
Shots: `docs/screens/P16/ui/app_light_4.png`, `app_dark_4.png` (absolute OUT path — relative fails because `shot.sh` cds into `app/` before copying).
Compares: `cmp_light_4.png`, `cmp_dark_4.png`.

Mean diff: light **1.06%**, dark **0.98%** (iteration 3: 1.06% / 0.98% — stable).

Band table (light): 0–105: 1.74 · 105–211: 0.27 · 211–316: 0.24 · 316–422: 0.33 · 422–527: 0.18 · 527–633: 0.48 · 633–738: 1.90 · 738–844: 3.33.
Band table (dark): 0–105: 1.72 · 105–211: 0.27 · 211–316: 0.24 · 316–422: 0.33 · 422–527: 0.18 · 527–633: 0.49 · 633–738: 1.73 · 738–844: 2.89.
(Band 0 = real OS status bar 08:22/08:23 vs design 9:41 — ignored per STATUS BAR rule. Band 7 = shared tab-bar chrome + OS home area — see §3.)

## Measured Y (logical px, design light vs app light, same script on both)

| Element | Design | App | Δ |
|---|---|---|---|
| Screen title text ("Family & settings") | 60.3–86.0 | 60.3–85.7 | 0 |
| FAMILY label | 116.7–125.7 | 116.7–125.7 | 0 |
| Family card top | 137.0 | 137.0 | 0 |
| First control title ("Sarah — you") | 152.3–166.3 | 152.3–167.3 | 0/+1 |
| CHILDREN label | 344.7–353.7 | 344.7–353.7 | 0 |
| Children card top | 365.0 | 365.0 | 0 |
| SUBSCRIPTION label | 572.3–581.7 | 572.7–581.7 | 0 |
| Subcard top | 593.0 | 593.0 | 0 |
| Subcard bottom edge | 710.7 | 712.7 | +2.0 |
| Tab bar top | 727.0 | 727.0 | 0 |

## Deviations

1. (Minor, P16-owned, at tolerance boundary, unchanged since iteration 2) Subcard bottom edge +2.0 px (710.7 → 712.7, unanimous over 32 sampled columns); subcard top exact, interior text within ≤1 px. Invisible in side-by-side inspection; within the ±2 px rule. Suspected title/subtitle line-box rounding; tracked via the shared label follow-up in `SHARED_REQUEST.md` §2.
2. No other deviations: full subtitles in both themes ("Pip: Fledgling · 120 coins", "Pip: Hatchling · 45 coins", "Nickname + age band only"), chevrons at the right edge (x≈352), copy char-exact (—, –, ·, &, ›, £), child order Maya then Leo, avatar colours, plus tiles, green "Manage subscription", 20 px gutters, edge-aligned cards/bars, Family tab active, dark-mode tokens correct, no unwanted ellipsis/overflow/clipping, radii and shadows per spec.

## Shared observations (not P16-editable, for orchestrator)

3. Money tab icon glyph differs from the design (banknote vs wallet) — shared shell chrome, carried from iterations 1–3; P16 cannot edit per RULES §1.
4. Bottom edge complies with the OWNER RULE in both themes (bar surface runs to the physical edge, no strip), overriding the design's paper strip.

VERDICT: PASS
