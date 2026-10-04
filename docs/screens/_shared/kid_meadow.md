Shared kid background: match `.screen.kid` + the `.meadow` hills SVG exactly. Every K screen uses it.

DESIGN SOURCE (identical on every kid screen; read K01-profile-picker.html lines ~8-11 and ~37, plus components.css:25):
- `.screen.kid { background-color: var(--kid-sky-bottom); background-image: var(--kid-stars), linear-gradient(180deg, var(--kid-sky-top) 0%, var(--kid-sky-bottom) 62%, var(--kid-horizon) 62%, var(--kid-meadow) 100%); }`
- `.meadow { position:absolute; left:0; bottom:0; width:390px; height:136px; }` with viewBox 0 0 390 136, preserveAspectRatio none, and two paths:
  - `.hill-back { fill: var(--kid-meadow) }`
  - `.hill-front { fill: color-mix(in srgb, var(--kid-meadow) 80%, var(--surface)) }`
  - Copy the exact `d` paths from the HTML.
- Light and dark tokens: tokens.css (kid-sky-top/bottom, kid-horizon, kid-meadow, surface), both blocks.

APP NOW (K01 UI check, read-only: ../nestling-screens/K01/docs/screens/K01/5_ui.md D3/D4 + ui/cmp_light_1.png): a single flat hill that starts ≈ 106 px lower than the design, with no hill-front overlay. Design bottom colour (204,237,192); app (191,232,176).

DO (app/lib/core/design_system/theme/kid_scope.dart and/or a new `NestKidBackground` / `NestMeadow` in core/design_system):
1. Paint the kid background exactly per `.screen.kid`: the gradient with the 62% horizon, plus the stars layer if `--kid-stars` is defined.
2. Paint the meadow SVG pinned to the PHYSICAL bottom of the screen (the screen bottom, under the home indicator, as in the design frame). Full width, 136 tall, scaled horizontally to the screen width (preserveAspectRatio none). Both paths use the exact d's and the token colours; hill-front is the 80% kid-meadow / 20% surface mix, computed in Dart.
3. It sits behind content (z 0) and never intercepts taps.
4. Tests (390×844, light and dark):
   - Sample pixels at design points from K01's PNG (design/screens/light/K01-profile-picker.png ÷3): the meadow top at the left gutter, the hill crest, the bottom row = (204,237,192) light.
   - Do the same in dark.
5. K03 Kid home is MERGED and uses kid backgrounds (incl. its dark meadow band behind the cards). Run its tests and compare against design/screens/*/K03-kid-home.png: K03 must not regress. If K03 painted its own meadow, list it in the report so the screen can switch.
6. grep app/lib/features for local meadow/hill code and list it in the report. Do NOT edit feature code.
DONE = dart format clean, flutter analyze "No issues found!", full flutter test green, docs/screens/_shared/kid_meadow_REPORT.md (how screens use it), committed.
