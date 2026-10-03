# Shared balanced_text_ellipsis report

Branch: `shared/balanced_text_ellipsis` (from `main`).

## Root cause

`NestBalancedText` defaulted `overflow` to `TextOverflow.ellipsis` and
`lineCountFor` always built its `TextPainter` with `ellipsis: '…'`,
even when `maxLines` was null. In Flutter, an ellipsis with no `maxLines`
truncates at the first line, so `lineCountFor` returned 1 and `build`
returned the plain `_text()` (also an ellipsis `Text`), rendering one line
(`How does pocket mone…`) instead of the design's two lines. P07 only
worked because it passes `maxLines`.

## Files changed

| File | What / why |
|---|---|
| `app/lib/core/design_system/components/nest_balanced_text.dart` | `overflow` default `ellipsis` → `clip`; `_text()` passes `overflow: maxLines == null ? TextOverflow.clip : overflow` so an ellipsis is only applied when there is a line cap; `lineCountFor` uses `ellipsis: maxLines == null ? null : '…'` so the uncapped measurement returns the true wrap count. Backward-compatible: capped call sites keep their `overflow`, uncapped sites stop truncating. |
| `app/test/design_system/nest_balanced_text_test.dart` | New `P06 heading without maxLines` group (real bundled Inter/Nunito via `FontLoader`); imports `test_harness.dart` for `pumpNest`. Existing P07 groups untouched. |

## NestBalancedText usages (`grep app/lib`)

| Call site | `maxLines` | Effect of this change |
|---|---|---|
| `app/lib/features/paywall/presentation/views/paywall_view.dart:411` (`Try Nestling free for 14 days`) | `3` | Unchanged path (`ellipsis: '…'` still used for measurement; `overflow` resolves to the passed/default value). Still balances to 2 lines; P07 widget tests green. |
| P06 branch `app/lib/features/pocket_money/presentation/views/pocket_money_setup_view.dart:143` (`How does pocket money work in your house?`, `textAlign: left`, no `maxLines`) — not present on this branch yet, verified in `../nestling-screens/P06` | none | The bug: previously measured as 1 line with `…`. After the fix measures 2 lines at 350 px content width and renders with `clip` (no `…`). No screen-code change needed. |
| No other `NestBalancedText(` call sites exist on this branch. | — | — |

## Tests added (`app/test/design_system/nest_balanced_text_test.dart`)

Group `P06 heading without maxLines (real Inter/Nunito)`, h1 (`NestType.h1`)
with `How does pocket money work in your house?`, no `maxLines` unless noted:

- `lineCountFor needs two lines at 350 with no cap` — unit, expects 2.
- `lineCountFor needs two lines at 390 with no cap` — unit, expects 2.
- `lineCountFor needs three lines at 320 with no cap` — unit, expects 3 (320 px is narrower so it wraps once more; the point is it wraps instead of collapsing to one ellipsis line).
- `uncapped headings default to clip, not ellipsis` — default `overflow` is `clip`.
- `at 350 lays out in two lines with no ellipsis` — widget: `didExceedMaxLines` false, plain text has no `…`, `Text.overflow` is `clip`, re-laid `TextPainter` at the rendered width has 2 line metrics.
- `at 390 lays out in two lines with no ellipsis` — same assertions at 390, 2 metrics.
- `at 320 lays out in three lines with no ellipsis` — same assertions at 320, 3 metrics, `didExceedMaxLines` false.
- `maxLines 1 still ellipsizes a long heading` — widget with `maxLines: 1, overflow: ellipsis`: `didExceedMaxLines` true, `Text.overflow` ellipsis, `lineCountFor(..., maxLines: 1)` is 1.

Kept green: `NestBalancedText search` (4 tests) and `P07 title balance`
(`the title keeps two lines of near-equal width`,
`the title breaks after "Nestling"`).

## Verification

- `cd app && dart format .` — clean (0 changed at final pass).
- `flutter analyze` — `No issues found!`, no new ignores.
- `flutter test` (full suite) — all pass (`+1025: All tests passed!`).

## Follow-ups for screens

- P06: no code change needed — the existing uncapped `NestBalancedText` now renders the design's 2 lines. Re-run the P06 UI check; the 34 px upward shift below the h1 should be gone.
- P07: no action — `maxLines: 3` path unchanged.
- All other screens: if you add a capped heading and want `…`, pass `overflow: TextOverflow.ellipsis` explicitly (the default is now `clip`). Uncapped headings must stay uncapped with the default `clip`; do not add `maxLines: 1` to silence a wrap.

VERDICT: PASS
