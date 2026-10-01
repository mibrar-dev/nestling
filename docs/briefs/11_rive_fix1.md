RIVE QA round 2 (orchestrator reviewed design/animations/rive/v2/COMPARE.png): rest poses for all 4 stages now match the brand SVGs very well, jar fill works — great. Remaining defects in the MOOD frames:
1. Crest: reference has 3 tuft strokes; your stage-3 moods (blink/happy/eating/evolve) show 1 tuft. Always 3 (same as rest pose).
2. Happy (stage 3): one wing detaches and floats up-left of the body. Wings must rotate about a SHOULDER pivot at the body edge (bone/group origin at the wing root), flap ±25°, never translate away from the body.
3. Evolve (stage 3): body stretches into a tall egg (scaleY ≫ scaleX). Keep squash & stretch volume-preserving and subtle (scaleX*scaleY≈1, max 1.12/0.9) and centred on the feet baseline.
4. Stage-4 happy: wings become pointed "ears" above the head. Same shoulder-pivot rule; wings stay at body sides.
5. Eating: beak chew should open/close the beak (two halves or scaleY on beak), not remove the crest.
Re-render every stage × mood with the CLI, rebuild COMPARE.png (add a 3rd column "mid-animation" frame), LOOK at it, iterate. Keep pip.riv < 30 KB; `rive --verify` + `rive inspect` 0 problems; in app/: flutter analyze clean, flutter test pass (do NOT run flutter clean).
Reply: changelog + sizes.
