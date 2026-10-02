# P02 Value tour — build notes (Stage 2, iteration 4)

Implemented per `docs/screens/P02/1_plan.md`, the mandatory
`docs/screens/P02/ORCHESTRATOR_NOTES.md`, the COPY / CHILD ORDER /
bottom-edge / alignment owner rules, and every item in
`docs/screens/P02/FIXES_3.md` (review findings 1–7 + P02-BUG-10a/b/c).

## Files changed (this stage)

- `app/lib/features/onboarding/presentation/widgets/value_tour_preview_row.dart`:
  new `ValueTourFitText` — single-line text that fits its slot without ever
  painting below 0.92× of its style size (`LayoutBuilder` slot vs
  `TextPainter` natural width at the ambient scaler; `FittedBox(scaleDown)`
  while `slot/natural ≥ 0.92`, else full-size ellipsis). Title slot uses it;
  row doc updated (permanent P02 row; tint-switch duplication deliberate —
  the mapping lives in shared code this feature may not edit). Wrapping is
  deliberately NOT the fallback: wrapped rows would overflow the spec-fixed
  400dp pager under the wide widget-test font, and card 2 has no room for a
  second caption line at any width — the review sanctions ellipsis as the
  full-size fallback, and there is no room (notes-3 qualifier).
- `app/lib/features/onboarding/presentation/views/value_tour_view.dart`:
  card-2 caption uses `ValueTourFitText` (identical pixels at 390dp —
  ratio 1.13 renders 1.0); `_headChip`/`_chipMaxW`/`_dateChipLabel` moved
  from `_ValueTourViewState` statics to file-private top level (review 6).
- `app/test/features/onboarding/p02_bugs_test.dart`: BUG-10a/b/c un-skipped
  (read 1.0 by construction on the fallback path — verified passing);
  BUG-2 rewritten font-robust (no `NestListRow` in card; 36dp tiles via
  `NestIcon` ancestors; row `spacing == s2`; row height == max(tile, text
  lines) ±0.5); header comments updated.
- `app/test/features/onboarding/value_tour_view_test.dart`: vacuous
  `didExceedMaxLines == false` test replaced with "starved titles keep full
  size and ellipsise" (no `FittedBox` ancestor, `didExceedMaxLines == true`,
  15dp style at 320dp × 1.3).
- `docs/screens/P02/SHARED_REQUEST.md`: item 4 marked DONE (orchestrator
  rewrote the shared push/pop contract to router locations — full suite
  green); new item 5 (chip border-box; `gap9` stays until it lands).
- Screenshots: `ui/app_light_5.png`, `ui/app_dark_5.png`, `ui/cmp_light_5.png`,
  `ui/cmp_dark_5.png` (step 1, sim 16e, fresh seed; both frames stable).

## Fix items (FIXES_3 → state)

- Review 1 / BUG-10 (unbounded shrink): bounded via `ValueTourFitText`;
  proofs read 1.0 (fallback path); device 390 unchanged (0.96 fit path).
- Review 2 (vacuous tests): BUG-7 proof already replaced by BUG-10 (bugs
  stage); contract test replaced as above.
- Review 3 (stale doc/duplication): doc updated as permanent + deliberate.
- Review 4 (chip border): shared request filed (item 5); `gap10` restore
  pending its landing (card 2 would overflow by 1px today).
- Review 5 (caption maxLines): same bounded rule (fit-or-ellipsis, no room
  to wrap); device pixels unchanged.
- Review 6 (state-owned statics): moved to file-private top level.
- Review 7 (PopScope deep link): confirmed intended — in-flow and cold
  deep-link back both land `/welcome` (onboarding entry, never exits
  mid-flow); documented here as requested.
- COPY/CHILD ORDER/bottom-edge/alignment: unchanged, still compliant
  (character audit, illustration order, bar-surface edge, 20px gutters).

## UI verification (sim 16e, `shot.sh` + `compare.py`, step 1)

- Light mean diff 4.00% → **3.91%**; dark **3.83%** (unchanged). Full titles
  incl. `Empty the dishwasher`, design copy/chip/subs, curly body, 400dp
  pager geometry, dots/title/CTA rows, Skip on the 20px gutter — confirmed
  on pixels. Residual bands 1–3 are font-raster detail only.

## Verification (in `app/`)

- `dart format .` — clean (0 changed on final pass).
- `flutter analyze` tail: `No issues found!`
- `flutter test` (full) tail: `00:12 +641: All tests passed!` (0 failed,
  0 skipped — includes the 3 un-skipped BUG-10 proofs and the orchestrator's
  rewritten push/pop contract).

VERDICT: PASS
