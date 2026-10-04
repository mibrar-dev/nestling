# K01 · Who's playing? — Stage 4 QA code review (iteration 1)

Reviewed `git diff main...HEAD` for screen K01. Scope checked:
feature-first layering (entity → abstract repo → impl → bloc → view),
RULES.md §1 edit surface, design-system reuse (no hard-coded
colours/sizes/fonts), DESIGN_SPEC §5 K01 copy, accessibility, performance,
error handling, Children's Code. Analyzer clean (`No issues found!`),
all 57 K01-owned tests pass.

## Findings

1. **major** — the failure card's *Try again* cannot recover from a
   profiles-stream failure. `profile_picker_view.dart` dispatches
   `KidHomeLoadRequested`, but `KidHomeBloc._onLoadRequested`
   (app/lib/features/kid_home/presentation/bloc/kid_home_bloc.dart:47-67)
   only re-subscribes and emits `loading` when `_homeSub == null`. In the
   failing case the home subscription is still live, so no loading state
   and no home restart happen; `_ensureProfilesSub()` restarts the
   profiles stream, and `_onProfilesReceived`
   (kid_home_bloc.dart:92-97) emits `copyWithProfiles`, which by design
   never touches `status`. If the failure card was shown because the
   profiles stream errored while `state.child == null` (K01 entry with no
   active child — `watchHome()` emits `KidHomeData(child: null)` when
   `activeChildId` is null, kid_home_repository_impl.dart:43-45), the
   state stays `KidHomeStatus.failure` forever: the watch stream has
   already delivered its value and will not re-emit without a DB write,
   and the only write path (`setActiveChild`) is unreachable behind the
   failure card. The comment at kid_home_bloc.dart:99-105 says a healthy
   emission restores `loaded` "via `copyWithLoaded`", but that requires
   a home-stream emission that is not guaranteed. **Fix:** in
   `_onProfilesReceived` restore the loaded state when the failure was
   caused by the profiles roster, e.g.
   `emit(state.copyWithProfiles(event.profiles).copyWith(status:
   state.status == KidHomeStatus.failure ? KidHomeStatus.loaded :
   state.status))`, and/or have Try again restart the profiles stream
   with an explicit `loading` emit. Add a regression test that drives
   profiles-failure → Try again → profiles-recovery and asserts
   `KidHomeStatus.loaded` without a new home emission.

2. **minor** — `KidHomeState.copyWithProfiles`
   (app/lib/features/kid_home/presentation/bloc/kid_home_state.dart:166)
   carries a stale `errorMessage` through a recovered profiles stream;
   clearing it alongside the status restore in finding 1 keeps the state
   honest for the toast/retry UI that reads `errorMessage`.

3. **minor** — Try again on the K01 failure card shows no spinner when
   the home subscription is still live (the `loading` emit is inside the
   `_homeSub == null` guard, kid_home_bloc.dart:50), so the tapped
   failure card just sits there until the next emission. Folded into the
   finding 1 fix.

## Non-findings (checked, OK)

- No navigation in the bloc; tile tap goes through
  `selectedProfileId` → `BlocListener` → `context.push` with
  `{'childId': id}` extra, matching the K02 contract.
- CHILD ORDER respected: `watchProfiles` in DB creation order, no sort.
- PIP rule respected: per-child `PipAvatar(style/skin/accessory/stage)`
  from the DB row; no `pip_stage_*.svg` in the picker.
- Copy matches the design; the one U+2019 vs ASCII deviation in the HTML
  fixture is a pre-agreed convention (all Dart screens use U+2019).
- No hard-coded colours/sizes/fonts; typography, radii, spacing,
  shadows, tints all from tokens; `NestBalancedText` used for the
  `.kid-title`; no `letterSpacing` additions; no `google_fonts`.
- Bottom-edge rule: no bottom bar on this screen, meadow runs to the
  edge — consistent with the design.
- Lock button → `/parental-gate`, guarded `_busy`; tiles and lock expose
  `SemanticsAction.tap` and tests perform the tap action.
- No `DateTime.now()` in K01 code; no analytics/ads/child-data leakage
  in kid mode; new tests pinned via `test/flutter_test_config.dart`.
- `KidChild.ageBand` added additively; all copyWith/withCompletion*
  constructors carry `profiles`/`selectedProfileId` through.
- The stale `DateTime.now()` hits in K03/today code and the branch
  being behind main are process items, not findings.

VERDICT: FAIL
