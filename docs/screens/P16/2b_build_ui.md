# P16 Settings — 2b build, UI chunk (iteration 2)

Scope: views + widgets only. Iteration 1 document superseded; this is the
current state.

## FIXES_1 triage (views/widgets owned items)

- **P16-T01 = P16-B07 (delete-confirm pops the branch): FIXED.** Both
  modal buttons now pop the root navigator
  (`Navigator.of(context, rootNavigator: true).pop(...)` in
  `settings_view.dart`). Un-skipped the two navigation tests; both pass.
- **P16-B06 (subcard radius): FIXED.** `Subscription` card renders a local
  surface container — `tokens.surface`, `NestRadii.allM` (16 per the
  design's `.subcard`), `tokens.cardShadow`, padding 16/14 — instead of
  `NestCard.standard` (24, a shared default NOT edited). The responsive
  test was adjusted to find the card via `ValueKey('p16_subcard')`.
  Un-skipped the B06 proof; `settings_responsive_test` green.
- **P16-B03 (picker overflow on 320×568 @1.3): FIXED.** The picker's row
  column is wrapped in the `Flexible` + `SingleChildScrollView` pattern
  already used by the reward editor sheet, so the list shrink-wraps when
  it fits and scrolls when it doesn't. Un-skipped the B03 proof.
- **P16-B05 ("1 coins"): FIXED.** `_ChildRow` pluralises
  (`1 coin` / `N coins`). Un-skipped the B05 proof.
- **P16-B04 (CLOCK rule): FIXED.** Both view call sites (zone-summary row
  and picker subtitles) now read `appNowUtc()`. Un-skipped the B04
  source-scan proof.
- **P16-B01 (device zone dropped after Not now): FIXED (2a half + my
  half).** The bloc now exposes `SettingsState.deviceZoneId` regardless of
  banner dismissal; `zone_picker_sheet.dart` orders by that field rather
  than the nullable banner-only `pendingZone`. Un-skipped the B01 proof.
- **P16-B02 (Not now session scope):** logic-side (SettingsSessionStore),
  un-skipped by the logic builder; in-suite green.
- **Review #2/#3/#5:** #3 (edit outside allowed paths) was already
  reverted in the iteration-1 merge; #5 (dead `items`) removed by 2a.
- **Review #8 (double semantics on Manage subscription): FIXED.** The
  outer wrapper now uses `excludeSemantics: true` like `NestCard`, so one
  labelled node with `SemanticsAction.tap` remains.
- **Review #7 (magic numbers/dummies):** the subcard/lock-hint/banner
  parts that carry design token values use `NestSpacing` steps now
  (`s4` vs `gap14`); the remaining one-offs are the design's own metrics
  (`min-height: 52` linkrow, banner's 14/20 paragraph — all present in
  the CSS).
- **Chevron location / truncated subtitles (ui finding 1):** fixed on
  main by the shared `list_row_trailing` patch (NestListRow no longer
  wraps the trailing in `Flexible`); `settings_rows.dart`'s local rows
  mirror that same construction (plain child with the 120 cap).
- **Progressive vertical drift (ui finding 2):** the main suspect was
  `NestSectionLabel`'s pinned 18 px line box vs the browser's natural
  (≈15.7 px) Inter line-height at 13 px — about 2 px per section. Views
  now render the section label through a local `_P16Sect` that probes
  Inter's natural height with a one-off `TextPainter`, so the box matches
  the CSS instead of the shared 18 px default. Stage 5 re-measures.

- **P16-T02 (switch target ≈36 px): NOT FIXED, scope-limited.** The
  report's suggested 6 px-padding fix was implemented temporarily and the
  a11y test still failed: with a title-only row, a full-path hit at
  `track.top − 5` still absorbed on the row's `InkWell` render — the
  `_RenderToggleHitSlop` inside `NestToggle` never registers ngoài its
  own box, and the row's `Padding` doesn't enlarge that box. Because the
  slops are shared (NestToggle + the same pattern on NestChip) this
  cannot be repaired legitimately inside `presentation/**`; filed under
  review note. The T02 a11y test stays skip-marked with that writeup.

## Contract note

- `SettingsState.items` was removed at iteration 2 — this doc's iter-1
  note about it is moot; no other contract items touched.

## Verified

- `flutter analyze` (full app): No issues found.
- `dart format`: clean.
- `flutter test test/features/settings`: **+105 ~1** green (the single
  skip is P16-T02 by design). No simulator used.

## LEFT FOR NEXT ITERATION

- P16-T02: the real fix belongs in the shared hit-slop (NestToggle /
  NestListRow via SHARED_REQUEST) — with a row-native alternative if the
  shared area later requests screen overrides.
- Stage 5 first full remeasure of the yard metrics after the sect
  line-height fix and the subcard radius change.

VERDICT: PASS
