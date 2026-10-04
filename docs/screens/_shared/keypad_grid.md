NestKeypad: lay out exactly like CSS `.keypad`. P17 (Parental gate) and K02 (Kid PIN) both use it.

CSS (design/html-source/components.css:193-196):
- `.keypad { display:grid; grid-template-columns: repeat(3, 1fr); gap: 10px; padding: 8px 24px 0; justify-items: center; }`
- buttons 72×72 circles; `.keypad-blank` 72×72
- P17-parental-gate.html:27 `.gate .keypad { margin-top: 16px; }`
APP NOW (app/lib/core/design_system/components/nest_keypad.dart ~23-44): explicit rows with row gap 16 (s4) and column gap 24 (s6). Result on P17 (read-only: ../nestling-screens/P17/docs/screens/P17/ui/cmp_light_2.png), design → app:
- row pitch 82 → 88
- column centres x 107/195/283 → 99/195/291
- the gate card is 26 px too tall
DO:
1. Reproduce the CSS grid: the available width minus 24 px padding on each side is split into 3 equal columns with a 10 px gap between them. Each 72×72 key is centred in its column cell. Rows are 72 tall with a 10 px gap. Top padding 8, bottom 0.
2. Measure BOTH designs to confirm the result, using design/screens/light/P17-parental-gate.png and K02-*.png ÷3:
   - P17: key centres at x 107/195/283 and rows 380/462/544/626 (logical, in the card).
   - K02: whatever its PNG shows.
   If K02's measured pitch differs from P17's, the CSS of the K02 screen has a local override: read K02's HTML and support it with a parameter. Do not guess.
3. Tests with real fonts: key rects and pitches for P17's card width (342 − card padding; read the gate card padding in the HTML) and for K02's width. 44 px minimum tap targets are kept (the 72 keys already exceed this). Semantics tap actions are unchanged.
4. Do NOT edit feature code. In the report, say what P17/K02 must change if anything (e.g. remove local spacing).
DONE = dart format clean, flutter analyze "No issues found!", full flutter test green, docs/screens/_shared/keypad_grid_REPORT.md, committed.
