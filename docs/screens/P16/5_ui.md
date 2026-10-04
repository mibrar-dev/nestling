# P16 Settings — 5_ui (iteration 2)

Route `/settings` · parent mode · child maya · seed demo · simulator 604697A9-11DA-462F-9837-396E9CA2493A (390×844).
Shots: `docs/screens/P16/ui/app_light_2.png`, `app_dark_2.png` (absolute OUT path — relative fails because `shot.sh` cds into `app/` before copying).
Compares: `cmp_light_2.png`, `cmp_dark_2.png`.

Mean diff: light **1.15%** (was 3.58%), dark **0.97%** (was 3.32%).

Band table (light): 0–105: 1.77 · 105–211: 0.27 · 211–316: 0.24 · 316–422: 0.33 · 422–527: 0.18 · 527–633: 0.48 · 633–738: 1.90 · 738–844: 4.00.
Band table (dark): 0–105: 1.71 · 105–211: 0.27 · 211–316: 0.24 · 316–422: 0.33 · 422–527: 0.18 · 527–633: 0.49 · 633–738: 1.73 · 738–844: 2.77.
(Band 0 = real OS status bar 04:56/04:57 vs design 9:41 — ignored per STATUS BAR rule. Band 7 = shared tab-bar chrome + OS home area — see §4.)

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
| Subcard title / "Manage subscription" text | 611.3–624.7 / 666.0–679.7 | 611.3–624.7 / 667.0–680.7 | 0 / +1 |
| Subcard bottom edge | 710.7 | 712.7 | +2.0 |
| Tab bar top | 727.0 | 727.0 | 0 |

## Iteration-1 deviations — all fixed

1. Truncation FIXED: "Pip: Fledgling · 120 coins", "Pip: Hatchling · 45 coins", "Nickname + age band only" render in full in both themes; chevrons sit at the right edge (x≈352) as designed.
2. Vertical drift FIXED: children card +4.0 → +0.3, subcard top +6.0 → 0, labels exact.
3. Family card top +2.0 → 0.

## Remaining notes (none designer-rejectable)

1. (Minor, P16-owned, at tolerance boundary) Subcard bottom edge +2.0 px (710.7 → 712.7, unanimous over 32 sampled columns); interior text matches to ≤1 px, card top exact. Invisible in side-by-side inspection; within the ±2 px rule. Likely title/subtitle line-box rounding (20/18 vs browser natural); left for the shared label follow-up in `SHARED_REQUEST.md` §2.
2. (Shared shell, orchestrator-owned, carried from iteration 1) Money tab icon glyph differs from the design (banknote vs wallet). `SHARED_REQUEST.md` "worth attention" bullet; P16 cannot edit shell chrome per RULES §1.
3. Bottom edge complies with the OWNER RULE in both themes (bar surface sampled to y=841.7, no strip), overriding the design's paper strip.

## What matches

Copy char-exact (—, –, ·, &, ›, £); child order Maya then Leo; section order; avatar colours (S leaf, J sky, M lilac, L peach); plus tiles; leaf-tint Invite tile; green "Manage subscription"; 20 px gutters; cards/bars edge-aligned; Family tab active; dark-mode tokens; no unwanted ellipsis/overflow/clipping; radii and shadows per spec (subcard r-m per `SHARED_REQUEST.md` §3).

VERDICT: PASS
