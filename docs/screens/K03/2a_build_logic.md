# K03 Kid home — Stage 2a logic chunk (iteration 9)

Scope: non-UI layer of `kid_home` only. No edits to
`presentation/views/**` or `presentation/widgets/**`. No state/event shape
changes this iteration — **no CONTRACT CHANGES**.

## Files changed

- `docs/screens/K03/SHARED_REQUEST.md`: new entry #16 (review findings
  1+2, one batch): (a) nest art-box/aspect independence in
  `PipNestFallback` — `BoxFit.fill` into the 236×156 stage box stretches
  the bowl to 0.661 vertical (rim 38→25 px, widest row +26 px, identical in
  dark), arithmetically unreachable from K03, with the exact numbers and the
  `nestH ≈ 214` vs `stageH = 236` conflict recorded; (b) shared-card 6 px
  bottom padding stacking with the 12 px `.k3-quests` gap (18–19 px painted
  rhythm vs 12–13). Per `ORCHESTRATOR_NOTES` 09:52 no local pet-block change.

## FIXES_8 items in my layer

- Finding 1 [major] nest stretch — shared cause (`pip_rive.dart`
  `BoxFit.fill` + mandated call); filed as #16a above. No K03-side fix
  exists or is attempted.
- Finding 2 [minor] card rhythm — shared cause (in-card 6 px shadow
  padding); filed as #16b above. No local compensation (would
  double-correct once core lands).
- Finding 6 [minor] `switchMapStream` in domain — no action (SHARED_REQUEST
  #14 already carries it; helper stays tested in place).
- Findings 3 (geometry pin), 4 (meadow painter), 5 (`844` constant) —
  views/geometry-test layer, UI builder's. Not touched.
- Skipped tests: zero in the feature (`grep skip:` clean); BUG-13/14 stay
  un-skipped-and-passing after the shared pet-stage batch, BUG-15 green in
  both files. Nothing to un-skip in my layer.

## Verification

- `dart format --set-exit-if-changed` on domain/data/bloc +
  `kid_home_bloc_test.dart` — 0 changed.
- `flutter analyze` on the same scope — No issues found.
- `flutter test test/features/kid_home/kid_home_bloc_test.dart` — 31/31.
- No `google_fonts` in my files; no letter-spacing touches; period/copy
  logic untouched. Full-suite run and simulator are the integrator's.

## LEFT FOR NEXT ITERATION

- Nothing open in my layer. Shared #13/#14/#16 (+ card rhythm) await the
  orchestrator; pet/meadow/card-gap UI work belongs to the UI builder.

VERDICT: PASS
