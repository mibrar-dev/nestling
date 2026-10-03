# K03 Kid home — UI check (Stage 5, iteration 6)

Method (simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB, 390x844):
- `bash tools/screens/shot.sh "$PWD/app" /kid-home "$PWD/docs/screens/K03/ui/app_light_6.png" <udid> light demo kid maya` -> `docs/screens/K03/ui/app_light_6.png` (1170x2532). Same with `dark` -> `app_dark_6.png`. Absolute OUT paths used. Both `stable frame saved`, no warnings.
- `python3 tools/screens/compare.py design/screens/light/K03-kid-home.png docs/screens/K03/ui/app_light_6.png docs/screens/K03/ui/cmp_light_6.png` (and dark). Read all four images. Logical px (PNG/3), tolerance ±2px.
- SHAPES rule: background/border rects (x,y,w,h) measured by colour segmentation for coin pill, lock, bubble, dock buttons, card-1 extents (chip pill rects share colours with neighbouring fills so were verified visually instead — full padded pills, no P05-style collapse).
- Rules applied: PIP (art mandated, slot must match design), STATUS BAR (ignore), DATA + PERIODS, BOTTOM EDGE (pass required), ALIGNMENT (20px gutters), CHILD ORDER (no child list here — n/a; quest order stays alphabetical per `1_plan.md` §a), COPY (U+0027 verified again in both files), FONTS (grepped: no `GoogleFonts`/google_fonts in feature lib or tests ✓), LETTER SPACING (no `letterSpacing` in view; no K03 case ✓), CHIP ROWS (chips display-only, no interactive row — n/a ✓), BALANCED HEADINGS (checked — see obs 5), TRIAL (n/a), ORCHESTRATOR_NOTES (all incl. #29 shared batch 2 + #32 partial-edits warning), `1_plan.md`, SPACING_SPEC.

Results:
- light mean diff: 12.52% — bands: 0: 1.89% · 1: 4.36% · 2: 14.03% · 3: 22.84% · 4: 9.54% · 5: 22.33% · 6: 18.37% · 7: 6.73%
- dark mean diff: 11.22% — bands: 0: 1.86% · 1: 3.98% · 2: 14.54% · 3: 16.22% · 4: 9.67% · 5: 21.70% · 6: 16.33% · 7: 5.42%
- Band 3 spiked (light 7.79→22.84): the pet slot regressed (see #1). Band 7 at its best yet (dock exact + bottom edge correct; residual is the required surface-vs-PNG-green delta).

SHAPES (design → app, light): coin pill (227,65,79,36) → (228,65,78,36) ✓; lock (315,56,54,54) → identical ✓; dock Pip (27,741,95,52) → (27,741,93,54) ✓; Shop (145,738,100,58) → (144,738,102,58) ✓; My jar (264,737,103,60) → (265,737,102,60) ✓; dock top border 719-721 → 719-721 EXACT ✓; bottom edge dock-surface to y842 both themes ✓ (white light, navy (31,28,46) dark — BOTTOM EDGE pass). Card-1 same height (~85-86 both) — position only (see #1).

Fixed / held since iter5: bottom edge, dock top exact (was −6), hearts stroke, dock icons, no OS pill artefacts, stable frames.

Accepted / overridden (NOT defects): A1 counts 4/4-of-6 + fill (DATA+PERIODS); A2 2nd-card sample order (alphabetical wins); A3 Pip ART (mandated v2); A4 status bar; A5 tiles (SHARED_REQUEST #1); A6 title size (pre-declared); A7 band-7 PNG delta (required by override); A8 COPY exact (U+0027 both files).

Deviations (design → app + fix):
1. Pet-stage block ~46-56px too tall; Pip slot wrong (MAJOR, both themes — REGRESSION from iter5, consistent with notes #32 partial migration). Design: Pip ≈152 seated IN the 260x236 nest (nest top ≈y300). App: small Pip floating high with a daylight gap + detached shadow above a smaller nest. Measured knock-on: hearts +46 (443-452 → 489-498), progress ≈+56 (borders 527/542 → 583/598), card-1 top +56 (559-561 → 615-617, height unchanged), card-2 fully hidden below the dock (design shows it peeking). Fix: size the shared `NestPetStage` box per notes #17/#25 (explicit size mode, `pipSize` = design size, PipAvatar seated between the nest rims, no gap, no excess bottom gap) — keep the correct fixes, finish the rest. No code touched in this stage.
2. Dark lower-content meadow still missing (moderate, dark-only, carried from iter4/5). Design dark x=10: (37,52,88)@540 grading to teal (33,64,72)@700. App dark: flat navy (38,46,102)→(36,53,86). Light renders its green band correctly, so this is dark-only. Fix: dark meadow fills behind the lower content (tokens + `hill-front` bake, SPACING §9.14).
3. Speech bubble 11px too tall (minor): white bbox (100,130,190,35) → (100,130,190,46), same x/y/w. Contributes to the downstream shift. Fix: `NestSpeechBubble` padding/text metrics vs HTML (`padding 8px 14px`, 16/24).
4. Section/card vertical positions inherit #1 (position only — shapes pass): section chip pill and card chips render full padded pills, correct h32 look; nothing collapsed. No separate fix beyond #1.
5. Observation (code conformance, NOT visible, not counted): "Today's quests" uses `NestType.kidTitle` directly (view l.477) instead of `NestBalancedText`, although `.kid-title` CSS has `text-wrap: balance`. Single-line heading renders identically, so no visual deviation — flag for the builder to adopt the component anyway per the BALANCED rule.

Otherwise correct: header row, bubble copy/tail, hearts 4/5 + caption, section chip, kid progress geometry, card geometry/chips/checks per status, dock (exact), 20px gutters edge-aligned, no overflow/ellipsis, coins-only, all other dark flips correct.

Iteration-7 fixes (local): #1 pet-stage size/seat (the whole +56 chain), #2 dark meadow, #3 bubble height; adopt #5 `NestBalancedText`. Shared/pre-declared: tile tint, title size.

VERDICT: FAIL
