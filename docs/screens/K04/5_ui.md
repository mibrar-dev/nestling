# K04 Quest detail — Stage 5 UI check (iteration 2)

Simulator: BC440E48-B3A3-43BC-971B-0EF5DB621874 (390×844). Route `/quest-detail`, seed `demo`, mode `kid`, child `maya`.
Shots: `bash tools/screens/shot.sh "$PWD/app" /quest-detail "$PWD/docs/screens/K04/ui/app_light_2.png" BC440E48-B3A3-43BC-971B-0EF5DB621874 light demo kid maya` (same `dark` → `app_dark_2.png`).
Compares: `python3 tools/screens/compare.py design/screens/light/K04-quest-detail.png docs/screens/K04/ui/app_light_2.png docs/screens/K04/ui/cmp_light_2.png` (and dark). Both captures rendered fully first try.

## Mean diff + bands (390×844 normalized)

Light — mean diff: 1.81%. Bands: 0 (0–105) 1.53 · 1 (105–211) 2.23 · 2 (211–316) 0.37 · 3 (316–422) 1.56 · 4 (422–527) 1.58 · 5 (527–633) 1.05 · 6 (633–738) 0.56 · 7 (738–844) 5.56.
Dark — mean diff: 1.52%. Bands: 0: 1.58 · 1: 2.15 · 2: 0.39 · 3: 1.23 · 4: 1.22 · 5: 0.85 · 6: 0.45 · 7: 4.30.
Band 7 = mandated bottom-edge override (surface vs design meadow strip) + home pill; band 1 = hero glyph strokes + unticked dots; band 0 = status-bar glyphs (ignored).

## Measured y positions (logical px, design vs app, edge-scan on 390×844 panels)

| Element | Light design | Light app | Dark design | Dark app |
|---|---|---|---|---|
| Icon tile top border | 109 | 109 | 109 | 109 |
| Title "Tidy your bedroom" top | 245 | 245 | 245 | 245 |
| Steps card top border | 350 | 350 | 350 | 350 |
| Bottom-bar top border | 634 | 634 | 634 | 634 |
| "I did it!" button top | 647 | 647 | 647 | 647 |

No uniform vertical shift; every pinned edge ±0 px (tolerance ±2 px). First control (back chevron) unchanged from iteration 1 (66/66 light).

## Element-by-element (light + dark)

Presence/order/copy/sizes/alignment/colours/radii/shadows/overflow all match: back + lock 56, 120×120 tile, title, +15 pill, hint, 3-step card (rows min-h 60, 2 px dividers, 40 px dots), Pip 64 + bubble (tail at bar), "I did it!" + "Back" full-width min-h 64, 20 px gutters everywhere, bar surface to y 844, dark tokens correct. Copy char-for-char vs HTML: all strings match (all ASCII on this screen).

## Numbered deviations (element, design value, app value, fix)

1. (MAJOR, verdict-driving) Hero tile icon — design value: bed with headboard post, pillow bump, long base and legs (K04 HTML tile paths `M2 18v-7 / M2 14h20v4 / …h-9v3 / M6 11V8h4v3`). App value: flat arch + baseline (shared `assets/icons/ic_quest_bed.svg`: `M3 18v-8a2…` + `M3 18h18`), which at the 64 px hero size renders as a plain hollow rounded rectangle with no bed cues — unrecognizable as a bed next to the design. This is a REGRESSION vs iteration 1 (bedSit, a recognizable bed). Root cause is not screen code: `quest_detail_view.dart:83-93` correctly implements the mandatory `ORCHESTRATOR_NOTES.md` 14:28 ruling (K04-BUG-3: map `bed`→`NestIcons.questBed`, "from the P09 HTML" — verified, P09 HTML line 30 is exactly this arch glyph). The conflict is P09-picker-glyph ≠ K04-hero-glyph: the batch-5 asset is faithful to P09 but wrong for the 120 px K04 hero. Fix: shared change only — enrich `ic_quest_bed.svg` with pillow/headboard/legs cues, or orchestrator revisits the K04-BUG-3 ruling (e.g. hero uses the K04 tile drawing). Screen agent must file SHARED_REQUEST; no fix exists inside `kid_home/` (and `core/**` is off-limits). A designer comparing this screen would reject the box icon.
2. Step dots 1–2 fill — design: first two green-filled; app: all hollow. ACCEPT, no fix: known deviation per `1_plan.md` §(d), correct runtime behaviour (fresh checklist starts unticked).
3. Pip art — design: v1 `pip-stage-3.svg`; app: `PipAvatar` Maya mochi/sunny/stage 3. ACCEPT: orchestrator PIP RULE override.
4. Bottom edge — design: meadow/dark-green strip under bar; app: bar surface to physical edge. ACCEPT (app correct): OWNER BOTTOM-EDGE RULE; strip would be a must-fail.
5. Status bar time/glyphs — IGNORED per STATUS BAR rule.

VERDICT: FAIL
