# 2b BUILD UI — K02 Kid PIN (`kid_home`, iteration 2, FIXES)

Scope is unchanged: `app/lib/features/kid_home/presentation/views/**` +
`presentation/widgets/**` for K02, and view/widget-named feature tests. The
logic contract from `2a_build_logic.md` still stands (no new CONTRACT
CHANGES).

## FIXES_1.md items — status

| item | source | status |
|---|---|---|
| K02-BUG-1 — emoji-leading nickname throws in avatar initial | 6_bugs/FIXES_1 #1 | **FIXED**: `kid_pin_view.dart` initial is now `String.fromCharCode(nickname.runes.first).toUpperCase()`; the (k02_bugs_test.dart `K02-BUG-1`) proof now runs un-skipped and passes. The cross-feature part of that fix remains a SHARED_REQUEST (item #3) — other features' sites were not touched (outside RULES §1 scope). |
| K02-BUG-2 — greeting clips a 20-char nickname at 320×1.3 | 6_bugs/FIXES_1 #2 | **FIXED**: the say line's `maxLines` is now 3 (was a silent-dropping 2) with a comment; un-skipped K02-BUG-2 proof passes. |
| K02-BUG-3 — no-PIN auto-advance could skip a PIN | 6_bugs/FIXES_1 #3 | **FIXED**: the post-frame callback in the `_noPinHandled` listener now re-reads `KidHomeState.child` via `context.read` and only navigates when the CURRENT child is still a no-PIN child; un-skipped K02-BUG-3 proof passes. |
| K02-BUG-4 — wrong-code toast outlives a successful retry | 6_bugs/FIXES_1 #4 | **FIXED**: the `pinPassed` listener calls `ScaffoldMessenger.of(context).hideCurrentSnackBar()` before `context.go(home)`; un-skipped K02-BUG-4 proof passes. |
| 4_review finding 2 — empty-child edge left 4 filled dots, no dispatch | review | **FIXED**: `_onKey` now reverts the 4th digit (`_entered.removeLast`) when the bloc's child is momentarily null, keeping entry editable and editable-only via Delete. |
| 4_review finding 3 — pill/key shapes not pinned in geometry test | review | **PINNED**: the mark pill's `Container` rect (centre x 195 ±2, height 26 ±2, fully-rounded tint) and all 11 key discs as 72×72 circles are asserted by shape in `kid_pin_view_test.dart`. |
| 4_review finding 4 — `_KidLoading`/`_KidFailure`/`_NoActiveChild` reserved `NestHomeIndicator()` rather than the real inset | review | **FIXED**: all three now use a shared `_BottomInset` widget that reserves `max(viewPaddingOf(context).bottom, NestDevice.homeH)`. |
| 5_ui keypad drift (deviations 1–3) | 5_ui.md | **UNCHANGED MODE**: shared drift only; main now carries the keypad fix — this class also fixed the pitch. The intentional K02 follow-up is applied: `NestKeypad(fit: NestKeypadFit.shrinkWrap)` at the call site, matching `.k2-body`'s centred shrink-wrap; no local key spacing. Caption offset then falls out of the shared grid. |

## Touched files

- `app/lib/features/kid_home/presentation/views/kid_pin_view.dart`: K02-BUG-1 rune initial, K02-BUG-2 `maxLines: 3`, K02-BUG-3 listener re-check, K02-BUG-4 toast hide, review finding 2 digit revert, `_BottomInset` in the three fallback states, `NestKeypadFit.shrinkWrap` on the keypad. No other behaviour change.
- `app/test/features/kid_home/k02_bugs_test.dart`: the four parked `skip: true` proofs for K02-BUG-1/2/3/4 are now un-skipped and ALL PASS — no test was deleted or weakened, and the un-skip was explicitly ordered by this brief.
- `app/test/features/kid_home/kid_pin_view_test.dart`: geometry/shapes group now pins the mark pill rect and the 72×72 key discs (review finding 3); otherwise unchanged from iteration 1's coverage.
- `app/lib/features/kid_home/presentation/bloc/**`, domain/, data/: untouched by this stage (logic builder's contract still matches; no new event/state fields).

## Gates this iteration (app/)

- `flutter analyze` on `lib/features/kid_home` + the two test files I touched → **No issues found**.
- `flutter test test/features/kid_home/kid_pin_view_test.dart` → **46/46 pass**.
- `flutter test test/features/kid_home/k02_bugs_test.dart` → **25/25 pass** (all four formerly-skipped bug proofs included).
- `dart format` clean on all three files.
- Integration (whole-app `flutter test` + simulator + UI check) is the integrator's stage — not run here.

## LEFT FOR NEXT ITERATION

- Nothing in my UI scope. Remaining open items are shared-owned: NestType.kidSay/kidMark (SHARED_REQUEST #1) and the grapheme-safe avatar-initial helper across the other features' seven sites (SHARED_REQUEST #3). The shared keypad-pitch fix is already on main in this tree and was applied at the K02 call site.

VERDICT: PASS
