Shared fix: NestPetStage explicit-size mode must centre the nest in the REAL box and match K03's design geometry. Also make NestSpeechBubble match the design height.

READ FIRST:
- ../nestling-screens/K03/docs/screens/K03/SHARED_REQUEST.md items 13 and 15. They contain measured numbers and a table. Read-only: do NOT edit anything in that worktree.
- ../nestling-screens/K03/docs/screens/K03/2_build.md, section 3.
- app/lib/core/design_system/components/nest_pet_stage.dart, app/lib/core/design_system/motion/pip_rive.dart (PipNestFallback / PipInNest).
- design/html-source K03 HTML + components.css (.pet-stage, .pet-shadow, .speech).
- design/screens/light/K03-kid-home.png (1170×2532, ÷3 = logical px).

PROBLEM:
- Explicit mode (`nestWidth` / `fixedPipHeight`) computes `stageW = nestW / 0.62` and positions every Positioned against that nominal width, not the width the widget actually gets. Inside K03's 350 px content box (390 − 2×20 gutters), the nest ends up +34.7 px right of centre at 390, +69.7 at 320 (and clipped).
- `PipNestFallback` assumes nestH == nestW, so the block is 276 tall instead of the design's 236.
- The nest SVG's visible outline is ≈ 0.84 × the nest box.

DESIGN TARGETS (K03 at 390×844, logical px; the K03 screen will pin them):
- Visible nest outline: x 96→294 (198 wide, centre x 195 = the centre of the screen and of the content box), y ≈ 278→364.
- Pip (any `pip:` widget): centred on the nest, head top ≈ y 201, bottom ≈ y 301. It overlaps the nest's top rim by ≈ 20 px, as if seated in the bowl. No gap and no shadow under Pip's feet.
- Ground shadow ends ≈ y 388. The pet block is 236 tall in the design's pet slot.
- Speech bubble (#15): design height ≈ 35 with the same x, y and width as today (app is 46). Match `.speech` in the HTML exactly: padding, font size and line-height, border.

DO:
1. Explicit mode:
   - Lay out against the ACTUAL box (`constraints.maxWidth`). The nest is always horizontally centred in that box.
   - Decorative layers (glow, ground shadow) may extend beyond the nest but never shift it. They paint with Clip.none or are clamped, and never push the layout wider than maxWidth.
   - If the requested nest does not fit, scale the whole scene down uniformly; never overflow. This is the guard the legacy path already had.
2. Make the scene height expressible: add `nestHeight` (or derive the height from the art's real aspect) so K03 can request the design's slot. Then K03 needs `nestWidth` ≈ 236 (198 visible) at 390, and the block is 236 tall.
   - Document in the dartdoc the visible-to-box ratio (≈0.84) and which parameter gives the visible outline.
   - A clearer API is welcome: e.g. `visibleNestWidth: 198`.
3. Pip is seated per the targets above for the fallback path (SVG/PipAvatar) and the Rive path. Both must share one geometry.
4. NestSpeechBubble: match `.speech` so its height is ≈ 35. If other screens use the bubble with a different design size, add a parameter, not a new default; grep usages and list them.
5. Legacy (non-explicit) mode must not change: every existing test stays green.
6. Tests (app/test/core/design_system/nest_pet_stage_test.dart):
   - In a 350-wide box centred in 390, the visible nest's centre x = 195 ±1 and its width is 198 ±2 with the K03 parameters. Also at 320 and 430: centred, no overflow, scaled down at 320.
   - Block height 236 ±2.
   - Pip bottom overlaps the nest top by ≈ 20 ±3.
   - Bubble height 35 ±1.
   - Rive-disabled and Reduce Motion paths are both covered.
7. In the report, give the exact constructor call K03 must use.
DONE = dart format clean, flutter analyze "No issues found!", full flutter test green, docs/screens/_shared/pet_stage_explicit_REPORT.md written, committed.
