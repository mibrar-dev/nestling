TASK — close the open kid-screen bugs from docs/screens/_shared/BACKLOG.md (shared/kid_bugs). Each bug has a skip-marked failing proof in its screen's bugs test (grep the bug id): fix the code, UN-SKIP the proof, keep it green.

1. K09-BUG-10 (kid_jar `_relativeDay`): same London day → "Today"; previous day → "Yesterday"; current London week → "This <weekday>"; previous week → "Last <weekday>"; older → a dated label (e.g. "Sat 19 Sep", UK format, family zone); future-dated rows never claim a day ("Coming up" + date, or exclude from history — pick the one consistent with K09/K10 designs and say why).
2. K09-BUG-9: large history amounts never overflow at 320 px × 1.3 (wrap or scale the amount column; no clipping).
3. K09-BUG-8: `moveToSavings` with no goal writes nothing (or throws a typed error the bloc shows) — money never leaves the jar to nowhere.
4. K09-BUG-7/7b and K10-BUG-1: a load/payout request and `close()` in the same tick never leaks a subscription or throws (guard with isClosed / cancel in close()).
5. K10-BUG-2: a goal saved past its target shows 100% (not 142%), "£0.00 to go" replaced by the design's reached state if one exists, else "Goal reached!".
6. K10-BUG-4: the fund-card heading wraps instead of clamping a long goal name at 320 × 1.3.
7. K05-BUG-5: a 4-digit lifetime count fits (no ellipsis) at 320 × 1.3; K05-BUG-6: the progress node's semantics value matches its label.
8. K07-BUG-10: if any of the three stat numbers is wider than its card, scale all three by ONE shared factor (FittedBox over the row of numbers, or measure and apply one scale) so they stay equal size; no clipping. Geometry at 390 / 1.0 unchanged.
9. K05/K06 growth percentage: K06 `PipGrowthCard` floors like K05 (K05-BUG-2) so both screens always agree; test both with 175/250 and 249/250.
10. K01-BUG-7: an orphaned selected child (deleted) never locks the tiles on Who's playing — clear the selection when the child no longer exists.
11. K02: delete the feature-local `kidAvatarInitial` (kid_style_helpers.dart:65) and use the shared `nestAvatarInitial` everywhere (kid_pin_view.dart:168 + tests).
At 390 px / text 1.0 no screen may move: for K01, K02, K05, K06, K07, K09, K10 run tools/screens/shot.sh + compare.py light+dark on simulator 604697A9-11DA-462F-9837-396E9CA2493A ONLY (seed per docs/screens/SCREENS.tsv) and report each mean diff vs its last accepted cmp in docs/screens/<ID>/ui/ (must be within ±0.2). Do NOT touch app/lib/core/design_system or app/lib/app (another agent owns them). `cd app && flutter analyze` + `flutter test --timeout 120s` FOREGROUND, all green. Commit. Report docs/screens/_shared/kid_bugs_REPORT.md ending `VERDICT: PASS|FAIL`.
