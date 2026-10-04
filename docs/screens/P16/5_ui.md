# P16 Settings — 5_ui (iteration 1)

Route `/settings` · parent mode · child maya · seed demo · simulator 604697A9-11DA-462F-9837-396E9CA2493A (390×844).
Shots: `docs/screens/P16/ui/app_light_1.png`, `app_dark_1.png` (absolute OUT path — relative path fails because `shot.sh` cds into `app/` before copying).
Compares: `cmp_light_1.png`, `cmp_dark_1.png`.

Mean diff: light **3.58%**, dark **3.32%**.

Band table (light): 0–105: 1.75 · 105–211: 2.19 · 211–316: 3.86 · 316–422: 3.00 · 422–527: 3.37 · 527–633: 5.95 · 633–738: 4.53 · 738–844: 4.00.
Band table (dark): 0–105: 1.73 · 105–211: 2.17 · 211–316: 3.81 · 316–422: 2.94 · 422–527: 3.26 · 527–633: 5.82 · 633–738: 4.04 · 738–844: 2.77.
(Status-bar band diff is the real OS clock 02:08/02:09 vs design 9:41 — ignored per STATUS BAR rule.)

## Measured Y (logical px, design light vs app light, same script on both)

| Element | Design | App | Δ |
|---|---|---|---|
| Title text top ("Family & settings") | 60.3 | 60.3 | 0 |
| Title text bottom | 86.0 | 85.7 | −0.3 |
| FAMILY label | 116.7–125.7 | 117.7–126.7 | +1.0 |
| Family card top | 137.0 | 139.0 | +2.0 |
| First control title ("Sarah — you") | 152.3–166.3 | 154.3–169.3 | +2.0/+3.0 |
| CHILDREN label | 344.7–353.7 | 347.7–356.7 | +3.0 |
| Children card top | 365.0 | 369.0 | +4.0 |
| SUBSCRIPTION label | 572.3–581.7 | 577.7–586.7 | +5.3 |
| Subcard top | 593.0 | 599.0 | +6.0 |
| Tab bar top | 727.0 | 727.0 | 0 |

Drift grows ~+1–2 px per section below the title. Time-zone section and move banner are correctly absent from the visible viewport (zone = London, no pending move).

## Deviations (P16-owned)

1. Chevron rows truncate subtitles + park chevron mid-card (light + dark). Design: "Pip: Fledgling · 120 coins", "Pip: Hatchling · 45 coins", "Nickname + age band only" in full, chevron glyph at x≈352 (16 px from card right edge). App: "Pip: Fledgling · 120 …", "Pip: Hatchling · 45 …", "Nickname + age b…", chevron at x≈225. Rows without trailing (Sarah, James) are full-width and match design exactly, so the trailing widget is over-wide. Fix: audit `settingsChevron()` intrinsic width and the `SettingsRow`/`NestListRow` main-axis constraints — the text column must flex to fill like the chevron-less rows. Values are identical to the design (120/45 coins from DB), so this is layout, not DATA-OVER-MOCKS.
2. Progressive vertical drift exceeds ±2 px (UI VERDICT RULE). Children card top +4.0, subcard top +6.0, CHILDREN label +3.0, SUBSCRIPTION label +5.3, first-row title bottom +3.0. Fix: audit section rhythm — `NestSectionLabel` box height/line-height vs design 13 px caps, the 24/8 gaps, and row heights — until card tops read 137 / 365 / 593.
3. Family card top +2.0 (boundary of ±2 px tolerance; listed so the next iteration re-measures it after fixing 2).

## Shared observations (not P16-editable, for orchestrator)

4. Money tab icon differs: design = wallet/card glyph (rounded rect, top stripe, short dash); app = banknote glyph (rect, centre circle + side dots). Tab bar is shared shell code — needs a shell-side icon swap if the design is authoritative.
5. Bottom edge complies with the OWNER RULE (overrides design): below the tab bar the app extends the bar surface to the physical edge (white light / #1F1C2E dark, sampled to y=841.7), while the design PNGs show a paper strip + pill. No coloured strip under the bar in either theme.

## What matches

Copy char-exact (—, –, ·, &, ›, £, .co.uk); child order Maya then Leo; avatar colours (S leaf, J sky, M lilac, L peach); plus tiles; leaf-tint Invite tile; green "Manage subscription"; section order; side gutters 20; Family tab active; dark-mode surfaces/text; no Pip on screen (avatars only — PIP rule N/A).

VERDICT: FAIL
