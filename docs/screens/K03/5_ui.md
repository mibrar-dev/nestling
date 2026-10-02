# K03 Kid home — UI check (Stage 5, iteration 5)

Method (simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB, 390x844):
- `bash tools/screens/shot.sh "$PWD/app" /kid-home "$PWD/docs/screens/K03/ui/app_light_5.png" <udid> light demo kid maya` -> `docs/screens/K03/ui/app_light_5.png` (1170x2532). Same with `dark` -> `app_dark_5.png`.
- NOTE: absolute OUT paths used (`shot.sh` cds to `$APP_DIR`). First stable run: both shots printed `stable frame saved` (no stabilisation warning) — the shared `disableAnimations` fix works.
- `python3 tools/screens/compare.py design/screens/light/K03-kid-home.png docs/screens/K03/ui/app_light_5.png docs/screens/K03/ui/cmp_light_5.png` (and dark). Read both sheets. Logical px (PNG/3), tolerance ±2px.
- Rules applied: PIP (`PipAvatar` Mochi/sunny/stage 3), STATUS BAR (ignore), DATA OVER MOCKS + PERIODS (in-period counts win; seed anchored to today), BOTTOM EDGE owner rule (bar surface to the edge — FAIL any coloured strip; overrides design), ALIGNMENT owner rule (20px gutters, nothing visibly off), CHILD ORDER (no child list on this screen — n/a; quest order stays alphabetical per `1_plan.md` §a), COPY (typographic characters verified by codepoint below), ORCHESTRATOR_NOTES (all items incl. iter4 shared-component migration + iter5 QA targets), `1_plan.md`, SPACING_SPEC.

Results:
- light mean diff: 11.99% — bands: 0: 2.94% · 1: 5.06% · 2: 9.93% · 3: 7.79% · 4: 9.08% · 5: 23.45% · 6: 24.88% · 7: 12.80%
- dark mean diff: 10.95% — bands: 0: 3.00% · 1: 4.98% · 2: 9.48% · 3: 5.58% · 4: 8.07% · 5: 22.18% · 6: 22.81% · 7: 11.49%
- QA band target MET: bands 3-5 dropped clearly vs iter4 (light 13.18→7.79 / 13.20→9.08; dark 9.71→5.58 / 12.90→8.07). Band 7 residual is the required dock-surface-vs-outdated-PNG-green delta (override, not a defect).
- QA position targets (logical px): hearts top design 443 vs app 446 (+3, was +12) ✓; dock top 719-721 vs 713-715 (−6, unchanged); bottom edge dock-surface to y842 both themes (white light, navy (31,28,46) dark) ✓ no strip.

Fixed since iter4: bottom-edge strip gone both themes (was must-FAIL); hearts +12→+3; light green band now starts y536 (was 562); shared forks removed per notes #15-20 (visual result identical-or-better).

Accepted / overridden (NOT defects):
- A1 counts "4 done today" / "4 of 6 done" / ~66.7% vs PNG 3/50% — correct per DATA + PERIODS + notes #2.
- A2 2nd card "Hoover the stairs" (approved → "Done") vs PNG "Reading" sample — alphabetical data order wins (`1_plan.md` §a); same peek-above-dock presentation. CHILD ORDER ruling concerns children, not quests.
- A3 Pip drawing vs v1 SVG — MANDATED `PipAvatar`. A4 status bar (OS time only) — ignored (band 0 is this only).
- A5 tiles `surface2` vs tints — SHARED_REQUEST #1. A6 title ≈17/22 vs 18/24 — pre-declared token. A7 no OS pill in captures — expected.
- A8 COPY rule PASS: "Today's quests" and "Let's do some quests!" use U+0027 in BOTH the HTML source and the view (verified codepoint-by-codepoint); "Waiting for Mum", "Hi Maya!", "Pip is happy today" match; quest titles come from the DB seed (data wins).

Deviations (design value → app value + fix):
1. Dark lower-content background missing the meadow tint (moderate, dark-only — FAIL driver, carried from iter4). Design dark x=10 grades (37,52,88) at y540 → teal (33,64,72) at y700 behind progress/cards. App dark is flat navy (37,51,89) across y540-710, while light correctly renders its green band. Fix: dark meadow fills behind the lower content (dark `--kid-meadow`/`--horizon`, `hill-front` bake per SPACING §9.14) — light proves the layer works; dark renders nothing. For the iteration-6 builder; no code touched here.
2. Residual +10-13px excess in the hearts→progress span (moderate, both themes). Hearts bottom → progress top: design 75px vs app 85px; progress borders ≈+13 (527-542 vs 540-555); card-1 top +13 (559-561 vs 572-574, same 3px triplet; progress→card-1 gap correct at 17 both). Title/chip/progress show clear doubling in the diff. Fix: trim ≈10px from the section-title block/gaps (shared section style or K03 spacing), keeping hearts top at 443-446.
3. Dock top −6px (minor, ALIGNMENT): light 713-715 vs 719-721, unchanged from iter3/4. Fix: land exactly on y≈720 when owning the inset.
4. Dark pet glow circle present in app, absent in PNG (informational). App follows SPACING §7 (white@10% dark); the PNG omits it. Spec-compliant — orchestrator to rule if ever normalised; not counted toward the verdict.

Otherwise correct: header row, bubble, hearts 4/5 stroked + caption, section chip, kid progress geometry, card geometry/chips/checks per status, dock buttons (glyphs, labels, colours both themes), 20px gutters edge-aligned, no overflow/ellipsis issues, coins-only, all other dark token flips correct.

Iteration-6 fixes (local): #1 dark meadow behind lower content; #2 section-block trim (≈10px); #3 dock top to y≈720. Shared/pre-declared: tile tint, title size.

VERDICT: FAIL
