# K03 Kid home — UI check (Stage 5, iteration 2)

Method (simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB, 390x844):
- `bash tools/screens/shot.sh "$PWD/app" /kid-home "$PWD/docs/screens/K03/ui/app_light_2.png" <udid> light demo kid maya` -> `docs/screens/K03/ui/app_light_2.png` (1170x2532). Same with `dark` -> `app_dark_2.png`.
- NOTE: absolute OUT paths used (`shot.sh` does `cd "$APP_DIR"`, so a relative OUT resolves under `app/`). Both runs again printed `WARNING — frame never stabilised in 25 s` and exited 1; saved last-capture frames are usable and mutually consistent (light/dark differ only in theme).
- `python3 tools/screens/compare.py design/screens/light/K03-kid-home.png docs/screens/K03/ui/app_light_2.png docs/screens/K03/ui/cmp_light_2.png` (and dark).
- Read: `cmp_light_2.png`, `cmp_dark_2.png`. All numbers logical px (PNG/3), tolerance ±2px.
- Overrides applied: ORCHESTRATOR PIP rule (`PipAvatar`, Maya Mochi/sunny/stage 3 — never v1 SVGs), STATUS BAR rule (ignore status-bar diffs), DATA OVER MOCKS (DB numbers win), `ORCHESTRATOR_NOTES.md` #1 (Pip slot: Pip ≈152 on 260x236 nest, nest top ≈y300) and #2 (4/4-of-6 correct).

Results:
- light mean diff: 15.14% — bands: 0 (0-105) 2.99% · 1 (105-211) 4.84% · 2 (211-316) 10.86% · 3 (316-422) 13.18% · 4 (422-527) 13.20% · 5 (527-633) 24.82% · 6 (633-738) 24.67% · 7 (738-844) 26.52%
- dark mean diff: 13.94% — bands: 0: 3.02% · 1: 4.47% · 2: 8.89% · 3: 9.71% · 4: 12.90% · 5: 23.72% · 6: 21.76% · 7: 26.95%
- Diff rose vs iter1 (11.74%/10.89%) for explained reasons: mandated PipAvatar art swap (bands 2-4), now-fully-visible card-2 content mismatch vs the PNG sample (Hoover/Done vs Reading/+10 — data order, bands 5-6), and the dock/home-strip offset below (band 7).
- Fixed since iter1: green band now present behind progress/cards; hearts stroked + closer (+12, was +30); dock icons correct glyphs + fg both themes; dark glow circle gone (matches PNG); card-1 top within +3px.

Accepted / overridden (NOT defects, excluded from verdict):
- A1 counts: design "3 done today"/"3 of 6 done"/50% vs app "4 done today"/"4 of 6 done"/~66.7% — database is correct (ORCHESTRATOR_NOTES #2, DATA rule).
- A2 card order/content: app 2nd card "Hoover the stairs"/"Done" (approved) vs PNG "Reading – 20 minutes"/"+10" — repo alphabetical order wins per `1_plan.md` §(a) (do NOT re-sort); "Done" chip + green check is the correct approved rendering.
- A3 Pip artwork: v1 SVG chick (hair spikes, green wing tips) vs `PipAvatar` Mochi/sunny/stage-3 (cheek discs, top curl) — MANDATED by the PIP rule; slot size/position kept close.
- A4 status bar: mock "9:41" vs real OS "02:30"/"02:32" — IGNORED per STATUS BAR rule (band 0 ≈3% is this only).
- A5 quest icon tiles `surface2` beige vs per-quest tints (measured light tile design (230,239,254) vs app beige) — SHARED_REQUEST #1, non-blocking.
- A6 card title ≈17/22 vs 18/24 — pre-declared shared token (noted iter1), not locally fixable.

Deviations (design value → app value + fix):
1. Home-indicator strip background wrong (major, both themes). Design: meadow green continues under dock + home area to y843 (light green; dark (30,65,56)) with a 134x5 pill (dark rows 825-829). App: light strip is WHITE (255,255,255 at y835/840) with only a thin mark; dark strip is NAVY ((31,28,46) at y838/842). Fix: extend the meadow/background layer under the bottom chrome — check `KidScope` layering vs Scaffold/dock/`NestHomeIndicator` backgrounds in both themes.
2. Dock sits ~28px too low (major). Dock top border: design y≈719-721 vs app y≈747-749 (light, measured). Card-1 top matches (+3: 560-561 vs 563-564), so ≈25px of excess height sits between card-1 top and dock top. Fix: audit progress→card-1 gap, card-1→card-2 gap (spec `.k3-quests` gap 12 vs base 16), and card internal heights until the dock + home pill land back on design rows.
3. Green band starts ~39px too low (moderate). Left-edge green: design y≈524 (behind the progress bar) vs app y≈563 (just below it). Same fix family as #2 — upper stack still slightly tall (hearts +12 accounts for part of it).
4. Hearts row +12px low (minor; was +30 in iter1). Yellow-heart rows: design y443-452 vs app y455-464. Outside ±2px but much improved. Fix: trim pet-stage bottom padding toward the orchestrator slot (nest top ≈y300, Pip ≈152).
5. Iteration-1 items #4 (dark glow) and #7 (dock icon fg) are FIXED — verified in both themes (dark dock icons: dark-on-lavender/amber/mint; light: white/dark/white as designed). Iter1 #5 hearts stroke FIXED. Iter1 #2 gap and #3 Pip scale substantially improved (slot now close; residual is the mandated art swap).

Otherwise correct: header (`k3-top`, s64 lilac M, 22/26 w900 name, 15/20 sub, 120 pill, 56 r18 lock), speech bubble, "Today's quests" 28/34 + `kchip`, kid progress (h16, 2px border, leaf fill + gloss), card geometry (min-h 72, pad 12, r24, 3px border, kid shadow, 56 checks, correct chips per status), dock layout/colours both themes, no overflow/ellipsis issues, coins-only (no £), dark token flips correct.

Iteration-3 fixes (local): #1 home-strip background both themes, #2 dock height audit (≈25px between card-1 and dock), #3/#4 upper-stack trim. Shared/pre-declared: tile tint, title size.

VERDICT: FAIL
