# Orchestrator notes for K03 (mandatory)
1. Replace the v1 Pip SVG with `PipAvatar` for the active child (Maya: Mochi, sunny, stage 3, inNest true). Keep the design's Pip slot size: Pip ≈152 px tall on the 260×236 nest, nest top ≈ y 300 — the current Pip renders larger and higher than the design.
2. "4 done today / 4 of 6 done" is correct (database). Not a defect.

## Ruling on "done today" (K03-BUG-4 / SHARED_REQUEST #4) — mandatory
Main now has `countsForCurrentPeriod` (app/lib/core/data/london_time.dart). In this feature's repository, treat a quest's latest completion as current only if `countsForCurrentPeriod(quest.repeatRule, completion.createdAt, DateTime.now().toUtc())`; otherwise the quest is "to do". Un-skip the day-boundary bug test and make it pass. The seed is anchored to today in the app and to Sat 3 Oct 2026 in tests (test/flutter_test_config.dart) — do not hard-code dates.

## Bottom inset after the shared NestHomeIndicator change (mandatory, iteration 3)
`NestHomeIndicator` no longer reserves 34 px (the OS draws the indicator). The kid dock is not inside NestBottomCta, so K03 must own the inset: put the dock in `SafeArea(top: false)` (or pad by `MediaQuery.viewPaddingOf(context).bottom`) so the dock top lands at the design's y≈720 on the 390×844 iPhone, and let the meadow background extend under the dock and the home-indicator area to the bottom edge (design: green to y=843, both themes). That fixes UI items 1–3 together.
`DISABLE_ANIMATIONS=1` now sets MediaQuery.disableAnimations app-wide (main) — K03-BUG-7 is shared and fixed; un-skip/adjust its test.

## OWNER FEEDBACK (overrides my earlier meadow note) — mandatory
The owner saw K03 and dislikes the green strip under the dock ("on the bottom I can see green, that is not looking good"). REVERSE the earlier instruction: the meadow must END at the dock's top edge. The dock's own surface colour (light: white surface; dark: the dock's dark surface) must fill everything from the dock's top border down to the physical screen edge, including the home-indicator area — no green below the dock in either theme.

## Review finding 1 (iteration 4) — shared components now exist on main (mandatory)
Delete the local forks in kid_home_view.dart and use the shared design system instead:
- `_KidPetStage` → `NestPetStage(pip: PipAvatar(style/skin/accessory/stage from the active child, inNest: false), speech: "Let's do some quests!", pipSize: <design size>)` — the new `pip:` slot seats the child's v2 Pip between the nest rims.
- `_SpeechBubble` / `_TailPainter` → `NestSpeechBubble` (now public, same geometry) — or just pass `speech:` to NestPetStage.
- `_HeartIcon` / `_HeartPainter` → `NestHeart(filled: …, size: 26)`.
- `_MeadowPainter` → rely on `KidScope`'s meadow; if the design needs a different meadow height, write it in docs/screens/K03/SHARED_REQUEST.md instead of painting a second hill.
Keep the owner's bottom-edge rule. Re-run the UI check numbers afterwards.

## Orchestrator QA of cmp_light_4 (iteration 4) — targets for iteration 5 (mandatory)
- Bottom-edge owner rule: PASS (dock surface runs to the edge). Keep it.
- Remaining real deviation: every element below the nest is ~12 px LOW (hearts row, "Today's quests" title, progress bar, first card). Cause: the pet-stage block is taller than the design's. Target (390×844, logical px): hearts row top ≈ y 443, section title cap-height top ≈ y 490, progress bar ≈ y 520, first card top ≈ y 560, dock top ≈ y 720. Fix by sizing the NestPetStage box (pipSize / nest width / bottom gap) — not by negative margins.
- Not defects: the v2 Pip art (intentional), "4 done today / 4 of 6" (database value).
- Measure your own result with tools/screens/compare.py band table; bands 3–5 must drop clearly.

## UPDATE (23:48) — shared batch 2 merged into your branch
NestChip is 32 px (44 hit area), NestTextField has an error state (errorText → danger border + text below), NestPetStage has an explicit size mode, children order by created_at. Use them; remove local workarounds. google_fonts is gone: delete any GoogleFonts lines in your tests (analyze currently reports them).

## UPDATE (05:36) — the UI builder for this iteration hit Fledge's rate limit and did not finish
Integrator: there is no fresh 2b_build_ui report this iteration. YOU must also make the UI fixes in the current FIXES list and the notes above. Check the views on disk: the UI builder may have left partial edits, so keep the correct ones and finish the rest.

## UPDATE (07:40, orchestrator) — ITERATION 7 IS THE LAST PASS. Exact targets, measured by the orchestrator
ROOT CAUSE of the pet-block failure (6 passes):
- kid_home_view.dart passes `nestWidth: _kNestWidth (260)`.
- NestPetStage computes `stageW = nestW / 0.62 = 419 px`. That is WIDER than the 390 px screen, so the stage overflows and is laid out off-centre (+35 px right). The nest also renders too big (visible outline 218 wide instead of 198).
- "260×236" was the design's whole pet slot box, NOT the nest width.

Design geometry at 390×844 (logical px, from design/screens/light/K03-kid-home.png; the app shot uses the same coordinates):
- Visible nest outline: x 96 → 294 (198 wide, centre x 195), y ≈ 278 → 364.
- Pip: centred at x 195. Head top ≈ y 201. Pip's lower body sits INSIDE the nest bowl: Pip's bottom ≈ y 301 overlaps the nest's top rim by ≈ 20 px. No gap and no separate shadow under Pip's feet.
- Ground shadow under the nest ends ≈ y 388.
- Hearts row centre ≈ y 448. "Today's quests" title ≈ y 494. Progress bar ≈ y 527–542. First card top ≈ y 559. Card 2 must be visible, peeking above the dock as in the design.
- App today: nest x 120→338 (218 wide, centre 229), nest y 299→414, hearts 494. So the pet block is 46 px too tall and 35 px off-centre.

DO:
1. Pick `nestWidth` so that the VISIBLE nest outline is 198 px. Measure the ratio of visible nest to nestW in PipNestFallback's art, or render and measure in a test.
   - The resulting stage box must be ≤ the available width and horizontally centred.
   - Pip (PipAvatar, the child's own v2 avatar) must be seated in the bowl, as in the design.
2. Add a geometry test with real fonts (FontLoader, as app/test/features/privacy_consent/privacy_consent_geometry_test.dart does) that pins:
   - nest outline rect centre x 195 ±1 and width 198 ±2;
   - hearts row y 448 ±2;
   - first card top 559 ±2.
3. If the shared NestPetStage cannot produce this without editing core, do NOT hack around it. Write SHARED_REQUEST.md with the exact numbers above and stop. The orchestrator will fix the shared component.
4. Also fix the rest of FIXES_6.md:
   - The failing "double tap across frames" test (finder).
   - Delete the scratch probe test so analyze is clean.
   - "Today's quests" uses NestBalancedText (.kid-title has balance).
   - Speech bubble height 46 → design 35, same x/y/w; check `.speech` in the HTML.
   - Dark-mode lower meadow (dark only).
   - Retry stacking subscriptions.
