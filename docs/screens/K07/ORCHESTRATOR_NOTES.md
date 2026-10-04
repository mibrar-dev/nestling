
## UPDATE (19:10) — orchestrator decisions for iteration 2
- D2 sparkles: fix as the UI check says (the exact HTML 4-point path at the 4 spots, token fills, ink 3 px stroke).
- D3 bubble tail: ACCEPT the CSS 18×9 (shared NestSpeechBubble follows .speech::after; the PNG export is smaller). Not a finding.
- D1 the Fledgling copy wrap shifting the stack by 34: ACCEPT (DB truth).

## UPDATE (23:55) — iteration 3, mandatory (overrides my 19:10 "token fills" wording)
- D4 sparks in DARK mode: the design's `svg.sparks` uses FIXED hex colours, not theme variables (`<g stroke="#1E1B3A">`, fills #F4B400 / #3D7FF0 / #1F9D63 / #7C6CF2 …). In the dark design the outline is therefore dark ink (invisible on the night sky) and the fills keep their light-theme colours. The app currently strokes with the dark theme's `ink` (#F3F0FA) and uses the dark accent fills, so every sparkle and dot gets a white ring in dark mode (cmp_dark_2.png).
  Fix in `pip_evolution_sparks.dart` only: `_SparksPainter` must resolve the stroke AND every fill from `NestColors.light` in both themes (e.g. `final palette = NestColors.light;` then `palette.ink`, `palette.lilac` …), and `shouldRepaint` no longer depends on the theme. Verify each fill hex equals the HTML's literal. Add a widget/painter test under dark theme asserting the stroke colour is 0xFF1E1B3A.
- UI check: re-measure dark sparkles; they must show no light outline.
