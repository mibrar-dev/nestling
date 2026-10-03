# Shared report — search field 54-high border box + centred text

## Files changed

- `app/lib/core/design_system/components/nest_text_field.dart` (search
  variant only) — field is now a 54-high border box with the hint and the
  typed text vertically centred in the 44 px slot; doc comments fixed.
- `app/test/design_system/shared_batch4_test.dart` — geometry test now
  expects 54 high.
- `app/test/design_system/search_field_fix_test.dart` (new) — real-font
  (FontLoader) pins for height, hint/typed centring, the x+16/x+50 slot,
  and the untouched labelled variant.

## What / why

P10 SHARED_REQUEST §§9–10: `.search` is `border-box`, so
`min-height:52px + padding 4px + border 1px` computes to 54 tall, but the
field rendered 52 (3 px vertical padding); and the hint — painted by the
`InputDecorator`, which ignores `TextAlignVertical` — sat at the top of
the tight 44 px slot, ~11 px above the field centre, while the icon was
already centred.

Fix: `minHeight` 52 → 54, vertical padding `gap3` (3) → `s1` (4), and
`contentPadding` gains 10 px top/bottom (`gap10` = (44 − 24) / 2 around
the 24 px Inter 16/24 line box, keeping the existing `left: -4` inset
cancellation). The decorator content is then exactly 44, so the hint and
the typed text both centre; `textAlignVertical.center` and `isDense`
stay. Horizontal slot untouched (icon x+16, hint x+50). Other
`NestTextField` variants untouched (same constructor API, no visual
change outside `.search`).

## Tests

New `app/test/design_system/search_field_fix_test.dart` (light + dark):

- `light/dark: field is 54 high` — outer container 54 ±0.5.
- `light/dark: hint is centred in the field` — hint centre = field
  centre ±1.
- `light/dark: typed text is centred in the field` — `enterText('bins')`
  centre = field centre ±1.
- `light/dark: icon at x+16, hint at x+50` — slot unchanged, icon still
  centred.
- `labelled variant is unaffected` — default constructor keeps
  `contentPadding` 16/14 with label + helper.

Updated: shared_batch4 `icon 24 at x+16, hint at x+50, field 54 high`.

Full suite: `flutter test` 1786 passed; `flutter analyze` No issues found.

## Follow-up for screens

None required. P10 picks this up automatically: its red pin
`the hint is centred in the field, not floated to the top` and the
`the search field sits on the design y` 54-height assertion should turn
green, and the 2 px uniform shift of the chip row and cards below the
field disappears. No screen-side wrapping or re-padding needed (still
forbidden).

VERDICT: PASS
