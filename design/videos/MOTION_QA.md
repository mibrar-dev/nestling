# MOTION_QA — Motion lab device proofs (iPhone 16e simulator)

Method: `xcrun simctl io <UDID> recordVideo --codec=h264 --force design/videos/<name>.mp4`
(start in background, drive via `--dart-define=MOTION_AUTOPLAY=<name>`, stop with SIGINT).
Frames: `ffmpeg -vf fps=30`, cropped to the animated widget's rect (1170×2532 px,
3×), per-frame mean absolute grayscale diff (python3 + Pillow `ImageChops.difference`
+ `ImageStat`). Noise floor on static regions (app bar / background) ≈ 0.004.
PASS = motion clearly above noise for roughly the expected duration.

Play-all fix (in this tree): each step `await`s its animation (Lottie composition
duration / Rive one-shot from RIVE_GUIDE) + 400 ms gap; before each step
`Scrollable.ensureVisible(panel, alignment 0.1, 350 ms)`; jar tweens fill
0.20 → 0.62 while the drop fires.

| animation | video | expected duration | measured motion duration | PASS/FAIL |
| --- | --- | --- | --- | --- |
| Pip idle (breathe + blink, 3.0 s loop) | `pip_idle.mp4` (7.8 s) | continuous (observe 5 s) | 7.70 s > 0.05 (crop 720×720, mean 0.117 vs noise 0.004, 30×; blinks to 1.08) | PASS |
| Pip happy (72 f @60 = 1.2 s) | `pip_happy.mp4` (9.8 s) | 1.2 s | 1.00 s > 0.15 (max 0.98, 8× breathing 0.12, 250× noise; single burst + reset, scroll-free) | PASS |
| Pip eating (108 f @60 = 1.8 s) | `pip_eating.mp4` (9.8 s) | 1.8 s | 1.13 s > 0.3 burst (max 1.04; + breathing throughout) | PASS |
| Pip evolve (90 f @60 = 1.5 s, stage 3→4) | `pip_evolve.mp4` (10.8 s) | 1.5 s + stage 3→4 | transition spike 41.2 (10,000× noise); 0.43 s > 0.6 + stage screenshots fledgling→songbird; songbird blinks after | PASS |
| Jar drop (96 f @60 = 1.6 s) + fill 0.20→0.62 | `jar_drop.mp4` (9.8 s) | 1.6 s + fill 0.2→0.62 | glass crop 0.77 s > 0.02 (max 0.40, 100× noise; brief fall + subtle settle below thresh); fill 0.62 + slider confirmed in frames | PASS |
| check_tick (Lottie, 0.6 s) | `lottie_check_tick.mp4` (8.8 s, 3× loop) | 0.6 s ×3 | 0.57 s > 0.08 per burst (max 9.94; 3 bursts, first 0.57 s ≈ 0.6 s) | PASS |
| coin_burst (Lottie, 1.0 s) | `lottie_coin_burst.mp4` (9.8 s, 3× loop) | 1.0 s ×3 | 0.80 s > 0.08 longest block (max 6.36; single burst 80% of 1.0 s) | PASS |
| confetti (Lottie, 2.5 s) | `lottie_confetti.mp4` (13.8 s, 3× loop) | 2.5 s ×3 | 4.77 s > 0.15 total; longest 2.20 s ≈ 2.5 s (max 2.39, full-frame) | PASS |
| badge_unlock (Lottie, 0.9 s) | `lottie_badge_unlock.mp4` (8.8 s, 3× loop) | 0.9 s ×3 | 1.00 s > 0.3 total; longest 0.47 s per burst (max 20.3) | PASS |
| Play all (7 steps: 0.6+1.0+1.2+1.6+0.9+1.5+2.5=9.3 s anim + 7×0.35 scroll + 7×0.4 gap ≈ 14.5 s active) | `motion_lab_play_all.mp4` (25.8 s) | ~14.5 s active | 10.9 s > 0.05 full-frame (10 fps; 7 motion blocks with 0.4 s gaps; all steps on-screen; ends on Play all) | PASS |

Crops (px on 1170×2532): Pip 720×720 `(225,450,945,1170)`; jar glass
410×400 `(380,1250,790,1650)` (fill text/slider confirmed in full-jar frames);
check_tick 270×270 `(450,550,720,820)`; coin/badge 870×800 `(150,650,1020,1450)`;
confetti/play-all full-frame.

Rive binding: `PipRive`/`PipJar` expose `onReady` + `isBound`; the lab keeps the
handles (sibling contexts cannot use `X.of`) and `_awaitRiveReady` polls
`isBound` (10 s cap) before every trigger — triggers fired before the VMI binds
are dropped silently, which is what the first evolve/jar captures hit before
the wait landed (stage stayed 3, jar glass static). Final captures use the wait:
evolve ends on Stage 4 Songbird, jar ends fill 0.62.
