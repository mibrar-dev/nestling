# 2a BUILD LOGIC — K02 Kid PIN (`kid_home`, iteration 1)

## CONTRACT CHANGES

None. Event/state names are exactly per `1_plan.md` §(b), which the UI
builder codes against:

- Event: `KidHomePinSubmitted({required childId, required pin})`
- State: `pinChecking=false`, `pinWrongNonce=0`, `pinPassed=false`
- View contract: dispatch on 4th digit; `BlocListener` pushes
  `KidHomeRoutePaths.home` on `pinPassed` false→true; on a `pinWrongNonce`
  bump clears entry + `showNestToast("That didn't work. Try again.")`.
  No-PIN child (`child.pinSet == false`) auto-advances without dispatching.

## Files changed (logic layer only — no views/widgets touched)

- `app/lib/features/kid_home/presentation/bloc/kid_home_event.dart`
  - Added `KidHomePinSubmitted({childId, pin})` (Equatable props cover both).
- `app/lib/features/kid_home/presentation/bloc/kid_home_state.dart`
  - Added `pinChecking`, `pinWrongNonce`, `pinPassed` (defaults
    `false`/`0`/`false`); added to `props`.
  - `copyWith` accepts all three; every other constructor
    (`copyWithSelection`, `copyWithSelectionHandled`,
    `withCompletionStarted/Failed/Succeeded`, `copyWithProfiles`,
    `copyWithProfilesRecovered`) carries them through.
  - `copyWithLoaded` preserves `pinChecking`/`pinWrongNonce` and resets
    `pinPassed=false` (one-shot consumption, mirrors
    `justCompletedQuestId`).
- `app/lib/features/kid_home/presentation/bloc/kid_home_bloc.dart`
  - Registered `on<KidHomePinSubmitted>(_onPinSubmitted)`; handler ignores
    re-entry while `pinChecking`, emits checking, awaits
    `repo.verifyPin`, builds the outcome from the state at completion time
    (interleaved stream emission cannot swallow it). Repository throw reads
    as the wrong path (nonce bump, list kept, no failure card).
- `app/test/features/kid_home/kid_home_bloc_test.dart`
  - Fake: `correctPin='1234'`, `failVerify`, `verifyGate` (mid-check
    re-entry/interleave tests), `verified` call record.
  - New `K02 PIN` group, 9 tests: correct→checking→passed; wrong→nonce 1
    + list kept; two wrongs→nonce 1,2; wrong-then-correct passes;
    throw→wrong path; mid-check re-submit ignored (1 verify call);
    interleaved emission preserves list AND outcome; next emission consumes
    `pinPassed` not the nonce; constructor carry-through + equality.
- `app/test/features/kid_home/kid_home_repository_test.dart`
  - New `K02 PIN verification` group (DB-backed, Seed.demo): Maya accepts
    `1234`, rejects `9999`/`''`; Leo (null hash) auto-passes any code.

No DI / route / schema / seed change (plan §(b): `verifyPin` and
`child.pinSet` already exist; route already provides the bloc). No domain
or data change needed. No shared touch — no `SHARED_REQUEST`.

## Items done (plan §(b), all)

1. `KidHomePinSubmitted` event — done.
2. State fields + `copyWith` threading + `withCompletion*` preservation +
   `copyWithLoaded` consumption semantics — done.
3. Handler with re-entry guard, catch→wrong path, completion-time state —
   done.
4. Bloc + repository tests for the PIN paths — done (52/52 pass across the
   two owned files; `flutter analyze lib/features/kid_home` → No issues
   found; `dart format` clean).
5. No `google_fonts`, no `DateTime.now()` in touched files; clock N/A (no
   dates on this screen).

## LEFT FOR NEXT ITERATION

- Nothing in the logic layer. UI builder owns the view per plan §§(a,c–e)
  and `kid_pin_view_test.dart`; integrator owns full `flutter test`,
  screenshots, and the UI check.

VERDICT: PASS
