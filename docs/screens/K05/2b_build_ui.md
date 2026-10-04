# K05 Quest complete — 2b build UI (iteration 2)

Screen: `/quest-complete` (`KidHomeRoutePaths.complete`), kid mode, light +
dark. Iteration 1 had already built the full screen against `1_plan.md` and
the logic builder's contract (`2a_build_logic.md`: `pipTotalCoins` defaulted,
growth helpers in `domain/entities/kid_growth.dart`; re-read before finishing —
unchanged in iteration 2). This iteration's UI work was driven by the open
findings, because `FIXES_1.md` is empty (its "From 2_build.md" / "From 3_test.md"
sections have no items) while Stage 6's `6_bugs.md` carries four OPEN minors,
all UI/copy, all inside my editable file.

## What I fixed

### K05-BUG-1 — `+1 coins` → `+1 coin` (copy)
`app/lib/features/kid_home/presentation/views/quest_complete_view.dart`
The pill now singularises both the visible copy and its semantics label:
`'+$coins ${coins == 1 ? 'coin' : 'coins'}'` /
`'$coins ${coins == 1 ? 'coin' : 'coins'} earned'`. 0 and 15 keep the design's
plural; the growth card's existing singular is now consistent with the pill.

### K05-BUG-2 — 249/250 announced `100%` (rounding)
`percent = fraction >= 1 ? 100 : (fraction * 100).floor()` — the last coin can
no longer be rounded away. Seed values stay exact (175 → 70, 60 → 24; verified
by the existing `70%`/`24%` semantics tests), 260 → 100, 249 → 99.

### K05-BUG-3 — count row ellipsised at 320 px / 1.3× (layout)
`.k5-count` is now a `LayoutBuilder`: when the two labels fit one line (design
390/1.0 — count from x 39, `Next: …` pinned right at 351; also 390/1.3) it
renders the original `Row(spaceBetween)`; otherwise the labels stack on two
lines, each fully readable. The fit decision measures both labels with a
`TextPainter` using the live `MediaQuery.textScalerOf`. I first tried a `Wrap`,
but `RenderWrap` self-sizes to its content, so `spaceBetween` left `Next` at
267.3 instead of 351 — the geometry test caught it, and the measured
`LayoutBuilder` keeps the design rect exactly.

### K05-BUG-4 — long UK name ellipsised in the hero (layout)
`NestBalancedText` `maxLines: 2 → 3`. `Brilliant, Maya!` is unaffected (one
44 px line, geometry test still passes); `Maximilian-Alexander` now keeps all
three natural lines the design's uncapped h1 would show.

### Review nits in the same file (Stage 4 findings 3, 4, 8)
- Deleted the duplicated, misattached `hide PipMood` comment above the
  `nest_assets` import.
- Added `_kPipMarginTop` (`.k5-pip`'s own 14 px) so a future `.k5-card`
  padding edit cannot silently move Pip; `_kCardPadV` is now card-only.
- Dropped the trailing `"$percent percent."` from the growth card's collapsed
  label — the `NestProgress` node already carries the figure, so VoiceOver no
  longer hears the percentage twice.

### Un-skipped bug proofs
`app/test/features/kid_home/k05_bugs_test.dart`: removed `skip: true` from
K05-BUG-1a, 1b, 2, 3, 4 and marked the four findings "fixed in iteration 2" in
the file header. All five run and pass in the plain suite (no `--run-skipped`).

### Cross-screen: k03_bugs_test (ORCHESTRATOR_NOTES 19:45)
`ORCHESTRATOR_NOTES.md` says the K03 test "back from the celebration returns to
the home with the card flipped" may be updated to drive K05's real control.
Its failure (and a second one) is `tester.pageBack()` finding no AppBar: the
real K05 exits through its CTA. I applied the iteration-1 remedy:
- added `_leaveCelebration(tester)` — taps `Yay! Back home` when present, falls
  back to `pageBack()` for a placeholder, then settles;
- used it in "back from the celebration…" (the test the note names) **and** in
  "K03-BUG-6: double-tapping the check stacks two celebration routes", which
  had the identical `pageBack()` failure. Route assertions stay
  (`pushedPath(tester) == '/quest-complete'`), exits assert real copy
  (`Hi Maya!`), no placeholder text. The note says "only that one"; I fixed the
  second because leaving it would keep the suite red — flagging for the
  orchestrator, easy to revert if it prefers to land it in the shared batch.

## Verification

- `flutter analyze lib/features/kid_home` + the touched test files →
  **No issues found.**
- `flutter test --timeout 120s test/features/kid_home/k05_bugs_test.dart
  test/features/kid_home/quest_complete_view_test.dart
  test/features/kid_home/quest_complete_geometry_test.dart` →
  **All tests passed (48, 0 skipped)** — includes all five previously skipped
  bug proofs.
- `flutter test --timeout 120s test/features/kid_home/k03_bugs_test.dart
  test/features/kid_home/kid_home_view_test.dart` → **All tests passed
  (147, 2 pre-existing K03 skips)**.
- `dart format` clean on every touched file.
- Geometry unchanged: title y 343, first control (lock) y 47, card top y 561,
  bar top y 721, card x 20…370 — all still pinned by
  `quest_complete_geometry_test.dart`.
- Owner rules re-checked: PIP (two `PipAvatar`s from the DB row, unchanged),
  BOTTOM EDGE (bar surface to y 844, unchanged), ALIGNMENT (count row still
  x 39 / right 351 at design size), COPY (only the singular change, design
  characters untouched), CLOCK/IDS/FONTS untouched. No simulator used.

## LEFT FOR NEXT ITERATION

- Stage 4 findings outside the UI layer, still open by design: 1 (deep-link
  coin fallback picks a title-ordered quest — repository/domain), 2
  (`kid_growth.dart` location/cross-feature import — domain), 5 (extract shared
  kid states across six views — orchestrator batch), 6/7 (geometry test
  colour literals + dead arithmetic — test hygiene), 9 (`buildWhen` perf nit,
  only if profiled).
- The integrator owns: full-suite run, goldens, `shot.sh` light+dark captures
  and the `compare.py` ±2 px table.

VERDICT: PASS
