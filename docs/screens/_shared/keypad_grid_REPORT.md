# Shared report — keypad_grid (NestKeypad CSS `.keypad` grid)

## Files changed
- `app/lib/core/design_system/components/nest_keypad.dart` — grid layout +
  `NestKeypadFit` parameter + `contentWidth` constant (only shared change).
- `app/test/design_system/overflow_test.dart` — updated `keypad pitch and
  dark treatment` to the CSS grid geometry (was asserting the old 24/16 gaps).
- `app/test/design_system/keypad_grid_test.dart` — NEW: geometry tests below.
- No feature code touched (`parental_gate` / `kid_home` views are still
  placeholders on this branch and do not use `NestKeypad` yet).

## What / why
Old widget: explicit rows with 24px column gaps + 16px row gaps and 8px
padding all round. CSS `.keypad` (components.css:193-196) is a grid:
`repeat(3, 1fr)`, 10px gaps, padding `8px 24px 0`, 72px keys centred in
their cells. On P17 this made rows 88px instead of 82px, columns 96px
instead of 88px, and the gate card 26px too tall (3x6px row gaps + 8px
bottom padding).
New widget: `Expanded` cells with 10px gaps reproduce the `1fr` columns at
whatever width the parent provides; padding is now 8 top / 24 sides / 0
bottom; rows are 72 tall with 10px gaps. Key visuals, 72px size, `kid`
styling, and semantics (tap actions) are unchanged. Fully backward
compatible: default `fit` is `stretch`, params only added.

## PNG measurement (design/screens/light/*.png, /3 to logical px)
Method: dark-pixel (ink) scans at 3x; outer ring walls + digit runs.
- P17: key columns 71-143 / 159-231 / 247-319, centres **107/195/283**,
  72px keys, ~82px row pitch. Matches the task's numbers exactly.
- K02: key columns 77-149 / 159-231 / 241-313, centres **113/195/277**,
  72px keys, 82px column pitch. Pitch differs from P17 (88).
- K02's HTML has NO local `.keypad` override — the narrowing comes from
  `.k2-body{display:flex;flex-direction:column;align-items:center}`, which
  shrink-wraps the grid to its max-content width: 3x72 + 2x10 + 2x24 = 284,
  centred in the 350px scroll content box (113 = 20 + 33 + 24 + 36).
- `box-sizing: border-box` (tokens.css:200) confirms 72px includes the kid
  3px border, matching the Flutter `Ink` box. P17 is `screen kid`, so both
  screens use kid-styled keys.

## Parameter for the K02 difference
`NestKeypadFit`: `stretch` (default, grid fills parent width — P17) vs
`shrinkWrap` (grid caps at `NestKeypad.contentWidth` = 284 and centres —
K02). `contentWidth` is derived from tokens
(`(tapKid+s4)*3 + gap10*2 + s6*2`), no magic numbers in feature code.

## Tests added (`app/test/design_system/keypad_grid_test.dart`, real
bundled Inter/Nunito fonts, no mocks)
- `contentWidth is the CSS max-content width` (+ default fit is stretch).
- `P17 stretch grid at 302px card content width` — centres 63/151/239
  (== 107/195/283 at card offset 44), pitches 88 x / 82 y, 72px keys,
  8px top / 0 bottom padding, 302x326 total.
- `K02 shrinkWrap grid at 350px scroll content width` — centres
  93/175/257 (== 113/195/277 at scroll offset 20), 82px pitches, 11 keys,
  72px, 57px side insets.
- `shrinkWrap caps at contentWidth on narrow screens` (320px device, 1.3
  text scale, both themes, no overflow).
- `digit and delete taps fire in both fits`.
Updated: `owner qa keypad grid geometry and dark treatment`
(overflow_test.dart). Existing `chrome_test` keypad/PIN tests and
`semantics_actions_test` NestKeypad tap-action tests pass unchanged —
44px minimum tap targets kept (72px keys).

## Follow-up for screen agents (do NOT land in this change)
- P17 (`parental_gate`): place `NestKeypad` (default `stretch`, `kid: true`
  — the gate is a `screen kid` context) full card-content width (302 =
  342 modal - 2x20 card padding). Put the 16px `.gate .keypad{margin-top}`
  OUTSIDE the widget (SizedBox/Padding above); the widget already has the
  8px grid top padding. Nothing to remove — view is still a placeholder.
- K02 (`kid_home`): place `NestKeypad(kid: true,
  fit: NestKeypadFit.shrinkWrap)` full scroll-content width (350); the
  widget centres the 284px grid itself. Do not add side padding or
  centring wrappers around it. Nothing to remove — view is still a
  placeholder.
- Gallery (`design_system_gallery`): no change needed; default `stretch`
  renders the grid at whatever width the gallery gives it.

## Verification
`cd app && dart format .` clean, `flutter analyze` → No issues found!,
`flutter test` → all pass (2891).

VERDICT: PASS
