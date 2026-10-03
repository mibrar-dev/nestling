Give chips inside a tight row (`Wrap`/`Row`) the full 44 px tap target without changing the 32 px layout.

PROBLEM (P05 bug P05-BUG-11, also affects P06 payout-day chips and every chip row):
- `NestChip` (app/lib/core/design_system/components/nest_chip.dart) is laid out 32 px high. Its `_ExpandedHitBox` accepts taps up to 6 px outside its box, so the tap target is 44 px (SPACING_SPEC §10.6, owner rule: 32 px visual + 44 px hit area).
- But Flutter hit testing stops at the first ancestor whose own bounds do not contain the point. A `Wrap` (or `Row`) of chips is exactly 32 px high per run, so taps in the 6 px above/below the first/last run never reach the chip.
- Measured on P05 at 390×844: a tap 5 px above or below an age chip does not select it.

DO:
1. Add a shared, public `NestChipWrap` to core/design_system/components:
   - Same API as `Wrap` for what chip rows need: children, spacing, runSpacing, alignment, crossAxisAlignment.
   - Its render object extends `RenderWrap` and overrides `hitTest` so points up to `NestChip`'s hit slop (6 px; share the constant with NestChip, do not duplicate the number) above the first run and below the last run are passed to `hitTestChildren`.
   - Horizontally do the same, so the 44 px minimum also holds for narrow chips at the row's left/right ends.
   - Layout size is UNCHANGED: identical to `Wrap`, so no screen moves.
   - Taps in the gap between two chips (spacing 8) go to the nearest chip.
2. Also add `NestChipRow` (single line, no wrapping), or document that `NestChipWrap` covers single rows; choose the simpler option.
3. Document it in the NestChip doc comment: "chips in a row: use NestChipWrap".
4. Tests in app/test/core/design_system/nest_chip_wrap_test.dart:
   - Inside a Column with ≥ 6 px gaps around the row, a tap 5 px above, 5 px below, and 2 px left of the first chip selects that chip.
   - Its laid-out size equals that of a plain `Wrap` with the same children.
   - A tap in the 8 px gap selects one of the two neighbouring chips.
   - Two runs with runSpacing 8: no tap position between the runs is dead.
5. Do NOT edit feature screen code. In the report, list where screens use `Wrap`/`Row` of NestChip today (grep app/lib/features) so the screens can switch.
