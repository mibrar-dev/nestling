# 2b BUILD UI — K02 Kid PIN (`kid_home`, iteration 1)

## Contract used (from `1_plan.md` + `2a_build_logic.md`, no changes)

- Event `KidHomePinSubmitted({childId, pin})`; state `pinChecking`,
  `pinWrongNonce`, `pinPassed` (all preserved through the constructor
  family, `copyWithLoaded` resets `pinPassed` only).
- View contract: dispatch on 4th digit from LOCAL entry state; `BlocListener`
  pushes `KidHomeRoutePaths.home` on `pinPassed` false→true; on
  `pinWrongNonce` bump clears entry + `showNestToast("That didn't work.
  Try again.")`; no-`pinSet` child (Leo) auto-advances once without a
  dispatch; `verifyPin` never called for Leo (repository auto-passes).

## UI items implemented (`presentation/views/kid_pin_view.dart`)

- `KidScope` (shared sky gradient + meadow hills to the edge) →
  `Scaffold(transparent)` → `Column`: `NestStatusBar`, top bar
  `Row(0,20,0,6)` with back `NestIconButton` (56, transparent bg/border,
  iconSize 26, semantics `Back`, deep-link-safe `canPop?pop:go(picker)`)
  and `NestLockButton` `Grown-ups` (busy-guarded 20-line copy of K03's
  `_GateLockButton`), then `Expanded` → `ListView` (pad 20/0/20/32):
  - Avatar: `Container(128, circle, lilacTint)` centred `NestAvatar(s96,
    lilac)`, `initial = nickname[0].toUpperCase()`.
  - `.k2-hi` column: mark pill `Container(lilacTint, pill, pad 2/12)` +
    `Text('NESTLING', Nunito 900 16/22, ink, letterSpacing: 1.28)` — TODO
    cites `SHARED_REQUEST #1` (`NestType.kidMark`) since the shared scale
    doesn't exist yet; then say `Hi {nickname}! Enter your secret code`
    (Nunito 800 20/26, ink, center, `margin-top: 2` → `SizedBox(gap2)`,
    maxLines 2) with TODO citing `SHARED_REQUEST #1` (`NestType.kidSay`).
  - `NestPinDots(total: 4, filled: entered)` — label-only; while awaiting
    the dots announce `Checking your code` (wrapper Semantics), otherwise
    the free `N of 4 entered` label stands.
  - `NestKeypad(onKey, onDelete, kid: true)` — TODO cites the
    07:13 ORCHESTRATOR_NOTES shared keypad-pitch fix (no local re-spacing).
  - Caption `Forgot it? Just ask a grown-up.` (`NestType.kidCaption`).
  - Trailing `SizedBox(MediaQuery.viewPaddingOf(context).bottom)` so the
    meadow shows through to the physical edge (BOTTOM EDGE owner rule).
  - Local state: `_entered` (≤4), `_awaiting` guard so a mid-check emit
    cannot desync the keypad; 4th digit dispatches `KidHomePinSubmitted`.
  - `BlocListener`s: `pinPassed` → `context.go(home)`; `pinWrongNonce`
    bump → clear `_entered`/`_awaiting=false` + toast.
  - No-`pinSet` child → postFrame `go(home)` once; loading UI meanwhile;
    no active child → `_NoActiveChild` (`Who's playing?` + `Choose` →
    picker); failure → K03 `_KidFailure` copy verbatim + `Try again`
    re-adds `KidHomeLoadRequested`; loading → K03 `_KidLoading` pattern
    with `Loading your secret code`.
- No local hills/meadow, no hard-coded colours; tokens (`context.nest`) +
  `NestSpacing`/`NestDevice` only. Dark mode: same tree, tokens flip.

## Tests (`app/test/features/kid_home/kid_pin_view_test.dart`, mine)

- Layout matrix light/dark × 320/390/430 × scale 1.0/1.3: copy, no `£`,
  no-overflow, loader-wrapped font metrics.
- Geometry (390/light, real fonts): avatar disc rect 128 at ~131/109,
  mark text 16/ls 1.28, four 18px dot circles in the dots row.
- Semantics: Back/Grown-ups/Digit N/Delete all have `SemanticsAction.tap`;
  digit `performAction` fills a dot; dots free label carries no tap action.
- Flows: correct `1234` → `/kid-home`; wrong `9999` → toast + cleared dots
  + still `/kid-pin`, retry works; 5th digit ignored; delete-on-empty no-op;
  back-to-back 4th-digit taps → one verify call; Leo (no PIN)
  auto-advances; `Seed`-less active child → chooser → `/who-is-playing`;
  hanging stream → loading label; broken stream → failure card → `Try again`
  recovers. `disposeApp` after every pump; pinned clock inherited.

## Notes / left for next iteration

- 5 `info`-level analyzer nits live in `kid_home_bloc_test.dart` (the
  LOGIC builder's file): leading underscored locals + one unneeded type
  annotation. Phase-out belongs to 2a.
- The keypad pitch should be re-checked against the design once the
  shared keypad-grid fix lands on main (ORCHESTRATOR_NOTES 07:13).
- `NestType.kidSay` / `NestType.kidMark` (SHARED_REQUEST #1) are TODOed
  at the call sites with local metric-matched styles until shared.

## Verification this iteration

- `flutter analyze lib/features/kid_home/presentation/views/kid_pin_view.dart`
  → No issues found.
- `flutter test test/features/kid_home/kid_pin_view_test.dart` → 22/22 pass.
- `dart format` clean on both files (2 changed on first pass, now formatted).
- Full `flutter test` + simulator checkpoints belong to the integrator stage.

VERDICT: PASS
