Fix the dark-mode pet glow in NestPetStage to match the design token.

DESIGN (design/html-source/tokens.css):
- light: `--pet-glow: none`
- dark: `--pet-glow: radial-gradient(circle 110px at 50% 45%, rgba(255,255,255,.10), transparent 70%)`
- applied by `.pet-stage::before`: a 230×230 box centred on the pet stage (left 50%, top 42%) whose background is that gradient (components.css line ~188).

APP NOW: app/lib/core/design_system/components/nest_pet_stage.dart ~233-250 and ~280-295 paint a SOLID `Color(0x1AFFFFFF)` disc, diameter ≈ nestW × 1.04 (≈ 245 px at K03). On K03 dark (../nestling-screens/K03/docs/screens/K03/ui/cmp_dark_10.png, read-only) it shows as a big hard-edged lilac circle. The design shows almost nothing: a soft fade.

DO:
1. Replace the solid disc (both the explicit and the legacy/Rive paths) with a 230×230 box.
   - Centre: horizontally on the stage centre; vertically at 42% of the stage height, matching `.pet-stage::before`.
   - Painted with `RadialGradient(center: Alignment(0, -0.1) /* 45% */, radius: 110/115, colors: [white @10%, transparent], stops: [0, 0.7])`, equivalent to CSS `circle 110px` with transparent at 70%.
   - Put the alpha in a token (e.g. `tokens.petGlow`, null in light) rather than a hard-coded Color.
2. Light mode: no glow at all (token null).
3. Tests (nest_pet_stage_test.dart):
   - Dark: the glow is a DecoratedBox with a RadialGradient, 230×230, centred on the stage x, centre y at 42% ±2 of the stage height; gradient stops [0, 0.7], first colour alpha ≈ 0.10.
   - Light: no glow widget.
DONE = dart format clean, flutter analyze "No issues found!", full flutter test green, docs/screens/_shared/pet_glow_REPORT.md written, committed.
