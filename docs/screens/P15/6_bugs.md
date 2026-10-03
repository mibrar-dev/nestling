# P15 · Child profile — bug hunt (Stage 6, iteration 2)

Route `/child-profile` (`FamilyRoutePaths.childProfile`) · feature `family` ·
parent mode · designs `design/screens/{light,dark}/P15-child-profile.png` ·
tree tested: iteration-2 checkpoint **`31a44b8`** ("P15: checkpoint after
build (iteration 2)"), main merged through `17a21b6`.

Sources re-read: `docs/screens/RULES.md`, `docs/ARCHITECTURE.md`,
`docs/DESIGN_SPEC.md` §5 P15, `docs/design/SPACING_SPEC.md`, `1_plan.md`,
`2_build.md`, `FIXES_1.md`, `SHARED_REQUEST.md`, `ORCHESTRATOR_NOTES.md`
(exists — all four items mandatory and re-checked below), plus the
iteration-2 sources (`family_repository_impl.dart`, `family_routes.dart`,
`family_bloc.dart`, `family_state.dart`, `child_profile_row.dart`,
`child_profile_body.dart`, `child_profile_copy.dart`, `child_profile_view.dart`).

Method: iteration 1's six proofs are un-skipped and green (regression guards);
the adversarial pass for this iteration re-probed every fixed area, then
targeted the new code — the deep-link selection, the remove cascade, the
injectable clock and the new P15-local `ProfileRow`. Every red probe is
written as a skipped proof in `app/test/features/family/p15_bugs_test.dart`
with its bug id, so this stage adds no red to the suite.

**Result: iteration-1 bugs all verified fixed; 1 NEW major bug (P15-BUG-9).**
**VERDICT: FAIL** (the brief's PASS bar is "no major bugs").

| Id | Iteration-1 status | Independent evidence on `31a44b8` |
|---|---|---|
| P15-BUG-1 (major) | **FIXED** | `?childId=` selects on the first navigation (`P15-BUG-1a/b` green); probes A2/A3 show the URI and the first deep link work — see P15-BUG-9 for the repeat case |
| P15-BUG-3 (minor) | **FIXED** | clear-then-raise re-emits both failures (`P15-BUG-3` green; test stage's state-level proof green) |
| P15-BUG-6 (major) | **FIXED** | `removeChild` cascade: no dependent row survives (`P15-BUG-6` green; probe J: no approval rows outlive the child; family-wide quests survive per the test stage's proof) |
| P15-BUG-7 (major) | **FIXED** | `active_child_id` repointed to the first remaining child (`P15-BUG-7` green) |
| P15-BUG-8 (major) | **FIXED** | injectable clock follows the pinned anchor (`P15-BUG-8` green); explicit-clock seam covered by the test stage's file |
| P15-BUG-9 (major) | **NEW** | repeat `?childId=` navigation is ignored while the Family branch page is alive — below |

The parallel stages' iteration-1 findings are also closed: the test stage's
P15-BUG-2 (double failure report), P15-BUG-4 ("Pip is a Egg") and P15-BUG-5
(`NestListRow` starvation) proofs are green, and `5_ui.md` (iteration 2)
PASSes with every band within ±2 px and the icons/subtitles fixed.

---

## P15-BUG-9 — major — a later `?childId=` is ignored while the Family branch page is alive

**Repro (user paths).**

1. Open the Family tab (`/child-profile`), then switch to Today and tap
   **Leo's** card. P15 shows **Maya** (the previous selection); the router URI
   says `?childId=leo`.
2. From Today, tap **Leo's** card, switch back to Today, tap **Maya's** card.
   P15 still shows **Leo**.
3. Router-level: `go('/child-profile?childId=leo')`, then
   `go('/child-profile?childId=maya')` — still Leo.

This is the common in-app flow: once the parent has looked at the Family tab
(or any child profile), every later kid-card tap on Today opens the *previous*
child's profile — wrong-child personal data, the same harm class as
iteration 1's P15-BUG-1.

**Evidence (probes on `31a44b8`, real Drift + shell).**

* probe-A: `go('/child-profile?childId=leo')` → Leo ✓; then
  `go('/child-profile?childId=maya')` → rendered child still `leo` ✗.
* probe-A2 (diagnostic): after the second `go`,
  `GoRouter.state.uri.queryParameters['childId'] == 'maya'` **but** the
  rendered `ChildProfileBody.profile.child.id == 'leo'` — the router knows the
  new id; the screen never hears it.
* probe-A3: start on `/child-profile` (Maya), tab to Today, tap Leo's card →
  still `maya` ✗ (the deep link is ignored even on its first use, if the
  branch page already exists).
* probe-B (full user path): Leo card → tab Today → Maya card → still `leo` ✗.

**Root cause.** `family_routes.dart:42-50` dispatches `FamilyChildSelected`
inside `BlocProvider.create`, which runs **once per route page**. With
`StatefulShellRoute`, the Family branch page stays alive; a later
`go('/child-profile?childId=…')` updates that existing page in place (same
route/page key), so `create` does not re-run and the new query never reaches
the bloc. The repository side is fine: `selectChild` and `_pendingSelection`
work whenever they are called (probes G/H green).

**Failing tests.** `p15_bugs_test.dart` → `P15-BUG-9a` (Family tab first, then
Leo's Today card) and `P15-BUG-9b` (Leo, then Maya). Both RED on `31a44b8`,
currently `skip: true` so the suite stays green until the build fixes them.

**Suggested fix.** React to the route's query changes instead of only to page
creation — e.g. keep `BlocProvider` in the builder and put a small stateful
wrapper between it and `ChildProfileView`:

```dart
class _ChildProfileRoute extends StatefulWidget {
  const _ChildProfileRoute({required this.requested});
  final String? requested;
  ...
}
// initState + didUpdateWidget: when `requested != null` (and changed),
// context.read<FamilyBloc>().add(FamilyChildSelected(childId: requested));
```

`FamilyLoadRequested` still goes through `create` once; `selectChild` is
idempotent and membership-gated, so re-dispatching on updates is safe.
Alternative: have the view watch `GoRouterState.of(context)` in
`didChangeDependencies` and dispatch when the id changes.

**Impact.** Wrong child's profile (PIN state, coins, owed money, Pip, and the
remove action) in the most common navigation flow, whenever the Family branch
has been visited before.

---

## Verified sound (iteration-2 probes on `31a44b8`, all green)

| Probe | Result |
|---|---|
| P15-BUG-1a/b, 3, 6, 7, 8 (iteration-1 proofs, un-skipped) | all green — the fixes are real |
| P11 fallout: after removing Maya, her approval rows are gone (probe J) | ✓ |
| Unknown `?childId=` after a valid one falls back to the roster (probe C) | ✓ |
| 6 children, deep link to the 6th (probe D) | ✓ renders, no exception |
| Back from `/kid-pin` keeps the deep-linked child (probe E) | ✓ |
| Long name (`Maximilian-Alexander`) at 320 × 1.3 after the hero wrap change (probe F) | ✓ no overflow |
| Overlapping `selectChild` calls: last request wins, none persists a removed child (probes G/H) | ✓ |
| Deep-linked selection survives an app re-pump (probe I) | ✓ persisted |
| `selectChild` failure after `bloc.close()` (probe K) | ✓ no unhandled emit-after-close |
| Icons: `ic_quests.svg` is exactly the design's circle r9 + check; `NestlingIllustrations.coin` = `assets/illustrations/coin.svg` (the design's `coin.svg`) | ✓ (also confirmed visually by `5_ui.md` iteration 2) |
| ORCHESTRATOR_NOTES item 1 (full subtitles at 390) | ✓ test stage's `didExceedMaxLines` proof green; UI stage measured no `…` |
| ORCHESTRATOR_NOTES items 2/3 (circled check, coin) | ✓ assets verified; UI stage PASS |
| ORCHESTRATOR_NOTES item 4 (pronoun "their", DB quest counts) | ✓ not reported as findings anywhere here |
| Double-tap / rapid confirm, dark mode, kid-mode guard, money rounding, empty states | ✓ unchanged, covered by the green suite |
| Simulator policy | no simulator was booted, installed on, screenshotted or driven in this stage ✓ |

## Gates (run in `app/` on `31a44b8` + this stage's file)

```
$ dart format test/features/family/p15_bugs_test.dart
Formatted 1 file (0 changed) in 0.01 seconds.

$ flutter test --no-pub test/features/family/p15_bugs_test.dart
00:03 +6 ~2: All tests passed.        # six regression guards + two skips

$ flutter test --no-pub test/features/family        # snapshot ~19:40 BST
00:10 +252 ~2 -1: Some tests failed.
```

* The two `~` are this stage's new P15-BUG-9 proofs (skipped by design).
* The one `-1` is **not a product bug and not this stage's file**: the
  parallel test stage's in-flight
  `child_profile_selection_test.dart` → `P15-BUG-8 · an explicit clock decides
  which period counts` expects `0` one London day after the anchor
  (`31a44b8` gives `2`). Sunday 4 Oct 2026 01:00 London is still inside the
  London week Mon 28 Sep 00:00 – Sun 4 Oct 24:00, so the two weekly
  completions from Thu/Fri **must** count under the PERIODS ruling — the
  product is right and the test's expectation is wrong. Left to the test
  stage (its file was still being written at this snapshot; the suite was
  `+230` green before that file landed).
* `flutter analyze` at the same snapshot reports 10 lint infos, all in the
  test stage's in-flight `child_profile_selection_test.dart` /
  `child_profile_view_test.dart` (unused imports, an underscore local, missing
  EOF newline, …). **No issue is attributed to `p15_bugs_test.dart` or to any
  `lib/` file**; my file is format- and lint-clean.

No production file was changed by this stage: the only additions are the two
skipped P15-BUG-9 proofs in `app/test/features/family/p15_bugs_test.dart` and
this document.

VERDICT: FAIL
