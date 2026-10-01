STAGE 5 — UI CHECK on the iPhone simulator (iteration {ITER}). Simulator UDID {SIM} (390×844, same as the designs).
1. `bash tools/screens/shot.sh $PWD/app {ROUTE} docs/screens/{ID}/ui/app_light_{ITER}.png {SIM} light {SEED} {MODE} {CHILD}` and the same with `dark` → app_dark_{ITER}.png.
2. `python3 tools/screens/compare.py design/screens/light/{ID}-{SLUG}.png docs/screens/{ID}/ui/app_light_{ITER}.png docs/screens/{ID}/ui/cmp_light_{ITER}.png` (and dark).
3. READ the compare images. Check element by element against the design: presence, order, copy, spacing (±2 px logical), sizes, alignment, colours, radii, shadows, icon choice, overflow/clipping/ellipsis, dark-mode colours.
Do not edit code. Write docs/screens/{ID}/5_ui.md: the mean diff %, then numbered deviations (element, design value, app value, fix). VERDICT: PASS only if no visible deviation a designer would reject.
