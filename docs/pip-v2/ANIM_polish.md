FINAL POLISH (orchestrator verified your new strips — great progress; this is the last round for your style). Fix, rebuild, re-render strips + MOTION_BOARD, and prove with md5 + timestamps + peak-frame descriptions:
1. SURPRISED frame ~15%: eyes still render with a thick grey/white ring around them (reads as glasses). Surprised eyes = the normal eye, scaled up 1.3× symmetric: white sclera, big dark pupil, one highlight, the same ink outline weight as idle — no extra ring/glare layer.
2. EVOLVE frame ~15%: the first ring frame appears off-centre (top-left) before snapping to centre. Every ring frame must be centred on Pip's body from frame 0.
3. Record a 6-second mp4 of the fledgling cycling idle→happy→eating→sleepy→surprised→proud→evolve (concatenate your per-mood mp4s with ffmpeg) as design/animations/rive/<style>/SHOWREEL.mp4.
Gates: verify/inspect 0 problems; flutter analyze clean; flutter test pass (Storybook: no Flutter edits).
