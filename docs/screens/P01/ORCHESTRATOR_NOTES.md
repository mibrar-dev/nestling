# Orchestrator notes for P01 (mandatory)
1. Replace the v1 `pipStage2` SVG with `PipAvatar(style: mochi, skin: sunny, stage: 2)` in the same slot (168×168 at left 91, top 120 inside the 350×388 scene), idle mood; still frame when DISABLE_ANIMATIONS / reduced motion.
2. Status-bar differences are harness artefacts — ignore (NestStatusBar no longer draws the mock clock).
3. (after iteration 2, orchestrator-reviewed cmp_light_2: 3.41% — very close.) The ONLY design item left is the headline break: the design wraps "Chores that feel / like a game." Constrain the headline width (e.g. ConstrainedBox maxWidth ≈ 300 from SPACING_SPEC / the HTML's max-width) so "like" falls to line 2 at 390 width; do NOT insert a hard "\n" (must still wrap sensibly at 320 and text scale 1.3).
4. The home-indicator pill is drawn by iOS (NestHomeIndicator draws nothing now) and `shot.sh` frame-instability is a harness note — neither is a P01 defect; do not chase them.
5. Fix the review's BUG-2 test item: un-skip it and assert the NEW contract (CTA top identical with bottomInset 0 vs 34, i.e. inset counted once).
