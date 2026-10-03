Make text letter-spacing match the design: 0 unless the design CSS sets it.

PROBLEM (found by P04 tests, applies to EVERY screen):
- `design/html-source/components.css` sets letter-spacing ONLY on `.display` and `.status-time` (-.01em). Every other class (.h1, .body, .body-s, .caption, .list-title, .list-sub, .opt-title, .opt-sub, .btn, .footnote, …) uses the browser default of 0.
- `app/lib/core/design_system/tokens/typography.dart` (`NestType._inter` / `_nunito`) passes `letterSpacing: null` by default. Null gets filled in from the Material 3 theme / DefaultTextStyle (e.g. 0.25, 0.5, 0.1). Text comes out wider than the design: on P04 an option title grew from 242.5 to 250.2 px and wrapped onto a second line.

DO:
1. In `NestType._inter` and `_nunito`, default `letterSpacing` to 0 (`letterSpacing ?? 0`).
   - Keep the explicit values that already exist (display -0.34, the 0.78 and -0.15 styles), but check each against design/html-source/*.css and tokens.css.
   - If a value has no CSS source, set it to the CSS value (0 if none) and list it in the report.
2. Check app/lib/app (ThemeData / textTheme / button and chip themes) and core components (NestButton, NestChip, NestTextField, list rows, …). Any theme or component that injects non-zero letter spacing the CSS doesn't have must also use 0.
   - For example: Material button `textStyle`, `TextTheme` built from Typography.material2021, InputDecoration styles.
3. Add a shared test, app/test/core/design_system/letter_spacing_test.dart:
   - For every public NestType style, `letterSpacing` equals the CSS value (0 unless the CSS says otherwise).
   - Pump a NestButton, a NestChip, a NestTextField and a Text(style: NestType.body()) inside the real app theme. Each rendered RenderParagraph's text spans must resolve to letterSpacing 0 (or the CSS value).
4. Run the whole suite. Some screen golden or geometry tests may change because text gets narrower.
   - Fix shared tests.
   - If a feature test breaks, do NOT edit feature code. List the test name and the reason in the report as a follow-up for that screen.

The report must list every NestType style with its old and new letterSpacing, and its CSS source.
