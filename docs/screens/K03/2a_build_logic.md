# K03 Kid home — Stage 2a logic chunk (iteration 13)

Scope: non-UI layer of `kid_home` only (domain/**, data/**,
presentation/bloc/**, DI/route registration, bloc/repository/data tests).
No edits to `presentation/views/**` or `presentation/widgets/**`. No
state/event shape changes this iteration — **no CONTRACT CHANGES**.

## Files changed

None in `app/` this iteration — the logic layer is complete and green, and
FIXES_12 contains nothing actionable in it (see below). This file is the
only write.

## FIXES_12 items in my layer

FIXES_12 holds a single item — K03-BUG-16 (Major, shared): the pet hero art
sits ~9–10 px above the design because the shared `NestPetStage` lays the
bubble→pet gap out as `NestSpacing.s2` (8) where the design's `.k3-pet` has
`margin: 14px auto 0` (SHARED_REQUEST #18). The fix is a shared-component
change (`NestPetStage` bubble→pet gap, core — which I must never edit)
plus view call-site updates (`bubbleGap: 14`, `_kStageToHearts` revert —
views, owned by the UI builder). Nothing in domain/data/bloc can move a
pixel, so there is no logic-side fix.

The skipped proof (`K03-BUG-16` in `app/test/features/kid_home/k03_bugs_test.dart`)
is a widget/UI test, not one of my owned files (names containing `bloc`,
`cubit`, `repository`, `data`), and its skip is load-bearing: it holds the
design values (rim y 278) so the defect cannot silently re-base. Un-skipping
it here would fail by design (app renders 269 until #18 lands) and touching
`k03_bugs_test.dart` would cross into the UI builder's file. Left skipped
for the shared fix + UI builder, per the "only the items in your layer" rule.

## Orchestrator mandatory items (logic side) — verified already in place

- PERIODS (K03-BUG-4): `_watchItemsFor` and `completeQuest` scope completions
  via `countsForCurrentPeriod(repeatRule, createdAt, now, zone)` from
  `family_time.dart` (the zone-aware form of the `london_time.dart` ruling;
  zone normalises to the family zone with London fallback). Stale-period
  completion ⇒ quest is "to do" again; writes store `createdAtTz`.
- CHILD ORDER: profiles stream straight from `watchChildren` (creation order,
  Maya then Leo — never re-sorted); quest items sorted alphabetically by
  title per the plan (data order wins).
- CLOCK: `appNowUtc()` only; no `DateTime.now()` in the feature.
- IDS: completions use autoincrement DB ids (no clock-derived ids); no new
  rows with hand-rolled ids in this feature.
- No `google_fonts` / `GoogleFonts.*` in domain/data/bloc or my test files;
  no letter-spacing touches; `nestAvatarInitial` is view-side (not my layer).

## Verification

- `dart format --set-exit-if-changed` on domain/data/bloc +
  `kid_home_bloc_test.dart` + `kid_home_repository_test.dart` — 0 changed.
- `flutter analyze lib/features/kid_home` — No issues found.
- `flutter test --timeout 120s test/features/kid_home/kid_home_bloc_test.dart
  test/features/kid_home/kid_home_repository_test.dart` — All tests passed
  (40/40). Full-suite run and simulator are the integrator's.

## LEFT FOR NEXT ITERATION

- Nothing open in my layer. K03-BUG-16 awaits the shared bubble→pet gap fix
  (#18) + UI-builder call-site update; no logic change will be needed.

VERDICT: PASS
