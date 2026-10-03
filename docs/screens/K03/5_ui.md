# K03 Kid home — UI check (Stage 5, iteration 7)

Method (simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB only, per SIMULATORS rule; 390x844):
- `bash tools/screens/shot.sh "$PWD/app" /kid-home "$PWD/docs/screens/K03/ui/app_light_7.png" <udid> light demo kid maya` -> `docs/screens/K03/ui/app_light_7.png` (1170x2532). Same with `dark` -> `app_dark_7.png`. Absolute OUT paths used. Both `stable frame saved`, no warnings.
- `python3 tools/screens/compare.py design/screens/light/K03-kid-home.png docs/screens/K03/ui/app_light_7.png docs/screens/K03/ui/cmp_light_7.png` (and dark). Read all four images. Logical px (PNG/3), tolerance ±2px.
- Rules applied: all orchestrator rules incl. new SIMULATORS rule (this stage used the designated simulator; nothing else in this stage did), PIP, STATUS BAR, DATA + PERIODS, BOTTOM EDGE, ALIGNMENT, CHILD ORDER (n/a — no child list), COPY (re-verified below), FONTS, LETTER SPACING, CHIP ROWS, SHAPES (rects), BALANCED HEADINGS, TRIAL (n/a), ORCHESTRATOR_NOTES (all incl. #35 last-pass targets), `1_plan.md`, SPACING_SPEC.

Results:
- light mean diff: 12.51% — bands: 0: 1.89% · 1: 4.36% · 2: 14.03% · 3: 22.84% · 4: 9.51% · 5: 22.33% · 6: 18.37% · 7: 6.73%
- dark mean diff: 11.22% — bands: 0: 1.87% · 1: 3.98% · 2: 14.54% · 3: 16.22% · 4: 9.65% · 5: 21.70% · 6: 16.35% · 7: 5.42%
- HEADLINE: the iteration-7 frames are visually UNCHANGED from iteration 6. Frame diff app_light_6→7: 0.17% mean, all tiny magnitudes (AA/clock noise); landmarks identical (hearts 489-498 both; card/progress border triplets identical). None of the #35 visual targets took effect in the running app. Everything below therefore carries over with fresh verification.

Target audit vs notes #35 exact geometry (logical px):
- Nest outline: target x96→294 (198 wide, cx195), y278→364. App (per orchestrator measurement, consistent with these frames): x120→338 (218 wide, cx229 = +34 off-centre), y299→414. MISS.
- Pip: target head top ≈201, bottom ≈301 overlapping rim ≈20px, no gap/shadow under feet. App: small Pip floating high with a daylight gap + detached shadow. MISS.
- Hearts centre 448 → app ≈493 (+45). Title 494 / progress 527-542 / card-1 559 → app progress ≈583-598 (+56), card-1 top 615-617 (+56, height correct ≈86). MISS.
- Dock 720 → app 719-721 EXACT ✓. Bottom edge dock-surface to y842 both themes ✓ (white light, navy dark — BOTTOM EDGE pass, no strip).
- Consequence: card-2 fully hidden below the dock; design shows it peeking. Hearts/progress/cards all strongly doubled in the diff.

Accepted / overridden (NOT defects): A1 counts 4/4-of-6 + fill (DATA+PERIODS); A2 2nd-card sample order (alphabetical wins); A3 Pip ART (mandated v2 — slot is the failure, not the art); A4 status bar (band 0 is clock only); A5 tiles (SHARED_REQUEST #1); A6 title size (pre-declared); A7 band-7 PNG delta (required by override); A8 COPY exact (U+0027 re-verified this iteration in both files); FONTS clean (no GoogleFonts in feature); no letterSpacing; chips display-only (CHIP ROWS n/a); shapes that pass — coin pill, lock 56, all 3 dock buttons within 1-2px, card-1 extents, 20px gutters, coins-only, other dark flips.
Fixed this iteration (code, not visible): `NestBalancedText` adopted for the kid-title (view l.483) — single-line so no visual change, as expected.

Deviations (design → app + fix):
1. Pet-slot geometry wrong (MAJOR, both themes — the last-pass blocker). Small floating Pip + oversized off-centre nest (+34 x, y299→414) instead of Pip ≈152 seated in the 198-wide centred nest with ≈20px rim overlap and no gap; +46-56px downstream shift hides card-2. Root cause already diagnosed in notes #35 (`nestWidth: 260` → `stageW = 419 > 390`, off-centre). Fix per notes #35: choose `nestWidth` for a 198 visible outline with a ≤390 centred stage box, seat PipAvatar in the bowl; pin with the geometry test (nest cx195±1 w198±2, hearts 448±2, card-1 559±2); if the shared component cannot do it without a core edit, file SHARED_REQUEST with these numbers and stop. No code touched in this stage.
2. Dark lower-content meadow still missing (moderate, dark-only, 3rd iteration). Design dark x=10: (37,52,88)@540 → teal (33,64,72)@700. App dark: flat navy (37,51,88)→(36,53,86). Light renders its band correctly. Fix: dark meadow fills behind the lower content.
3. Speech bubble 46 vs 35 tall, same x/y/w (minor, carried; contributes to the shift). Fix: `NestSpeechBubble` metrics vs HTML `.speech`.

Otherwise correct: header, bubble copy/tail, hearts 4/5 + caption, chips (full pills), progress geometry, card geometry/checks per status, exact dock, alignment outside the pet chain, no overflow/ellipsis.

Iteration-8 (or orchestrator shared fix): #1 geometry + test (or SHARED_REQUEST per #35.3), #2 dark meadow, #3 bubble height. Shared/pre-declared: tile tint, title size.

VERDICT: FAIL
